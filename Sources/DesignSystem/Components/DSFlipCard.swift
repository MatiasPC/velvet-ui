import SwiftUI

// MARK: - Design System Flip Card
// A two-sided card that flips in 3D to reveal its back. Perfect for
// flashcards, stat "front/back" reveals, profile cards, or any tap-to-reveal
// interaction. The face swap happens precisely at the 90° midpoint — driven by
// an `Animatable` angle so the reverse side is never seen mirrored or
// double-exposed — and the card dips slightly in scale through the turn for a
// premium sense of depth. Works controlled (via a binding) or uncontrolled
// (tap to flip).

// MARK: - Flip Axis

public enum DSFlipAxis {
    /// Flips around the vertical axis — the card turns left-to-right.
    case horizontal
    /// Flips around the horizontal axis — the card turns top-to-bottom.
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

    // MARK: Configuration

    private let axis: DSFlipAxis
    private let perspective: CGFloat
    private let animation: Animation
    private let haptic: DSHapticStyle
    private let flipOnTap: Bool
    private let front: Front
    private let back: Back

    // MARK: State

    @State private var internalFlipped: Bool
    private let externalFlipped: Binding<Bool>?

    /// The current side, resolved from the external binding when controlled,
    /// otherwise from internal state.
    private var isFlipped: Bool {
        externalFlipped?.wrappedValue ?? internalFlipped
    }

    // MARK: Uncontrolled Initializer

    /// A self-managing flip card that flips on tap.
    /// - Parameters:
    ///   - axis: The rotation axis. Defaults to `.horizontal` (left-to-right).
    ///   - perspective: Depth of the 3D projection. Smaller values are flatter,
    ///     larger values more dramatic. Defaults to `0.5`.
    ///   - animation: Spring used for the turn. Defaults to `DSAnimation.springSmooth`.
    ///   - haptic: Feedback fired on each flip. Defaults to `.rigid`.
    ///   - flipOnTap: Whether tapping the card flips it. Defaults to `true`.
    ///   - front: The face shown at rest.
    ///   - back: The face revealed after flipping.
    public init(
        axis: DSFlipAxis = .horizontal,
        perspective: CGFloat = 0.5,
        animation: Animation = DSAnimation.springSmooth,
        haptic: DSHapticStyle = .rigid,
        flipOnTap: Bool = true,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self.axis = axis
        self.perspective = perspective
        self.animation = animation
        self.haptic = haptic
        self.flipOnTap = flipOnTap
        self._internalFlipped = State(initialValue: false)
        self.externalFlipped = nil
        self.front = front()
        self.back = back()
    }

    // MARK: Controlled Initializer

    /// A flip card whose side is driven by an external binding. Tapping still
    /// toggles the binding when `flipOnTap` is `true`, and updating the binding
    /// elsewhere animates the turn.
    /// - Parameters:
    ///   - isFlipped: Binding to the current side (`false` = front).
    ///   - axis: The rotation axis. Defaults to `.horizontal`.
    ///   - perspective: Depth of the 3D projection. Defaults to `0.5`.
    ///   - animation: Spring used for the turn. Defaults to `DSAnimation.springSmooth`.
    ///   - haptic: Feedback fired on each flip. Defaults to `.rigid`.
    ///   - flipOnTap: Whether tapping the card flips it. Defaults to `true`.
    ///   - front: The face shown when `isFlipped` is `false`.
    ///   - back: The face shown when `isFlipped` is `true`.
    public init(
        isFlipped: Binding<Bool>,
        axis: DSFlipAxis = .horizontal,
        perspective: CGFloat = 0.5,
        animation: Animation = DSAnimation.springSmooth,
        haptic: DSHapticStyle = .rigid,
        flipOnTap: Bool = true,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self.axis = axis
        self.perspective = perspective
        self.animation = animation
        self.haptic = haptic
        self.flipOnTap = flipOnTap
        self._internalFlipped = State(initialValue: isFlipped.wrappedValue)
        self.externalFlipped = isFlipped
        self.front = front()
        self.back = back()
    }

    // MARK: Body

