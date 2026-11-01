import SwiftUI

// MARK: - Design System Flip Card
// Two faces, one card. Tap it and it turns over in 3D — the front rotates away,
// the back arrives un-mirrored, and a single rigid haptic lands on the turn.
// Use it for a flashcard (question → answer), a reveal (tap to show the code,
// the balance, the answer) or a stat card with detail on the back.
//
// The polish is in the face swap. Both faces live in the same ZStack; the one
// facing away is hidden. Doing that with a plain boolean would flip visibility
// at the *start* of the turn, so the back would flash, mirrored, across the
// front. Instead `DSFlipFace` is `Animatable`: SwiftUI re-evaluates it on every
// interpolated frame, so each face appears exactly as it passes edge-on (90°),
// where its width is zero and the swap is invisible.
//
// Give both faces a similar size — the card sizes to the union of the two.

/// Which way the card turns.
public enum DSFlipAxis: Sendable {
    /// Turns left-to-right, around the vertical axis. The default.
    case horizontal
    /// Turns top-to-bottom, around the horizontal axis.
    case vertical

    /// Axis vector for `rotation3DEffect`.
    var vector: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch self {
        case .horizontal: return (x: 0, y: 1, z: 0)
        case .vertical:   return (x: 1, y: 0, z: 0)
        }
    }
}

private enum Metrics {
    /// Perspective for the turn, as `rotation3DEffect` expects (0 = none, ~0.5 = default depth).
    static let perspective: CGFloat = 0.5
    /// Face shown while the turn is below this angle; the other face takes over past it.
    static let swapAngle: Double = 90
    /// A full half-turn, in degrees.
    static let halfTurn: Double = 180
}

// MARK: - Animatable Face

/// One face of the card. `Animatable` so the visibility swap tracks the live
/// turn angle and happens exactly as the face passes edge-on — no mirrored flash.
private struct DSFlipFace: ViewModifier, Animatable {
    /// Current turn angle, 0 (front square on) … 180 (back square on).
    var angle: Double
    let isBack: Bool
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        // The back is mounted pre-rotated a half-turn, so it reads un-mirrored
        // when the card finishes on 180°.
        let faceAngle = isBack ? angle - Metrics.halfTurn : angle
        let isVisible = isBack ? angle >= Metrics.swapAngle : angle < Metrics.swapAngle
        content
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(!isVisible)
            .rotation3DEffect(.degrees(faceAngle), axis: axis, perspective: Metrics.perspective)
    }
}

// MARK: - Flip Card

/// A two-sided card that turns over in 3D when tapped.
///
/// Manage the state yourself, or let the card own it:
///
///     DSFlipCard {
///         DSCard { Text("What is the capital of France?").ds(.title3) }
///     } back: {
///         DSCard { Text("Paris").ds(.title1) }
///     }
///
/// or drive it from the outside with a binding:
///
///     DSFlipCard(isShowingBack: $revealed) { … } back: { … }
///
/// Tapping always turns the card; with a binding, the tap updates it. A rigid
/// haptic fires on each turn. With Reduce Motion on, the faces swap instantly
/// without the 3D spin.
public struct DSFlipCard<Front: View, Back: View>: View {
    private let front: Front
    private let back: Back
    private let axis: DSFlipAxis
    private let haptic: DSHapticStyle?

    @State private var internalShowingBack: Bool
    private let externalBinding: Binding<Bool>?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A flip card that owns its state. Tap it to turn it over.
    /// - Parameters:
    ///   - axis: Which way the card turns. Defaults to `.horizontal`.
    ///   - showsBackFirst: Start showing the back. Defaults to `false`.
    ///   - haptic: Fired on each turn. Pass `nil` for none. Defaults to `.rigid`.
    ///   - front: The face shown at rest.
    ///   - back: The face shown after a turn.
    public init(
        axis: DSFlipAxis = .horizontal,
        showsBackFirst: Bool = false,
        haptic: DSHapticStyle? = .rigid,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self.axis = axis
        self.haptic = haptic
        self.front = front()
        self.back = back()
        self._internalShowingBack = State(initialValue: showsBackFirst)
        self.externalBinding = nil
    }

    /// A flip card driven by a binding. Tapping turns it over by updating the binding.
    /// - Parameters:
    ///   - isShowingBack: Whether the back face is showing.
    ///   - axis: Which way the card turns. Defaults to `.horizontal`.
    ///   - haptic: Fired on each turn from a tap. Pass `nil` for none. Defaults to `.rigid`.
    ///   - front: The face shown when `isShowingBack` is `false`.
    ///   - back: The face shown when `isShowingBack` is `true`.
    public init(
        isShowingBack: Binding<Bool>,
        axis: DSFlipAxis = .horizontal,
        haptic: DSHapticStyle? = .rigid,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self.axis = axis
        self.haptic = haptic
        self.front = front()
        self.back = back()
        self._internalShowingBack = State(initialValue: isShowingBack.wrappedValue)
        self.externalBinding = isShowingBack
    }

    private var isShowingBack: Bool { externalBinding?.wrappedValue ?? internalShowingBack }

    public var body: some View {
        let angle: Double = isShowingBack ? Metrics.halfTurn : 0
        ZStack {
            front.modifier(DSFlipFace(angle: angle, isBack: false, axis: axis.vector))
            back.modifier(DSFlipFace(angle: angle, isBack: true, axis: axis.vector))
        }
        .contentShape(Rectangle())
        .onTapGesture { flip() }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text("Flip")) { flip() }
    }

    private func flip() {
        if let haptic { DSHapticEngine.shared.fire(haptic) }
        let next = !isShowingBack
        withAnimation(reduceMotion ? nil : DSAnimation.springSmooth) {
            if let externalBinding {
                externalBinding.wrappedValue = next
            } else {
                internalShowingBack = next
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSFlipCardPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var revealed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                Text("Tap a card to flip it").ds(.footnote, color: DSColors.textSecondary)

                // Flashcard — owns its own state.
                DSFlipCard {
                    flashFace("Capital of France?", style: .title2)
                } back: {
                    flashFace("Paris", style: .displayMedium, accent: true)
                }

                // Vertical turn, driven by a binding + an external button.
                DSFlipCard(isShowingBack: $revealed, axis: .vertical) {
                    flashFace("Tap to reveal balance", style: .title3)
                } back: {
                    flashFace("$1,248.00", style: .displayMedium, accent: true)
                }

                DSButton(revealed ? "Hide" : "Reveal", variant: .secondary) {
                    withAnimation(DSAnimation.springSmooth) { revealed.toggle() }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func flashFace(_ text: String, style: DSTextStyle, accent: Bool = false) -> some View {
        DSCard {
            Text(text)
                .ds(style, color: accent ? theme.gradient.accent : nil)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: DSSpacing.massive * 2)
        }
    }
}

#Preview("FlipCard — Light") {
    DSFlipCardPreviewHost().preferredColorScheme(.light)
}

#Preview("FlipCard — Dark") {
    DSFlipCardPreviewHost().preferredColorScheme(.dark)
}
#endif
