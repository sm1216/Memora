import SwiftUI

struct MemoriesBoardView: View {
    @EnvironmentObject var store: MemoryStore
    @State private var selectedYear: Int? = nil
    @State private var showCreate = false
    @State private var selectedMemory: Memory?

    private let tapeColors: [Color] = [
        AppTheme.tapePink, AppTheme.tapeMint, AppTheme.tapeYellow,
        AppTheme.claySoft, AppTheme.sageSoft
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        yearFilter
                            .padding(.top, AppTheme.space12)

                        ForEach(displayYears, id: \.self) { year in
                            yearSection(year)
                        }

                        if store.memories.isEmpty {
                            EmptyStateView(
                                icon: "photo.on.rectangle.angled",
                                title: "No memories yet",
                                message: "Create your first trip album, then link it to an NFC sticker.",
                                actionTitle: "Create memory",
                                action: { showCreate = true }
                            )
                        }
                    }
                    .padding(.bottom, AppTheme.tabBarHeight + 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCreate) {
                CreateMemoryFlow()
            }
            .navigationDestination(item: $selectedMemory) { memory in
                MemoryDetailView(memory: memory, presentation: .push)
            }
        }
    }

    private var displayYears: [Int] {
        if let y = selectedYear { return [y] }
        return store.years()
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Board")
                    .font(.memoraTitle(32))
                    .foregroundStyle(AppTheme.ink)
                Text("\(store.memories.count) stories · polaroid wall")
                    .font(.memoraCallout(14))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
            Spacer()
            Button { showCreate = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.inkOnClay)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.clay)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.clay.opacity(0.30), radius: 8, y: 3)
            }
            .accessibilityLabel("Create memory")
        }
        .padding(.horizontal, AppTheme.space20)
        .padding(.top, AppTheme.space16)
    }

    private var yearFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", selected: selectedYear == nil) {
                    selectedYear = nil
                }
                ForEach(store.years(), id: \.self) { year in
                    FilterChip(title: "\(year)", selected: selectedYear == year) {
                        selectedYear = year
                    }
                }
            }
            .padding(.horizontal, AppTheme.space20)
            .padding(.vertical, 4)
        }
    }

    private func yearSection(_ year: Int) -> some View {
        let items = store.memories(for: year)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text("\(year)")
                    .font(.memoraHeadline(18))
                    .foregroundStyle(AppTheme.ink)
                Rectangle()
                    .fill(AppTheme.ink.opacity(0.08))
                    .frame(height: 1)
            }
            .padding(.horizontal, AppTheme.space20)
            .padding(.top, AppTheme.space24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, memory in
                        Button {
                            selectedMemory = memory
                        } label: {
                            PolaroidCard(
                                memory: memory,
                                rotation: Double([-2.5, 1.8, -1.2, 2.8, -1.8][index % 5]),
                                tapeColor: tapeColors[index % tapeColors.count]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.space20)
                .padding(.vertical, 14)
            }
        }
    }
}