    public var body: some View {
        let card = DSFlipFace(
            angle: isFlipped ? 180 : 0,
            axis: axis.vector,
            perspective: perspective,
            front: front,
            back: back
        )
        .animation(animation, value: isFlipped)

        return Group {
            if flipOnTap {
                card
                    .contentShape(Rectangle())
                    .onTapGesture(perform: flip)
            } else {
                card
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(flipOnTap ? .isButton : [])
        .accessibilityHint(flipOnTap ? Text("Double tap to flip") : Text(""))
        .accessibilityAction {
            if flipOnTap { flip() }
        }
    }

    // MARK: Actions

    private func flip() {
        DSHapticEngine.shared.fire(haptic)
        if let externalFlipped {
            externalFlipped.wrappedValue.toggle()
        } else {
            internalFlipped.toggle()
        }
    }
}

// MARK: - Animatable Face Container

/// Renders both faces and swaps visibility at the 90° midpoint. Conforming to
/// `Animatable` makes SwiftUI re-evaluate the body for each interpolated angle,
/// so the crossover is frame-accurate rather than snapping at the start of the
/// animation.
private struct DSFlipFace<Front: View, Back: View>: View, Animatable {
    var angle: Double
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let perspective: CGFloat
    let front: Front
    let back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    /// Front is visible for the first half of the turn, back for the second.
    private var showFront: Bool { angle < 90 }

    /// Subtle scale dip toward the midpoint for a sense of depth (1.0 at the
    /// faces, ~0.92 edge-on).
    private var depthScale: CGFloat {
        let t = CGFloat(min(abs(90 - angle) / 90, 1)) // 1 at a face, 0 edge-on
        return 0.92 + 0.08 * t
    }

    var body: some View {
        ZStack {
            front
                .opacity(showFront ? 1 : 0)
                .accessibilityHidden(!showFront)

            back
                .rotation3DEffect(.degrees(180), axis: axis)
                .opacity(showFront ? 0 : 1)
                .accessibilityHidden(showFront)
        }
        .scaleEffect(depthScale)
        .rotation3DEffect(.degrees(angle), axis: axis, perspective: perspective)
    }
}

// MARK: - Preview

#Preview("Light") {
    FlipCardPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    FlipCardPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct FlipCardPreview: View {
    @State private var isFlipped = false

    var body: some View {
        VStack(spacing: DSSpacing.xxl) {
            VStack(spacing: DSSpacing.sm) {
                Text("Tap to flip")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)

                DSFlipCard {
                    statFace(
                        title: "Steps",
                        value: "8,420",
                        caption: "Tap for details",
                        tint: DSColors.defaultPalette.primary
                    )
                } back: {
                    statFace(
                        title: "Goal",
                        value: "84%",
                        caption: "6,580 to go",
                        tint: DSColors.defaultPalette.tertiary
                    )
                }
            }

            VStack(spacing: DSSpacing.sm) {
                Text("Controlled — vertical axis")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)

                DSFlipCard(isFlipped: $isFlipped, axis: .vertical) {
                    flashFace(text: "capital of France?", tint: DSColors.defaultPalette.secondary)
                } back: {
                    flashFace(text: "Paris", tint: DSColors.defaultPalette.success)
                }

                DSButton(isFlipped ? "Show question" : "Reveal answer", variant: .outline, size: .small) {
                    isFlipped.toggle()
                }
            }
        }
    }

    private func statFace(title: String, value: String, caption: String, tint: Color) -> some View {
        DSCard(style: .elevated) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title.uppercased())
                    .ds(.overline, color: tint)
                Text(value)
                    .ds(.displayMedium)
                Text(caption)
                    .ds(.footnote, color: DSColors.defaultPalette.textSecondary)
            }
            .frame(width: 220, alignment: .leading)
        }
    }

    private func flashFace(text: String, tint: Color) -> some View {
        DSCard(style: .elevated) {
            Text(text)
                .ds(.title3)
                .multilineTextAlignment(.center)
                .frame(width: 220, height: 80)
        }
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous)
                .stroke(tint, lineWidth: 2)
        )
    }
}
