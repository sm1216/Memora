import SwiftUI

struct ScanView: View {
    @EnvironmentObject var nfc: NFCService
    @EnvironmentObject var store: MemoryStore
    @Binding var selectedTab: MainTab
    @State private var openedMemory: Memory?
    @State private var showManual = false
    @State private var manualCode = ""

    var body: some View {
        ZStack {
            AppTheme.night.ignoresSafeArea()
            LinearGradient(
                colors: [AppTheme.clay.opacity(0.18), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { selectedTab = .home } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.inkOnNight)
                            .padding(11)
                            .background(AppTheme.nightElevated)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                SoftChip(text: "Free NFC path", icon: "checkmark.seal.fill")
                    .padding(.top, 10)

                Spacer()

                Text("STICKERS")
                    .font(.memoraMicro(11))
                    .tracking(2.2)
                    .foregroundStyle(AppTheme.clay)
                Text("One tap")
                    .font(.memoraDisplay(34))
                    .foregroundStyle(AppTheme.inkOnNight)
                    .padding(.top, 6)
                Text("To remember.")
                    .font(.memoraDisplay(34))
                    .foregroundStyle(AppTheme.clay)

                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    Text(nfc.isListeningForSystemTap ? "Listening…" : "Scan a sticker")
                        .font(.memoraHeadline(20))
                        .foregroundStyle(AppTheme.ink)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Hold sticker to the top of iPhone", systemImage: "wave.3.right")
                        Label("iOS opens the story in Memories", systemImage: "link")
                    }
                    .font(.memoraCaption(13))
                    .foregroundStyle(AppTheme.inkSecondary)

                    ZStack {
                        Circle()
                            .stroke(AppTheme.clay.opacity(0.35), lineWidth: 2.5)
                            .frame(width: 88, height: 88)
                        Image(systemName: nfc.isListeningForSystemTap ? "wave.3.right" : "iphone")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(AppTheme.clay)
                            .symbolEffect(.pulse, isActive: nfc.isListeningForSystemTap)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                    Text(nfc.statusMessage.isEmpty
                         ? "Tap Listen, then hold a sticker with a Memories URL."
                         : nfc.statusMessage)
                        .font(.memoraBody(14))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    if let err = nfc.errorMessage {
                        Text(err)
                            .font(.memoraCaption(12))
                            .foregroundStyle(AppTheme.clayDeep)
                            .multilineTextAlignment(.center)
                    }

                    if let sid = nfc.lastScannedShortId {
                        Text("Last tag · \(sid)")
                            .font(.memoraCaption(12))
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.clay)
                            .frame(maxWidth: .infinity)
                    }

                    Button {
                        nfc.scan()
                    } label: {
                        Text(nfc.isListeningForSystemTap || nfc.isScanning ? "Listening… hold tag" : "Listen for tag")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if nfc.isListeningForSystemTap {
                        Button("Stop") { nfc.stopListening() }
                            .buttonStyle(GhostButtonStyle())
                            .frame(maxWidth: .infinity)
                    }

                    Button("Enter code manually") { showManual = true }
                        .buttonStyle(GhostButtonStyle())
                        .frame(maxWidth: .infinity)
                }
                .padding(22)
                .background(AppTheme.paperElevated)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous))
                .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
                .padding(.horizontal, 20)
                .padding(.bottom, AppTheme.tabBarHeight + 24)
            }
        }
        // MainTabView also opens stories from nfc.openRequest (covers cold start).
        // Keep local sheet for when user is already on Scan tab.
        .onChange(of: nfc.openRequest) { _, request in
            guard let request, let memory = store.memory(shortId: request.shortId) else { return }
            openedMemory = memory
        }
        .sheet(item: $openedMemory) { memory in
            NavigationStack { MemoryDetailView(memory: memory, presentation: .sheet) }
        }
        .alert("Open memory", isPresented: $showManual) {
            TextField("Short code e.g. ROME26", text: $manualCode)
            Button("Open") {
                let code = manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
                if let m = store.memory(shortId: code) {
                    openedMemory = m
                } else {
                    nfc.lastScannedShortId = code
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Type the short id from your memory / tag.")
        }
    }
}
