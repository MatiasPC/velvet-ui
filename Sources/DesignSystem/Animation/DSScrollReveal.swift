import SwiftUI

// MARK: - Design System Scroll Reveal
// A scroll-linked reveal: items fade, scale and rise into place as they enter
// the viewport, and settle back the same way as they leave. The transform is
// driven continuously by the scroll position — not a one-shot on-appear — so it
// tracks the finger, plays in reverse on scroll-up, and never fires twice for
// the same row.
//
// This is the companion to `dsStaggerIn` (Animation/DSAnimation.swift): stagger
// is an entrance that runs once when a view first mounts; reveal is an ambient,
// reversible response to scrolling. Reach for stagger on a screen that appears
// all at once, reveal on a long scroll of content.
//
// Built on `scrollTransition(.interactive,…)` (iOS 17+), so the effect is a
// no-op outside a `ScrollView` and costs nothing to leave applied. Follows the
// Velvet motion rules: eased, position-driven motion (no spring — nothing was
// touched), Reduce Motion as a real resting state rather than a bail-out, and
// pure SwiftUI so both platforms build. Only GPU transforms (opacity, scale,
// offset) are used, so it stays cheap across a `LazyVStack` of many rows.

/// How far a revealing element travels and dims at the edges of the viewport.
public enum DSScrollRevealIntensity: Sendable {
    /// Barely-there: a short rise and a light dim. Dense lists, metadata rows.
    case subtle
    /// The default: a comfortable rise and dim. Cards, feed items.
    case medium
    /// Pronounced: a long rise, a deep dim and a visible shrink. Hero rows,
    /// a gallery of a few large cards.
    case strong

    /// Travel distance at the viewport edge, in points. A `DSSpacing` step so
    /// the motion sits on the same rhythm as layout.
    var rise: CGFloat {
        switch self {
        case .subtle: return DSSpacing.xs   // 8
        case .medium: return DSSpacing.md   // 16
        case .strong: return DSSpacing.xl   // 24
        }
    }

    /// How much the element shrinks at the edge (0 = none). Dropped under
    /// Reduce Motion — scale is motion.
    var scaleDip: CGFloat {
        switch self {
        case .subtle: return 0.04
        case .medium: return 0.08
        case .strong: return 0.14
        }
    }

    /// How much opacity the element loses at the edge. Kept under Reduce Motion
    /// — a cross-fade reads as a state change, not travel, and Apple fades
    /// rather than moves in that mode.
    var dim: Double {
        switch self {
        case .subtle: return 0.35
        case .medium: return 0.55
        case .strong: return 0.75
        }
    }
}

// MARK: - Modifier

public struct DSScrollRevealModifier: ViewModifier {
    let intensity: DSScrollRevealIntensity
    let axis: Axis

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `scrollTransition` hands back a `phase` whose `.value` runs −1 → 0 → +1
    /// across the viewport: −1 at the leading edge (top / leading), 0 at rest in
    /// the centre, +1 at the trailing edge (bottom / trailing). `.interactive`
    /// makes that value track the scroll offset continuously instead of snapping
    /// at a threshold, so every transform below interpolates with the scroll.
    ///
    /// `abs(value)` folds both edges together for the symmetric dim and shrink;
    /// the signed `value` drives the offset so an element rises *up* into place
    /// from the bottom and lifts *away* toward the top — motion in the scroll's
    /// own direction, not against it.
    public func body(content: Content) -> some View {
        content.scrollTransition(.interactive, axis: axis) { view, phase in
            // `phase.value` is a `Double`; the token-derived lengths are `CGFloat`.
            // Convert explicitly — SwiftUI will not bridge the two for us.
            let value = phase.value
            let distance = abs(value)
            return view
                .opacity(1 - distance * intensity.dim)
                .scaleEffect(reduceMotion ? 1 : 1 - CGFloat(distance) * intensity.scaleDip)
                .offset(
                    x: !reduceMotion && axis == .horizontal ? CGFloat(value) * intensity.rise : 0,
                    y: !reduceMotion && axis == .vertical ? CGFloat(value) * intensity.rise : 0
                )
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Reveal this element as it scrolls into view and settle it as it leaves:
    /// a fade, a soft shrink and a rise driven continuously by scroll position.
    /// Apply it to each row or card inside a `ScrollView`; it does nothing
    /// outside one.
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
    /// - Parameters:
    ///   - intensity: How far it travels and dims. Defaults to `.medium`.
    ///   - axis: The scroll axis to react to. Defaults to `.vertical`; pass
    ///     `.horizontal` inside a horizontal `ScrollView` or carousel.
    func dsScrollReveal(
        _ intensity: DSScrollRevealIntensity = .medium,
        axis: Axis = .vertical
    ) -> some View {
        modifier(DSScrollRevealModifier(intensity: intensity, axis: axis))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSScrollRevealPreviewHost: View {
    @State private var theme = DSTheme()

    private let rows = Array(0..<8)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                Text("Scroll — each card reveals as it enters")
                    .ds(.overline, color: DSColors.textSecondary)

                ForEach(rows, id: \.self) { index in
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text("Card \(index + 1)").ds(.title3)
                            Text("Fades, shrinks and rises into place, then reverses on the way out.")
                                .ds(.callout, color: DSColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .dsScrollReveal(index.isMultiple(of: 2) ? .medium : .strong)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xxl)
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
