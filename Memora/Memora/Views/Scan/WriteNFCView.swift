import SwiftUI

struct WriteNFCView: View {
    @EnvironmentObject var nfc: NFCService
    @EnvironmentObject var store: MemoryStore
    @Environment(\.dismiss) private var dismiss

    let memory: Memory
    @State private var selectedTagId: UUID?
    @State private var status: String?
    @State private var isWriting = false
    @State private var newTagName = ""
    @State private var step: Int = 0

    private var tagURL: String {
        memory.nfcURL.absoluteString
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Link “\(memory.title)” to a sticker")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    // Free path callout
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FREE NFC (no $99)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.clay)
                        Text("Apple blocks in-app NFC APIs on free developer accounts. Real stickers still work: write this URL with free NFC Tools / Shortcuts, then anyone can tap the tag and iOS opens Memories.")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.inkSecondary)
                    }
                    .padding(14)
                    .background(AppTheme.claySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.clay.opacity(0.35), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tag payload (NDEF URL)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.inkSecondary)
                        Text(tagURL)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(AppTheme.ink)
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.paperElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppTheme.ink.opacity(0.10), lineWidth: 1)
                            )
                    }

                    // Tag picker
                    Text("Your sticker name")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    ForEach(store.tags) { tag in
                        Button { selectedTagId = tag.id } label: {
                            HStack {
                                Image(systemName: tag.isConnected ? "wave.3.right.circle.fill" : "wave.3.right.circle")
                                    .foregroundStyle(tag.isConnected ? AppTheme.clay : AppTheme.inkSecondary)
                                VStack(alignment: .leading) {
                                    Text(tag.name)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppTheme.ink)
                                    Text(tag.statusText)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.inkSecondary)
                                }
                                Spacer()
                                if selectedTagId == tag.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.clay)
                                }
                            }
                            .padding(14)
                            .background(AppTheme.paperElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        selectedTagId == tag.id ? AppTheme.clay : AppTheme.ink.opacity(0.10),
                                        lineWidth: selectedTagId == tag.id ? 1.5 : 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 10) {
                        TextField("New tag name", text: $newTagName)
                            .padding(12)
                            .foregroundStyle(AppTheme.ink)
                            .background(AppTheme.paperElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppTheme.ink.opacity(0.12), lineWidth: 1)
                            )

                        Button {
                            let name = newTagName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            store.addTag(name: name)
                            newTagName = ""
                            selectedTagId = store.tags.last?.id
                        } label: {
                            Text("Add")
                                .font(.memoraCallout(15))
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.inkOnClay)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(AppTheme.clay)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(newTagName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1)
                    }

                    Divider()
                        .overlay(AppTheme.ink.opacity(0.12))
                        .padding(.vertical, 4)

                    Text("Step-by-step write")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)

                    stepRow(1, "Copy URL") {
                        nfc.copyToPasteboard(tagURL)
                        status = "Copied \(tagURL)"
                    }

                    stepRow(2, "Open NFC Tools (free)") {
                        _ = nfc.openNFCTools()
                        status = "In NFC Tools: Write → Add record → URL/URI → paste → Write → hold sticker"
                    }

                    stepRow(3, "Or open Shortcuts") {
                        nfc.openShortcutsForWrite()
                        status = "Shortcuts → create action “Write NFC Tag” with Clipboard text, run it, hold sticker"
                    }

                    Button {
                        markLinked()
                    } label: {
                        Label("I’ve written the sticker — mark linked", systemImage: "checkmark.seal.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedTagId == nil)
                    .opacity(selectedTagId == nil ? 0.55 : 1)

                    Button {
                        Task { await tryCoreNFCWrite() }
                    } label: {
                        if isWriting {
                            ProgressView()
                                .tint(AppTheme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        } else {
                            Text("Try in-app CoreNFC write (only works with paid team)")
                                .font(.system(size: 14, weight: .semibold))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    if let status {
                        Text(status)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.ink.opacity(0.9))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.paperInset)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.top, 4)
                    }

                    Text("After writing: hold sticker to iPhone → system opens Memories → memory appears.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.inkSecondary)
                        .padding(.bottom, 20)
                }
                .padding(20)
            }
            .background(AppTheme.paper.ignoresSafeArea())
            .navigationTitle("Write NFC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.clay)
                }
            }
            .onAppear {
                selectedTagId = store.tags.first(where: { !$0.isConnected })?.id ?? store.tags.last?.id
            }
        }
    }

    private func stepRow(_ n: Int, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("\(n)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.inkOnClay)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.clay)
                    .clipShape(Circle())
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
            .padding(14)
            .background(AppTheme.paperElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.ink.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func markLinked() {
        guard let tagId = selectedTagId,
              let tag = store.tags.first(where: { $0.id == tagId }) else { return }
        nfc.confirmExternalWrite(urlString: tagURL)
        store.link(tag: tag, to: memory)
        store.markWritten(tagId: tagId)
        status = "Linked! Hold the sticker to any iPhone — it should open Memories → \(memory.shortId)"
    }

    private func tryCoreNFCWrite() async {
        guard let tagId = selectedTagId,
              let tag = store.tags.first(where: { $0.id == tagId }) else { return }
        isWriting = true
        status = "Trying CoreNFC…"
        let result = await nfc.write(urlString: tagURL)
        isWriting = false
        switch result {
        case .success:
            store.link(tag: tag, to: memory)
            store.markWritten(tagId: tagId)
            status = "CoreNFC write succeeded!"
        case .failure(let error):
            status = error.localizedDescription + " — use Copy URL + NFC Tools instead (still real NFC)."
        }
    }
}
