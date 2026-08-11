import SwiftUI
import PhotosUI
import CoreLocation

struct CreateMemoryFlow: View {
    @EnvironmentObject var store: MemoryStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var step: Step = .photos
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var photos: [PhotoAssetMeta] = []
    @State private var title = ""
    @State private var story = ""
    @State private var locationName = ""
    @State private var countryCode = "XX"
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isPublic = true
    @State private var assistantProgress: Double = 0
    @State private var assistantDone: Set<Int> = []
    @State private var assistantStatus = "Reading photo metadata…"
    @State private var steps: [MemoryStep] = []
    @State private var metaSummary = ""
    @State private var isLoadingPhotos = false

    enum Step: Int, CaseIterable {
        case photos, assistant, details, preview
    }

    private var photoData: [Data] { photos.map(\.imageData) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.paper.ignoresSafeArea()
                Group {
                    switch step {
                    case .photos: photosStep
                    case .assistant: assistantStep
                    case .details: detailsStep
                    case .preview: previewStep
                    }
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if step == .assistant {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") { step = .details }
                    }
                }
            }
        }
    }

    private var navTitle: String {
        switch step {
        case .photos: return "Add photos"
        case .assistant: return "Reading metadata"
        case .details: return "Memory details"
        case .preview: return "Preview"
        }
    }

    // MARK: Photos

    private var photosStep: some View {
        VStack(spacing: 20) {
            Text("Photos in.\nDates & places auto-filled.")
                .font(.memoraDisplay(26))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.ink)
                .padding(.top, 12)

            Text("We read date, time, and GPS from each photo’s EXIF when available.")
                .font(.memoraBody(14))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 40,
                matching: .images,
                photoLibrary: .shared()
            ) {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.clay)
                    if isLoadingPhotos {
                        ProgressView()
                            .tint(AppTheme.clay)
                        Text("Loading photos…")
                            .font(.memoraCallout(14))
                            .foregroundStyle(AppTheme.inkSecondary)
                    } else {
                        Text(photos.isEmpty ? "Select photos from your library" : "\(photos.count) photos selected")
                            .font(.memoraHeadline(17))
                            .foregroundStyle(AppTheme.ink)
                        Text("Prefer original camera photos (GPS is stripped from many edits)")
                            .font(.memoraCaption(12))
                            .foregroundStyle(AppTheme.inkTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(AppTheme.paperElevated)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: AppTheme.shadowSoft, radius: 8, y: 3)
            }
            .padding(.horizontal, 20)
            .onChange(of: selectedItems) { _, items in
                Task { await loadPhotos(items) }
            }

            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(photos) { p in
                            ZStack(alignment: .bottomLeading) {
                                if let ui = UIImage(data: p.imageData) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 76, height: 76)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                HStack(spacing: 3) {
                                    if p.hasGPS {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    if p.takenAt != nil {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                }
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(Color.black.opacity(0.45))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                let gpsCount = photos.filter(\.hasGPS).count
                let dateCount = photos.filter { $0.takenAt != nil }.count
                Text("\(dateCount) with date · \(gpsCount) with GPS")
                    .font(.memoraCaption(12))
                    .foregroundStyle(AppTheme.inkSecondary)
            }

            Spacer()

            Button("Continue") {
                step = .assistant
                runAssistant()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .disabled(photos.isEmpty || isLoadingPhotos)
            .opacity(photos.isEmpty || isLoadingPhotos ? 0.45 : 1)
        }
    }

    // MARK: Assistant

    private var assistantStep: some View {
        VStack(spacing: 24) {
            SoftChip(text: "EXIF date · GPS · reverse geocode", icon: "wand.and.stars")
                .padding(.top, 20)

            ZStack {
                Circle()
                    .fill(AppTheme.clay)
                    .frame(width: 72, height: 72)
                Image(systemName: "location.magnifyingglass")
                    .font(.title)
                    .foregroundStyle(.white)
            }

            Text("Building your journey")
                .font(.memoraDisplay(24))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)

            Text(assistantStatus)
                .font(.memoraBody(14))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            ProgressView(value: assistantProgress)
                .tint(AppTheme.clay)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 14) {
                assistantRow(0, "Reading dates & GPS")
                assistantRow(1, "Resolving place names")
                assistantRow(2, "Grouping into stops")
            }
            .padding(.horizontal, 40)

            if !metaSummary.isEmpty {
                Text(metaSummary)
                    .font(.memoraCaption(12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Spacer()

            Button("Continue") {
                step = .details
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .disabled(assistantProgress < 1)
            .opacity(assistantProgress < 1 ? 0.5 : 1)
        }
    }

    private func assistantRow(_ index: Int, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: assistantDone.contains(index) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(assistantDone.contains(index) ? AppTheme.clay : AppTheme.inkTertiary)
            Text(text)
                .font(.memoraCallout(15))
                .foregroundStyle(assistantDone.contains(index) ? AppTheme.ink : AppTheme.inkSecondary)
            Spacer()
        }
    }

    // MARK: Details

    private var detailsStep: some View {
        Form {
            Section {
                if !metaSummary.isEmpty {
                    Text(metaSummary)
                        .font(.memoraCaption(12))
                        .foregroundStyle(AppTheme.inkSecondary)
                }
            }

            Section("Title & story") {
                TextField("Title", text: $title)
                TextField("Story", text: $story, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section("Place (from photos)") {
                TextField("Location name", text: $locationName)
                TextField("Country code", text: $countryCode)
                    .textInputAutocapitalization(.characters)
                HStack {
                    Text("Latitude")
                    TextField("lat", value: $latitude, format: .number)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Longitude")
                    TextField("lon", value: $longitude, format: .number)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section("Dates (from photos)") {
                DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
            }
            if !steps.isEmpty {
                Section("Stops (\(steps.count))") {
                    ForEach(steps) { s in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.title).font(.headline)
                            if let p = s.placeName {
                                Text(p).font(.caption).foregroundStyle(.secondary)
                            }
                            Text("\(s.photoIndices.count) photos")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Visibility") {
                Toggle("Public album", isOn: $isPublic)
            }
            Section {
                Button("Preview memory") {
                    if title.trimmingCharacters(in: .whitespaces).isEmpty {
                        title = locationName.isEmpty ? "Untitled trip" : locationName
                    }
                    step = .preview
                }
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.clay)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.paper)
    }

    // MARK: Preview

    private var previewStep: some View {
        VStack(spacing: 16) {
            let draft = buildMemory()
            PolaroidCard(memory: draft, rotation: -2)
                .scaleEffect(1.15)
                .padding(.top, 24)

            Text(draft.title)
                .font(.memoraHeadline(22))
                .foregroundStyle(AppTheme.ink)
            Text("\(draft.locationName) · \(draft.dateRangeText)")
                .font(.memoraCallout(14))
                .foregroundStyle(AppTheme.inkSecondary)
            if !draft.story.isEmpty {
                Text(draft.story)
                    .font(.memoraBody(15))
                    .foregroundStyle(AppTheme.ink.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Text("\(draft.steps.count) stops · \(draft.photoData.count) photos")
                .font(.memoraCaption(12))
                .foregroundStyle(AppTheme.inkTertiary)

            Spacer()

            Button("Save memory") {
                store.upsert(draft)
                settings.lightImpact()
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: Load photos + EXIF

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        await MainActor.run { isLoadingPhotos = true }
        var loaded: [PhotoAssetMeta] = []

        for item in items {
            // Prefer full original file so EXIF/GPS is intact
            var raw: Data?
            if let data = try? await item.loadTransferable(type: Data.self) {
                raw = data
            }
            guard let original = raw else { continue }

            let meta = PhotoMetadataService.extract(from: original)
            // Compress for storage but keep metadata
            let stored = PhotoMetadataService.compressPreservingMetadata(original, quality: 0.78)

            loaded.append(PhotoAssetMeta(
                id: UUID(),
                imageData: stored,
                takenAt: meta.date,
                latitude: meta.lat,
                longitude: meta.lon,
                altitude: meta.alt,
                placeName: nil,
                countryCode: nil
            ))
        }

        // Sort by capture time when available
        loaded.sort { ($0.takenAt ?? .distantFuture) < ($1.takenAt ?? .distantFuture) }

        await MainActor.run {
            photos = loaded
            isLoadingPhotos = false
            isPublic = settings.defaultMemoriesPublic
        }
    }

    // MARK: Assistant — real metadata pipeline

    private func runAssistant() {
        assistantProgress = 0
        assistantDone = []
        assistantStatus = "Reading EXIF dates & GPS…"
        metaSummary = ""

        Task {
            // Step 0 — already have EXIF from load
            try? await Task.sleep(nanoseconds: 350_000_000)
            let gpsN = photos.filter(\.hasGPS).count
            let dateN = photos.filter { $0.takenAt != nil }.count
            await MainActor.run {
                assistantDone.insert(0)
                assistantProgress = 0.28
                assistantStatus = dateN > 0 || gpsN > 0
                    ? "Found \(dateN) dated · \(gpsN) with GPS"
                    : "No EXIF GPS/date — you can set place manually"
            }

            // Step 1+2 — reverse geocode + group
            await MainActor.run {
                assistantStatus = "Resolving place names…"
            }
            let draft = await PhotoMetadataService.buildDraft(from: photos)

            await MainActor.run {
                assistantDone.insert(1)
                assistantProgress = 0.72
                assistantStatus = "Grouping stops by day & place…"

                startDate = draft.startDate
                endDate = draft.endDate
                latitude = draft.latitude
                longitude = draft.longitude
                locationName = draft.locationName
                countryCode = draft.countryCode
                if title.isEmpty { title = draft.titleSuggestion }
                steps = draft.steps
                metaSummary = summaryLine(draft)
            }

            try? await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run {
                assistantDone.insert(2)
                assistantProgress = 1
                assistantStatus = "Ready — review details next"
            }
        }
    }

    private func summaryLine(_ d: PhotoMetadataService.MemoryDraftMeta) -> String {
        var parts: [String] = []
        parts.append("\(d.photosWithDate)/\(photos.count) dated")
        parts.append("\(d.photosWithGPS)/\(photos.count) GPS")
        if d.photosWithGPS > 0 {
            parts.append(d.locationName)
        }
        let df = DateFormatter()
        df.dateStyle = .medium
        if d.photosWithDate > 0 {
            parts.append("\(df.string(from: d.startDate)) – \(df.string(from: d.endDate))")
        }
        parts.append("\(d.steps.count) stops")
        return parts.joined(separator: " · ")
    }

    private func buildMemory() -> Memory {
        Memory(
            id: UUID(),
            shortId: Memory.makeShortId(),
            title: title.isEmpty ? "Untitled" : title,
            story: story,
            locationName: locationName.isEmpty ? "Unknown" : locationName,
            countryCode: countryCode.uppercased().isEmpty ? "XX" : String(countryCode.uppercased().prefix(2)),
            latitude: latitude,
            longitude: longitude,
            startDate: startDate,
            endDate: endDate,
            isPublic: isPublic,
            coverImageData: photoData.first,
            photoData: photoData,
            steps: steps,
            tagIds: [],
            collaboratorNames: ["You"],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
