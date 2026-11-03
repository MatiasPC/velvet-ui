import SwiftUI

// MARK: - Design System Tilt Card
// A glass card that tips in 3D toward the finger as you drag it, with a specular
// highlight that slides across the surface like light catching glass, then springs
// back to rest on release. It is the Velvet reading of the "parallax / holo card"
// micro-interaction: the tilt and the moving sheen are one gesture, and the sheen rides
// the same white specular language as `DSWash.edge` and `dsEdgeSweep`.
//
// It wraps arbitrary content on a `.glass` surface (radius `DSRadius.card`, soft
// `DSShadow`), so it reads as an elevated card at rest and only comes alive on touch.
// Use it for a hero, feature, loyalty or product card — anywhere a single surface is
// meant to feel physical. For a flat tappable surface use `DSInteractiveCard`; this is
// about depth and light, not a tap action.
//
// Motion: tracking the finger is un-animated (a lagging tilt feels broken); release
// or a cancelled touch springs back with `DSAnimation.springGentle`. Under Reduce
// Motion the card never rotates, the shadow does not lift and the sheen does not slide;
// it only fades in while the card is held, so touch still gets visible feedback.
// The gesture is simultaneous, so a card inside a ScrollView does not block scrolling
// and buttons inside the card keep working. On macOS it follows a mouse drag.
//
// Technique (drag-driven `rotation3DEffect` on both axes with a spring snap-back and a
// gesture-tracked sheen) is the common SwiftUI tilt-card pattern, rewritten on Velvet
// tokens, motion and haptics. Inspiration: Design+Code "Drag Gesture on X and Y" /
// "3D Card with Holo Effect", and Codelaby's interactive 3D card experiments.

// MARK: - Metrics

/// Tuning constants for the tilt feel, in one place. Internal (not private) because the
/// public initializer resolves its default `maxTilt` from here and the tests pin the maths.
enum DSTiltMetrics {
    /// Peak rotation reached at the edge of the drag span. Gentle on purpose: a card
    /// that tips too far stops reading as a surface and starts reading as a page turn.
    static let tilt: Angle = .degrees(12)
    /// Drag distance, in points, that maps to the peak tilt. Past it the tilt clamps.
    static let travel: CGFloat = 120
    /// `rotation3DEffect` perspective. Below 1 the vanishing point sits further back,
    /// so the distortion stays subtle instead of fish-eyed.
    static let perspective: CGFloat = 0.7
    /// Peak opacity of the specular sheen at full tilt, on light and dark themes.
    /// Light glass needs a stronger highlight to read; on dark it blooms quickly.
    static let sheenPeakLight: Double = 0.55
    static let sheenPeakDark: Double = 0.4
    /// Oversize factor for the sheen band so it can travel without its edges showing.
    static let sheenScale: CGFloat = 1.6
    /// How far, in points, the sheen band slides across the surface at full tilt.
    static let sheenTravel: CGFloat = 44
}

// MARK: - Math

/// The pure maths behind `DSTiltCard`, kept out of the generic view so it can be tested directly.
enum DSTiltMath {
    /// Drag translation mapped to −1…1 on each axis (`travel` points = 1).
    static func normalized(_ translation: CGSize, travel: CGFloat = DSTiltMetrics.travel) -> CGSize {
        guard travel > 0 else { return .zero }
        func clamp(_ value: CGFloat) -> CGFloat {
            value.isFinite ? max(-1, min(1, value / travel)) : 0
        }
        return CGSize(width: clamp(translation.width), height: clamp(translation.height))
    }

    /// Overall tilt strength, 0 at rest to 1 at the edge of the span. Drives the sheen.
    static func magnitude(of normalized: CGSize) -> Double {
        let distance = (normalized.width * normalized.width + normalized.height * normalized.height).squareRoot()
        return Double(min(1, distance))
    }

    /// Rotation, in degrees, around the horizontal (`x`) and vertical (`y`) axes for a
    /// normalized drag. Dragging right dips the right edge away from the viewer and
    /// dragging down dips the bottom edge away, so the surface leans toward the finger.
    static func rotation(for normalized: CGSize, maxTilt: Angle) -> (x: Double, y: Double) {
        let limit = abs(maxTilt.degrees)
        return (x: -Double(normalized.height) * limit, y: Double(normalized.width) * limit)
    }
}

// MARK: - Tilt Card

public struct DSTiltCard<Content: View>: View {
    let maxTilt: Angle?
    let padding: CGFloat
    let cornerRadius: CGFloat
    let haptic: DSHapticStyle?
    let content: () -> Content

