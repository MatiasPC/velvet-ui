import SwiftUI

// MARK: - Design System Scroll Reveal
// A scroll-position-driven reveal: rows and cards fade, rise and settle as they
// enter the viewport, and gently give it back as they leave. It rides iOS 17's
// `scrollTransition`, so the effect is *linked to the scroll offset* — not a
// one-shot played on appear. That is the distinction from `.dsStaggerIn` and
// `.dsPopIn`, which fire once when a view first mounts: `.dsScrollReveal` keeps
// reacting, so scrolling back up re-reveals, and a half-scrolled row sits at a
// half-resolved state instead of snapping.
//
// It only has an effect on a view inside a `ScrollView` — `scrollTransition`
// is inert elsewhere, so it is harmless to leave on a view that later moves out
// of a scroll context. Pure `VisualEffect` transforms (opacity, scale, offset),
// so there is no extra layout work per frame.
//
// Technique from Apple's WWDC23 "Beyond scroll views" (`scrollTransition` +
// `VisualEffect`); tuned onto Velvet spacing tokens. No upstream code reproduced.

// MARK: - Style

/// How far a view travels on its way in. Opacity always fades fully; the
/// scale and rise below are what separate the three readings.
public enum DSScrollRevealStyle: Sendable {
    /// Fade + rise — rows lift into place. The default; right for list cells.
    case rise
    /// Fade + zoom — settles from slightly small. Right for cards and tiles.
    case zoom
    /// Fade + rise + zoom — the fullest reveal, for a hero card or feature row.
    case lift

    /// Opacity at the viewport edges. Fully transparent, so the reveal reads as
    /// the content arriving rather than merely dimming.
    var edgeOpacity: Double { 0 }

    /// Scale at the viewport edges. `1` disables the zoom for `.rise`.
    var edgeScale: CGFloat {
        switch self {
        case .rise:        return 1
        case .zoom, .lift: return 0.92
        }
    }

    /// Vertical travel at the viewport edges. `0` disables the rise for `.zoom`.
    var edgeRise: CGFloat {
        switch self {
        case .rise, .lift: return DSSpacing.lg
        case .zoom:        return 0
        }
    }
}

// MARK: - Modifier

public struct DSScrollRevealModifier: ViewModifier {
    let style: DSScrollRevealStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Under Reduce Motion nothing travels or scales and the view stays fully
    /// visible — a scroll-linked slide is motion, so it settles at rest rather
    /// than fading in and out as the user scrolls.
    ///
    /// `phase.value` runs −1 at the leading edge → 0 at rest (identity) → +1 at
    /// the trailing edge, so the offset is symmetric: a row lifts the same amount
    /// entering from the bottom as it does leaving past the top.
    public func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.scrollTransition(.interactive) { view, phase in
                view
                    .opacity(phase.isIdentity ? 1 : style.edgeOpacity)
                    .scaleEffect(phase.isIdentity ? 1 : style.edgeScale, anchor: .center)
                    .offset(y: style.edgeRise * CGFloat(phase.value))
            }
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Reveal a view as it scrolls into the viewport and give it back as it
    /// leaves — a fade paired with a rise, a zoom, or both. Apply it to the
    /// items inside a `ScrollView` (rows, cards, tiles); it is inert outside one.
    /// Settles to fully visible under Reduce Motion.
    func dsScrollReveal(_ style: DSScrollRevealStyle = .rise) -> some View {
        modifier(DSScrollRevealModifier(style: style))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSScrollRevealPreviewHost: View {
    @State private var theme = DSTheme()

    private let rows = [
        ("Weekly summary", "4 sessions · 2 h 35 min"),
        ("Personal best", "12.4 km at 5:02 /km"),
        ("Streak", "9 days in a row"),
        ("Recovery", "Resting heart rate 54 bpm"),
        ("Sleep", "7 h 12 min · 82 score"),
        ("Nutrition", "1,980 kcal · on target"),
        ("Mindfulness", "3 sessions · 24 min"),
        ("Steps", "9,214 today")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                DSPreviewThemeDots(theme: theme)

                Text("Scroll to reveal").ds(.overline, color: DSColors.textSecondary)

                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    DSCard(style: index == 0 ? .elevated : .flat) {
                        HStack {
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text(row.0).ds(.title3)
                                Text(row.1).ds(.callout, color: DSColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(DSColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .dsScrollReveal(index == 0 ? .lift : .rise)
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
