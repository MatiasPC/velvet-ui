import SwiftUI

// MARK: - Design System Scroll Effects
// Scroll-coupled motion: the one verb in the Velvet motion vocabulary that is
// driven by scroll position rather than by `onAppear`. It sits in the same
// layer as `DSMotion` (above `DSAnimation`'s curves, below the components) and
// follows the same six motion rules (docs/proposals/0002).
//
// `dsStaggerIn` / `dsPopIn` fire once when a view mounts and never look back.
// `.dsScrollReveal()` is different in kind: it ties a view's prominence to where
// it sits in the scroll view's visible area. A view is at full presence while it
// is inside, recedes as it crosses the leading or trailing edge, and does it
// again, in reverse, when the user scrolls back. That bidirectional, reversible
// coupling is what `onAppear` entrances cannot express, and it is exactly what
// `scrollTransition` was built for.
//
// Works on any axis: drop it on the rows of a vertical `ScrollView` for a gentle
// settle at the top and bottom, or on the cards of a horizontal, `.viewAligned`
// carousel with peeking neighbours for centre emphasis. The axis is inferred from
// the enclosing scroll view.
//
// Technique inspired by the `scrollTransition` carousel pattern (AppCoda, Hacking
// with Swift, Create with Swift). Rewritten on Velvet tokens; no upstream code is
// reproduced.

// MARK: - Intensity

/// How far a view recedes once it is fully past the edge of the scroll view. The
/// values are tokens on `DSMotion` (`scrollReveal…Scale` / `…Opacity`);
/// `.interactive` interpolates from here back to full presence (scale 1,
/// opacity 1) as the view travels into the visible area.
public enum DSScrollRevealIntensity: Sendable {
    /// A whisper of depth for text rows and list cells.
    case subtle
    /// The default: cards in a feed settling into place.
    case medium
    /// Carousel cards; the ones at the edge clearly stand back.
    case strong

    /// Scale applied at the furthest-from-visible phase.
    var minScale: CGFloat {
        switch self {
        case .subtle: return DSMotion.scrollRevealSubtleScale
        case .medium: return DSMotion.scrollRevealMediumScale
        case .strong: return DSMotion.scrollRevealStrongScale
        }
    }

    /// Opacity applied at the furthest-from-visible phase.
    var minOpacity: Double {
        switch self {
        case .subtle: return DSMotion.scrollRevealSubtleOpacity
        case .medium: return DSMotion.scrollRevealMediumOpacity
        case .strong: return DSMotion.scrollRevealStrongOpacity
        }
    }
}

// MARK: - Maths

/// The pure maths behind `dsScrollReveal`, kept out of the modifier so it can be tested directly.
enum DSScrollRevealMath {
    /// Scale and opacity for a scroll-transition phase value: 0 while the view is in
    /// the visible area, ±1 once it is fully past an edge (anything beyond is
    /// clamped). Reduce Motion pins the result at full presence: scale 1, opacity 1.
    static func effect(
        for intensity: DSScrollRevealIntensity,
        phaseValue: Double,
        reduceMotion: Bool
    ) -> (scale: CGFloat, opacity: Double) {
        let t = reduceMotion ? 0 : min(max(abs(phaseValue), 0), 1)
        return (
            scale: 1 - (1 - intensity.minScale) * CGFloat(t),
            opacity: 1 - (1 - intensity.minOpacity) * t
        )
    }
}

// MARK: - Modifier

/// Emphasises a view while it is inside its scroll view and lets it recede as it
/// crosses an edge. Scale and opacity are the only channels — both are
/// render-only transforms, so nothing reflows and neighbours never shift.
private struct DSScrollRevealModifier: ViewModifier {
    let intensity: DSScrollRevealIntensity

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.scrollTransition(.interactive) { view, phase in
            // Reduce Motion settles at the resting state — full presence — rather
            // than dimming and shrinking everything near the edges, which would lower
            // contrast for exactly the people the setting is meant to help.
            // (Mirrors `DSMotion.loop(_:unless:)` returning `nil`: the effect is
            // not skipped, it rests.)
            let reveal = DSScrollRevealMath.effect(for: intensity, phaseValue: phase.value, reduceMotion: reduceMotion)
            return view
                .opacity(reveal.opacity)
                .scaleEffect(reveal.scale)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Couple this view's prominence to its position in the enclosing
    /// `ScrollView`: full presence while it is inside the visible area, receding as
    /// it crosses an edge, and reversing as the user scrolls back. Put it on each
    /// repeated item (feed rows, carousel cards). Settles at full presence under
    /// Reduce Motion. Ambient, like the rest of `DSMotion` — no haptics.
    func dsScrollReveal(_ intensity: DSScrollRevealIntensity = .medium) -> some View {
        modifier(DSScrollRevealModifier(intensity: intensity))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSScrollRevealPreviewHost: View {
    @State private var theme = DSTheme()

    private let feed = [
        ("Weekly summary", "4 sessions · 2 h 35 min"),
        ("New follower", "aurora_dev started following you"),
        ("Backup complete", "1 248 photos · just now"),
        ("Battery full", "Unplug to preserve battery health"),
        ("Trip reminder", "Flight to Lisbon in 3 hours"),
        ("Goal reached", "10 000 steps — nice work")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Horizontal — carousel").ds(.overline, color: DSColors.textSecondary)
                ScrollView(.horizontal) {
                    HStack(spacing: DSSpacing.md) {
                        ForEach(0..<5, id: \.self) { index in
                            DSCard {
                                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                    Text("Card \(index + 1)").ds(.title3)
                                    Text("Peeking neighbours recede").ds(.callout, color: DSColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .containerRelativeFrame(.horizontal)
                            .dsScrollReveal(.strong)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, DSSpacing.xxxl, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)

                Text("Vertical — feed").ds(.overline, color: DSColors.textSecondary)
                ForEach(Array(feed.enumerated()), id: \.offset) { _, item in
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text(item.0).ds(.title3)
                            Text(item.1).ds(.callout, color: DSColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .dsScrollReveal()
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
