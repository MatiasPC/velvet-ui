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
    private let haptic: DSHapticStyle?
    private let front: () -> Front
    private let back: () -> Back

    @State private var internalIsFlipped = false
    @State private var isTurning = false
    @State private var turnToken = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A self-managing flip card: tap to turn it over.
    /// - Parameters:
    ///   - axis: Which way the card swings. Defaults to `.horizontal`.
    ///   - style: Glass treatment of each face, same as `DSCard`. Defaults to `.elevated`.
    ///   - padding: Inner padding of each face. Defaults to `DSSpacing.md`.
    ///   - cornerRadius: Corner radius of each face. Defaults to `DSRadius.card`.
    ///   - flipOnTap: Turn the card over when it is tapped. Set `false` when a face
    ///     holds its own controls and should only flip from code. Defaults to `true`.
    ///   - haptic: Haptic fired on every turn, tap or binding. `nil` for none. Defaults to `.rigid`.
    ///   - front: The face shown at rest.
    ///   - back: The face revealed after the turn.
    public init(
        axis: DSFlipAxis = .horizontal,
        style: DSCardStyle = .elevated,
        padding: CGFloat = DSSpacing.md,
        cornerRadius: CGFloat = DSRadius.card,
        flipOnTap: Bool = true,
        haptic: DSHapticStyle? = .rigid,
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
        haptic: DSHapticStyle? = .rigid,
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
            angle: DSFlipMath.angle(isFlipped: isFlipped),
            flipped: isFlipped,
            reduceMotion: reduceMotion,
            glass: isTurning ? 0 : 1,
            axis: axis,
            perspective: Self.perspective,
            style: style,
            padding: padding,
            cornerRadius: cornerRadius,
            front: front(),
            back: back()
        )
        // Reduce Motion: no turn; the faces crossfade (handled in `DSFlipFaces`).
        .animation(reduceMotion ? nil : DSAnimation.springSmooth, value: isFlipped)
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .modifier(DSFlipTapModifier(enabled: flipOnTap, isFlipped: isFlipped, flip: flip))
        // The haptic rides the state change, so a binding-driven flip gets it too.
        .onChange(of: isFlipped) { _, _ in
            if let haptic { DSHapticEngine.shared.fire(haptic) }
            beginTurn()
        }
    }

    /// Holds the solid body from now until `settleSeconds` after the LAST flip, so rapid
    /// taps stay solid until the final spring has landed. Idempotent: `flip()` calls it
    /// before toggling (no glass frame at the start), `onChange` covers binding flips.
    private func beginTurn() {
        guard !reduceMotion else { return }
        isTurning = true
        turnToken += 1
        let token = turnToken
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(DSFlipMath.settleSeconds))
            guard token == turnToken else { return }
            withAnimation(DSAnimation.fast) { isTurning = false }
        }
    }

    private func flip() {
        beginTurn()
        if let externalIsFlipped {
            externalIsFlipped.wrappedValue.toggle()
        } else {
            internalIsFlipped.toggle()
        }
    }
}

// MARK: - Math

/// The pure rules behind the turn, kept out of the generic views so they can be tested.
enum DSFlipMath {
    /// Rest angle of each side, in degrees.
    static func angle(isFlipped: Bool) -> Double { isFlipped ? 180 : 0 }

    /// Which face is visible at a live, per-frame angle: the back from the 90 degree edge on.
    static func showsBack(angle: Double) -> Bool { angle >= 90 }

    /// How long the solid body is held after the last flip before the glass fades back
    /// in: the settle time of `DSAnimation.springSmooth` (response 0.45 s, damping 0.75)
    /// with margin. Glass does not render while the 3D transform is still animating, and
    /// the spring spends a long tail within a degree of rest, so an angle threshold hands
    /// back too early; a hold measured from the last flip does not.
    static let settleSeconds: Double = 0.9

    /// Pre-rotation of the back face so it reads the right way round once the card has
    /// turned. Zero under Reduce Motion, where the card never turns.
    static func backPreRotation(reduceMotion: Bool) -> Double { reduceMotion ? 0 : 180 }
}

// MARK: - Animatable Face Container

/// Interpolates one angle across the turn and shows the matching face. Because
/// the visibility threshold is read from the live, per-frame `angle`, the faces
/// hand off exactly at the 90° edge for any animation — spring included — with no
/// cross-fade ghosting. The back face is pre-rotated a half turn so it reads the
/// right way round once the card has flipped.
private struct DSFlipFaces<FrontContent: View, BackContent: View>: View, Animatable {
    // `nonisolated`: `View` makes the type main-actor, while SwiftUI's animation engine
    // reads the `Animatable` conformance off the main actor (an error in Swift 6 mode).
    nonisolated var angle: Double
    let flipped: Bool
    let reduceMotion: Bool
    let glass: Double
    let axis: DSFlipAxis
    let perspective: CGFloat
    let style: DSCardStyle
    let padding: CGFloat
    let cornerRadius: CGFloat
    let front: FrontContent
    let back: BackContent

