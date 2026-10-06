import SwiftUI

// MARK: - Design System Scroll Reveal
// A scroll-position-driven reveal: content de-emphasises as it nears a scroll
// view's edges and snaps to full presence when it reaches the middle. Unlike
// `.dsPopIn` / `.dsStaggerIn` — which fire once on `onAppear` and then never
// react again — this effect is *linked to the scroll offset*, so it plays
// forwards as an item scrolls in and backwards as it scrolls out, every time.
//
// It is pure SwiftUI built on `scrollTransition` (iOS 17 / macOS 14): the
// closure receives a `ScrollTransitionPhase` and returns visual effects only
// (opacity, scale, blur, offset), so it never changes layout and never costs a
// re-measure. The drift follows the scroll axis, giving a light parallax —
// items below lag down into place, items above accelerate away.
//
// Six Velvet motion rules still hold: eased, interactive interpolation (the
// scroll drives it, no spring is "touched"); colour untouched; Reduce Motion is
// a real state (the modifier returns the content unchanged so items are simply
// present); glass untouched; no haptics (this is ambient, not an interaction);
// pure SwiftUI so both platforms build.
//
// Must be applied to the *elements inside* a scrolling container (rows in a
// `LazyVStack`, tiles in an `HStack`). Applied anywhere else it stays at rest
// and does nothing — safe, but pointless.

// MARK: - Intensity

/// How far an off-centre element recedes before it reaches full presence. The
/// shaping constants live here, next to the effect, the same way
/// `DSBreatheIntensity` carries its own scale and dip — these are motion-shaping
/// values, not spacing, so they are not spacing tokens. The one spatial value,
/// `drift`, *is* a `DSSpacing` token.
public enum DSScrollRevealIntensity: Sendable {
    /// Barely there — lists where the content must stay readable while scrolling.
    case subtle
    /// The default — feature rows, cards, media tiles.
    case medium
    /// A pronounced settle — hero carousels, onboarding, a short showcase scroll.
    case strong

    /// Opacity at the extreme of the transition (fully faded-in is always 1).
    var restingOpacity: Double {
        switch self {
        case .subtle: return 0.75
        case .medium: return 0.55
        case .strong: return 0.35
        }
    }

    /// Scale at the extreme of the transition.
    var restingScale: CGFloat {
        switch self {
        case .subtle: return 0.96
        case .medium: return 0.90
        case .strong: return 0.82
        }
    }

    /// Softening blur at the extreme, in points. Small — enough to push the item
    /// back, not enough to smear text.
    var blur: CGFloat {
        switch self {
        case .subtle: return 1
        case .medium: return 2
        case .strong: return 4
        }
    }

    /// Peak parallax drift along the scroll axis. A spacing token, so the drift
    /// stays on the same 4pt grid as every other distance in the system.
    var drift: CGFloat {
        switch self {
        case .subtle: return DSSpacing.xs
        case .medium: return DSSpacing.md
        case .strong: return DSSpacing.lg
        }
    }
}

// MARK: - Modifier

public struct DSScrollRevealModifier: ViewModifier {
    let intensity: DSScrollRevealIntensity
    let axis: Axis

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        if reduceMotion {
            // Motion off: the reveal is pure decoration, and a half-faded,
            // shrunk row is worse than a plain one. Present everything at rest.
            content
        } else {
            content.scrollTransition(.interactive, axis: axis) { view, phase in
                view
                    .opacity(phase.isIdentity ? 1 : intensity.restingOpacity)
                    .scaleEffect(phase.isIdentity ? 1 : intensity.restingScale)
                    .blur(radius: phase.isIdentity ? 0 : intensity.blur)
                    .offset(
                        x: axis == .horizontal ? phase.value * intensity.drift : 0,
                        y: axis == .vertical ? phase.value * intensity.drift : 0
                    )
            }
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Reveal this element as it scrolls through its container: it fades, scales,
    /// blurs and drifts toward full presence as it nears the centre, and reverses
    /// as it leaves. Apply it to the items *inside* a `ScrollView` (rows, cards,
    /// tiles), matching `axis` to the scroll direction.
    ///
    ///     ScrollView {
    ///         LazyVStack(spacing: DSSpacing.md) {
    ///             ForEach(items) { item in
    ///                 DSCard { … }.dsScrollReveal()
    ///             }
    ///         }
    ///     }
    ///
    /// Settles to full presence under Reduce Motion instead of animating.
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

    private let rows = Array(1...12)
    private let tiles = Array(1...8)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                Text("Horizontal — strong").ds(.overline, color: DSColors.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DSSpacing.md) {
                        ForEach(tiles, id: \.self) { index in
                            RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous)
                                .fill(theme.gradient.horizontalGradient)
                                .frame(width: DSSpacing.massive * 2, height: DSSpacing.massive)
                                .overlay(
                                    Text("\(index)").ds(.title2, color: theme.gradient.onAccent)
                                )
                                .dsScrollReveal(.strong, axis: .horizontal)
                        }
                    }
                    .padding(.horizontal, DSSpacing.screenHorizontal)
                }
                .padding(.horizontal, -DSSpacing.screenHorizontal)

                Text("Vertical — medium").ds(.overline, color: DSColors.textSecondary)
                LazyVStack(spacing: DSSpacing.md) {
                    ForEach(rows, id: \.self) { index in
                        DSCard {
                            HStack(spacing: DSSpacing.md) {
                                DSAvatar(name: "Row \(index)", size: DSSpacing.xxl)
                                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                    Text("Reveal row \(index)").ds(.title3)
                                    Text("Fades, scales and drifts into place")
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
