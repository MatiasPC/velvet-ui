import SwiftUI

// MARK: - Design System Scroll Reveal
// A scroll-driven reveal for items in a `ScrollView`: rows sit full-size and
// opaque at the centre of the viewport and ease down in scale, opacity and a
// touch of blur as they approach the leading and trailing edges. It is the
// continuous, position-driven companion to `dsStaggerIn` (which fires once on
// appear): where the stagger animates an entrance, this keeps animating for the
// whole scroll, so content reads as coming into and out of focus as it passes.
//
// Built on the iOS 17 `scrollTransition` / `VisualEffect` pipeline rather than a
// hand-rolled `GeometryReader` offset reader: SwiftUI tracks each item's
// position against the scroll container and interpolates the effect off the main
// thread, so the reveal stays smooth under a fast flick where a per-frame
// geometry read would stutter. Applied per item, never on the container — the
// same shape as `dsStaggerIn`.
//
// Follows the Velvet motion rules: eased/interactive interpolation for ambience
// (never a spring — nothing was touched), Reduce Motion as a real state (the
// scale and blur drop out; the opacity fade stays, because opacity is not
// motion — the same call `dsPopIn` makes), and pure SwiftUI so both platforms
// build. It is decorative: no haptics, no color, no layout of its own.

// MARK: - Intensity

/// How far an item recedes at the viewport edges.
public enum DSScrollRevealIntensity: Sendable {
    /// Barely there — dense feeds and lists where the content is the point.
    case subtle
    /// The default — a clear "coming into focus" without hiding anything.
    case medium
    /// Cinematic — hero carousels and single-column card stacks.
    case strong

    // The resting values below are the effect at a viewport edge; the centre is
    // always identity (scale 1, opacity 1, no blur). They are animation shaping
    // ratios, not layout — there is no spacing, radius or color token for "how
    // small does a card get at the edge" — so, like `DSBreatheIntensity`, they
    // live here as named constants tuned by eye against the glass surfaces.

    /// Scale at the edge. Never below `strong`'s value — past ~0.8 the row reads
    /// as thrown away rather than receding.
    var restScale: CGFloat {
        switch self {
        case .subtle: return 0.94
        case .medium: return 0.88
        case .strong: return 0.80
        }
    }

    /// Opacity at the edge. Kept above zero so nothing fully vanishes mid-scroll.
    var restOpacity: Double {
        switch self {
        case .subtle: return 0.60
        case .medium: return 0.40
        case .strong: return 0.20
        }
    }

    /// Blur radius at the edge, in points. `subtle` stays crisp; the heavier
    /// levels add just enough softening to read as depth, not as a focus pull.
    var restBlur: CGFloat {
        switch self {
        case .subtle: return 0
        case .medium: return 2
        case .strong: return 6
        }
    }
}

// MARK: - Modifier

public struct DSScrollRevealModifier: ViewModifier {
    let intensity: DSScrollRevealIntensity

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `.interactive` interpolates the effect continuously with the scroll offset
    /// (the App Store "Today" feel), so the reveal tracks the finger instead of
    /// snapping at a threshold the way `.animated` would.
    public func body(content: Content) -> some View {
        content.scrollTransition(.interactive) { effect, phase in
            effect
                .scaleEffect(scale(for: phase))
                .opacity(opacity(for: phase))
                .blur(radius: blur(for: phase))
        }
    }

    // Reduce Motion keeps the opacity fade (opacity is not motion) and pins the
    // scale and blur at their identity values so nothing travels or defocuses —
    // the reveal degrades to a gentle positional cross-fade rather than off.

    private func scale(for phase: ScrollTransitionPhase) -> CGFloat {
        phase.isIdentity || reduceMotion ? 1 : intensity.restScale
    }

    private func opacity(for phase: ScrollTransitionPhase) -> Double {
        phase.isIdentity ? 1 : intensity.restOpacity
    }

    private func blur(for phase: ScrollTransitionPhase) -> CGFloat {
        phase.isIdentity || reduceMotion ? 0 : intensity.restBlur
    }
}

// MARK: - View Extension

public extension View {
    /// Fade + shrink an item as it nears the edges of its `ScrollView`, easing
    /// back to full size and opacity at the centre. Apply it to the items inside
    /// a scroll container (rows, cards, carousel cells), not to the container:
    ///
    ///     ScrollView {
    ///         LazyVStack(spacing: DSSpacing.md) {
    ///             ForEach(items) { item in
    ///                 DSCard { ItemView(item) }
    ///                     .dsScrollReveal()
    ///             }
    ///         }
    ///     }
    ///
    /// Works on either axis — the scroll direction is inferred. Under Reduce
    /// Motion the scale and blur drop out and only the opacity fade remains.
    func dsScrollReveal(_ intensity: DSScrollRevealIntensity = .medium) -> some View {
        modifier(DSScrollRevealModifier(intensity: intensity))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSScrollRevealPreviewHost: View {
    @State private var theme = DSTheme()

    private let rows = Array(0..<12)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                DSPreviewThemeDots(theme: theme)

                Text("Scroll — rows come into focus at the centre and recede at the edges.")
                    .ds(.caption1, color: DSColors.textSecondary)

                ForEach(rows, id: \.self) { index in
                    DSCard {
                        HStack(spacing: DSSpacing.md) {
                            Circle()
                                .fill(theme.gradient.horizontalGradient)
                                .frame(width: DSSpacing.huge, height: DSSpacing.huge)
                                .overlay {
                                    Text("\(index + 1)")
                                        .ds(.numeric, color: theme.gradient.onAccent)
                                }
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text("Row \(index + 1)").ds(.title3)
                                Text("Reveals with scroll position")
                                    .ds(.callout, color: DSColors.textSecondary)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .dsScrollReveal(index.isMultiple(of: 2) ? .medium : .strong)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Scroll Reveal — Light") {
    DSScrollRevealPreviewHost().preferredColorScheme(.light)
}

#Preview("Scroll Reveal — Dark") {
    DSScrollRevealPreviewHost().preferredColorScheme(.dark)
}
#endif
