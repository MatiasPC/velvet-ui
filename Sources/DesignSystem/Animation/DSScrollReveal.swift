import SwiftUI

// MARK: - Design System Scroll Reveal
// Scroll-position-driven reveal, built on the iOS 17 `scrollTransition` API.
// This is the layer that `dsStaggerIn`/`dsPopIn` could not reach: those fire
// once on `onAppear`, so a row already on screen at launch never animates and
// a row scrolled back into view never animates again. `dsScrollReveal` instead
// ties the effect to the item's live position in the scroll viewport — rows
// settle as they reach the centre and recede toward the edges, continuously and
// interruptibly, however the user scrolls.
//
// Follows the six Velvet motion rules (docs/proposals/0002): eased, position-
// driven ambience rather than a touch spring; no color (opacity/scale/offset/
// blur only, so light and dark are automatic); Reduce Motion as a real state —
// the transform and blur drop but the cross-fade stays, because a cross-fade is
// not motion (it is what the system itself substitutes for slides). Pure
// SwiftUI, so both platforms build.

// MARK: - Magnitudes

/// Tuned magnitudes for `dsScrollReveal`, kept together the way `DSMotion` keeps
/// its loop and envelope constants. Spatial values come from `DSSpacing`; the
/// unitless scale/opacity factors are named here so no raw number lives in a
/// `body`.
public enum DSScrollReveal {
    /// `.soft` dims to this at the edge instead of vanishing, so content never
    /// becomes unreadable the instant it is still partly on screen.
    public static let softOpacity: Double = 0.4
    /// `.soft` edge scale — a barely-there shrink that reads as "settling".
    public static let softScale: CGFloat = 0.94
    /// `.scale` edge scale — a pronounced pop as cards reach the centre.
    public static let popScale: CGFloat = 0.80
    /// `.blur` keeps content visible but out of focus at the edge.
    public static let blurOpacity: Double = 0.6
    /// `.blur` edge blur radius (`DSSpacing.xs` = 8pt).
    public static let blurRadius: CGFloat = DSSpacing.xs
    /// `.rise` edge travel (`DSSpacing.lg` = 20pt), signed by scroll direction so
    /// an item entering from the bottom rises up and one leaving by the top drifts up.
    public static let riseDistance: CGFloat = DSSpacing.lg
}

// MARK: - Style

/// How a view reveals as it crosses the scroll viewport. Every style resolves to
/// identity (fully shown) at the centre and to its "edge" look at the top and
/// bottom; `scrollTransition(.interactive)` interpolates between the two as the
/// item scrolls.
public enum DSScrollRevealStyle: String, CaseIterable, Sendable {
    /// The signature: a gentle fade-and-shrink that never fully hides a row. The default.
    case soft = "Soft"
    /// A pure cross-fade, nothing else. Identical with Reduce Motion on.
    case fade = "Fade"
    /// Cards pop up to full size from `popScale` as they reach the centre.
    case scale = "Scale"
    /// Rows translate into place, signed by scroll direction.
    case rise = "Rise"
    /// Content stays placed but softens out of focus toward the edges — a depth cue.
    case blur = "Blur"

    /// Resolved visual parameters, applied uniformly so the `scrollTransition`
    /// closure always returns one concrete `VisualEffect` type.
    struct Params {
        var opacity: Double
        var scale: CGFloat
        var offsetY: CGFloat
        var blur: CGFloat
    }

    /// Opacity at the viewport edge (identity is always 1).
    private var edgeOpacity: Double {
        switch self {
        case .soft: return DSScrollReveal.softOpacity
        case .blur: return DSScrollReveal.blurOpacity
        case .fade, .scale, .rise: return 0
        }
    }

    /// Scale at the viewport edge (identity is always 1).
    private var edgeScale: CGFloat {
        switch self {
        case .soft:  return DSScrollReveal.softScale
        case .scale: return DSScrollReveal.popScale
        case .fade, .rise, .blur: return 1
        }
    }

