import Foundation

/// Lightweight Supabase REST + GoTrue client (no SPM dependency).
@MainActor
final class SupabaseClient: ObservableObject {
    static let shared = SupabaseClient()

    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var userId: String?
    @Published private(set) var email: String?

    private let base = AppConfig.supabaseURL
    private let anon = AppConfig.supabaseAnonKey
    private let defaults = UserDefaults.standard
    private let sessionKey = "memora.supabase.session"

    struct Session: Codable {
        var access_token: String
        var refresh_token: String
        var expires_at: TimeInterval?
        var user: User
    }

    struct User: Codable {
        var id: String
        var email: String?
        var email_confirmed_at: String?
        var user_metadata: [String: JSONValue]?
    }

    /// Signup may return session OR only user when confirmation was required.
    struct SignUpResponse: Codable {
        var access_token: String?
        var refresh_token: String?
        var expires_at: TimeInterval?
        var user: User?
        // GoTrue sometimes nests session
        var session: NestedSession?
        var id: String? // bare user shape
        var email: String?
        var msg: String?
        var error_code: String?
        var error: String?
        var message: String?

        struct NestedSession: Codable {
            var access_token: String?
            var refresh_token: String?
            var user: User?
        }

        var resolvedSession: Session? {
            if let at = access_token, let rt = refresh_token, let u = user {
                return Session(access_token: at, refresh_token: rt, expires_at: expires_at, user: u)
            }
            if let s = session, let at = s.access_token, let rt = s.refresh_token, let u = s.user ?? user {
                return Session(access_token: at, refresh_token: rt, expires_at: nil, user: u)
            }
            return nil
        }

        var resolvedUser: User? {
            if let u = user { return u }
            if let id {
                return User(id: id, email: email, email_confirmed_at: nil, user_metadata: nil)
            }
            return session?.user
        }
    }

