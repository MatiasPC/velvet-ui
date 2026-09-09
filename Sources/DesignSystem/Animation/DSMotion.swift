import SwiftUI

// MARK: - Design System Motion
// Ambient, composable motion effects — the layer above `DSAnimation` (which
// holds curves) and below the components (which hold behavior).
//
// Everything here follows the six Velvet motion rules (docs/proposals/0002):
// springs for touch and eased curves for ambience, color from the theme,
// Reduce Motion as a real state rather than a bail-out, glass instead of fills,
// haptics on the beat, and pure SwiftUI so both platforms build.
//
// Techniques adapted from github.com/amosgyamfi/open-swiftui-animations
// (pulsing hearts, hue-rotation slides, marching-ants border). Rewritten on
// Velvet tokens; no upstream code is reproduced.

public enum DSMotion {

    // MARK: - Loop Durations

    /// 2.4s — breathing swell. Slow enough to read as alive, not as a spinner.
    public static let breatheDuration: Double = 2.4
    /// 2.0s — one full trip of the edge sweep.
    public static let sweepDuration: Double = 2.0
    /// 8.0s — hue drift. Deliberately slow: you should notice it only on a second look.
    public static let driftDuration: Double = 8.0

    // MARK: - Bounds

    /// Maximum hue rotation of `dsHueDrift`. Small on purpose — the gradient theme
    /// must stay recognisable, so the drift shifts within the family, never out of it.
    public static let driftDegrees: Double = 12
    /// Peak rotation of the first `dsJiggle` swing; later swings shrink from here.
    public static let jiggleDegrees: Double = 7
    /// 0.45s — total length of one `dsJiggle`. A quick "no" shake, not a wobble.
    public static let jiggleDuration: Double = 0.45
    /// The `dsJiggle` envelope in degrees: a kick to `jiggleDegrees`, then
    /// counter-swings at ~0.6× each, alternating sign, ending at rest. Cubic
    /// keyframes interpolate between these so it reads as one continuous shake.
    public static let jiggleSwings: [Double] = [
        jiggleDegrees,
        -jiggleDegrees * 0.62,
        jiggleDegrees * 0.38,
        -jiggleDegrees * 0.18,
        0
    ]

    // MARK: - Reduce Motion

    /// Wrap an animation in `repeatForever`, or return `nil` when Reduce Motion is on.
    ///
    /// Passing `nil` to `withAnimation`/`.animation(_:value:)` applies the change
    /// instantly, so every ambient effect settles at its resting state instead of
    /// being skipped:
    ///
    ///     .animation(DSMotion.loop(DSAnimation.ambient, unless: reduceMotion), value: phase)
    public static func loop(
        _ base: Animation,
        autoreverses: Bool = true,
        unless reduceMotion: Bool
    ) -> Animation? {
        reduceMotion ? nil : base.repeatForever(autoreverses: autoreverses)
    }
}

// MARK: - Breathe

/// How far a breathing element swells.
public enum DSBreatheIntensity: Sendable {
    /// 1.02 — status dots, "live" indicators, anything next to text.
    case subtle
    /// 1.05 — the default: loading states, waiting avatars.
    case medium
    /// 1.10 — a single hero element asking to be tapped.
    case strong

    var scale: CGFloat {
        switch self {
        case .subtle: return 1.02
        case .medium: return 1.05
        case .strong: return 1.10
        }
    }

    var dip: Double {
        switch self {
        case .subtle: return 0.06
        case .medium: return 0.12
        case .strong: return 0.20
        }
    }
}

public struct DSBreatheModifier: ViewModifier {
    let intensity: DSBreatheIntensity

    @State private var isSwollen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isSwollen ? intensity.scale : 1)
            .opacity(isSwollen ? 1 - intensity.dip : 1)
            .animation(
                DSMotion.loop(.easeInOut(duration: DSMotion.breatheDuration), unless: reduceMotion),
                value: isSwollen
            )
            .onAppear { isSwollen = true }
    }
}

// MARK: - Jiggle

public struct DSJiggleModifier<T: Equatable>: ViewModifier {
    let trigger: T

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A decaying rotational impulse fired on every `trigger` change: a kick out
    /// to `jiggleDegrees`, then counter-swings at roughly 0.6× each, alternating
    /// sign, easing back to zero over `jiggleDuration`.
    ///
    /// One continuous `keyframeAnimator` track, not stepped `phaseAnimator`
    /// phases: with phases each swing runs its own spring and *settles* before
    /// the next starts, which reads as five separate twitches. Cubic keyframes
    /// carry velocity across the whole track, so the swings flow into one shake.
    /// The `DSAnimation` springs are frozen and none is damped low enough to
    /// ring, hence the hand-shaped envelope here.
    public func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, angle in
                view.rotationEffect(.degrees(angle))
            } keyframes: { _ in
                let step = DSMotion.jiggleDuration / Double(DSMotion.jiggleSwings.count)
                for swing in DSMotion.jiggleSwings {
                    CubicKeyframe(swing, duration: step)
                }
            }
        }
    }
}

// MARK: - Pop In

public struct DSPopInModifier: ViewModifier {
    let delay: Double

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Reduce Motion keeps the fade — opacity is not motion — and pins the scale at
    /// rest so nothing travels.
    private var startScale: CGFloat { reduceMotion ? 1 : 0.8 }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(hasAppeared ? 1 : startScale)
            .opacity(hasAppeared ? 1 : 0)
            .onAppear {
                let animation = reduceMotion
                    ? DSAnimation.fast.delay(delay)
                    : DSAnimation.springBouncy.delay(delay)
                withAnimation(animation) { hasAppeared = true }
            }
    }
}

