import SwiftUI

// MARK: - Design System Scroll Reveal
// A scroll-position-driven reveal: content settles into place as it enters the
// scroll viewport and recedes again as it leaves. It is the companion to the
// one-shot entrances in `DSMotion` — `dsStaggerIn` / `dsPopIn` fire once on
// appear and are done, while this stays tied to the scroll offset, so a row
// re-dims when scrolled back toward the edge and reveals again on the way in.
//
// Built on SwiftUI's own `scrollTransition` (iOS 17+): SwiftUI interpolates the
// visual effects between the resting ("identity") state and the edge state as
// the element crosses the viewport boundary, so there is no geometry reader, no
// offset math and nothing to keep in sync — the scroll view drives it per frame.
//
// Three curated styles, tuned on Velvet tokens so a reveal always reads as the
// same family of motion rather than a per-call-site guess:
//
//   .rise   → fade + travel along the scroll axis — feed rows, lists, settings
//   .scale  → fade + scale down toward the edge   — cards, tiles, grid items
//   .soften → stays faintly visible but blurs out — hero media, large imagery
//
// Like every ambient effect in the motion layer, it has no haptics (there is no
// discrete interaction, only scrolling) and it honours Reduce Motion: the
// transition is dropped entirely so content simply sits at its resting state.

// MARK: - Style

public enum DSScrollRevealStyle: Sendable {
    /// Fade in while travelling into place along the scroll axis. The default —
    /// the quiet reveal for feed rows, list cells and stacked content.
    case rise
    /// Fade in while scaling up from slightly smaller. Reads as depth; good for
    /// cards, tiles and grid items that should feel like they settle forward.
    case scale
    /// Stay faintly visible but blur toward the edge, like a rack-focus pull.
    /// For hero media and large imagery where a hard fade would feel abrupt.
    case soften
}

// MARK: - Metrics

/// Motion-shaping values. The travel distance is a real spacing token; the
/// others are animation shaping (a scale ratio, a blur radius, a residual
/// opacity) with no layout meaning, so — as with `DSMotion.driftDegrees` and the
/// `DSParticleField` metrics — they live here, named and tuned by eye, rather
/// than as bare literals at the call site.
private enum Metrics {
    /// How far a `.rise` element travels into place, along the scroll axis.
    /// `DSSpacing.lg` (20) — enough to read as motion, small enough not to shove
    /// the layout around as rows settle.
    static let riseTravel: CGFloat = DSSpacing.lg
    /// Scale of a `.scale` element at the viewport edge. 0.86 dips just enough to
    /// feel like it steps forward without the row visibly shrinking its box.
    static let edgeScale: CGFloat = 0.86
    /// Blur radius of a `.soften` element at the edge. 6pt loses detail while the
    /// shape stays legible, so it reads as out-of-focus, not gone.
    static let edgeBlur: CGFloat = 6
    /// Residual opacity of a `.soften` element at the edge. It never fully
    /// vanishes — the blur carries the recede, the fade only deepens it.
    static let softenOpacity: Double = 0.3
}

// MARK: - Modifier

public struct DSScrollRevealModifier: ViewModifier {
    let style: DSScrollRevealStyle
    let axis: Axis

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Reduce Motion drops the transition entirely rather than animating a
    /// reduced version: the reveal is pure decoration, so the content rests fully
    /// in place (opacity 1, no offset, no scale, no blur) exactly as it would at
    /// the identity phase.
    public func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.scrollTransition(axis: axis) { view, phase in
                view
                    .opacity(opacity(for: phase))
                    .scaleEffect(scale(for: phase))
                    .offset(x: offset(for: phase, on: .horizontal),
                            y: offset(for: phase, on: .vertical))
                    .blur(radius: blur(for: phase))
            }
        }
    }

    // MARK: Per-phase effect values

    private func opacity(for phase: ScrollTransitionPhase) -> Double {
        if phase.isIdentity { return 1 }
        switch style {
        case .rise, .scale: return 0
        case .soften:       return Metrics.softenOpacity
        }
    }

    private func scale(for phase: ScrollTransitionPhase) -> CGFloat {
        guard style == .scale, !phase.isIdentity else { return 1 }
        return Metrics.edgeScale
    }

    private func blur(for phase: ScrollTransitionPhase) -> CGFloat {
        guard style == .soften, !phase.isIdentity else { return 0 }
        return Metrics.edgeBlur
    }

    /// `.rise` travels along the scroll axis only. `phase.value` is -1 at the
    /// leading edge and +1 at the trailing edge, so the offset carries an element
    /// up into place from below and lets one above drift up as it leaves —
    /// symmetric either way the scroll goes.
    private func offset(for phase: ScrollTransitionPhase, on wanted: Axis) -> CGFloat {
        guard style == .rise, axis == wanted, !phase.isIdentity else { return 0 }
        return CGFloat(phase.value) * Metrics.riseTravel
    }
}

// MARK: - View Extension

public extension View {
    /// Reveal this content as it scrolls into the viewport, and let it recede as
    /// it leaves. Apply it to the repeating element inside a `ScrollView` (a row,
    /// a card, a grid item). Under Reduce Motion the content rests fully in place.
    ///
    ///     ScrollView {
    ///         LazyVStack(spacing: DSSpacing.md) {
    ///             ForEach(items) { item in
    ///                 ItemCard(item).dsScrollReveal()
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - style: Which reveal to use. Defaults to `.rise`.
    ///   - axis: The scroll axis to track. Defaults to `.vertical`; pass
    ///     `.horizontal` for a carousel so the fade keys off the right edge.
    func dsScrollReveal(
        _ style: DSScrollRevealStyle = .rise,
        axis: Axis = .vertical
    ) -> some View {
        modifier(DSScrollRevealModifier(style: style, axis: axis))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSScrollRevealPreviewHost: View {
    @State private var theme = DSTheme()

    private let styles: [(name: String, style: DSScrollRevealStyle)] = [
        ("rise", .rise),
        ("scale", .scale),
        ("soften", .soften)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                Text("Scroll — each row reveals as it enters, recedes as it leaves")
                    .ds(.footnote, color: DSColors.textSecondary)

                ForEach(0..<12, id: \.self) { index in
                    let entry = styles[index % styles.count]
                    DSCard {
                        HStack(spacing: DSSpacing.md) {
                            RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                                .fill(theme.gradient.horizontalGradient)
                                .frame(width: DSSpacing.huge, height: DSSpacing.huge)
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text("Row \(index + 1)").ds(.title3)
                                Text(".dsScrollReveal(.\(entry.name))")
                                    .ds(.caption1, color: DSColors.textSecondary)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .dsScrollReveal(entry.style)
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
