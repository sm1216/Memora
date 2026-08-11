import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var auth: AuthService
    @State private var showGuestName = false
    @State private var guestName = "Traveler"
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var mode: Mode = .signIn

    enum Mode { case signIn, signUp }

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()

            // Quiet clay wash (not rainbow orbs)
            LinearGradient(
                colors: [AppTheme.claySoft.opacity(0.35), AppTheme.paper.opacity(0)],
                startPoint: .topLeading,
                endPoint: .center
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 56)

                    BrandWordmark()
                        .padding(.bottom, 20)

                    Text("Your memories.\nKept for good.")
                        .font(.memoraDisplay(32))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 28)

                    Text("Link photos to NFC stickers. One tap brings the trip back.")
                        .font(.memoraBody(15))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .padding(.top, 10)

                    // Auth card
                    VStack(spacing: 14) {
                        HStack(spacing: 0) {
                            modeTab("Sign in", .signIn)
                            modeTab("Sign up", .signUp)
                        }
                        .padding(3)
                        .background(AppTheme.paperInset)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        if mode == .signUp {
                            TextField("Display name", text: $displayName)
                                .textContentType(.name)
                                .memoraField()
                        }

                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .memoraField()

                        SecureField("Password", text: $password)
                            .textContentType(mode == .signUp ? .newPassword : .password)
                            .memoraField()

                        Button {
                            Task {
                                if mode == .signIn {
                                    await auth.signIn(email: email, password: password)
                                } else {
                                    await auth.signUp(
                                        email: email,
                                        password: password,
                                        displayName: displayName.isEmpty ? "Traveler" : displayName
                                    )
                                }
                            }
                        } label: {
                            Text(mode == .signIn ? "Continue" : "Create account")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(email.isEmpty || password.count < 6 || auth.isLoading)
                        .opacity(email.isEmpty || password.count < 6 ? 0.45 : 1)

                        if let info = auth.infoMessage {
                            Text(info)
                                .font(.memoraCaption(12))
                                .foregroundStyle(AppTheme.inkSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .memoraCard(padding: 18)
                    .padding(.horizontal, 22)
                    .padding(.top, 28)

                    VStack(spacing: 12) {
                        Button {
                            Task { await auth.signInWithGoogle() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                Text(auth.googleConfigured ? "Continue with Google" : "Google (optional setup)")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button { showGuestName = true } label: {
                            Text("Continue as guest")
                        }
                        .buttonStyle(GhostButtonStyle())
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)

                    if let err = auth.errorMessage {
                        Text(err)
                            .font(.memoraCaption(12))
                            .foregroundStyle(AppTheme.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.top, 12)
                    }

                    Text("Use a real email (Gmail etc). Password min 6 chars.\nNo email verification needed — you sign in right away.")
                        .font(.memoraMicro(11))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 28)
                        .padding(.bottom, 48)
                }
            }
        }
        .alert("What should we call you?", isPresented: $showGuestName) {
            TextField("Name", text: $guestName)
            Button("Continue") { auth.continueAsGuest(name: guestName.isEmpty ? "Traveler" : guestName) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Guest mode keeps memories on this phone only.")
        }
        .overlay {
            if auth.isLoading {
                Color.ink.opacity(0.12).ignoresSafeArea()
                ProgressView()
                    .tint(AppTheme.clay)
                    .padding(28)
                    .background(AppTheme.paperElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: AppTheme.shadowCard, radius: 12, y: 4)
            }
        }
    }

    private func modeTab(_ title: String, _ value: Mode) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) { mode = value }
        } label: {
            Text(title)
                .font(.memoraCallout(13))
                .fontWeight(.semibold)
                .foregroundStyle(mode == value ? AppTheme.ink : AppTheme.inkTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    mode == value
                    ? RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppTheme.paperElevated)
                    : nil
                )
                .shadow(color: mode == value ? AppTheme.shadowSoft : .clear, radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }
}

private extension Color {
    static let ink = AppTheme.ink
}
