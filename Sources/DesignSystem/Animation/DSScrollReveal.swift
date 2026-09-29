import SwiftUI

// MARK: - Design System Scroll Reveal
// Content that settles into place as it scrolls into view: it arrives faded and
// scaled-down — and, for the heavier styles, lifted or defocused — then resolves
// to rest exactly as it reaches the viewport's centre. Unlike the looping
// effects in `DSMotion`, this one carries no clock of its own: it is driven
// entirely by scroll position through iOS 17's `scrollTransition`, so it is
// scrubbable. Drag the scroll back and the reveal plays in reverse, frame for
// frame with the finger.
//
// It keeps to the same motion rules as the rest of Velvet. The interpolation is
// eased and position-driven, never a spring — nothing here was touched, so a
// spring would read as a lie. Every magnitude comes from `DSSpacing`. And Reduce
// Motion is a resting state, not a skip: the content is handed back untouched
// and fully visible, so the layout is byte-for-byte identical to no modifier at
// all — no offset to leave an element parked off-centre, no residual scale.
//
// Reveal-on-scroll is a pattern the SwiftUI community built on `scrollTransition`
// as soon as iOS 17 shipped it (Swift with Majid, Hacking with Swift). The API
// is Apple's; the Velvet reading — three tuned presets over the token scale — is
// what lives here.

// MARK: - Style

public enum DSScrollRevealStyle: Sendable {
    /// Fade + a gentle scale-up. The safe default: reads well on any list or feed
    /// and never moves an element off its own layout line.
    case soft
    /// Fade + scale + a small settle along the scroll axis — rows rise into place
    /// (or slide in, on a horizontal carousel).
    case rise
    /// Fade + scale + a soft defocus. The most cinematic; for hero cards and
    /// full-bleed media, one or two on screen at a time.
    case blur

    /// Scale at the edges; interpolates up to `1` at rest.
    var minScale: CGFloat {
        switch self {
        case .soft: return 0.94
        case .rise: return 0.96
        case .blur: return 0.92
        }
    }

    /// Peak signed travel along the scroll axis at the edges, in points.
    var travel: CGFloat {
        self == .rise ? DSSpacing.lg : 0
    }

    /// Peak blur radius at the edges, in points.
    var maxBlur: CGFloat {
        self == .blur ? DSSpacing.xs : 0
    }
}

// MARK: - Modifier

public struct DSScrollRevealModifier: ViewModifier {
    let style: DSScrollRevealStyle
    let axis: Axis

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        if reduceMotion {
            // Resting state, not a skip: identity leaves the element exactly where
            // and how it would sit with no modifier — fully visible, at scale 1,
            // on its own layout line.
            content
        } else {
            content.scrollTransition(axis: axis) { view, phase in
                // `phase.value` is 0 at rest (identity) and runs to ±1 at the
                // leading/trailing edges. `distance` is how far this element is
                // from home, regardless of which edge it is near.
                let distance = min(abs(phase.value), 1)
                let scale = 1 - CGFloat(distance) * (1 - style.minScale)
                return view
                    .opacity(1 - distance)
                    .scaleEffect(scale)
                    .offset(offset(for: phase.value))
                    .blur(radius: CGFloat(distance) * style.maxBlur)
            }
        }
    }

    /// Signed offset along the scroll axis. Keeping `phase.value`'s sign means an
    /// element still below/trailing starts further along and travels back to rest
    /// as it reaches the centre, so the motion always runs with the reading
    /// direction rather than against it.
    private func offset(for value: Double) -> CGSize {
        let amount = CGFloat(value) * style.travel
        switch axis {
        case .vertical:   return CGSize(width: 0, height: amount)
        case .horizontal: return CGSize(width: amount, height: 0)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Reveal this element as it scrolls into view — a fade and scale, plus a
    /// settle (`.rise`) or defocus (`.blur`), resolving to rest at the viewport
    /// centre. Apply it to each row or card inside a `ScrollView`; pass
    /// `axis: .horizontal` for a carousel. Settles fully visible under Reduce
    /// Motion, leaving layout untouched.
    func dsScrollReveal(_ style: DSScrollRevealStyle = .soft, axis: Axis = .vertical) -> some View {
        modifier(DSScrollRevealModifier(style: style, axis: axis))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSScrollRevealPreviewHost: View {
    @State private var theme = DSTheme()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                Text("Scroll — rows resolve to rest at the centre")
                    .ds(.footnote, color: DSColors.textSecondary)

                ForEach(0..<10, id: \.self) { index in
                    DSCard {
                        HStack(spacing: DSSpacing.md) {
                            DSAvatar(name: "Row \(index + 1)", size: DSSpacing.huge)
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text("Row \(index + 1)").ds(.title3)
                                Text("Fades and rises into place")
                                    .ds(.callout, color: theme.palette.textSecondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .dsScrollReveal(.rise)
                }

                Text("Horizontal carousel — .blur")
                    .ds(.footnote, color: DSColors.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DSSpacing.md) {
                        ForEach(0..<6, id: \.self) { index in
                            DSCard {
                                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                    Text("\(index + 1)").ds(.displayMedium)
                                    Text("Defocus reveal")
                                        .ds(.callout, color: theme.palette.textSecondary)
                                }
                                .frame(width: DSSpacing.massive * 2, alignment: .leading)
                            }
                            .dsScrollReveal(.blur, axis: .horizontal)
                        }
                    }
                    .padding(.horizontal, DSSpacing.xxs)
                    .padding(.vertical, DSSpacing.xs)
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
