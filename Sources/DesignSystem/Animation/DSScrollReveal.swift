import SwiftUI

// MARK: - Design System Scroll Reveal
// A scroll-driven entrance for content inside a `ScrollView`: as a view crosses
// into the visible region it rises into place, scales up from slightly small,
// sharpens from a soft defocus and fades in — then does the reverse as it leaves.
// It is the ambient companion to `.dsStaggerIn` (a one-shot entrance on appear):
// this one is *tied to the scroll position*, so the motion tracks the finger and
// reverses when you scroll back.
//
// Built on `scrollTransition` (iOS 17+), so the effect is interpolated
// continuously as the view travels through the viewport — there is no timer and
// no state to manage. The `phase.value` (−1 at the leading edge, 0 at rest, +1 at
// the trailing edge) drives a directional lift, so rows rise up into place from
// below and sink as they exit the top, which reads as content "settling".
//
// Following the Velvet motion rules (docs/proposals/0002): Reduce Motion is a
// real state, not a bail-out — it keeps the fade (opacity is not motion) and
// drops the travel, scale and blur so nothing moves. Applied to a view that has
// no containing scroll view the modifier is inert, so it is always safe to add.

// MARK: - Intensity

/// How pronounced the scroll reveal is at the edges of the viewport.
public enum DSScrollRevealIntensity: Sendable {
    /// A whisper — a short lift and a barely-there scale. Dense lists, long feeds.
    case subtle
    /// The default — a clear rise, scale and soft defocus. Cards, feed rows.
    case medium
    /// A hero reveal — a long lift, deep scale and heavy defocus. Single large items.
    case strong

    /// Opacity at the edge of the viewport (reaches 1 at rest).
    var edgeOpacity: Double {
        switch self {
        case .subtle: return 0.4
        case .medium: return 0.0
        case .strong: return 0.0
        }
    }

    /// Scale at the edge of the viewport (reaches 1 at rest).
    var edgeScale: CGFloat {
        switch self {
        case .subtle: return 0.97
        case .medium: return 0.92
        case .strong: return 0.85
        }
    }

    /// Gaussian blur radius at the edge of the viewport (reaches 0 at rest).
    var edgeBlur: CGFloat {
        switch self {
        case .subtle: return 0
        case .medium: return 2
        case .strong: return 6
        }
    }

    /// Vertical travel at the edge of the viewport (reaches 0 at rest). The sign
    /// comes from `phase.value`, so content rises from below and sinks at the top.
    var lift: CGFloat {
        switch self {
        case .subtle: return 8
        case .medium: return 16
        case .strong: return 28
        }
    }
}

// MARK: - Modifier

public struct DSScrollRevealModifier: ViewModifier {
    let intensity: DSScrollRevealIntensity

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content.scrollTransition(.interactive) { effect, phase in
            // −1 at the leading edge, 0 at rest, +1 at the trailing edge.
            let position = Double(phase.value)
            // 0 at rest, up to 1 at either edge — drives the amount of the effect.
            let distance = min(abs(position), 1)
            // Reduce Motion keeps the fade (opacity is not motion) and pins
            // everything that would travel or distort to its resting value.
            let scale: CGFloat = reduceMotion ? 1 : intensity.edgeScale
            let blur: CGFloat = reduceMotion ? 0 : intensity.edgeBlur
            let lift: CGFloat = reduceMotion ? 0 : intensity.lift

            return effect
                .opacity(1 - (1 - intensity.edgeOpacity) * distance)
                .scaleEffect(1 - (1 - scale) * CGFloat(distance))
                .blur(radius: blur * CGFloat(distance))
                .offset(y: lift * CGFloat(position))
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Reveal this view as it scrolls into the viewport: it rises into place,
    /// scales up, sharpens and fades in, then reverses as it leaves. Tie it to
    /// rows or cards inside a `ScrollView` for a premium "content settles into
    /// place" feel. Inert outside a scroll view; keeps only the fade under
    /// Reduce Motion.
    ///
    ///     ScrollView {
    ///         LazyVStack(spacing: DSSpacing.md) {
    ///             ForEach(items) { item in
    ///                 DSCard { … }
    ///                     .dsScrollReveal()
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameter intensity: How pronounced the reveal is. Defaults to `.medium`.
    func dsScrollReveal(_ intensity: DSScrollRevealIntensity = .medium) -> some View {
        modifier(DSScrollRevealModifier(intensity: intensity))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSScrollRevealPreviewHost: View {
    @State private var theme = DSTheme()
    let intensity: DSScrollRevealIntensity

    private let rows = [
        ("Weekly summary", "4 sessions · 2 h 35 min", "chart.bar.fill"),
        ("New follower", "aurora_dev started following you", "person.fill.badge.plus"),
        ("Backup complete", "1 248 photos · just now", "checkmark.icloud.fill"),
        ("Payment received", "$42.00 from Lagoon Studio", "dollarsign.circle.fill"),
        ("Reminder", "Design review at 3:00 PM", "bell.fill"),
        ("Trip saved", "Cabaña en el bosque · $120/night", "heart.fill"),
        ("Update available", "Velvet UI 0.3 is ready to install", "arrow.down.circle.fill"),
        ("Streak extended", "7 days in a row — keep it up", "flame.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.md) {
                DSPreviewThemeDots(theme: theme)
                    .padding(.bottom, DSSpacing.xs)

                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    DSCard {
                        HStack(spacing: DSSpacing.md) {
                            Image(systemName: row.2)
                                .font(.title3)
                                .foregroundStyle(theme.gradient.accent)
                                .frame(width: DSSpacing.xl)
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text(row.0).ds(.title3)
                                Text(row.1).ds(.callout, color: DSColors.textSecondary)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .dsScrollReveal(intensity)
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
    DSScrollRevealPreviewHost(intensity: .medium).preferredColorScheme(.light)
}

#Preview("Scroll Reveal — Dark") {
    DSScrollRevealPreviewHost(intensity: .strong).preferredColorScheme(.dark)
}
#endif
