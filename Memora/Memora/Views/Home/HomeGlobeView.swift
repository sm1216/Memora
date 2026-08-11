import SwiftUI

struct HomeGlobeView: View {
    @EnvironmentObject var store: MemoryStore
    @Binding var selectedTab: MainTab
    @State private var selectedMemory: Memory?
    @State private var showPager = false
    /// Drives globe fly-to + pin highlight while half-sheet is open.
    @State private var focusedPinId: UUID?

    /// Memories that have a map pin (real coords).
    private var pinMemories: [Memory] {
        store.memories
            .filter { abs($0.latitude) > 0.0001 || abs($0.longitude) > 0.0001 }
            .sorted { $0.startDate > $1.startDate }
    }

    private var globeMemories: [Memory] {
        pinMemories.isEmpty ? store.memories : pinMemories
    }

    var body: some View {
        ZStack {
            AppTheme.night.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    BrandWordmark(light: true, compact: true)
                    Spacer()
                    Button {
                        selectedTab = .profile
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.inkOnNight.opacity(0.9))
                    }
                    .accessibilityLabel("Profile")
                }
                .padding(.horizontal, AppTheme.space20)
                .padding(.top, 8)

                ZStack(alignment: .topLeading) {
                    MapboxGlobeView(
                        memories: globeMemories,
                        focusedId: focusedPinId
                    ) { memory in
                        focusedPinId = memory.id
                        selectedMemory = memory
                        showPager = true
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        SoftChip(text: "Tap pin → half story", icon: "hand.tap.fill")
                        SoftChip(text: "Swipe · globe spins", icon: "globe.americas.fill")
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                }
                .padding(.top, 8)

                FloatingPanel(night: true) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(pinMemories.count) pins")
                                .font(.memoraCallout(15))
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.inkOnNight)
                            Text(showPager
                                 ? "Swipe stories · lines stay on globe"
                                 : "Tap a pin · see journey lines")
                                .font(.memoraCaption(12))
                                .foregroundStyle(AppTheme.inkOnNight.opacity(0.55))
                        }
                        Spacer()
                        Button {
                            selectedTab = .memories
                        } label: {
                            Text("Board")
                                .font(.memoraCallout(13))
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.clay)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(AppTheme.paperElevated)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, AppTheme.space16)
                .padding(.top, 10)
                .padding(.bottom, AppTheme.tabBarHeight + 12)
            }
        }
        // Half sheet so globe + route lines stay visible above.
        .sheet(isPresented: $showPager) {
            Group {
                if let initial = selectedMemory {
                    MemoryPagerSheet(
                        memories: globeMemories,
                        initial: initial,
                        focusedId: $focusedPinId,
                        onClose: {
                            showPager = false
                            focusedPinId = nil
                            selectedMemory = nil
                        }
                    )
                } else {
                    Color.clear
                        .onAppear { showPager = false }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(22)
            // Keep globe interactive while sheet is at half height.
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
        .onChange(of: showPager) { _, open in
            if !open {
                selectedMemory = nil
                focusedPinId = nil
            }
        }
    }
}
