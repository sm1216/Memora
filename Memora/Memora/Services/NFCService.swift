import Foundation
import CoreNFC
import UIKit

/// Free-tier NFC strategy (no $99 Apple Developer Program required):
///
/// 1) **READ (works free)**: Write tags as NDEF *URL* records (`memora://m/CODE`).
///    iOS system NFC opens that URL into this app via `onOpenURL` — no CoreNFC entitlement needed.
/// 2) **WRITE (works free)**: Copy URL → write with free App Store apps (NFC Tools / Shortcuts).
///    Optional: try CoreNFC if the binary somehow has the entitlement.
/// 3) **CoreNFC in-app scan/write**: only if Apple signed the NFC entitlement (paid team).
///
/// There is no supported way to force Apple’s free Personal Team to grant the NFC entitlement.
/// This hybrid flow is the real working path for free accounts.
@MainActor
final class NFCService: NSObject, ObservableObject {
    @Published var statusMessage = ""
    @Published var lastScannedURL: URL?
    @Published var lastScannedShortId: String?
    @Published var isScanning = false
    @Published var errorMessage: String?
    /// True while waiting for system NFC / deep link to open a tag URL.
    @Published var isListeningForSystemTap = false
    @Published var lastWriteURL: String?
    /// UI should open this memory when set (each request is unique so onChange always fires).
    @Published var openRequest: MemoryOpenRequest?

    struct MemoryOpenRequest: Identifiable, Equatable {
        let id: UUID
        let shortId: String
        init(shortId: String) {
            self.id = UUID()
            self.shortId = shortId
        }
    }

    private var session: NFCNDEFReaderSession?
    private var writePayload: String?
    private var mode: Mode = .read
    private var continuation: CheckedContinuation<Result<String, Error>, Never>?

    enum Mode { case read, write }

