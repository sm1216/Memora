import SwiftUI
import MapKit

/// How the detail is presented — controls whether we show Done vs system back.
enum MemoryPresentation {
    case push      // navigationDestination → system back only
    case sheet     // full sheet → Done button
    case halfSheet // half sheet over globe → no map hero, explicit close
}

struct MemoryDetailView: View {
    @EnvironmentObject var store: MemoryStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let memory: Memory
    var presentation: MemoryPresentation = .sheet
    /// Prefer this for nested TabView/NavigationStack (Done was a no-op otherwise).
    var onClose: (() -> Void)? = nil

    @State private var showWriteNFC = false
    @State private var showEdit = false
    @State private var selectedPhoto: Data?

    private var live: Memory {
        store.memory(id: memory.id) ?? memory
    }

    private var showsDone: Bool {
        presentation == .sheet || presentation == .halfSheet
    }

    private var hidesMapHero: Bool {
        presentation == .halfSheet
    }

    /// Extra bottom inset so Share/Edit clear the floating tab bar on push.
    private var bottomActionPad: CGFloat {
        presentation == .push ? AppTheme.tabBarHeight + 28 : 28
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !hidesMapHero {
                    mapHero
                        .padding(.bottom, 12)
                }

                VStack(alignment: .leading, spacing: 20) {
                    titleBlock

                    if !live.story.isEmpty {
                        Text(live.story)
                            .font(.memoraBody(16))
                            .foregroundStyle(AppTheme.ink.opacity(0.92))
                            .lineSpacing(5)
                    }

                    if !live.photoData.isEmpty {
                        photoStrip
                    }

                    if !live.steps.isEmpty {
                        stepsSection
                    }

                    metaSection
                    actionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, hidesMapHero ? 8 : 0)
                .padding(.bottom, bottomActionPad)
            }
        }
        .background(AppTheme.paper.ignoresSafeArea())
        .navigationTitle(live.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(showsDone)
        .toolbar {
            if showsDone {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { close() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.clay)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showEdit = true
                    } label: {
                        Text("Edit")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.clay)
                    }
                    ShareLink(item: live.shareURL) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                    }
                }
            }
        }
        .toolbarBackground(AppTheme.paper.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            // Hide floating tab bar so it never covers Share / Edit on push
            if presentation == .push {
                settings.tabBarHidden = true
            }
        }
        .onDisappear {
            if presentation == .push {
                settings.tabBarHidden = false
            }
        }
        .sheet(isPresented: $showWriteNFC) {
            WriteNFCView(memory: live)
        }
        .sheet(isPresented: $showEdit) {
            EditMemoryView(memoryId: live.id)
        }
        .fullScreenCover(item: Binding(
            get: { selectedPhoto.map { PhotoItem(data: $0) } },
            set: { selectedPhoto = $0?.data }
        )) { item in
            ZStack {
                Color.black.ignoresSafeArea()
                if let ui = UIImage(data: item.data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                }
            }
            .onTapGesture { selectedPhoto = nil }
            .overlay(alignment: .topTrailing) {
                Button {
                    selectedPhoto = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                        .padding()
                }
            }
        }
    }

    private var mapHero: some View {
        MapboxMapView(
            center: live.coordinate,
            zoom: 11,
            markers: [(live.coordinate, live.locationName, "#D6662E")],
            route: routeCoords,
            interactive: true
        )
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        // Respect safe area under status bar — map sits below nav
        .padding(.top, 0)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(live.title)
                .font(.memoraTitle(hidesMapHero ? 22 : 26))
                .foregroundStyle(AppTheme.ink)

            HStack(spacing: 8) {
                CountryLabel(code: live.countryCode)
                Text(live.locationName)
                    .font(.memoraCallout(14))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
                Text("·")
                    .foregroundStyle(AppTheme.inkTertiary)
                Text(live.dateRangeText)
                    .font(.memoraCaption(12))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            if !live.collaboratorNames.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(live.collaboratorNames.prefix(3).enumerated()), id: \.offset) { i, name in
                        Circle()
                            .fill(i == 0 ? AppTheme.clay : AppTheme.inkTertiary.opacity(0.5))
                            .frame(width: 26, height: 26)
                            .overlay(
                                Text(String(name.prefix(1)).uppercased())
                                    .font(.memoraMicro(11))
                                    .foregroundStyle(.white)
                            )
                    }
                    Text(live.collaboratorNames.joined(separator: ", "))
                        .font(.memoraCaption(12))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.paperElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
        .shadow(color: AppTheme.shadowSoft, radius: hidesMapHero ? 4 : 8, y: 3)
        // Overlap map only when map hero is present.
        .offset(y: hidesMapHero ? 0 : -28)
        .padding(.bottom, hidesMapHero ? 0 : -16)
        .padding(.horizontal, 16)
    }

    private var routeCoords: [CLLocationCoordinate2D] {
        let steps = live.steps.compactMap { step -> CLLocationCoordinate2D? in
            guard let lat = step.latitude, let lon = step.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return steps.count >= 2 ? steps : []
    }

    private var photoStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Photos")
                .font(.memoraHeadline(18))
                .foregroundStyle(AppTheme.ink)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(live.photoData.enumerated()), id: \.offset) { _, data in
                        if let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .onTapGesture { selectedPhoto = data }
                        }
                    }
                }
            }
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stops")
                .font(.memoraHeadline(18))
                .foregroundStyle(AppTheme.ink)
            ForEach(Array(live.steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d", index + 1))
                        .font(.memoraMicro(11))
                        .foregroundStyle(AppTheme.clay)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.claySoft)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.memoraCallout(16))
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.ink)
                        if let place = step.placeName, !place.isEmpty {
                            Text(place)
                                .font(.memoraCaption(12))
                                .foregroundStyle(AppTheme.inkSecondary)
                        }
                        if !step.note.isEmpty {
                            Text(step.note)
                                .font(.memoraBody(14))
                                .foregroundStyle(AppTheme.ink.opacity(0.88))
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(AppTheme.paperElevated)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var metaSection: some View {
        HStack(spacing: 14) {
            Label(live.isPublic ? "Public" : "Private", systemImage: live.isPublic ? "globe" : "lock.fill")
            Label("\(live.tagIds.count) tags", systemImage: "tag")
            Label(live.shortId, systemImage: "link")
        }
        .font(.memoraCaption(12))
        .foregroundStyle(AppTheme.inkSecondary)
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button { showWriteNFC = true } label: {
                Label("Write to NFC sticker", systemImage: "wave.3.right.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button { showEdit = true } label: {
                Label("Edit story", systemImage: "pencil")
            }
            .buttonStyle(SecondaryButtonStyle())

            ShareLink(item: live.shareURL) {
                Label("Share link", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

private struct PhotoItem: Identifiable {
    let id = UUID()
    let data: Data
}
