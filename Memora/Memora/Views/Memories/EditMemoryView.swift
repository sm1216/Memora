import SwiftUI

struct EditMemoryView: View {
    @EnvironmentObject var store: MemoryStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let memoryId: UUID

    @State private var title = ""
    @State private var story = ""
    @State private var locationName = ""
    @State private var countryCode = ""
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isPublic = true
    @State private var steps: [MemoryStep] = []
    @State private var showDeleteConfirm = false

    private var original: Memory? { store.memory(id: memoryId) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Story") {
                    TextField("Title", text: $title)
                    TextField("Story", text: $story, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Place") {
                    TextField("Location", text: $locationName)
                    TextField("Country code (e.g. IT)", text: $countryCode)
                        .textInputAutocapitalization(.characters)
                    HStack {
                        Text("Latitude")
                        TextField("lat", value: $latitude, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Longitude")
                        TextField("lon", value: $longitude, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, displayedComponents: .date)
                }

                Section("Visibility") {
                    Toggle("Public album", isOn: $isPublic)
                }

                if !steps.isEmpty {
                    Section("Steps") {
                        ForEach($steps) { $step in
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Step title", text: $step.title)
                                TextField("Place", text: Binding(
                                    get: { step.placeName ?? "" },
                                    set: { step.placeName = $0.isEmpty ? nil : $0 }
                                ))
                                TextField("Note", text: $step.note, axis: .vertical)
                                    .lineLimit(2...4)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { steps.remove(atOffsets: $0) }

                        Button("Add step") {
                            steps.append(MemoryStep(title: "New stop", emoji: ""))
                        }
                    }
                } else {
                    Section {
                        Button("Add first step") {
                            steps.append(MemoryStep(title: "Day 1", emoji: ""))
                        }
                    }
                }

                Section {
                    Button("Save changes") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.clay)
                }

                Section {
                    Button("Delete memory", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.paper)
            .navigationTitle("Edit story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.clay)
                }
            }
            .onAppear { load() }
            .confirmationDialog("Delete this memory?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let original {
                        store.delete(original)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func load() {
        guard let m = original else { return }
        title = m.title
        story = m.story
        locationName = m.locationName
        countryCode = m.countryCode
        latitude = m.latitude
        longitude = m.longitude
        startDate = m.startDate
        endDate = m.endDate
        isPublic = m.isPublic
        steps = m.steps
    }

    private func save() {
        guard var m = original else { return }
        m.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title
        m.story = story
        m.locationName = locationName
        m.countryCode = countryCode.uppercased().isEmpty ? "XX" : String(countryCode.uppercased().prefix(2))
        m.latitude = latitude
        m.longitude = longitude
        m.startDate = startDate
        m.endDate = endDate
        m.isPublic = isPublic
        m.steps = steps.map { step in
            var s = step
            if s.emoji.count > 1 || s.emoji.unicodeScalars.contains(where: { $0.properties.isEmojiPresentation }) {
                // strip decorative emoji from steps for cleaner UI
                s.emoji = ""
            }
            return s
        }
        m.updatedAt = Date()
        store.upsert(m)
        settings.lightImpact()
        dismiss()
    }
}
