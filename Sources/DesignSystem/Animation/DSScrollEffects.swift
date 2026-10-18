import SwiftUI

// MARK: - Design System Scroll Effects
// Scroll-coupled motion: the one verb in the Velvet motion vocabulary that is
// driven by scroll position rather than by `onAppear`. It sits in the same
// layer as `DSMotion` (above `DSAnimation`'s curves, below the components) and
// follows the same six motion rules (docs/proposals/0002).
//
// `dsStaggerIn` / `dsPopIn` fire once when a view mounts and never look back.
// `.dsScrollReveal()` is different in kind: it ties a view's prominence to where
// it sits in the scroll viewport, so a card swells to full presence as it
// reaches the centre and recedes as it leaves — and does it again, in reverse,
// when the user scrolls back. That bidirectional, reversible coupling is what
// `onAppear` entrances cannot express, and it is exactly what iOS 17's
// `scrollTransition` was built for.
//
// Works on any axis: drop it on the rows of a vertical `ScrollView` for a gentle
// settle, or on the cards of a horizontal, `.viewAligned` carousel for the
// centre-emphasis feel. The axis is inferred from the enclosing scroll view.
//
// Technique inspired by the iOS 17 `scrollTransition` carousel pattern
// (AppCoda, Hacking with Swift, Create with Swift). Rewritten on Velvet tokens;
// no upstream code is reproduced.

// MARK: - Intensity

/// How far an off-centre view recedes. Each case is the resting state at the
/// edge of the viewport; `.interactive` interpolates from here back to full
/// presence (scale 1, opacity 1) as the view travels toward the centre.
public enum DSScrollRevealIntensity: Sendable {
    /// Scale 0.96 · opacity 0.65 — a whisper of depth for text rows and list cells.
    case subtle
    /// Scale 0.90 · opacity 0.40 — the default: cards in a feed settling into place.
    case medium
    /// Scale 0.80 · opacity 0.15 — carousel cards; the off-centre ones clearly stand back.
    case strong

    /// Scale applied at the furthest-from-centre phase.
    var minScale: CGFloat {
        switch self {
        case .subtle: return 0.96
        case .medium: return 0.90
        case .strong: return 0.80
        }
    }

    /// Opacity applied at the furthest-from-centre phase.
    var minOpacity: Double {
        switch self {
        case .subtle: return 0.65
        case .medium: return 0.40
        case .strong: return 0.15
        }
    }
}

// MARK: - Modifier

/// Emphasises a view as it reaches the centre of its scroll viewport and lets it
/// recede toward the edges. Scale and opacity are the only channels — both are
/// render-only transforms, so nothing reflows and neighbours never shift.
public struct DSScrollRevealModifier: ViewModifier {
    let intensity: DSScrollRevealIntensity

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content.scrollTransition(.interactive) { view, phase in
            // Reduce Motion settles at the resting state — full presence — rather
            // than dimming and shrinking everything off-centre, which would lower
            // contrast for exactly the people the setting is meant to help.
            // (Mirrors `DSMotion.loop(_:unless:)` returning `nil`: the effect is
            // not skipped, it rests.)
            let recede = !reduceMotion && !phase.isIdentity
            return view
                .opacity(recede ? intensity.minOpacity : 1)
                .scaleEffect(recede ? intensity.minScale : 1)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Couple this view's prominence to its position in the enclosing
    /// `ScrollView`: it swells to full presence at the centre and recedes toward
    /// the edges, reversing as the user scrolls back. Put it on each repeated
    /// item (feed rows, carousel cards). Settles at full presence under Reduce
    /// Motion. Ambient, like the rest of `DSMotion` — no haptics.
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
                DSPreviewThemeDots(theme: theme)

                Text("Horizontal — carousel").ds(.overline, color: DSColors.textSecondary)
                ScrollView(.horizontal) {
                    HStack(spacing: DSSpacing.md) {
                        ForEach(0..<5, id: \.self) { index in
                            DSCard {
                                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                    Text("Card \(index + 1)").ds(.title3)
                                    Text("Centre me").ds(.callout, color: DSColors.textSecondary)
                                }
                                .frame(width: 180, alignment: .leading)
                            }
                            .dsScrollReveal(.strong)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, DSSpacing.screenHorizontal)
                }
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
