import SwiftUI

// MARK: - Design System Flip Card
// A two-sided card that turns over in 3D to reveal its back — flashcards, loyalty
// and credit cards, stat tiles that flip to detail, question/answer reveals.
//
// The flip is the hard part to get right, and this does:
//   • The whole stack rotates around one axis with `rotation3DEffect` + perspective,
//     so it reads as a physical card turning, not a crossfade.
//   • A 180° rotation mirrors whatever faces away, so the back is counter-mirrored
//     and only un-mirrors as it comes to face the viewer — its text never reads
//     backwards.
//   • The two faces crossfade exactly as the card passes edge-on (90°), where it is
//     a thin sliver, so you never see both faces or the mirror bleed through.
//
// It imposes no surface of its own: each face is whatever you pass (usually a
// `DSCard`), so a glass front can flip to a gradient back. Give both faces the
// same size — the stack sizes to the larger one. Spring on touch, a `.rigid` snap
// haptic on each flip. Under Reduce Motion the 3D turn is dropped for a plain
// crossfade so nothing swings through depth.

// MARK: - Flip Axis

public enum DSFlipAxis: Sendable {
    /// Turns left-to-right around the vertical axis — the default, like turning a page.
    case horizontal
    /// Turns top-to-bottom around the horizontal axis.
    case vertical
}

// MARK: - Flip Card

public struct DSFlipCard<Front: View, Back: View>: View {
    private let axis: DSFlipAxis
    private let perspective: CGFloat
    private let haptic: DSHapticStyle
    private let externalFlipped: Binding<Bool>?
    private let front: () -> Front
    private let back: () -> Back

    @State private var internalFlipped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A flip card that turns over on tap.
    /// - Parameters:
    ///   - axis: Which way the card turns. Defaults to `.horizontal`.
    ///   - perspective: Depth of the 3D turn, as `rotation3DEffect` expects
    ///     (0 = flat, ~0.6 = a gentle, premium amount). Defaults to `0.6`.
    ///   - haptic: Fired on every flip. Defaults to `.rigid` (a precise snap).
    ///   - isFlipped: Optional external binding. Omit it and the card manages its
    ///     own state; pass one to flip it from elsewhere (tapping still updates it).
    ///   - front: The face shown at rest.
    ///   - back: The face shown once flipped.
    public init(
        axis: DSFlipAxis = .horizontal,
        perspective: CGFloat = 0.6,
        haptic: DSHapticStyle = .rigid,
        isFlipped: Binding<Bool>? = nil,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self.axis = axis
        self.perspective = perspective
        self.haptic = haptic
        self.externalFlipped = isFlipped
        self.front = front
        self.back = back
    }

    private var isFlipped: Bool {
        externalFlipped?.wrappedValue ?? internalFlipped
    }

    private var axisVector: (x: CGFloat, y: CGFloat, z: CGFloat) {
        axis == .horizontal ? (0, 1, 0) : (1, 0, 0)
    }

    /// Angle of the whole card. Zero under Reduce Motion, so the faces only crossfade.
    private var angle: Double {
        guard !reduceMotion else { return 0 }
        return isFlipped ? 180 : 0
    }

    /// Counter-mirror for the back face so the container's 180° turn lands it
    /// un-mirrored. Identity under Reduce Motion, where the container never turns.
    private var backScale: (x: CGFloat, y: CGFloat) {
        guard !reduceMotion else { return (1, 1) }
        return axis == .horizontal ? (-1, 1) : (1, -1)
    }

    public var body: some View {
        ZStack {
            front()
                .opacity(isFlipped ? 0 : 1)
                .accessibilityHidden(isFlipped)

            back()
                .scaleEffect(x: backScale.x, y: backScale.y)
                .opacity(isFlipped ? 1 : 0)
                .accessibilityHidden(!isFlipped)
        }
        .rotation3DEffect(
            .degrees(angle),
            axis: axisVector,
            perspective: perspective
        )
        .animation(reduceMotion ? DSAnimation.fast : DSAnimation.springSmooth, value: isFlipped)
        .contentShape(Rectangle())
        .onTapGesture { flip() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { flip() }
    }

    private func flip() {
        DSHapticEngine.shared.fire(haptic)
        if let externalFlipped {
            externalFlipped.wrappedValue.toggle()
        } else {
            internalFlipped.toggle()
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSFlipCardPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var statsFlipped = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                Text("Tap a card to flip it").ds(.footnote, color: DSColors.textSecondary)

                // Flashcard: glass front → glass back, horizontal turn.
                DSFlipCard {
                    flashFace("¿Cómo estás?", caption: "TAP TO REVEAL")
                } back: {
                    flashFace("How are you?", caption: "TRANSLATION")
                }

                // Loyalty card: gradient front → stats back, vertical turn.
                DSFlipCard(axis: .vertical) {
                    gradientFace
                } back: {
                    statsFace
                }
                .frame(height: 180)

                // Externally driven: a button elsewhere flips the stat tile.
                HStack(spacing: DSSpacing.md) {
                    DSFlipCard(isFlipped: $statsFlipped) {
                        tile("1,248", label: "Steps today")
                    } back: {
                        tile("82%", label: "Of your goal")
                    }
                    DSButton("Flip", variant: .secondary, size: .small) {
                        statsFlipped.toggle()
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func flashFace(_ text: String, caption: String) -> some View {
        DSCard {
            VStack(spacing: DSSpacing.sm) {
                Text(caption).ds(.overline, color: DSColors.textTertiary)
                Text(text).ds(.title1)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        }
    }

    private var gradientFace: some View {
        VStack(alignment: .leading) {
            Text("VELVET").ds(.overline, color: theme.gradient.onAccent)
            Spacer()
            Text("•••• 4921").ds(.numeric, color: theme.gradient.onAccent)
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(theme.gradient.linearGradient)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous))
        .dsWashEdge(radius: DSRadius.card)
    }

    private var statsFace: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Balance").ds(.footnote, color: DSColors.textSecondary)
                Text("$2,480.00").ds(.displayMedium)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private func tile(_ value: String, label: String) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(value).ds(.title2)
                Text(label).ds(.caption1, color: DSColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("Flip Card — Light") {
    DSFlipCardPreviewHost().preferredColorScheme(.light)
}

#Preview("Flip Card — Dark") {
    DSFlipCardPreviewHost().preferredColorScheme(.dark)
}
#endif