    /// - Parameter value: the phase value from `ScrollTransitionPhase` — `0` at
    ///   the centre (identity), `-1` at the top edge, `+1` at the bottom edge.
    func params(value: Double, reduceMotion: Bool) -> Params {
        guard value != 0 else { return Params(opacity: 1, scale: 1, offsetY: 0, blur: 0) }

        // Reduce Motion keeps only the cross-fade: nothing scales, travels or
        // softens, matching the DSMotion rule that an effect settles at a
        // resting state rather than being skipped mid-transition.
        if reduceMotion {
            return Params(opacity: edgeOpacity, scale: 1, offsetY: 0, blur: 0)
        }

        let offsetY: CGFloat = self == .rise ? CGFloat(value) * DSScrollReveal.riseDistance : 0
        let blur: CGFloat = self == .blur ? DSScrollReveal.blurRadius : 0
        return Params(opacity: edgeOpacity, scale: edgeScale, offsetY: offsetY, blur: blur)
    }
}

// MARK: - Modifier

public struct DSScrollRevealModifier: ViewModifier {
    let style: DSScrollRevealStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content.scrollTransition(.interactive) { effect, phase in
            let p = style.params(value: phase.value, reduceMotion: reduceMotion)
            return effect
                .opacity(p.opacity)
                .scaleEffect(p.scale)
                .offset(x: 0, y: p.offsetY)
                .blur(radius: p.blur)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Reveal this view as it scrolls through the viewport: fully shown at the
    /// centre, receding toward its `style` look at the top and bottom edges.
    ///
    /// Apply it to the repeating items of a `ScrollView` or `List` (it only has
    /// an effect inside a scroll container). Unlike `dsStaggerIn`/`dsPopIn`, which
    /// fire once on appear, this reacts to live scroll position, so items re-reveal
    /// every time they return to view.
    ///
    ///     ScrollView {
    ///         LazyVStack(spacing: DSSpacing.md) {
    ///             ForEach(items) { item in
    ///                 ItemCard(item).dsScrollReveal()
    ///             }
    ///         }
    ///     }
    func dsScrollReveal(_ style: DSScrollRevealStyle = .soft) -> some View {
        modifier(DSScrollRevealModifier(style: style))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSScrollRevealPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var style: DSScrollRevealStyle = .soft

    var body: some View {
        VStack(spacing: DSSpacing.md) {
            DSPreviewThemeDots(theme: theme)

            DSSegmentedControl(
                selection: $style,
                segments: DSScrollRevealStyle.allCases.map { DSSegment($0.rawValue, value: $0) }
            )

            Text("Scroll the cards — each reveals with .\(style.rawValue.lowercased())")
                .ds(.footnote, color: DSColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                VStack(spacing: DSSpacing.md) {
                    ForEach(0..<12, id: \.self) { index in
                        card(index).dsScrollReveal(style)
                    }
                }
                .padding(.vertical, DSSpacing.sm)
            }
            // Fresh identity on style change so the list resets to the top and the
            // reveal can be felt from the first card again.
            .id(style)
        }
        .dsScreenPadding()
        .padding(.top, DSSpacing.md)
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func card(_ index: Int) -> some View {
        HStack(spacing: DSSpacing.md) {
            RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                .fill(theme.gradient.horizontalGradient)
                .frame(width: DSSpacing.huge, height: DSSpacing.huge)
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text("Row \(index + 1)").ds(.title3)
                Text("Reveals on scroll").ds(.callout, color: DSColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(DSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsSurface(.glass, radius: DSRadius.card)
    }
}

#Preview("ScrollReveal — Light") {
    DSScrollRevealPreviewHost().preferredColorScheme(.light)
}

#Preview("ScrollReveal — Dark") {
    DSScrollRevealPreviewHost().preferredColorScheme(.dark)
}
#endif