    enum JSONValue: Codable {
        case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if c.decodeNil() { self = .null; return }
            if let v = try? c.decode(Bool.self) { self = .bool(v); return }
            if let v = try? c.decode(Double.self) { self = .number(v); return }
            if let v = try? c.decode(String.self) { self = .string(v); return }
            if let v = try? c.decode([String: JSONValue].self) { self = .object(v); return }
            if let v = try? c.decode([JSONValue].self) { self = .array(v); return }
            self = .null
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self {
            case .string(let v): try c.encode(v)
            case .number(let v): try c.encode(v)
            case .bool(let v): try c.encode(v)
            case .object(let v): try c.encode(v)
            case .array(let v): try c.encode(v)
            case .null: try c.encodeNil()
            }
        }
        var stringValue: String? {
            if case .string(let s) = self { return s }
            return nil
        }
    }

    var isAuthenticated: Bool { accessToken != nil && userId != nil }

    init() {
        loadSession()
    }

    func loadSession() {
        guard let data = defaults.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(Session.self, from: data) else { return }
        apply(session)
    }

    private func apply(_ session: Session) {
        accessToken = session.access_token
        refreshToken = session.refresh_token
        userId = session.user.id
        email = session.user.email
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: sessionKey)
        }
    }

    func clearSession() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        email = nil
        defaults.removeObject(forKey: sessionKey)
    }

    // MARK: - Auth

    /// Returns a session when auto-confirm is on; otherwise returns user-only and throws needsConfirmation.
    func signUp(email: String, password: String, displayName: String) async throws -> Session {
        struct Body: Encodable {
            let email: String
            let password: String
            let data: [String: String]
        }
        let body = Body(email: email, password: password, data: ["display_name": displayName])
        let data = try await requestRaw(
            path: "/auth/v1/signup",
            method: "POST",
            bodyData: try JSONEncoder().encode(body),
            auth: false
        )
        let parsed = try JSONDecoder().decode(SignUpResponse.self, from: data)
        if let session = parsed.resolvedSession {
            apply(session)
            return session
        }
        // No session — often email confirmation (should be rare after autoconfirm)
        if let user = parsed.resolvedUser {
            throw SupabaseError.needsEmailConfirmation(user.email ?? email)
        }
        throw SupabaseError.api(friendlyAuthError(from: data))
    }

    func signIn(email: String, password: String) async throws -> Session {
        struct Body: Encodable { let email: String; let password: String }
        let data = try await requestRaw(
            path: "/auth/v1/token?grant_type=password",
            method: "POST",
            bodyData: try JSONEncoder().encode(Body(email: email, password: password)),
            auth: false
        )
        do {
            let session = try JSONDecoder().decode(Session.self, from: data)
            apply(session)
            return session
        } catch {
            throw SupabaseError.api(friendlyAuthError(from: data))
        }
    }

    func resendConfirmation(email: String) async throws {
        struct Body: Encodable {
            let type = "signup"
            let email: String
        }
        _ = try await requestRaw(
            path: "/auth/v1/resend",
            method: "POST",
            bodyData: try JSONEncoder().encode(Body(email: email)),
            auth: false
        )
    }

    func signOut() async {
        _ = try? await requestRaw(path: "/auth/v1/logout", method: "POST", bodyData: nil, auth: true)
        clearSession()
    }

    func refreshIfNeeded() async {
        guard let refresh = refreshToken else { return }
        struct Body: Encodable { let refresh_token: String }
        do {
            let data = try await requestRaw(
                path: "/auth/v1/token?grant_type=refresh_token",
                method: "POST",
                bodyData: try JSONEncoder().encode(Body(refresh_token: refresh)),
                auth: false
            )
            let session = try JSONDecoder().decode(Session.self, from: data)
            apply(session)
        } catch {}
    }

    private func friendlyAuthError(from data: Data) -> String {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let code = (obj["error_code"] as? String) ?? ""
            let msg = (obj["msg"] as? String)
                ?? (obj["error_description"] as? String)
                ?? (obj["message"] as? String)
                ?? (obj["error"] as? String)
                ?? String(data: data, encoding: .utf8)
                ?? "Auth failed"
            switch code {
            case "invalid_credentials":
                return "Wrong email or password. If you just signed up, try again — confirmation is now off."
            case "email_address_invalid":
                return "Use a real email address (e.g. your Gmail)."
            case "user_already_exists", "email_exists":
                return "That email is already registered. Tap Sign in instead."
            case "over_email_send_rate_limit":
                return "Too many emails sent. Wait a minute, then Sign in (confirmation emails are disabled now)."
            case "weak_password":
                return "Password too weak. Use at least 6 characters."
            case "email_not_confirmed":
                return "Email not confirmed yet. Confirmation is disabled now — try Sign in again, or Sign up with a new email."
            default:
                return msg
            }
        }
        return String(data: data, encoding: .utf8) ?? "Auth failed"
    }

    // MARK: - REST helpers

    func select<T: Decodable>(
        table: String,
        query: String = "",
        type: T.Type = T.self
    ) async throws -> T {
        try await request(path: "/rest/v1/\(table)\(query.isEmpty ? "" : "?\(query)")", method: "GET", body: Optional<String>.none, auth: true)
    }

    func insert<T: Encodable, R: Decodable>(table: String, rows: T, returning: R.Type = R.self) async throws -> R {
        try await request(
            path: "/rest/v1/\(table)?select=*",
            method: "POST",
            body: rows,
            auth: true,
            extraHeaders: ["Prefer": "return=representation"]
        )
    }

    func upsert<T: Encodable, R: Decodable>(table: String, rows: T, onConflict: String, returning: R.Type = R.self) async throws -> R {
        try await request(
            path: "/rest/v1/\(table)?on_conflict=\(onConflict)&select=*",
            method: "POST",
            body: rows,
            auth: true,
            extraHeaders: ["Prefer": "resolution=merge-duplicates,return=representation"]
        )
    }

    func update<T: Encodable, R: Decodable>(table: String, query: String, patch: T, returning: R.Type = R.self) async throws -> R {
        try await request(
            path: "/rest/v1/\(table)?\(query)&select=*",
            method: "PATCH",
            body: patch,
            auth: true,
            extraHeaders: ["Prefer": "return=representation"]
        )
    }

    func delete(table: String, query: String) async throws {
        _ = try await requestRaw(path: "/rest/v1/\(table)?\(query)", method: "DELETE", bodyData: nil, auth: true)
    }

    func upload(path: String, data: Data, contentType: String = "image/jpeg") async throws -> String {
        let objectPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        let url = base.appendingPathComponent("storage/v1/object/\(AppConfig.supabaseStorageBucket)/\(objectPath)")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(anon, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken ?? anon)", forHTTPHeaderField: "Authorization")
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.setValue("true", forHTTPHeaderField: "x-upsert")
        req.httpBody = data
        let (respData, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.api(String(data: respData, encoding: .utf8) ?? "upload failed")
        }
        return publicURL(for: path)
    }

    func publicURL(for path: String) -> String {
        "\(base.absoluteString)/storage/v1/object/public/\(AppConfig.supabaseStorageBucket)/\(path)"
    }

    private func request<T: Decodable, B: Encodable>(
        path: String,
        method: String,
        body: B?,
        auth: Bool,
        extraHeaders: [String: String] = [:]
    ) async throws -> T {
        let data: Data?
        if let body { data = try JSONEncoder().encode(body) } else { data = nil }
        let respData = try await requestRaw(path: path, method: method, bodyData: data, auth: auth, extraHeaders: extraHeaders)
        do {
            return try JSONDecoder().decode(T.self, from: respData)
        } catch {
            throw SupabaseError.decode("\(error)\n\(String(data: respData, encoding: .utf8) ?? "")")
        }
    }

    private func requestRaw(
        path: String,
        method: String,
        bodyData: Data?,
        auth: Bool,
        extraHeaders: [String: String] = [:]
    ) async throws -> Data {
        guard let url = URL(string: base.absoluteString + path) else {
            throw SupabaseError.api("Bad URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(anon, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if auth, let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            req.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
        }
        for (k, v) in extraHeaders { req.setValue(v, forHTTPHeaderField: k) }
        req.httpBody = bodyData
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw SupabaseError.api("No response") }
        if !(200...299).contains(http.statusCode) {
            throw SupabaseError.api(friendlyAuthError(from: data))
        }
        return data
    }
}

enum SupabaseError: LocalizedError {
    case api(String)
    case decode(String)
    case needsEmailConfirmation(String)

    var errorDescription: String? {
        switch self {
        case .api(let s), .decode(let s): return s
        case .needsEmailConfirmation(let email):
            return "Account created for \(email). Email confirmation was required before — it is now disabled. Tap Sign in with the same password."
        }
    }
}