    nonisolated var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        // Reduce Motion: the card never turns, the faces trade places with a short fade.
        let turn = reduceMotion ? 0 : angle
        let showingBack = reduceMotion ? flipped : DSFlipMath.showsBack(angle: angle)
        // Materials and shadows lose their backdrop under a 3D projection, so while the card
        // is turning each face keeps a solid body; the glass fades back in once the turn has settled.
        let glass = reduceMotion ? 1 : self.glass
        DSFlipStack {
            DSFlipFace(style: style, padding: padding, cornerRadius: cornerRadius, glass: glass, content: front)
                .opacity(showingBack ? 0 : 1)
                .allowsHitTesting(!showingBack)
                .accessibilityHidden(showingBack)
            DSFlipFace(style: style, padding: padding, cornerRadius: cornerRadius, glass: glass, content: back)
                .rotation3DEffect(
                    .degrees(DSFlipMath.backPreRotation(reduceMotion: reduceMotion)),
                    axis: axis.vector
                )
                .opacity(showingBack ? 1 : 0)
                .allowsHitTesting(showingBack)
                .accessibilityHidden(!showingBack)
        }
        // nil in 3D: the swap must land on the 90 degree edge, never cross-fade over the spring.
        .animation(reduceMotion ? DSAnimation.fast : nil, value: showingBack)
        .rotation3DEffect(.degrees(turn), axis: axis.vector, perspective: perspective)
    }
}

// MARK: - Face

/// One side of the card: the same surfaces as `DSCard` (elevated, outlined, flat), but
/// with a solid layer under the glass whose weight is `1 - glass`. It fills the size the
/// stack gives it, so both faces share one frame.
private struct DSFlipFace<Content: View>: View {
    let style: DSCardStyle
    let padding: CGFloat
    let cornerRadius: CGFloat
    let glass: Double
    let content: Content

    @DSThemed private var theme

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { surface }
    }

    // Sequential handoff, so the body never dips through "neither": the glass fades in
    // over the still-opaque solid body (first half of `glass`), and only then does the
    // solid body fade out underneath it (second half).
    private var glassOpacity: Double { min(1, glass * 2) }
    private var solidOpacity: Double { 1 - max(0, glass * 2 - 1) }

    /// The body held while turning. Opaque, but the tone of the resting glass over the
    /// page (`backgroundSecondary`) rather than the white of `.solid`, so the handoff is a
    /// gentle tone shift, not a flash.
    private var turningBody: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return shape.fill(theme.palette.backgroundSecondary)
            .overlay { shape.strokeBorder(theme.washEdge, lineWidth: DSWash.edgeWidth) }
    }

    @ViewBuilder
    private var surface: some View {
        switch style {
        case .elevated:
            ZStack {
                turningBody.dsShadow(.md).opacity(solidOpacity)
                Color.clear.dsSurface(.glass, radius: cornerRadius).dsShadow(.md).opacity(glassOpacity)
            }
        case .outlined:
            ZStack {
                turningBody.opacity(solidOpacity)
                Color.clear.dsSurface(.glassThick, radius: cornerRadius).opacity(glassOpacity)
            }
        case .flat:
            // No material to lose: the wash is a flat fill already.
            Color.clear
                .background(theme.subtleFill)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

// MARK: - Equal-Size Stack

/// Lays both faces over each other at the size of the larger one, so the card keeps its
/// frame when it turns. Height is the larger natural height (a taller offer from the
/// parent never stretches it); each face is then proposed that exact size and fills it.
private struct DSFlipStack: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let natural = ProposedViewSize(width: proposal.width, height: nil)
        let sizes = subviews.map { $0.sizeThatFits(natural) }
        return CGSize(
            width: sizes.map(\.width).max() ?? 0,
            height: sizes.map(\.height).max() ?? 0
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            subview.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
        }
    }
}

// MARK: - Tap Modifier

/// Adds the tap-to-flip gesture and button semantics only when `enabled`, so a
/// card that flips from code keeps its faces' own hit testing and VoiceOver.
private struct DSFlipTapModifier: ViewModifier {
    let enabled: Bool
    let isFlipped: Bool
    let flip: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            // One element: the visible face reads as the label, and the value changes
            // on every turn so VoiceOver announces which side is showing.
            content
                .onTapGesture(perform: flip)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityValue(Text(isFlipped ? "Back side" : "Front side"))
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
            Image(systemName: icon).foregroundStyle(theme.style.accent)
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
