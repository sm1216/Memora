import SwiftUI

struct PolaroidCard: View {
    let memory: Memory
    var rotation: Double = 0
    var tapeColor: Color = AppTheme.tapePink

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let data = memory.coverImageData ?? memory.photoData.first,
                   let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: gradientColors(for: memory),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VStack(spacing: 6) {
                        Text(memory.countryCode.uppercased())
                            .font(.memoraMicro(11))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                        Text(memory.locationName.split(separator: ",").first.map(String.init) ?? memory.locationName)
                            .font(.memoraCaption(11))
                            .foregroundStyle(.white.opacity(0.92))
                            .lineLimit(1)
                    }
                    .padding(8)
                }
            }
            .frame(width: 122, height: 122)
            .clipped()
            .padding(.horizontal, 9)
            .padding(.top, 9)

            Text(memory.title)
                .font(.memoraCaption(12))
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .frame(width: 140)
        .background(AppTheme.paperElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tapeColor.opacity(0.88))
                .frame(width: 40, height: 12)
                .rotationEffect(.degrees(-5))
                .offset(y: -5)
        }
        .rotationEffect(.degrees(rotation))
    }

    private func gradientColors(for memory: Memory) -> [Color] {
        let palette: [[Color]] = [
            [AppTheme.clay, AppTheme.clayDeep],
            [Color(red: 0.30, green: 0.45, blue: 0.58), Color(red: 0.18, green: 0.30, blue: 0.42)],
            [AppTheme.sage, Color(red: 0.25, green: 0.38, blue: 0.32)],
            [Color(red: 0.55, green: 0.40, blue: 0.48), Color(red: 0.38, green: 0.25, blue: 0.35)]
        ]
        let idx = abs(memory.shortId.hashValue) % palette.count
        return palette[idx]
    }
}

struct MemoryRowCard: View {
    let memory: Memory

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                if let data = memory.coverImageData ?? memory.photoData.first,
                   let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [AppTheme.clay.opacity(0.9), AppTheme.clayDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Text(memory.countryCode.uppercased())
                        .font(.memoraMicro(10))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(memory.title)
                    .font(.memoraCallout(16))
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    CountryLabel(code: memory.countryCode)
                    Text(memory.locationName)
                        .font(.memoraCaption(13))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                }
                Text(memory.dateRangeText)
                    .font(.memoraMicro(11))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            Spacer()
            Image(systemName: memory.isPublic ? "globe" : "lock.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .padding(12)
        .background(AppTheme.paperElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
        .shadow(color: AppTheme.shadowSoft, radius: 8, y: 2)
    }
}
