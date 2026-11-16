import SwiftUI
import VelvetUI

struct PasswordStrengthScreen: View {
    @State private var password = ""
    @State private var pin = ""

    var body: some View {
        GalleryScreen(title: "Password Strength", caption: "Segments fill as the password gets stronger, with the one change that helps most") {
            LabeledExample("Sign up") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        DSTextField(label: "New password", placeholder: "At least 8 characters", icon: "lock",
                                    text: $password, isSecure: true)
                        DSPasswordStrength(password: password)
                        DSButton("Create account", isFullWidth: true) {}
                            .disabled(DSPasswordStrength.level(of: password) < .good)
                    }
                }
            }

            LabeledExample("Shorter minimum, success haptic") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        DSTextField(label: "Vault phrase", placeholder: "At least 6 characters", text: $pin, isSecure: true)
                        DSPasswordStrength(password: pin, minLength: 6, haptic: .success, accessibilityLabel: "Phrase strength")
                    }
                }
            }

            LabeledExample("Levels") {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    ForEach(["password1", "sunflower", "sunflower7!", "correct horse battery staple"], id: \.self) { sample in
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text(sample).ds(.caption1, color: DSColors.textTertiary)
                            DSPasswordStrength(password: sample)
                        }
                    }
                }
            }

            Text("Length counts most, a common password is weak however it is decorated, and reaching Strong fires one haptic. With VoiceOver on, the meter is one element that reads the level and the hint, and level changes are announced.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Recording stage: a sign-up card with a visible (not secure) password field,
/// so a recording and the UI test can see what is typed. The meter is the
/// accessibility element "Password strength", whose value is the level and the
/// hint ("Fair. Add a number"). "Create account" is enabled from Good, through
/// `DSPasswordStrength.level(of:)`, and "Clear" empties the field. The UI test
/// types into the field and reads the meter after each step.
struct PasswordStrengthStage: View {
    let autoplay: Bool
    @State private var password = ""

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Create your account").ds(.title3)
                DSTextField(label: "New password", placeholder: "Choose a password", icon: "lock", text: $password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                DSPasswordStrength(password: password)
                HStack(spacing: DSSpacing.sm) {
                    DSButton("Create account", size: .small) {}
                        .disabled(DSPasswordStrength.level(of: password) < .good)
                    DSButton("Clear", variant: .ghost, size: .small) { password = "" }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for next in ["", "sun", "sunflower", "sunflower7!", "sunflower7!Kite", "password1"] {
                    await stagePause(1.2)
                    if Task.isCancelled { return }
                    password = next
                }
            }
        }
    }
}
