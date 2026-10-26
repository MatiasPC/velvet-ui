import SwiftUI

// MARK: - Design System Tilt Card
// A glass card that tips in 3D toward the finger as you drag it, with a specular
// highlight that slides across the surface like light catching glass, then springs
// back to rest on release. It is the Velvet reading of the "parallax / holo card"
// micro-interaction: the tilt and the moving sheen are one gesture, the sheen rides
// the same white specular language as `DSWash.edge` and `dsEdgeSweep`, and the whole
// thing settles flat under Reduce Motion so nothing is left mid-tilt.
//
// It wraps arbitrary content on a `.glass` surface (radius `DSRadius.card`, soft
// `DSShadow`), so it reads as an elevated card at rest and only comes alive on touch.
// Use it for a hero, feature, loyalty or product card — anywhere a single surface is
// meant to feel physical. For a flat tappable surface use `DSInteractiveCard`; this is
// about depth and light, not a tap action.
//
// Technique (drag-driven `rotation3DEffect` on both axes with a spring snap-back and a
// gesture-tracked sheen) is the common SwiftUI tilt-card pattern, rewritten on Velvet
// tokens, motion and haptics. Inspiration: Design+Code "Drag Gesture on X and Y" /
// "3D Card with Holo Effect", and Codelaby's interactive 3D card experiments.

// MARK: - Metrics

/// Tuning constants for the tilt feel. Local to the component, like `DSToggleSize`'s
/// track sizes — the numbers that make the motion read right, in one place.
private enum DSTiltMetrics {
    /// Peak rotation reached at the edge of the drag span. Gentle on purpose: a card
    /// that tips too far stops reading as a surface and starts reading as a page turn.
    static let tilt: Angle = .degrees(12)
    /// Drag distance, in points, that maps to the peak tilt. Past it the tilt clamps.
    static let travel: CGFloat = 120
    /// `rotation3DEffect` perspective. Below 1 the vanishing point sits further back,
    /// so the distortion stays subtle instead of fish-eyed.
    static let perspective: CGFloat = 0.7
    /// Peak opacity of the specular sheen at full tilt.
    static let sheenPeak: Double = 0.4
    /// Oversize factor for the sheen band so it can travel without its edges showing.
    static let sheenScale: CGFloat = 1.6
    /// How far, in points, the sheen band slides across the surface at full tilt.
    static let sheenTravel: CGFloat = 44
}

// MARK: - Tilt Card

public struct DSTiltCard<Content: View>: View {
    let maxTilt: Angle
    let padding: CGFloat
    let cornerRadius: CGFloat
    let haptic: DSHapticStyle
    let content: () -> Content

    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - maxTilt: Peak rotation at the edge of the drag. Defaults to 12°.
    ///   - padding: Inner padding around `content`. Defaults to `DSSpacing.md`.
    ///   - cornerRadius: Corner radius of the glass surface. Defaults to `DSRadius.card`.
    ///   - haptic: Fired once when the drag begins. Defaults to `.soft`.
    ///   - content: The card's content.
    public init(
        maxTilt: Angle = DSTiltMetrics.tilt,
        padding: CGFloat = DSSpacing.md,
        cornerRadius: CGFloat = DSRadius.card,
        haptic: DSHapticStyle = .soft,
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
        content()
            .padding(padding)
            .dsSurface(.glass, radius: cornerRadius)
            .overlay {
                // Specular light sliding across the glass. Decorative, so it rides the
                // Reduce Motion rule with the tilt: no tilt, no sheen.
                if !reduceMotion {
                    sheen.clipShape(shape)
                }
            }
            .dsShadow(isDragging ? .xl : .lg)
            // Horizontal drag rotates around the vertical axis, vertical drag around the
            // horizontal one, so the surface tips toward the finger. Both are no-ops at
            // rest (angle 0) and under Reduce Motion (offset never leaves .zero).
            .rotation3DEffect(
                .degrees(-Double(normalized.height) * maxTilt.degrees),
                axis: (x: 1, y: 0, z: 0),
                perspective: DSTiltMetrics.perspective
            )
            .rotation3DEffect(
                .degrees(Double(normalized.width) * maxTilt.degrees),
                axis: (x: 0, y: 1, z: 0),
                perspective: DSTiltMetrics.perspective
            )
            .gesture(dragGesture, including: reduceMotion ? .subviews : .all)
            .accessibilityElement(children: .contain)
    }

    // MARK: - Sheen

    private var sheen: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(DSTiltMetrics.sheenPeak), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .scaleEffect(DSTiltMetrics.sheenScale)
        .offset(
            x: -normalized.width * DSTiltMetrics.sheenTravel,
            y: -normalized.height * DSTiltMetrics.sheenTravel
        )
        .opacity(magnitude)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    withAnimation(DSAnimation.fast) { isDragging = true }
                    DSHapticEngine.shared.fire(haptic)
                }
                // Track the finger 1:1 — no animation here, or the tilt would lag.
                offset = value.translation
            }
            .onEnded { _ in
                withAnimation(DSAnimation.springGentle) {
                    offset = .zero
                    isDragging = false
                }
            }
    }

    // MARK: - Derived

    /// Drag offset mapped to −1…1 on each axis.
    private var normalized: CGSize {
        CGSize(
            width: max(-1, min(1, offset.width / DSTiltMetrics.travel)),
            height: max(-1, min(1, offset.height / DSTiltMetrics.travel))
        )
    }

    /// Overall tilt strength, 0 at rest to 1 at the edge — drives the sheen's fade-in.
    private var magnitude: Double {
        let n = normalized
        let distance = (n.width * n.width + n.height * n.height).squareRoot()
        return Double(min(1, distance))
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