    @State private var offset: CGSize = .zero
    @State private var isLifted = false
    /// True while a finger is down. `@GestureState` resets itself when the gesture ends
    /// *or is cancelled* (a ScrollView claiming the touch, a system interruption), which
    /// `onEnded` alone would miss, so the card can never be left mid-tilt.
    @GestureState private var isTouching = false

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - maxTilt: Peak rotation at the edge of the drag. `nil` (the default) is 12°.
    ///   - padding: Inner padding around `content`. Defaults to `DSSpacing.md`.
    ///   - cornerRadius: Corner radius of the glass surface. Defaults to `DSRadius.card`.
    ///   - haptic: Fired once when the touch begins. `nil` for none. Defaults to `.soft`.
    ///   - content: The card's content.
    public init(
        maxTilt: Angle? = nil,
        padding: CGFloat = DSSpacing.md,
        cornerRadius: CGFloat = DSRadius.card,
        haptic: DSHapticStyle? = .soft,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.maxTilt = maxTilt
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.haptic = haptic
        self.content = content
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        // Reduce Motion is a resting state: no rotation, no sliding sheen, no lift. The
        // offset is also ignored here (not just never set), so toggling the setting
        // mid-drag settles the card flat immediately.
        let normalized = reduceMotion ? .zero : DSTiltMath.normalized(offset)
        let rotation = DSTiltMath.rotation(for: normalized, maxTilt: maxTilt ?? DSTiltMetrics.tilt)

        content()
            .padding(padding)
            .dsSurface(.glass, radius: cornerRadius)
            .overlay {
                sheen(normalized: normalized).clipShape(shape)
            }
            .dsShadow(isLifted && !reduceMotion ? .xl : .lg)
            // Horizontal drag rotates around the vertical axis, vertical drag around the
            // horizontal one, so the surface tips toward the finger. Both are no-ops at rest.
            .rotation3DEffect(
                .degrees(rotation.x),
                axis: (x: 1, y: 0, z: 0),
                perspective: DSTiltMetrics.perspective
            )
            .rotation3DEffect(
                .degrees(rotation.y),
                axis: (x: 0, y: 1, z: 0),
                perspective: DSTiltMetrics.perspective
            )
            .contentShape(shape)
            // Simultaneous, so the card never steals a scroll from the ScrollView it sits in
            // and buttons inside it keep their taps.
            .simultaneousGesture(dragGesture)
            // A cancelled gesture (a ScrollView takes the touch over) never calls `onEnded`,
            // but it does reset `isTouching`, so that is the safety net that flattens the card.
            .onChange(of: isTouching) { _, touching in
                if !touching { settle() }
            }
            .accessibilityElement(children: .contain)
    }

    // MARK: - Sheen

    /// Specular light sliding across the glass. Decorative, so it keeps to the same
    /// white highlight language as `DSWash.edge`. Under Reduce Motion it stays put and
    /// only fades in while the card is held, so touch still gets visible feedback.
    private func sheen(normalized: CGSize) -> some View {
        let peak = theme.isDark ? DSTiltMetrics.sheenPeakDark : DSTiltMetrics.sheenPeakLight
        let strength = reduceMotion ? (isLifted ? 1 : 0) : DSTiltMath.magnitude(of: normalized)
        return LinearGradient(
            colors: [.clear, .white.opacity(peak), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .scaleEffect(DSTiltMetrics.sheenScale)
        .offset(
            x: -normalized.width * DSTiltMetrics.sheenTravel,
            y: -normalized.height * DSTiltMetrics.sheenTravel
        )
        .opacity(strength)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isTouching) { _, state, _ in state = true }
            .onChanged { value in
                if !isLifted {
                    withAnimation(DSAnimation.fast) { isLifted = true }
                    if let haptic { DSHapticEngine.shared.fire(haptic) }
                }
                // Track the finger 1:1 with no animation, or the tilt would lag behind it.
                offset = value.translation
            }
            .onEnded { _ in settle() }
    }

    /// Release or cancel: spring flat. Safe to call twice (end, then the state reset).
    private func settle() {
        guard isLifted || offset != .zero else { return }
        // Under Reduce Motion only the sheen is left to fade out; a spring would overshoot it.
        withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springGentle) {
            offset = .zero
            isLifted = false
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSTiltCardPreviewHost: View {
    @State private var theme = DSTheme()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                Text("Drag a card to tilt it")
                    .ds(.overline, color: DSColors.textSecondary)

                DSTiltCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Image(systemName: "creditcard.fill")
                            .font(.title2)
                            .foregroundStyle(theme.gradient.accent)
                        Text("Velvet Card").ds(.title2)
                        Text("•••• •••• •••• 2048")
                            .ds(.numeric, color: DSColors.textSecondary)
                        HStack {
                            Text("A. Lovelace").ds(.footnote)
                            Spacer()
                            Text("12 / 29").ds(.footnote, color: DSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSTiltCard(maxTilt: .degrees(18)) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Weekly streak").ds(.footnote, color: DSColors.textSecondary)
                        Text("7 days").ds(.displayMedium)
                        Text("Your best run yet.").ds(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Tilt Card — Light") {
    DSTiltCardPreviewHost().preferredColorScheme(.light)
}

#Preview("Tilt Card — Dark") {
    DSTiltCardPreviewHost().preferredColorScheme(.dark)
}
#endif
