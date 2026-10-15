import SwiftUI

// MARK: - Design System Scroll Reveal
// Scroll-linked entrance: content fades, rises, scales and softens as it crosses
// the edges of the viewport, settling to rest while centred. Built on iOS 17's
// `scrollTransition`, so the effect tracks the scroll position continuously
// rather than firing once — the App Store / Apple Music "cards settle into place"
// feel, available to any `ScrollView` content with a single modifier.
//
// This is the scroll-driven sibling of `dsStaggerIn`:
//
//   • `dsStaggerIn(index:)` fires once, on appear, sequenced by index — right for
//     content that is already on screen when a view mounts.
//   • `dsScrollReveal()` is driven by scroll position, re-revealing every time an
//     item passes an edge — right for long lists where on-appear timing is
//     unreliable and items should react as the user scrolls.
//
// Pure SwiftUI, both platforms. Honours Reduce Motion by keeping the crossfade
// (opacity is not motion) while pinning scale, lift and blur at rest, so nothing
// travels.

// MARK: - Intensity

/// How strongly content transforms at the viewport edges. Values are motion
/// shaping constants, tuned by eye like `DSBreatheIntensity` — there is no token
/// for "how far a card lifts as it scrolls in".
public enum DSScrollRevealIntensity: Sendable {
    /// Barely there — dense lists, rows, anything that should stay calm.
    case subtle
    /// The default — cards and media tiles.
    case medium
    /// Pronounced — hero sections, a single feature tile per screen.
    case strong

    /// Opacity at the edge (the view reaches 1 at rest).
    var minOpacity: Double {
        switch self {
        case .subtle: return 0.70
        case .medium: return 0.40
        case .strong: return 0.0
        }
    }

    /// Scale at the edge (the view reaches 1 at rest).
    var minScale: CGFloat {
        switch self {
        case .subtle: return 0.97
        case .medium: return 0.92
        case .strong: return 0.85
        }
    }

    /// How far, in points, the view is displaced along the scroll axis at the edge.
    /// Uses the spacing scale so the travel stays on-grid.
    var lift: CGFloat {
        switch self {
        case .subtle: return DSSpacing.xxs
        case .medium: return DSSpacing.sm
        case .strong: return DSSpacing.lg
        }
    }

    /// Peak blur at the edge. Small on purpose — a hint of focus pulling in, not a smear.
    var blur: CGFloat {
        switch self {
        case .subtle: return 0
        case .medium: return 2
        case .strong: return 4
        }
    }
}

// MARK: - Modifier

public struct DSScrollRevealModifier: ViewModifier {
    let intensity: DSScrollRevealIntensity

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content.scrollTransition { view, phase in
            // `phase.value` is 0 at rest, negative past the leading edge and
            // positive past the trailing edge. Magnitude drives the symmetric
            // fade/scale/blur; the signed value drives the lift so the view
            // always travels *toward* its resting centre.
            let travel = min(abs(phase.value), 1)        // 0 at rest → 1 at the edge
            let t = CGFloat(travel)
            return view
                .opacity(1 - (1 - intensity.minOpacity) * travel)
                .scaleEffect(reduceMotion ? 1 : 1 - (1 - intensity.minScale) * t)
                .offset(y: reduceMotion ? 0 : intensity.lift * CGFloat(phase.value))
                .blur(radius: reduceMotion ? 0 : intensity.blur * t)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Reveal content as it scrolls into view — fade, rise, scale and soften at the
    /// viewport edges, resting while centred. Apply to each item inside a `ScrollView`
    /// (a `LazyVStack`/`LazyHStack` row, a card, a media tile).
    ///
    ///     ScrollView {
    ///         LazyVStack(spacing: DSSpacing.md) {
    ///             ForEach(items) { item in
    ///                 DSCard { … }.dsScrollReveal()
    ///             }
    ///         }
    ///     }
    ///
    /// For content that is on screen at mount and should sequence in once, prefer
    /// `dsStaggerIn(index:)`.
    func dsScrollReveal(_ intensity: DSScrollRevealIntensity = .medium) -> some View {
        modifier(DSScrollRevealModifier(intensity: intensity))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSScrollRevealPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var choice = "Medium"

    private var intensity: DSScrollRevealIntensity {
        switch choice {
        case "Subtle": return .subtle
        case "Strong": return .strong
        default:       return .medium
        }
    }

    private let tiles = [
        ("Mirador del valle", "$120 / noche", "Nuevo"),
        ("Loft en el centro", "$96 / noche", nil),
        ("Cabaña junto al lago", "$145 / noche", "Top"),
        ("Estudio con vistas", "$80 / noche", nil),
        ("Casa de playa", "$210 / noche", "Nuevo"),
        ("Ático minimalista", "$132 / noche", nil)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DSSpacing.md) {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        DSPreviewThemeDots(theme: theme)
                        Text("Scroll to reveal").ds(.title3)
                        DSSegmentedControl(
                            selection: $choice,
                            options: ["Subtle", "Medium", "Strong"]
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(tiles, id: \.0) { tile in
                    DSImageCard(title: tile.0, subtitle: tile.1, badge: tile.2)
                        .dsScrollReveal(intensity)
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
