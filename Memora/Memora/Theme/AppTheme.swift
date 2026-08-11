import SwiftUI
import UIKit

// Hallmark · Clay Journal · adaptive light/dark
// Dynamic colors follow preferredColorScheme (system / light / dark)

enum AppTheme {
    // MARK: - Adaptive surfaces

    static let paper = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 1)
            : UIColor(red: 0.972, green: 0.965, blue: 0.958, alpha: 1)
    })

    static let paperElevated = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1)
            : UIColor.white
    })

    static let paperInset = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            : UIColor(red: 0.945, green: 0.935, blue: 0.925, alpha: 1)
    })

    /// Map / scan full-bleed shell (always deep)
    static let night = Color(red: 0.07, green: 0.075, blue: 0.085)
    static let nightElevated = Color(red: 0.12, green: 0.125, blue: 0.14)

    // MARK: - Ink

    static let ink = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1)
            : UIColor(red: 0.11, green: 0.09, blue: 0.08, alpha: 1)
    })

    static let inkSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.72, green: 0.70, blue: 0.68, alpha: 1)
            : UIColor(red: 0.38, green: 0.34, blue: 0.31, alpha: 1)
    })

    static let inkTertiary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.53, blue: 0.50, alpha: 1)
            : UIColor(red: 0.55, green: 0.50, blue: 0.46, alpha: 1)
    })

    static let inkOnClay = Color.white
    static let inkOnNight = Color(red: 0.96, green: 0.95, blue: 0.93)

    // MARK: - Brand

    static let clay = Color(red: 0.84, green: 0.40, blue: 0.18)
    static let clayDeep = Color(red: 0.68, green: 0.30, blue: 0.12)
    static let claySoft = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.22, blue: 0.16, alpha: 1)
            : UIColor(red: 0.94, green: 0.82, blue: 0.72, alpha: 1)
    })
    static let sage = Color(red: 0.42, green: 0.52, blue: 0.45)
    static let sageSoft = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.28, blue: 0.24, alpha: 1)
            : UIColor(red: 0.86, green: 0.90, blue: 0.86, alpha: 1)
    })

    static let danger = Color(red: 0.85, green: 0.35, blue: 0.32)
    static let success = Color(red: 0.32, green: 0.58, blue: 0.42)
    static let info = Color(red: 0.30, green: 0.50, blue: 0.70)

    // Legacy aliases
    static let terracotta = clay
    static let terracottaDeep = clayDeep
    static let washiCream = paper
    static let softBlush = claySoft
    static let cardWhite = paperElevated
    static let mutedInk = inkSecondary
    static let globeOcean = night
    static let globeLand = sageSoft
    static let mapDark = night
    static let accentBlue = info
    static let tapePink = Color(red: 0.88, green: 0.62, blue: 0.66)
    static let tapeMint = Color(red: 0.55, green: 0.72, blue: 0.62)
    static let tapeYellow = Color(red: 0.88, green: 0.78, blue: 0.42)

    static let tabBarHeight: CGFloat = 76
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space20: CGFloat = 20
    static let space24: CGFloat = 24
    static let cornerLarge: CGFloat = 22
    static let cornerMedium: CGFloat = 16
    static let cornerSmall: CGFloat = 12
    static let cornerButton: CGFloat = 14
    static let shadowSoft = Color.black.opacity(0.08)
    static let shadowCard = Color.black.opacity(0.10)
}

extension Font {
    static func memoraDisplay(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func memoraTitle(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func memoraHeadline(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func memoraBody(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    static func memoraCallout(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func memoraCaption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func memoraMicro(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

struct BrandWordmark: View {
    var light: Bool = false
    var compact: Bool = false

    var body: some View {
        VStack(alignment: compact ? .leading : .center, spacing: 3) {
            HStack(spacing: 0) {
                Text("memories")
                    .font(.system(size: compact ? 22 : 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(light ? AppTheme.inkOnNight : AppTheme.ink)
                    .tracking(-0.3)
                Circle()
                    .fill(AppTheme.clay)
                    .frame(width: compact ? 6 : 7, height: compact ? 6 : 7)
                    .offset(x: 2, y: -7)
            }
            Text(AppConfig.appTagline.uppercased())
                .font(.memoraMicro(9))
                .tracking(2.4)
                .foregroundStyle(light ? AppTheme.inkOnNight.opacity(0.55) : AppTheme.inkTertiary)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppTheme.clay
    var foreground: Color = AppTheme.inkOnClay

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.memoraCallout(16))
            .fontWeight(.semibold)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(color.opacity(configuration.isPressed ? 0.88 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerButton, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.memoraCallout(15))
            .fontWeight(.semibold)
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.paperElevated.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerButton, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerButton, style: .continuous)
                    .stroke(AppTheme.ink.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.memoraCallout(14))
            .foregroundStyle(AppTheme.inkSecondary.opacity(configuration.isPressed ? 0.6 : 1))
    }
}

struct SoftChip: View {
    let text: String
    var icon: String? = nil
    var emphasized: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(text)
                .font(.memoraCaption(12))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(emphasized ? AppTheme.clay : AppTheme.paperElevated)
        .foregroundStyle(emphasized ? AppTheme.inkOnClay : AppTheme.ink)
        .clipShape(Capsule())
        .shadow(color: AppTheme.shadowSoft, radius: 6, y: 2)
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.memoraCallout(13))
                .fontWeight(.semibold)
                .foregroundStyle(selected ? AppTheme.inkOnClay : AppTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? AppTheme.clay : AppTheme.paperElevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(selected ? Color.clear : AppTheme.ink.opacity(0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct MemoraTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.memoraBody(16))
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(AppTheme.paperElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerSmall, style: .continuous)
                    .stroke(AppTheme.ink.opacity(0.10), lineWidth: 1)
            )
    }
}

extension View {
    func memoraField() -> some View { modifier(MemoraTextFieldStyle()) }

    func memoraCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(AppTheme.paperElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
            .shadow(color: AppTheme.shadowCard, radius: 8, y: 3)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.claySoft)
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppTheme.clay)
            }
            Text(title)
                .font(.memoraHeadline(18))
                .foregroundStyle(AppTheme.ink)
            Text(message)
                .font(.memoraBody(14))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(width: 200)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct FloatingPanel<Content: View>: View {
    var night: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                    .fill(night ? AppTheme.nightElevated.opacity(0.94) : AppTheme.paperElevated)
                    .shadow(color: .black.opacity(night ? 0.35 : 0.08), radius: 16, y: 6)
            )
    }
}

/// Country code as plain text (optional flag via settings)
struct CountryLabel: View {
    let code: String
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        if settings.showFlags {
            Text(flagEmoji(code))
        } else {
            Text(code.uppercased())
                .font(.memoraMicro(10))
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.paperInset)
                .clipShape(Capsule())
        }
    }

    private func flagEmoji(_ code: String) -> String {
        let base: UInt32 = 127397
        var s = ""
        for v in code.uppercased().unicodeScalars {
            if let scalar = UnicodeScalar(base + v.value) { s.unicodeScalars.append(scalar) }
        }
        return s.isEmpty ? "·" : s
    }
}
