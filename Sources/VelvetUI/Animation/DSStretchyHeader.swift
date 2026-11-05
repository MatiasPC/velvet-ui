import SwiftUI

// MARK: - Design System Stretchy Header
// The hero at the top of a detail screen (a profile, a trip, an album, a recipe)
// that answers the pull instead of leaving a gap. Pull down past the top and the
// header grows to fill the space, pinned to the top edge. Scroll up and it
// drifts away at half speed inside its own frame (parallax), so the content
// below seems to slide over it.
//
// Scroll-coupled, like `dsScrollReveal`, and in the same layer: above
// `DSAnimation`'s curves, below the components. Both effects are render-only
// transforms computed in `visualEffect` from the header's frame in the scroll
// view, so there is no state, no `GeometryReader`, nothing reflows and the
// content below never jumps.
//
// Technique inspired by "Stretchy header in SwiftUI with visualEffect()"
// (Nil Coalescing) and "Building a stretchy header view with SwiftUI on iOS 18"
// (Donny Wals). Rewritten on Velvet tokens; no upstream code is reproduced.

// MARK: - Maths

/// The pure maths behind `dsStretchyHeader`, kept out of the modifier so it can be
/// tested directly. `minY` is the header's top edge in the scroll view's
/// coordinate space: 0 at rest, positive while the user pulls past the top,
/// negative once the header scrolls up.
enum DSStretchyHeaderMath {
    /// Uniform scale, anchored at the bottom, that grows the header by exactly the
    /// overscroll so its top edge stays pinned to the top of the scroll view.
    /// 1 at rest and while scrolling up.
    static func stretchScale(minY: CGFloat, height: CGFloat) -> CGFloat {
        guard height > 0, minY > 0 else { return 1 }
        return (height + minY) / height
    }

    /// Downward offset that makes the header move at `1 - factor` of the scroll
    /// speed while it scrolls up. 0 at rest, while pulling, with parallax off and
    /// under Reduce Motion. The travel is capped at the header's own height (it is
    /// fully clipped by then) and `factor` is clamped to 0...1.
    static func parallaxOffset(
        minY: CGFloat,
        height: CGFloat,
        factor: CGFloat,
        reduceMotion: Bool
    ) -> CGFloat {
        guard !reduceMotion, minY < 0, height > 0 else { return 0 }
        let clampedFactor = min(max(factor, 0), 1)
        return min(-minY, height) * clampedFactor
    }
}

// MARK: - Modifier

/// Stretches the header on overscroll and, optionally, lets it trail the scroll
/// with parallax. The parallax offset is applied inside a clip so the header
/// never slides out of its own frame and under the content that follows; the
/// stretch is applied outside the clip so the pull can grow it past that frame.
private struct DSStretchyHeaderModifier: ViewModifier {
    let parallax: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        // Plain values, so the `@Sendable` visual-effect closures capture no view state.
        let factor = parallax ? DSMotion.stretchyHeaderParallax : 0
        let restsUnderReduceMotion = reduceMotion

        return content
            .visualEffect { effect, proxy in
                effect.offset(
                    y: DSStretchyHeaderMath.parallaxOffset(
                        minY: proxy.frame(in: .scrollView).minY,
                        height: proxy.size.height,
                        factor: factor,
                        reduceMotion: restsUnderReduceMotion
                    )
                )
            }
            .clipped()
            .visualEffect { effect, proxy in
                // Stretch is not decorative motion: it tracks the finger 1:1 and
                // replaces the empty rubber-band gap, so it stays on under Reduce Motion.
                effect.scaleEffect(
                    DSStretchyHeaderMath.stretchScale(
                        minY: proxy.frame(in: .scrollView).minY,
                        height: proxy.size.height
                    ),
                    anchor: .bottom
                )
            }
    }
}

// MARK: - View Extension

public extension View {
    /// Make this view a stretchy hero header. Pull the scroll view down past the
    /// top and the header grows to fill the gap, pinned to the top edge; scroll up
    /// and, with `parallax`, it trails at half speed inside its own frame.
    ///
    /// Put it on the **first** view inside a vertical `ScrollView`, give that view a
    /// fixed height, and let the scroll view run under the status bar with
    /// `.ignoresSafeArea(edges: .top)`. The effect is measured from the top of the
    /// scroll view, so a header further down the page would read as "pulled".
    ///
    ///     ScrollView {
    ///         VStack(spacing: 0) {
    ///             Image("lisbon")
    ///                 .resizable()
    ///                 .scaledToFill()
    ///                 .frame(height: 320)
    ///                 .dsStretchyHeader()
    ///             details
    ///         }
    ///     }
    ///     .ignoresSafeArea(edges: .top)
    ///
    /// The header is clipped to its frame (so parallax never bleeds under the
    /// content below); attach anything that should overhang it, such as an
    /// avatar, with an `.overlay` after this modifier. Under Reduce Motion the
    /// parallax rests and only the stretch, which follows the finger, remains.
    /// Scroll-coupled and ambient, so it fires no haptic.
    func dsStretchyHeader(parallax: Bool = true) -> some View {
        modifier(DSStretchyHeaderModifier(parallax: parallax))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSStretchyHeaderPreviewHost: View {
    @State private var theme = DSTheme()

    private let rows = [
        ("Check-in", "Friday, from 15:00"),
        ("Check-out", "Monday, until 11:00"),
        ("Guests", "2 adults"),
        ("Room", "River view, king bed"),
        ("Breakfast", "Included, 7:00 to 10:30"),
        ("Cancellation", "Free until Wednesday")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Rectangle().fill(theme.style.accent)
                    Image(systemName: "sun.horizon.fill")
                        .dsFont(.displayLarge)
                        .foregroundStyle(theme.style.onAccent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text("Weekend in Lisbon")
                        .ds(.title1, color: theme.style.onAccent)
                        .padding(DSSpacing.lg)
                }
                .frame(height: DSSpacing.massive * 4)
                .dsStretchyHeader()

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Pull down to stretch, scroll up for parallax")
                        .ds(.footnote, color: DSColors.textSecondary)
                    ForEach(rows, id: \.0) { row in
                        DSCard {
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text(row.0).ds(.title3)
                                Text(row.1).ds(.callout, color: DSColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .dsScreenPadding()
                .padding(.vertical, DSSpacing.xl)
            }
        }
        .ignoresSafeArea(edges: .top)
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Stretchy Header — Light") {
    DSStretchyHeaderPreviewHost().preferredColorScheme(.light)
}

#Preview("Stretchy Header — Dark") {
    DSStretchyHeaderPreviewHost().preferredColorScheme(.dark)
}
#endif
