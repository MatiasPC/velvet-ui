import SwiftUI

// MARK: - Design System Scroll Reveal
// The scroll-driven sibling of the `DSMotion` primitives. Those decorate a view
// on a timer (`dsBreathe`), a trigger (`dsJiggle`) or an appearance (`dsPopIn`);
// this one decorates a view's *position in a scroll*. As a cell approaches the
// leading or trailing edge of its scroll container it dims, shrinks a touch and
// slides a few points along the scroll axis, settling to rest only once it
// reaches the middle — the App Store / Music "cards settling onto glass" feel.
//
// It is built on iOS 17's `.scrollTransition`, so SwiftUI interpolates the
// effect from the cell's live scroll offset. There is no `withAnimation`, no
// `@State`, no timeline: the finger drives the motion frame-perfectly and the
// effect is exactly reversible when you scroll back. Outside a scroll container
// the modifier is inert (every cell stays at identity), so it is always safe to
// attach.
//
// One opinionated house curve, four amounts of it, so every list in every app
// scrolls with the same Velvet signature instead of each screen inventing its
// own `.scrollTransition` closure. Reduce Motion collapses all four to the fade
// alone — opacity is information, not travel — matching how the rest of the
// motion set settles rather than switching off.
//
// Technique from iOS 17's ScrollView additions (WWDC23 "Beyond scroll views"):
// developer.apple.com/documentation/swiftui/scrolltransitionphase and
// swiftwithmajid.com/2023/06/13/mastering-scrollview-in-swiftui-transitions.
// No upstream code is reproduced.

// MARK: - Style

/// How much of the house reveal a cell gets as it crosses a scroll edge. Every
/// style shares the same fade; they differ only in whether the cell also scales,
/// slides, or both.
public enum DSScrollRevealStyle: Sendable {
    /// Opacity only — the calmest reveal, and the Reduce Motion fallback for all
    /// four. Good for dense text lists where travel would feel busy.
    case fade
    /// Fade + a small shrink toward the edge. The cell reads as receding.
    case scale
    /// Fade + a slide along the scroll axis. The cell reads as sliding into place.
    case rise
    /// Fade + scale + slide — the signature Velvet reveal, and the default. Cards
    /// settle onto the glass as they reach the middle of the viewport.
    case settle
}

// MARK: - Metrics

private enum Metrics {
    /// Opacity a cell reaches at the very edge of the container. Zero, so cells
    /// dissolve into the boundary rather than stopping at a visible dimmed state.
    static let edgeOpacity: Double = 0
    /// Scale a cell reaches at the edge. A gentle recede — enough to feel depth,
    /// not so much that neighbouring cells visibly change size. No press/scale
    /// token fits: `DSPress.scale` is the *touch* dip, a different gesture.
    static let edgeScale: CGFloat = 0.90
    /// How far a cell slides along the scroll axis at the edge, in points. One
    /// spacing step — present but never enough to read as lag behind the finger.
    static let slideDistance: CGFloat = DSSpacing.lg
}

// MARK: - Modifier

public struct DSScrollRevealModifier: ViewModifier {
    let style: DSScrollRevealStyle
    let axis: Axis

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content.scrollTransition { view, phase in
            let step = resolved(for: phase)
            return view
                .opacity(step.opacity)
                .scaleEffect(step.scale)
                .offset(
                    x: axis == .horizontal ? step.slide : 0,
                    y: axis == .vertical ? step.slide : 0
                )
        }
    }

    /// The three scalars for a phase, resolved for the style. The chain in `body`
    /// applies all three unconditionally — `scaleEffect(1)` and `offset(0)` are
    /// no-ops — so every style and the Reduce Motion path share one return type
    /// (`scrollTransition` needs a single concrete `VisualEffect`), and a style
    /// simply leaves the axes it does not use at their identity value.
    private func resolved(
        for phase: ScrollTransitionPhase
    ) -> (opacity: Double, scale: CGFloat, slide: CGFloat) {
        // `value` is 0 at rest (identity), −1 at the leading edge and +1 at the
        // trailing edge. `magnitude` is the eased-in distance from rest; `value`
        // keeps its sign so the slide pushes outward toward whichever edge the
        // cell is leaving.
        let magnitude = min(abs(phase.value), 1)
        let fade = 1 - magnitude * (1 - Metrics.edgeOpacity)
        let shrink = 1 - CGFloat(magnitude) * (1 - Metrics.edgeScale)
        let slide = CGFloat(phase.value) * Metrics.slideDistance

        if reduceMotion { return (fade, 1, 0) }

        switch style {
        case .fade:   return (fade, 1, 0)
        case .scale:  return (fade, shrink, 0)
        case .rise:   return (fade, 1, slide)
        case .settle: return (fade, shrink, slide)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Reveal this cell as it scrolls into the middle of its container: it dims,
    /// shrinks and slides toward whichever edge it is nearest, settling to rest at
    /// the centre. Attach it to each item in a `ScrollView` / `LazyVStack` /
    /// `LazyHStack` (or `DSHorizontalScroll`).
    ///
    ///     ScrollView {
    ///         LazyVStack(spacing: DSSpacing.md) {
    ///             ForEach(items) { item in
    ///                 DSCard { … }.dsScrollReveal()
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - style: How much of the reveal to apply. Defaults to `.settle`.
    ///   - axis: The scroll axis the slide follows. Defaults to `.vertical`; pass
    ///     `.horizontal` inside a horizontal scroll so cells slide sideways.
    ///
    /// The motion is driven entirely by scroll position — reversible, and inert
    /// outside a scroll container. Reduce Motion keeps the fade and drops the
    /// scale and slide.
    func dsScrollReveal(
        _ style: DSScrollRevealStyle = .settle,
        axis: Axis = .vertical
    ) -> some View {
        modifier(DSScrollRevealModifier(style: style, axis: axis))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSScrollRevealPreviewHost: View {
    @State private var theme = DSTheme()

    private let rows = Array(1...12)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                Text("dsScrollReveal(.rise, axis: .horizontal)")
                    .ds(.overline, color: DSColors.textSecondary)
                DSHorizontalScroll {
                    ForEach(rows.prefix(6), id: \.self) { index in
                        DSCard {
                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                Text("Card \(index)").ds(.title3)
                                Text("Slides in as it scrolls")
                                    .ds(.callout, color: DSColors.textSecondary)
                            }
                            .frame(width: 160, alignment: .leading)
                        }
                        .dsScrollReveal(.rise, axis: .horizontal)
                    }
                }

                Text("dsScrollReveal(.settle) — scroll the whole page")
                    .ds(.overline, color: DSColors.textSecondary)
                LazyVStack(spacing: DSSpacing.md) {
                    ForEach(rows, id: \.self) { index in
                        DSCard {
                            HStack(spacing: DSSpacing.md) {
                                DSAvatar(name: "Row \(index)", size: 40)
                                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                    Text("Settling row \(index)").ds(.title3)
                                    Text("Dims, shrinks and rises to centre")
                                        .ds(.callout, color: DSColors.textSecondary)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .dsScrollReveal()
                    }
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