    /// Hardware can do NFC RF (iPhone 7+). Does NOT mean CoreNFC API is entitled.
    var hardwareNFC: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return NFCNDEFReaderSession.readingAvailable
        #endif
    }

    /// Always true on device for product UX — free path always works.
    var isAvailable: Bool { true }

    /// CoreNFC sessions may work only with paid-team entitlement.
    var coreNFCLikelyEntitled: Bool {
        // Free Personal Team builds ship without NFC entitlement.
        // We still *try* CoreNFC; if it fails we fall back to free path.
        hardwareNFC
    }

    // MARK: - Scan

    /// Prefer free system-NFC listen; also fire CoreNFC if possible.
    func scan() {
        errorMessage = nil
        #if targetEnvironment(simulator)
        lastScannedShortId = "ROME26"
        statusMessage = "Simulator mock → ROME26"
        return
        #endif

        // Free path: listen for system/deep-link open after user holds tag to phone
        isListeningForSystemTap = true
        statusMessage = "Hold the TOP of your iPhone to the sticker. iOS will open the tag URL into Memories — no paid Apple account needed."

        // Also try CoreNFC (succeeds only if entitlement present)
        if hardwareNFC {
            mode = .read
            writePayload = nil
            startSession(alert: "Hold near sticker… (or dismiss and use system NFC tap)")
        }
    }

    func stopListening() {
        isListeningForSystemTap = false
        cancel()
    }

    /// Called from App when a URL opens (system NFC, Safari, Shortcuts, etc.)
    func handleIncomingURL(_ url: URL) {
        lastScannedURL = url
        #if DEBUG
        print("[Memora NFC] open URL:", url.absoluteString,
              "scheme:", url.scheme ?? "-",
              "host:", url.host ?? "-",
              "path:", url.path,
              "pathComponents:", url.pathComponents)
        #endif
        if let sid = Self.shortId(from: url) {
            routeToMemory(shortId: sid)
        } else {
            errorMessage = "Tag opened app but URL wasn’t recognized: \(url.absoluteString)"
            statusMessage = "Couldn’t parse story id from \(url.absoluteString)"
        }
    }

    /// Open a story by short code (from NFC, manual entry, etc.)
    func routeToMemory(shortId: String) {
        let sid = shortId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !sid.isEmpty else { return }
        lastScannedShortId = sid
        openRequest = MemoryOpenRequest(shortId: sid)
        statusMessage = "Opening story → \(sid)"
        isListeningForSystemTap = false
        errorMessage = nil
        session?.invalidate()
        isScanning = false
    }

    func clearOpenRequest() {
        openRequest = nil
    }

    // MARK: - Write

    /// Try CoreNFC write; on free team this usually fails — caller should use freeWrite helpers.
    func write(urlString: String) async -> Result<String, Error> {
        lastWriteURL = urlString
        #if targetEnvironment(simulator)
        return .success("Simulated write: \(urlString)")
        #endif
        guard hardwareNFC else {
            return .failure(NFCError.unavailable)
        }
        return await withCheckedContinuation { cont in
            self.continuation = cont
            self.mode = .write
            self.writePayload = urlString
            startSession(alert: "Hold iPhone near blank NFC sticker to write…")
        }
    }

    /// Mark write complete after user wrote the URL with Shortcuts / NFC Tools (free).
    func confirmExternalWrite(urlString: String) {
        lastWriteURL = urlString
        statusMessage = "Tag linked (written via free NFC tool)"
        errorMessage = nil
    }

    func copyToPasteboard(_ string: String) {
        UIPasteboard.general.string = string
        statusMessage = "Copied — paste into NFC Tools or Shortcuts"
    }

    /// Open NFC Tools (free App Store app) if installed.
    @discardableResult
    func openNFCTools() -> Bool {
        // Common schemes used by NFC utilities (best-effort)
        let candidates = [
            "nfctools://",
            "nfc-tools://",
            "nfctools://"
        ]
        for s in candidates {
            if let u = URL(string: s), UIApplication.shared.canOpenURL(u) {
                UIApplication.shared.open(u)
                return true
            }
        }
        // App Store search for NFC Tools
        if let u = URL(string: "itms-apps://apple.com/app/id1252962749") {
            UIApplication.shared.open(u)
        }
        return false
    }

    /// Open Shortcuts so user can run “Write NFC Tag” with clipboard URL.
    func openShortcutsForWrite() {
        // Bring user to Shortcuts; they use Automation → NFC or a Write NFC action
        if let u = URL(string: "shortcuts://") {
            UIApplication.shared.open(u)
        }
    }

    // MARK: - CoreNFC session

    private func startSession(alert: String) {
        errorMessage = nil
        isScanning = true
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = alert
        session?.begin()
    }

    func cancel() {
        session?.invalidate()
        session = nil
        isScanning = false
        if let cont = continuation {
            continuation = nil
            cont.resume(returning: .failure(NFCError.cancelled))
        }
    }

    static func shortId(from url: URL) -> String? {
        // Robust parse for memora://m/ROME26, memora:///m/ROME26, https://x/m/ROME26, etc.
        let absolute = url.absoluteString

        if let regex = try? NSRegularExpression(pattern: #"(?i)m/+([A-Z0-9]{3,12})"#) {
            let range = NSRange(absolute.startIndex..<absolute.endIndex, in: absolute)
            if let match = regex.firstMatch(in: absolute, range: range),
               match.numberOfRanges > 1,
               let r = Range(match.range(at: 1), in: absolute) {
                return String(absolute[r]).uppercased()
            }
        }

        // memora://m/SHORT  → host=m, path=/SHORT
        if url.scheme?.lowercased() == AppConfig.urlScheme {
            if (url.host?.lowercased() == "m") {
                let code = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if !code.isEmpty { return code.uppercased() }
            }
            let parts = url.pathComponents.filter { $0 != "/" }
            if let idx = parts.firstIndex(where: { $0.lowercased() == "m" }),
               parts.indices.contains(idx + 1) {
                return parts[idx + 1].uppercased()
            }
            // memora:ROME26 or memora://ROME26
            if let host = url.host, host.lowercased() != "m", host.count >= 3 {
                return host.uppercased()
            }
        }

        let parts = url.pathComponents.filter { $0 != "/" }
        if let idx = parts.firstIndex(where: { $0.lowercased() == "m" }),
           parts.indices.contains(idx + 1) {
            return parts[idx + 1].uppercased()
        }

        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let id = items.first(where: { $0.name == "id" || $0.name == "short" })?.value,
           !id.isEmpty {
            return id.uppercased()
        }

        let last = url.lastPathComponent.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if last.count >= 3, last.count <= 12,
           last.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil,
           last.lowercased() != "m" {
            return last.uppercased()
        }
        return nil
    }

    /// Canonical free-path URL to store on tags
    static func tagURL(for shortId: String) -> URL {
        URL(string: "\(AppConfig.urlScheme)://m/\(shortId)")!
    }
}

enum NFCError: LocalizedError {
    case unavailable
    case cancelled
    case invalidPayload
    case writeFailed(String)
    case needsFreePath

