import SwiftUI

// MARK: - Design System Flip Card
// A two-sided glass card that turns over in 3D to reveal its back: tap it, or
// drive it from a binding. The flip is a single spring about one axis with a
// touch of perspective, and it fires a haptic on the turn — the premium reading
// of "there's more on the other side" (a stat and its detail, a question and its
// answer, a card's face and its number).
//
// The turn is driven by one animated angle through an `Animatable` container, so
// the two faces swap exactly at the 90° edge — no ghosting, no mirrored text, and
// no fixed duration to tune. Under Reduce Motion the card swaps faces instantly
// instead of spinning. Each face sits on a `DSCard`, so it inherits the glass,
// the edge highlight and the shadow with no extra work.

// MARK: - Flip Axis

public enum DSFlipAxis: Sendable {
    /// Turns around the vertical axis — the card swings left-to-right. The default.
    case horizontal
    /// Turns around the horizontal axis — the card swings top-to-bottom.
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

    /// Vanishing point for the turn. Small enough to read as a real card lifting
    /// off the glass, large enough to avoid a fisheye warp at the edges.
    private static var perspective: CGFloat { 0.5 }

    private let externalIsFlipped: Binding<Bool>?
    private let axis: DSFlipAxis
    private let style: DSCardStyle
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let flipOnTap: Bool
    private let haptic: DSHapticStyle
    private let front: () -> Front
    private let back: () -> Back

    @State private var internalIsFlipped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A self-managing flip card: tap to turn it over.
    /// - Parameters:
    ///   - axis: Which way the card swings. Defaults to `.horizontal`.
    ///   - style: Glass treatment of each face, same as `DSCard`. Defaults to `.elevated`.
    ///   - padding: Inner padding of each face. Defaults to `DSSpacing.md`.
    ///   - cornerRadius: Corner radius of each face. Defaults to `DSRadius.card`.
    ///   - flipOnTap: Turn the card over when it is tapped. Set `false` when a face
    ///     holds its own controls and should only flip from code. Defaults to `true`.
    ///   - haptic: Haptic fired on the turn. Defaults to `.rigid`.
    ///   - front: The face shown at rest.
    ///   - back: The face revealed after the turn.
    public init(
        axis: DSFlipAxis = .horizontal,
        style: DSCardStyle = .elevated,
        padding: CGFloat = DSSpacing.md,
        cornerRadius: CGFloat = DSRadius.card,
        flipOnTap: Bool = true,
        haptic: DSHapticStyle = .rigid,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self.externalIsFlipped = nil
        self.axis = axis
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.flipOnTap = flipOnTap
        self.haptic = haptic
        self.front = front
        self.back = back
    }

    /// A flip card whose face is bound to your own state, so you can turn it over
    /// from code as well as by tapping.
    /// - Parameter isFlipped: `false` shows `front`, `true` shows `back`.
    public init(
        isFlipped: Binding<Bool>,
        axis: DSFlipAxis = .horizontal,
        style: DSCardStyle = .elevated,
        padding: CGFloat = DSSpacing.md,
        cornerRadius: CGFloat = DSRadius.card,
        flipOnTap: Bool = true,
        haptic: DSHapticStyle = .rigid,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self.externalIsFlipped = isFlipped
        self.axis = axis
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.flipOnTap = flipOnTap
        self.haptic = haptic
        self.front = front
        self.back = back
    }

    private var isFlipped: Bool {
        externalIsFlipped?.wrappedValue ?? internalIsFlipped
    }

    public var body: some View {
        DSFlipFaces(
            angle: isFlipped ? 180 : 0,
            axis: axis,
            perspective: Self.perspective,
            front: DSCard(style: style, padding: padding, cornerRadius: cornerRadius, content: front),
            back: DSCard(style: style, padding: padding, cornerRadius: cornerRadius, content: back)
        )
        // Reduce Motion: a quiet, instant swap rather than a spin. Passing `nil`
        // animates the angle change immediately, so the faces trade places at rest.
        .animation(reduceMotion ? nil : DSAnimation.springSmooth, value: isFlipped)
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .modifier(DSFlipTapModifier(enabled: flipOnTap, flip: flip))
    }

    private func flip() {
        DSHapticEngine.shared.fire(haptic)
        if let externalIsFlipped {
            externalIsFlipped.wrappedValue.toggle()
        } else {
            internalIsFlipped.toggle()
        }
    }
}

// MARK: - Animatable Face Container

/// Interpolates one angle across the turn and shows the matching face. Because
/// the visibility threshold is read from the live, per-frame `angle`, the faces
/// hand off exactly at the 90° edge for any animation — spring included — with no
/// cross-fade ghosting. The back face is pre-rotated a half turn so it reads the
/// right way round once the card has flipped.
private struct DSFlipFaces<FrontFace: View, BackFace: View>: View, Animatable {
    var angle: Double
    let axis: DSFlipAxis
    let perspective: CGFloat
    let front: FrontFace
    let back: BackFace

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let showingBack = angle >= 90
        ZStack {
            front
                .opacity(showingBack ? 0 : 1)
                .accessibilityHidden(showingBack)
            back
                .rotation3DEffect(.degrees(180), axis: axis.vector)
                .opacity(showingBack ? 1 : 0)
                .accessibilityHidden(!showingBack)
        }
        .rotation3DEffect(.degrees(angle), axis: axis.vector, perspective: perspective)
    }
}

// MARK: - Tap Modifier

/// Adds the tap-to-flip gesture and button semantics only when `enabled`, so a
/// card that flips from code keeps its faces' own hit testing and VoiceOver.
private struct DSFlipTapModifier: ViewModifier {
    let enabled: Bool
    let flip: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            content
                .onTapGesture(perform: flip)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(Text("Double tap to flip"))
        } else {
            content
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSFlipCardPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var detailsShown = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                Text("Tap to flip").ds(.overline, color: DSColors.textSecondary)
                DSFlipCard {
                    statFace(title: "This month", value: "1 248", caption: "steps today")
                } back: {
                    statFace(title: "On the back", value: "+12%", caption: "vs. last month")
                }

                Text("Vertical, driven from a binding").ds(.overline, color: DSColors.textSecondary)
                DSFlipCard(isFlipped: $detailsShown, axis: .vertical) {
                    faceRow(icon: "creditcard", text: "•••• 4242")
                } back: {
                    faceRow(icon: "lock.fill", text: "CVC 123 · 09/28")
                }
                DSButton(detailsShown ? "Hide details" : "Show details", variant: .secondary, size: .small) {
                    withAnimation(DSAnimation.springSmooth) { detailsShown.toggle() }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func statFace(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(title).ds(.footnote, color: DSColors.textSecondary)
            Text(value).ds(.displayMedium)
            Text(caption).ds(.callout, color: DSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func faceRow(icon: String, text: String) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: icon).foregroundStyle(theme.gradient.accent)
            Text(text).ds(.numeric)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Flip Card — Light") {
    DSFlipCardPreviewHost().preferredColorScheme(.light)
}

#Preview("Flip Card — Dark") {
    DSFlipCardPreviewHost().preferredColorScheme(.dark)
}
#endif
