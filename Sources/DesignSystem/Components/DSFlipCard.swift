import SwiftUI

// MARK: - Design System Flip Card
// A two-faced surface that turns over in 3D to reveal its back: flashcards,
// stat tiles that flip to show the breakdown, loyalty cards, "tap to reveal".
// Both faces are arbitrary views, so the card stays content-agnostic and the
// glass look comes from whatever you put on each side (usually a `DSCard`).
//
// How the turn stays honest:
//   • Both faces live in one `ZStack`; the whole stack rotates 0 → 180°.
//   • The back is pre-rotated a half-turn so that, once the stack has turned,
//     its content reads the right way round instead of mirrored.
//   • Each face fades out as it turns away. The swap lands at the 90° midpoint —
//     where the card is edge-on and its projected width is ~0 — so the crossfade
//     is hidden behind the turn rather than seen as a dissolve.
//   • Only the face in view takes hits and is visible to VoiceOver, so
//     interactive content on the hidden side can't be reached by accident.
//
// Reduce Motion drops the 3D rotation entirely and cross-fades the two faces
// flat (the back is not pre-rotated in that case, so it never reads mirrored).
//
// Technique (not code) adapted from the SwiftUI community's standard flip:
// a ZStack with a pre-rotated back and an edge-on opacity swap — see
// zenn.dev/touyou/articles/flip_tilt_card_swiftui, swiftui-lab.com/?p=834 and
// danielsaidi.com/blog/2025/06/01/introducing-flipkit-for-swiftui. Rewritten on
// Velvet tokens: `DSAnimation.springSmooth` for the turn, `DSHapticEngine` on
// the flip, Reduce Motion as a real state.

// MARK: - Axis

public enum DSFlipAxis: Sendable {
    /// Turns around the vertical (Y) axis — the card flips left-to-right.
    case horizontal
    /// Turns around the horizontal (X) axis — the card flips top-to-bottom.
    case vertical

    var vector: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch self {
        case .horizontal: return (0, 1, 0)
        case .vertical:   return (1, 0, 0)
        }
    }
}

// MARK: - Flip Card

public struct DSFlipCard<Front: View, Back: View>: View {
    private let axis: DSFlipAxis
    private let haptic: DSHapticStyle
    private let tapToFlip: Bool
    private let front: () -> Front
    private let back: () -> Back

    /// Set when the flip is driven by the caller; `nil` when the card owns its
    /// own state and flips on tap.
    private let externalFlipped: Binding<Bool>?
    @State private var internalFlipped = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Uncontrolled: the card owns its state and turns over when tapped.
    public init(
        axis: DSFlipAxis = .horizontal,
        haptic: DSHapticStyle = .rigid,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self.axis = axis
        self.haptic = haptic
        self.tapToFlip = true
        self.externalFlipped = nil
        self.front = front
        self.back = back
    }

    /// Controlled: you drive the turn through `isFlipped`. Keep `tapToFlip` on
    /// (default) to also allow a tap on the card, or turn it off when a face has
    /// its own controls and only the binding should flip it.
    public init(
        isFlipped: Binding<Bool>,
        axis: DSFlipAxis = .horizontal,
        haptic: DSHapticStyle = .rigid,
        tapToFlip: Bool = true,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self.axis = axis
        self.haptic = haptic
        self.tapToFlip = tapToFlip
        self.externalFlipped = isFlipped
        self.front = front
        self.back = back
    }

    private var isFlipped: Bool {
        externalFlipped?.wrappedValue ?? internalFlipped
    }

    private var turnAnimation: Animation {
        reduceMotion ? DSAnimation.normal : DSAnimation.springSmooth
    }

    public var body: some View {
        ZStack {
            front()
                .opacity(isFlipped ? 0 : 1)
                .allowsHitTesting(!isFlipped)
                .accessibilityHidden(isFlipped)

            back()
                // Pre-turn the back so it reads correctly once the stack flips.
                // Flat under Reduce Motion, where nothing rotates to undo it.
                .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: axis.vector)
                .opacity(isFlipped ? 1 : 0)
                .allowsHitTesting(isFlipped)
                .accessibilityHidden(!isFlipped)
        }
        .rotation3DEffect(.degrees(reduceMotion ? 0 : (isFlipped ? 180 : 0)), axis: axis.vector)
        .animation(turnAnimation, value: isFlipped)
        .contentShape(Rectangle())
        .accessibilityAddTraits(tapToFlip ? .isButton : [])
        .modifier(DSFlipTapModifier(enabled: tapToFlip, flip: flip))
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

// MARK: - Tap Modifier

/// Adds the tap gesture only when `enabled`, so a controlled card with
/// `tapToFlip: false` keeps the whole surface free for its faces' own gestures.
private struct DSFlipTapModifier: ViewModifier {
    let enabled: Bool
    let flip: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            content
                .onTapGesture(perform: flip)
                .accessibilityAction(named: Text("Flip"), flip)
        } else {
            content
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

                // Uncontrolled — tap the card to turn it over.
                Text("Tap to flip").ds(.overline, color: DSColors.textSecondary)
                DSFlipCard {
                    flashcardFace(title: "Aurora", caption: "Tap to reveal the hex")
                } back: {
                    flashcardFace(title: "#7F5AF0", caption: "Violet → fuchsia")
                }

                // Vertical axis.
                Text("Vertical axis").ds(.overline, color: DSColors.textSecondary)
                DSFlipCard(axis: .vertical) {
                    flashcardFace(title: "Question", caption: "What ships the glass look?")
                } back: {
                    flashcardFace(title: "dsSurface", caption: "glass + specular edge")
                }

                // Controlled — a button drives the turn; the card itself stays put.
                Text("Controlled").ds(.overline, color: DSColors.textSecondary)
                DSFlipCard(isFlipped: $statsFlipped, tapToFlip: false) {
                    statFace(value: "1 248", label: "Steps today")
                } back: {
                    statFace(value: "+12%", label: "vs. yesterday")
                }
                DSButton(statsFlipped ? "Show total" : "Show change", size: .small) {
                    statsFlipped.toggle()
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func flashcardFace(title: String, caption: String) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title).ds(.title2)
                Text(caption).ds(.callout, color: DSColors.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: DSSpacing.massive, alignment: .leading)
        }
    }

    private func statFace(value: String, label: String) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(value).ds(.displayMedium)
                Text(label).ds(.callout, color: DSColors.textSecondary)
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
