import SwiftUI

struct TagsView: View {
    @EnvironmentObject var store: MemoryStore
    @State private var showAdd = false
    @State private var newName = ""
    @State private var writeMemory: Memory?
    @State private var tagForWrite: NFCTagItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tags")
                            .font(.memoraTitle(32))
                            .foregroundStyle(AppTheme.ink)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        Text("Name stickers and link them to stories. Guests tap to open.")
                            .font(.memoraBody(14))
                            .foregroundStyle(AppTheme.inkSecondary)
                            .padding(.horizontal, 20)

                        if store.tags.isEmpty {
                            emptyState
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        } else {
                            ForEach(store.tags) { tag in
                                tagCard(tag)
                            }
                        }

                        Button {
                            showAdd = true
                        } label: {
                            Label("Add NFC tag", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, AppTheme.tabBarHeight + 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("New NFC tag", isPresented: $showAdd) {
                TextField("Name e.g. Fridge magnet", text: $newName)
                Button("Add") {
                    let n = newName.trimmingCharacters(in: .whitespaces)
                    if !n.isEmpty { store.addTag(name: n) }
                    newName = ""
                }
                Button("Cancel", role: .cancel) { newName = "" }
            }
            .sheet(item: $writeMemory) { memory in
                WriteNFCView(memory: memory)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No stickers yet")
                .font(.memoraCallout(16))
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.ink)
            Text("Add a tag name, link a story, then write the URL with NFC Tools.")
                .font(.memoraBody(14))
                .foregroundStyle(AppTheme.inkSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.paperElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.ink.opacity(0.10), lineWidth: 1)
        )
    }

    private func tagCard(_ tag: NFCTagItem) -> some View {
        let linked = tag.memoryId.flatMap { store.memory(id: $0) }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wave.3.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(tag.isConnected ? AppTheme.clay : AppTheme.inkSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text(tag.isConnected ? "● Connected" : "○ Unlinked")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(tag.isConnected ? AppTheme.clay : AppTheme.inkSecondary)
                }
                Spacer()
            }

            if let linked {
                HStack {
                    Text(linked.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text(linked.shortId)
                        .font(.caption.monospaced())
                        .foregroundStyle(AppTheme.inkSecondary)
                }
                .padding(10)
                .background(AppTheme.claySoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppTheme.clay.opacity(0.30), lineWidth: 1)
                )
            }

            HStack(spacing: 10) {
                if let linked {
                    actionChip("Rewrite NFC", systemImage: "arrow.triangle.2.circlepath") {
                        writeMemory = linked
                    }

                    actionChip("Unlink", systemImage: "link.badge.minus", destructive: true) {
                        store.unlink(tag: tag)
                    }
                } else {
                    Menu {
                        ForEach(store.memories) { m in
                            Button(m.title) {
                                store.link(tag: tag, to: m)
                                writeMemory = m
                            }
                        }
                    } label: {
                        Label("Link memory", systemImage: "link")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.inkOnClay)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.clay)
                            .clipShape(Capsule())
                    }
                }
                Spacer(minLength: 0)
                if let date = tag.lastWrittenAt {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
        }
        .padding(16)
        .background(AppTheme.paperElevated)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.ink.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: AppTheme.shadowSoft, radius: 8, y: 3)
        .padding(.horizontal, 20)
    }

    private func actionChip(
        _ title: String,
        systemImage: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(destructive ? AppTheme.danger : AppTheme.inkOnClay)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(destructive ? AppTheme.danger.opacity(0.16) : AppTheme.clay)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            destructive ? AppTheme.danger.opacity(0.45) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
