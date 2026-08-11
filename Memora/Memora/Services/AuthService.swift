import Foundation
import AuthenticationServices
import CryptoKit
import SwiftUI

@MainActor
final class AuthService: NSObject, ObservableObject {
    @Published var user: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let client = SupabaseClient.shared
    private let userKey = "memora.user"
    private var currentNonce: String?

    var isSignedIn: Bool { user != nil }
    var googleConfigured: Bool { !AppConfig.googleClientID.isEmpty }

    override init() {
        super.init()
        // Restore Supabase session + local profile
        if client.isAuthenticated {
            let name = UserDefaults.standard.string(forKey: "memora.displayName")
            user = AppUser(
                id: client.userId ?? UUID().uuidString,
                displayName: name ?? (client.email?.split(separator: "@").first.map(String.init) ?? "Traveler"),
                email: client.email,
                photoURL: nil,
                provider: .email,
                createdAt: Date()
            )
        } else {
            loadLocal()
        }
    }

    private func loadLocal() {
        guard let data = UserDefaults.standard.data(forKey: userKey),
              let decoded = try? JSONDecoder().decode(AppUser.self, from: data) else { return }
        // Only restore guest offline without supabase session
        if decoded.provider == .guest {
            user = decoded
        }
    }

    private func persist(_ user: AppUser) {
        self.user = user
        UserDefaults.standard.set(user.displayName, forKey: "memora.displayName")
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    // MARK: - Email (Supabase)

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanEmail.contains("@"), cleanEmail.contains(".") else {
            errorMessage = "Enter a valid email like you@gmail.com"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        do {
            let session = try await client.signUp(
                email: cleanEmail,
                password: password,
                displayName: displayName
            )
            let metaName = session.user.user_metadata?["display_name"]?.stringValue
            let appUser = AppUser(
                id: session.user.id,
                displayName: metaName ?? displayName,
                email: session.user.email ?? cleanEmail,
                photoURL: nil,
                provider: .email,
                createdAt: Date()
            )
            persist(appUser)
            infoMessage = "Signed in. Email confirmation is not required."
        } catch {
            // If signup created user but no session, try immediate login (autoconfirm path)
            if case SupabaseError.needsEmailConfirmation = error {
                do {
                    let session = try await client.signIn(email: cleanEmail, password: password)
                    persist(AppUser(
                        id: session.user.id,
                        displayName: displayName,
                        email: cleanEmail,
                        photoURL: nil,
                        provider: .email,
                        createdAt: Date()
                    ))
                    return
                } catch {
                    errorMessage = error.localizedDescription
                    infoMessage = "Try Sign in with the same email and password."
                    return
                }
            }
            // Already registered → try login
            let msg = error.localizedDescription.lowercased()
            if msg.contains("already") || msg.contains("exists") {
                do {
                    await signIn(email: cleanEmail, password: password)
                    if user != nil { return }
                }
            }
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanEmail.contains("@") else {
            errorMessage = "Enter a valid email."
            return
        }
        do {
            let session = try await client.signIn(email: cleanEmail, password: password)
            let appUser = AppUser(
                id: session.user.id,
                displayName: session.user.user_metadata?["display_name"]?.stringValue
                    ?? session.user.email?.split(separator: "@").first.map(String.init)
                    ?? "Traveler",
                email: session.user.email ?? cleanEmail,
                photoURL: nil,
                provider: .email,
                createdAt: Date()
            )
            persist(appUser)
        } catch {
            errorMessage = error.localizedDescription
            infoMessage = "Tip: use the same password you signed up with. Guest works offline without email."
        }
    }

    func continueAsGuest(name: String = "Traveler") {
        client.clearSession()
        let guest = AppUser(
            id: UUID().uuidString,
            displayName: name,
            email: nil,
            photoURL: nil,
            provider: .guest,
            createdAt: Date()
        )
        persist(guest)
    }

    func signOut() {
        Task { await client.signOut() }
        user = nil
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    func updateProfile(displayName: String) {
        guard var u = user else { return }
        u.displayName = displayName
        persist(u)
        guard client.isAuthenticated, let uid = client.userId else { return }
        Task {
            struct Patch: Encodable { let display_name: String; let updated_at: String }
            let iso = ISO8601DateFormatter().string(from: Date())
            _ = try? await client.update(
                table: "profiles",
                query: "id=eq.\(uid)",
                patch: Patch(display_name: displayName, updated_at: iso),
                returning: [ProfileRow].self
            )
        }
    }

    struct ProfileRow: Decodable {
        let id: String
        let display_name: String?
    }

    // MARK: - Google (optional OAuth)

    func signInWithGoogle() async {
        guard googleConfigured else {
            errorMessage = "Add Google Client ID in Config.swift and enable Google in Supabase Auth providers."
            return
        }
        // Prefer Supabase OAuth URL
        isLoading = true
        defer { isLoading = false }
        let redirect = "\(AppConfig.urlScheme)://auth/callback"
        var components = URLComponents(url: AppConfig.supabaseURL.appendingPathComponent("auth/v1/authorize"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirect)
        ]
        guard let authURL = components.url else {
            errorMessage = "Bad OAuth URL"
            return
        }
        do {
            let callback = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
                let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: AppConfig.urlScheme) { url, error in
                    if let error { cont.resume(throwing: error); return }
                    guard let url else { cont.resume(throwing: URLError(.badServerResponse)); return }
                    cont.resume(returning: url)
                }
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                if !session.start() { cont.resume(throwing: URLError(.unknown)) }
            }
            // Supabase returns tokens in fragment or query
            let comps = URLComponents(url: callback, resolvingAgainstBaseURL: false)
            var params: [String: String] = [:]
            if let frag = comps?.fragment {
                for pair in frag.split(separator: "&") {
                    let p = pair.split(separator: "=", maxSplits: 1).map(String.init)
                    if p.count == 2 { params[p[0]] = p[1].removingPercentEncoding ?? p[1] }
                }
            }
            comps?.queryItems?.forEach { params[$0.name] = $0.value ?? "" }
            guard let access = params["access_token"], let refresh = params["refresh_token"] else {
                errorMessage = "Google OAuth did not return tokens. Configure Google in Supabase dashboard."
                return
            }
            // Fetch user
            var req = URLRequest(url: AppConfig.supabaseURL.appendingPathComponent("auth/v1/user"))
            req.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(access)", forHTTPHeaderField: "Authorization")
            let (data, _) = try await URLSession.shared.data(for: req)
            struct U: Decodable { let id: String; let email: String? }
            let u = try JSONDecoder().decode(U.self, from: data)
            let session = SupabaseClient.Session(
                access_token: access,
                refresh_token: refresh,
                expires_at: nil,
                user: .init(id: u.id, email: u.email, user_metadata: nil)
            )
            // Apply via private path — re-signin style
            UserDefaults.standard.set(try? JSONEncoder().encode(session), forKey: "memora.supabase.session")
            client.loadSession()
            persist(AppUser(id: u.id, displayName: u.email?.split(separator: "@").first.map(String.init) ?? "Google User", email: u.email, photoURL: nil, provider: .google, createdAt: Date()))
        } catch {
            let ns = error as NSError
            if ns.domain == ASWebAuthenticationSessionErrorDomain { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple (paid team only — kept for future)

    func prepareAppleNonce() -> String {
        let nonce = randomNonce()
        currentNonce = nonce
        return sha256(nonce)
    }

    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Apple Sign-In failed."
                return
            }
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }.joined(separator: " ")
            let name = fullName.isEmpty ? "Apple User" : fullName
            persist(AppUser(id: credential.user, displayName: name, email: credential.email, photoURL: nil, provider: .apple, createdAt: Date()))
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            errorMessage = error.localizedDescription
        }
    }

    private func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }
            for random in randoms where remaining > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
