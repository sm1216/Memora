import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var store: MemoryStore
    @EnvironmentObject var settings: AppSettings

    @State private var displayName: String = ""
    @State private var showSignOut = false
    @State private var showClearDemo = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Text("You")
                            .font(.memoraTitle(28))
                            .foregroundStyle(AppTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        header
                        stats

                        settingsSection("Appearance") {
                            appearancePicker
                            settingsToggle(
                                icon: "flag",
                                title: "Show country flags",
                                subtitle: "Off by default for a cleaner UI",
                                isOn: $settings.showFlags
                            )
                        }

                        settingsSection("Preferences") {
                            settingsToggle(
                                icon: "hand.tap",
                                title: "Haptics",
                                subtitle: "Light feedback on save",
                                isOn: $settings.hapticsEnabled
                            )
                            settingsToggle(
                                icon: "figure.walk.motion",
                                title: "Reduce motion",
                                subtitle: "Calmer transitions",
                                isOn: $settings.reduceMotion
                            )
                            settingsToggle(
                                icon: "globe",
                                title: "New memories public",
                                subtitle: "Default visibility for new stories",
                                isOn: $settings.defaultMemoriesPublic
                            )
                        }

                        settingsSection("Account") {
                            settingsRow(icon: "person.fill", title: "Save display name") {
                                auth.updateProfile(displayName: displayName)
                                settings.lightImpact()
                            }
                            settingsRow(icon: "arrow.clockwise", title: "Reload demo memories") {
                                showClearDemo = true
                            }
                            settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign out", destructive: true) {
                                showSignOut = true
                            }
                        }

                        about
                    }
                    .padding(.bottom, AppTheme.tabBarHeight + 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { displayName = auth.user?.displayName ?? "" }
            .confirmationDialog("Sign out?", isPresented: $showSignOut) {
                Button("Sign out", role: .destructive) { auth.signOut() }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Replace library with demo trips?", isPresented: $showClearDemo) {
                Button("Reload demo data", role: .destructive) {
                    store.resetDemoData()
                    settings.lightImpact()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.clay, AppTheme.clayDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                Text(initials)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: AppTheme.clay.opacity(0.28), radius: 12, y: 4)

            TextField("Display name", text: $displayName)
                .font(.memoraHeadline(22))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.ink)
                .onSubmit { auth.updateProfile(displayName: displayName) }

            if let email = auth.user?.email {
                Text(email)
                    .font(.memoraCallout(14))
                    .foregroundStyle(AppTheme.inkSecondary)
            }

            Text(providerLabel)
                .font(.memoraMicro(11))
                .foregroundStyle(AppTheme.clayDeep)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.claySoft)
                .clipShape(Capsule())
        }
        .padding(.top, 8)
    }

    private var stats: some View {
        HStack(spacing: 12) {
            statBox(value: "\(store.memories.count)", label: "Stories")
            statBox(value: "\(store.tags.filter(\.isConnected).count)", label: "Tags")
            statBox(value: "\(store.years().count)", label: "Years")
        }
        .padding(.horizontal, 20)
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.memoraHeadline(22))
                .foregroundStyle(AppTheme.ink)
            Text(label)
                .font(.memoraCaption(12))
                .foregroundStyle(AppTheme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.paperElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: AppTheme.shadowSoft, radius: 6, y: 2)
    }

    private var appearancePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Image(systemName: "circle.lefthalf.filled")
                    .frame(width: 28)
                    .foregroundStyle(AppTheme.clay)
                Text("Theme")
                    .foregroundStyle(AppTheme.ink)
                Spacer()
            }
            Picker("Theme", selection: $settings.appearance) {
                ForEach(AppSettings.Appearance.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.leading, 42)
        }
        .padding(16)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.memoraCaption(12))
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                content()
            }
            .background(AppTheme.paperElevated)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.shadowSoft, radius: 6, y: 2)
            .padding(.horizontal, 20)
        }
    }

    private func settingsToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .frame(width: 28)
                    .foregroundStyle(AppTheme.clay)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.memoraCaption(11))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
        }
        .tint(AppTheme.clay)
        .padding(16)
    }

    private func settingsRow(icon: String, title: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .frame(width: 28)
                    .foregroundStyle(destructive ? AppTheme.danger : AppTheme.clay)
                Text(title)
                    .foregroundStyle(destructive ? AppTheme.danger : AppTheme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(16)
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.memoraHeadline(16))
                .foregroundStyle(AppTheme.ink)
            Text("Memories links photo stories to NFC stickers. Mapbox maps, local + Supabase storage. Free NFC path uses system tag open + NFC Tools.")
                .font(.memoraCaption(12))
                .foregroundStyle(AppTheme.inkSecondary)
            Text("v1.0 · Clay Journal theme")
                .font(.memoraMicro(10))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.paperElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var initials: String {
        let name = auth.user?.displayName ?? "T"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var providerLabel: String {
        switch auth.user?.provider {
        case .apple: return "Apple"
        case .google: return "Google"
        case .email: return "Email"
        case .guest: return "Guest"
        case .none: return "—"
        }
    }
}
