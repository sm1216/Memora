import SwiftUI

@main
struct MemoraApp: App {
    @StateObject private var auth = AuthService()
    @StateObject private var store = MemoryStore()
    @StateObject private var nfc = NFCService()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(store)
                .environmentObject(nfc)
                .environmentObject(settings)
                .preferredColorScheme(settings.appearance.preferredColorScheme)
                .onOpenURL { url in
                    nfc.handleIncomingURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        nfc.handleIncomingURL(url)
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var nfc: NFCService

    var body: some View {
        Group {
            if auth.isSignedIn {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: auth.isSignedIn)
        // NFC tag opened app while logged out → continue as guest so the story can show
        .onChange(of: nfc.openRequest) { _, request in
            guard request != nil, !auth.isSignedIn else { return }
            auth.continueAsGuest(name: "Traveler")
        }
        .onAppear {
            if nfc.openRequest != nil, !auth.isSignedIn {
                auth.continueAsGuest(name: "Traveler")
            }
        }
    }
}
