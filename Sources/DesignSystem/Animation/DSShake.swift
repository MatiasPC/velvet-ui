import SwiftUI

// MARK: - Design System Shake
// The "no" gesture for a view: a quick horizontal shake that says *this is
// wrong* without a word of copy — a rejected password, an empty required
// field, a failed action. Drive it off any `Equatable` value: bump the value
// (a counter, an error id, a Bool) and the view shakes once and settles.
//
// The motion is a damped sine on a `GeometryEffect` (layout never moves, so it
// composes with any content), the same mechanic proven inside `DSCodeField`,
// lifted here as one reusable modifier. It fires an `.error` haptic by default
// and honors Reduce Motion — the haptic still plays, the pixels stay put.

public enum DSShake {
    /// Peak horizontal travel of the shake, in points.
    public static let amount: CGFloat = 8
    /// Half-cycles per shake — how many left/right passes before it rests.
    public static let oscillations: CGFloat = 4
    /// Curve driving one shake. A timing curve (no overshoot) so the sine plays
    /// cleanly; a spring on the driver would smear the wave.
    public static let animation: Animation = DSAnimation.normal
}

// MARK: - Geometry Effect

/// Horizontal shake driven by an animatable count. Each whole-number step of
/// `shakes` plays one damped shake that starts and settles at rest, so
/// incrementing it inside `withAnimation` runs exactly one shake.
public struct DSShakeEffect: GeometryEffect {
    /// Peak horizontal travel. Set to `0` to disable motion (Reduce Motion).
    public var travel: CGFloat
    /// The animated shake count. Fractional values are the in-flight progress.
    public var shakes: CGFloat

    public var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    public init(travel: CGFloat = DSShake.amount, shakes: CGFloat) {
        self.travel = travel
        self.shakes = shakes
    }

    public func effectValue(size: CGSize) -> ProjectionTransform {
        // Progress through the current shake (0 → 1); fade the amplitude out
        // across it so the wave decays instead of stopping mid-swing.
        let progress = shakes - shakes.rounded(.down)
        let damping = 1 - progress
        let offset = travel * damping * sin(shakes * .pi * DSShake.oscillations)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

// MARK: - Modifier

public struct DSShakeModifier<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let haptic: DSHapticStyle?

    @State private var shakes: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(trigger: Trigger, haptic: DSHapticStyle?) {
        self.trigger = trigger
        self.haptic = haptic
    }

    public func body(content: Content) -> some View {
        content
            .modifier(DSShakeEffect(travel: reduceMotion ? 0 : DSShake.amount, shakes: shakes))
            .onChange(of: trigger) {
                if let haptic {
                    DSHapticEngine.shared.fire(haptic)
                }
                guard !reduceMotion else { return }
                withAnimation(DSShake.animation) {
                    shakes += 1
                }
            }
    }
}

// MARK: - View Extension

public extension View {
    /// Shake the view horizontally whenever `trigger` changes — the standard
    /// "invalid input / rejected action" nudge.
    ///
    /// Change any `Equatable` value to fire one shake: a failure counter, the
    /// id of the latest error, or a toggled `Bool`.
    ///
    ///     DSTextField(placeholder: "Password", text: $password, isSecure: true)
    ///         .dsShake(attempts)   // attempts += 1 on a wrong password
    ///
    /// - Parameters:
    ///   - trigger: The value to watch. Every change runs one shake.
    ///   - haptic: Feedback fired with each shake. Defaults to `.error`; pass
    ///     `nil` for a silent shake.
    func dsShake(_ trigger: some Equatable, haptic: DSHapticStyle? = .error) -> some View {
        modifier(DSShakeModifier(trigger: trigger, haptic: haptic))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSShakePreviewHost: View {
    @State private var theme = DSTheme()

    @State private var password = ""
    @State private var attempts = 0
    @State private var wrong = false

    private var isValid: Bool { password.count >= 6 }

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSPreviewThemeDots(theme: theme)

            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Sign in").ds(.title3)

                    DSTextField(
                        placeholder: "Password (min. 6)",
                        icon: "lock",
                        text: $password,
                        state: wrong ? .error("Incorrect password") : .normal,
                        isSecure: true
                    )
                    .dsShake(attempts)

                    DSButton("Log in", isFullWidth: true) {
                        if isValid {
                            wrong = false
                        } else {
                            wrong = true
                            attempts += 1   // fires the shake + .error haptic
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Works on any view, not just inputs.
            DSButton("Shake this button", variant: .secondary) {
                attempts += 1
            }
            .dsShake(attempts, haptic: .warning)
        }
        .dsScreenPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Shake — Light") {
    DSShakePreviewHost().preferredColorScheme(.light)
}

#Preview("Shake — Dark") {
    DSShakePreviewHost().preferredColorScheme(.dark)
}
#endif
