import SwiftUI

enum MainTab: Hashable {
    case home, memories, scan, tags, profile
}

struct MainTabView: View {
    @EnvironmentObject var nfc: NFCService
    @EnvironmentObject var store: MemoryStore
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var settings: AppSettings

    @State private var selected: MainTab = .home
    @State private var openedMemory: Memory?
    @State private var missingCode: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .home:
                    HomeGlobeView(selectedTab: $selected)
                case .memories:
                    MemoriesBoardView()
                case .scan:
                    ScanView(selectedTab: $selected)
                case .tags:
                    TagsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !settings.tabBarHidden {
                CustomTabBar(selected: $selected)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: settings.tabBarHidden)
        .ignoresSafeArea(.keyboard)
        .onChange(of: nfc.openRequest) { _, request in
            guard let request else { return }
            openMemory(shortId: request.shortId)
        }
        .onAppear {
            if let request = nfc.openRequest {
                openMemory(shortId: request.shortId)
            } else if let sid = nfc.lastScannedShortId {
                openMemory(shortId: sid)
            }
        }
        .sheet(item: $openedMemory) { memory in
            NavigationStack {
                MemoryDetailView(memory: memory, presentation: .sheet)
            }
            .presentationDragIndicator(.visible)
        }
        .alert("Story not found", isPresented: Binding(
            get: { missingCode != nil },
            set: { if !$0 { missingCode = nil } }
        )) {
            Button("OK", role: .cancel) { missingCode = nil }
        } message: {
            Text("No memory with code “\(missingCode ?? "")” on this phone. Open Write NFC on that story and re-link.")
        }
    }

    private func openMemory(shortId: String) {
        let code = shortId.trimmingCharacters(in: .whitespacesAndNewlines)
        if let memory = store.memory(shortId: code) {
            selected = .memories
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                openedMemory = memory
                nfc.clearOpenRequest()
            }
        } else {
            missingCode = code.uppercased()
            nfc.clearOpenRequest()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: MainTab

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home, icon: "globe.americas.fill", label: "Map")
            tabButton(.memories, icon: "rectangle.stack.fill", label: "Board")

            Button {
                selected = .scan
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.clay, AppTheme.clayDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 58, height: 58)
                            .shadow(color: AppTheme.clay.opacity(0.40), radius: 10, y: 4)
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppTheme.inkOnClay)
                            .symbolEffect(.pulse, isActive: selected == .scan)
                    }
                }
            }
            .offset(y: -16)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Scan NFC")

            tabButton(.tags, icon: "tag.fill", label: "Tags")
            tabButton(.profile, icon: "person.fill", label: "You")
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.paperElevated)
                .shadow(color: .black.opacity(0.10), radius: 16, y: 6)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppTheme.ink.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 2)
        )
    }

    private func tabButton(_ tab: MainTab, icon: String, label: String) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) { selected = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: selected == tab ? .semibold : .regular))
                Text(label)
                    .font(.memoraMicro(10))
            }
            .foregroundStyle(selected == tab ? AppTheme.clay : AppTheme.inkTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
