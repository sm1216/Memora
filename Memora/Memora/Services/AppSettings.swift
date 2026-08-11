import SwiftUI
import Combine

/// User preferences (appearance, UI options). Persisted in UserDefaults.
@MainActor
final class AppSettings: ObservableObject {
    enum Appearance: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var label: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }

        var preferredColorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    @Published var appearance: Appearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    @Published var showFlags: Bool {
        didSet { UserDefaults.standard.set(showFlags, forKey: Keys.showFlags) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    @Published var reduceMotion: Bool {
        didSet { UserDefaults.standard.set(reduceMotion, forKey: Keys.reduceMotion) }
    }

    @Published var defaultMemoriesPublic: Bool {
        didSet { UserDefaults.standard.set(defaultMemoriesPublic, forKey: Keys.defaultPublic) }
    }

    /// Hide floating tab bar when a full-screen story is open (push).
    @Published var tabBarHidden: Bool = false

    private enum Keys {
        static let appearance = "memora.settings.appearance"
        static let showFlags = "memora.settings.showFlags"
        static let haptics = "memora.settings.haptics"
        static let reduceMotion = "memora.settings.reduceMotion"
        static let defaultPublic = "memora.settings.defaultPublic"
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Keys.appearance) ?? Appearance.system.rawValue
        appearance = Appearance(rawValue: raw) ?? .system
        // Default: no flag emojis (cleaner UI)
        if UserDefaults.standard.object(forKey: Keys.showFlags) == nil {
            showFlags = false
        } else {
            showFlags = UserDefaults.standard.bool(forKey: Keys.showFlags)
        }
        if UserDefaults.standard.object(forKey: Keys.haptics) == nil {
            hapticsEnabled = true
        } else {
            hapticsEnabled = UserDefaults.standard.bool(forKey: Keys.haptics)
        }
        reduceMotion = UserDefaults.standard.bool(forKey: Keys.reduceMotion)
        if UserDefaults.standard.object(forKey: Keys.defaultPublic) == nil {
            defaultMemoriesPublic = true
        } else {
            defaultMemoriesPublic = UserDefaults.standard.bool(forKey: Keys.defaultPublic)
        }
    }

    func lightImpact() {
        guard hapticsEnabled, !reduceMotion else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