    var errorDescription: String? {
        switch self {
        case .unavailable: return "This iPhone has no NFC hardware."
        case .cancelled: return "Cancelled."
        case .invalidPayload: return "Invalid NFC payload."
        case .writeFailed(let s): return s
        case .needsFreePath:
            return "In-app CoreNFC is blocked on free Apple IDs. Use free write: Copy URL → NFC Tools / Shortcuts (still real NFC)."
        }
    }
}

extension NFCService: NFCNDEFReaderSessionDelegate {
    nonisolated func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            self.isScanning = false
            let ns = error as NSError
            if ns.domain == NFCReaderError.errorDomain,
               ns.code == NFCReaderError.readerSessionInvalidationErrorUserCanceled.rawValue {
                if let cont = self.continuation {
                    self.continuation = nil
                    cont.resume(returning: .failure(NFCError.cancelled))
                }
                return
            }
            if ns.domain == NFCReaderError.errorDomain,
               ns.code == NFCReaderError.readerSessionInvalidationErrorFirstNDEFTagRead.rawValue {
                return
            }
            // Entitlement missing → guide free path, don't dead-end
            let msg = error.localizedDescription
            if msg.localizedCaseInsensitiveContains("entitlement")
                || msg.localizedCaseInsensitiveContains("not available")
                || ns.code == NFCReaderError.readerSessionInvalidationErrorSystemIsBusy.rawValue {
                self.errorMessage = nil
                self.statusMessage = "In-app NFC API locked by Apple free team. Use free path: hold tag to phone (system opens it), or write with NFC Tools using the copied URL."
                if let cont = self.continuation {
                    self.continuation = nil
                    cont.resume(returning: .failure(NFCError.needsFreePath))
                }
                return
            }
            self.errorMessage = msg
            if let cont = self.continuation {
                self.continuation = nil
                cont.resume(returning: .failure(error))
            }
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        Task { @MainActor in
            guard mode == .read else { return }
            for message in messages {
                for record in message.records {
                    if let url = record.wellKnownTypeURIPayload() {
                        handleIncomingURL(url)
                        session.alertMessage = "Memory found!"
                        session.invalidate()
                        return
                    }
                }
            }
            session.alertMessage = "No URL on tag."
            session.invalidate()
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        Task { @MainActor in
            if mode == .read, let tag = tags.first {
                session.connect(to: tag) { error in
                    if let error {
                        session.invalidate(errorMessage: error.localizedDescription)
                        return
                    }
                    tag.readNDEF { message, error in
                        if let message {
                            self.readerSession(session, didDetectNDEFs: [message])
                        } else {
                            session.invalidate(errorMessage: error?.localizedDescription ?? "Empty tag")
                        }
                    }
                }
                return
            }

            guard mode == .write, let payloadString = writePayload, let tag = tags.first else { return }
            if tags.count > 1 {
                session.alertMessage = "One tag only."
                session.restartPolling()
                return
            }

            session.connect(to: tag) { error in
                if let error {
                    session.invalidate(errorMessage: error.localizedDescription)
                    Task { @MainActor in
                        self.continuation?.resume(returning: .failure(error))
                        self.continuation = nil
                        self.isScanning = false
                    }
                    return
                }
                tag.queryNDEFStatus { status, _, error in
                    if let error {
                        session.invalidate(errorMessage: error.localizedDescription)
                        Task { @MainActor in
                            self.continuation?.resume(returning: .failure(error))
                            self.continuation = nil
                            self.isScanning = false
                        }
                        return
                    }
                    guard status != .notSupported, status != .readOnly,
                          let url = URL(string: payloadString),
                          let uriPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) else {
                        session.invalidate(errorMessage: "Can't write this tag.")
                        Task { @MainActor in
                            self.continuation?.resume(returning: .failure(NFCError.invalidPayload))
                            self.continuation = nil
                            self.isScanning = false
                        }
                        return
                    }
                    let message = NFCNDEFMessage(records: [uriPayload])
                    tag.writeNDEF(message) { error in
                        if let error {
                            session.invalidate(errorMessage: error.localizedDescription)
                            Task { @MainActor in
                                self.continuation?.resume(returning: .failure(error))
                                self.continuation = nil
                                self.isScanning = false
                            }
                            return
                        }
                        session.alertMessage = "Written!"
                        session.invalidate()
                        Task { @MainActor in
                            self.statusMessage = "Wrote \(payloadString)"
                            self.continuation?.resume(returning: .success(payloadString))
                            self.continuation = nil
                            self.isScanning = false
                        }
                    }
                }
            }
        }
    }
}