// MARK: - Edge Sweep

/// A specular highlight travelling around a surface edge — the Velvet reading of
/// a "marching ants" border. It is not a border: it rides the same 1pt
/// `DSWash.edge` highlight that every glass surface already draws, so it reads as
/// light moving across glass rather than as a stroke.
public struct DSEdgeSweepModifier: ViewModifier {
    let radius: CGFloat
    let isActive: Bool

    @State private var rotation: Double = 0
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var peak: Double { theme.isDark ? 0.55 : 0.85 }

    private var sweep: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: .white.opacity(0), location: 0.00),
                .init(color: .white.opacity(0), location: 0.30),
                .init(color: .white.opacity(peak), location: 0.50),
                .init(color: .white.opacity(0), location: 0.70),
                .init(color: .white.opacity(0), location: 1.00)
            ]),
            center: .center,
            angle: .degrees(rotation)
        )
    }

    public func body(content: Content) -> some View {
        content.overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(sweep, lineWidth: DSWash.edgeWidth)
                .opacity(isActive ? 1 : 0)
                .allowsHitTesting(false)
                .animation(DSAnimation.micro, value: isActive)
        }
        .onAppear { startIfNeeded() }
        .onChange(of: isActive) { _, _ in startIfNeeded() }
    }

    private func startIfNeeded() {
        guard isActive, !reduceMotion, rotation == 0 else { return }
        withAnimation(.linear(duration: DSMotion.sweepDuration).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}

// MARK: - Hue Drift

/// Slow hue rotation bounded to `DSMotion.driftDegrees`. Gives a static gradient
/// surface a sense of being lit from a moving source without leaving the theme.
public struct DSHueDriftModifier: ViewModifier {
    let isActive: Bool

    @State private var hasDrifted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content
            .hueRotation(.degrees(hasDrifted && isActive ? DSMotion.driftDegrees : 0))
            .animation(
                DSMotion.loop(.easeInOut(duration: DSMotion.driftDuration), unless: reduceMotion),
                value: hasDrifted
            )
            .onAppear { hasDrifted = true }
    }
}

// MARK: - View Extensions

public extension View {
    /// Ambient swell — "this is alive and waiting". Settles static under Reduce Motion.
    func dsBreathe(_ intensity: DSBreatheIntensity = .medium) -> some View {
        modifier(DSBreatheModifier(intensity: intensity))
    }

    /// One decaying wiggle, fired every time `trigger` changes. Use for a rejected
    /// input or an item that needs noticing — it ends on its own.
    func dsJiggle<T: Equatable>(trigger: T) -> some View {
        modifier(DSJiggleModifier(trigger: trigger))
    }

    /// Entrance with a `springBouncy` overshoot. Under Reduce Motion it fades only.
    /// For lists prefer `dsStaggerIn(index:)`, which sequences this feel across rows.
    func dsPopIn(delay: Double = 0) -> some View {
        modifier(DSPopInModifier(delay: delay))
    }

    /// A highlight travelling the surface edge — processing, recording, "AI is working".
    /// Pair it with the radius of the surface underneath.
    func dsEdgeSweep(radius: CGFloat = DSRadius.card, isActive: Bool = true) -> some View {
        modifier(DSEdgeSweepModifier(radius: radius, isActive: isActive))
    }

    /// Slow, bounded hue drift over the theme gradient. Decorative only.
    func dsHueDrift(isActive: Bool = true) -> some View {
        modifier(DSHueDriftModifier(isActive: isActive))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSMotionPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var jiggle = 0
    @State private var sweeping = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                label("dsBreathe")
                HStack(spacing: DSSpacing.xl) {
                    dot("subtle", .subtle)
                    dot("medium", .medium)
                    dot("strong", .strong)
                }

                label("dsJiggle")
                HStack(spacing: DSSpacing.md) {
                    Image(systemName: "bell.fill")
                        .font(.largeTitle)
                        .foregroundStyle(theme.gradient.accent)
                        .dsJiggle(trigger: jiggle)
                    Spacer()
                    DSButton("Shake", size: .small) { jiggle += 1 }
                }

                label("dsEdgeSweep")
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Processing…").ds(.body)
                    DSToggle("Sweeping", isOn: $sweeping)
                }
                .padding(DSSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsSurface(.glass, radius: DSRadius.card)
                .dsEdgeSweep(radius: DSRadius.card, isActive: sweeping)

                label("dsPopIn + dsHueDrift")
                HStack(spacing: DSSpacing.sm) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                            .fill(theme.gradient.horizontalGradient)
                            .frame(height: DSSpacing.huge)
                            .dsHueDrift()
                            .dsPopIn(delay: Double(index) * 0.08)
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func label(_ text: String) -> some View {
        Text(text).ds(.overline, color: DSColors.textSecondary)
    }

    private func dot(_ name: String, _ intensity: DSBreatheIntensity) -> some View {
        VStack(spacing: DSSpacing.xs) {
            Circle()
                .fill(theme.gradient.accent)
                .frame(width: DSSpacing.huge, height: DSSpacing.huge)
                .dsBreathe(intensity)
            Text(name).ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

#Preview("Motion — Light") {
    DSMotionPreviewHost().preferredColorScheme(.light)
}

#Preview("Motion — Dark") {
    DSMotionPreviewHost().preferredColorScheme(.dark)
}
#endif
