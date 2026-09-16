import SwiftUI

// MARK: - Design System Like Button
// The tap-to-favourite micro-interaction every social, commerce and media app
// reaches for — a heart that fills, pops and throws off a ring of sparks. It is
// the interactive counterpart to `DSBadge` (static) and to the drag-only,
// internal `DSParticleField`: a single, self-contained, list-safe gesture.
//
// Three motions play off one tap, each on a native SF Symbol / keyframe API so
// there is no bespoke animation engine to maintain:
//
//   1. **Swap** — `.contentTransition(.symbolEffect(.replace))` morphs the
//      outline symbol into its filled twin instead of hard-cutting.
//   2. **Pop**  — `.symbolEffect(.bounce)` gives the glyph a spring on like.
//   3. **Spark** — a one-shot `keyframeAnimator` ring flings light outward and
//      fades it, then holds a resting value and stops. No `TimelineView`, so a
//      feed of a hundred of these costs nothing while idle.
//
// Colour comes from the theme (`accent` when liked, `textSecondary` at rest),
// haptics fire inside the component, and Reduce Motion drops the pop and the
// sparks while keeping the swap — the state change is never hidden.

public struct DSLikeButton: View {

    // MARK: - Shaping

    /// Size-relative multipliers for the burst. These are motion-shaping ratios,
    /// not layout — there is no spacing token for "how big is a spark" — so they
    /// live here, tuned by eye against the symbol they ring (cf. DSParticleField).
    private enum Metrics {
        /// Spark diameter as a fraction of the symbol point size.
        static let sparkRatio: CGFloat = 0.14
        /// How far a spark travels from centre, as a fraction of the symbol size.
        static let travelRatio: CGFloat = 0.9
        /// Sparks in the ring. Evenly spaced, so 8 reads as a burst, not a clock.
        static let sparkCount: Int = 8
        /// One burst's length. Short enough to read as a pop, not an animation.
        static let burstDuration: Double = 0.55
    }

    // MARK: - Configuration

    @Binding var isLiked: Bool
    let filledSymbol: String
    let outlineSymbol: String
    let size: CGFloat
    let likedColor: Color?
    let haptic: DSHapticStyle
    let accessibilityLabel: String

    // MARK: - State

    /// Bumped on every *like* (never on unlike). Drives both the glyph bounce and
    /// the spark ring, so the two fire from one source and can never desync.
    @State private var likeTick = 0

    @DSThemed private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - isLiked: The liked state. Toggled on tap.
    ///   - filledSymbol: SF Symbol shown when liked. Defaults to `heart.fill`.
    ///   - outlineSymbol: SF Symbol shown at rest. Defaults to `heart`.
    ///   - size: Symbol point size. Defaults to 28.
    ///   - likedColor: Fill + spark colour when liked. Defaults to the theme accent.
    ///   - haptic: Fired on every tap. Defaults to `.light`.
    ///   - accessibilityLabel: VoiceOver label. Defaults to "Like".
    public init(
        isLiked: Binding<Bool>,
        filledSymbol: String = "heart.fill",
        outlineSymbol: String = "heart",
        size: CGFloat = 28,
        likedColor: Color? = nil,
        haptic: DSHapticStyle = .light,
        accessibilityLabel: String = "Like"
    ) {
        self._isLiked = isLiked
        self.filledSymbol = filledSymbol
        self.outlineSymbol = outlineSymbol
        self.size = size
        self.likedColor = likedColor
        self.haptic = haptic
        self.accessibilityLabel = accessibilityLabel
    }

    // MARK: - Body

    private var likedFill: Color { likedColor ?? theme.accent }

    public var body: some View {
        Button(action: tap) {
            Image(systemName: isLiked ? filledSymbol : outlineSymbol)
                .font(.system(size: size))
                .foregroundStyle(isLiked ? likedFill : theme.palette.textSecondary)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: likeTick)
                .overlay {
                    if !reduceMotion {
                        DSLikeBurst(
                            trigger: likeTick,
                            tint: likedFill,
                            diameter: size * Metrics.sparkRatio,
                            travel: size * Metrics.travelRatio,
                            count: Metrics.sparkCount,
                            duration: Metrics.burstDuration
                        )
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityValue(isLiked ? Text("Liked") : Text("Not liked"))
        .accessibilityAddTraits(isLiked ? .isSelected : [])
    }

    // MARK: - Interaction

    private func tap() {
        guard isEnabled else { return }
        let nowLiked = !isLiked

        // Reduce Motion keeps the swap (state must stay visible) but drops the
        // springy overshoot, so the glyph changes without travelling.
        withAnimation(reduceMotion ? DSAnimation.micro : DSAnimation.springSnappy) {
            isLiked = nowLiked
        }

        // Sparks and bounce are a *reward* for liking; unliking is a quiet undo.
        if nowLiked && !reduceMotion {
            likeTick += 1
        }
        DSHapticEngine.shared.fire(nowLiked ? haptic : .soft)
    }
}

// MARK: - Spark Ring

/// A one-shot ring of light thrown outward from centre on every `trigger` change.
///
/// One continuous `keyframeAnimator` track, like `DSJiggleModifier`: each tick
/// replays the whole `0 → 1` progress from `initialValue`, then rests at `1`
/// where the sparks have flown out and faded to nothing. Between taps the track
/// holds that resting value and does no work — there is no `TimelineView` here,
/// so the button is free to live in a scrolling list.
private struct DSLikeBurst: View {
    let trigger: Int
    let tint: Color
    let diameter: CGFloat
    let travel: CGFloat
    let count: Int
    let duration: Double

    var body: some View {
        Color.clear
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, progress in
                view.overlay { ring(progress: progress) }
            } keyframes: { _ in
                LinearKeyframe(1.0, duration: duration)
            }
            .allowsHitTesting(false)
    }

    /// Sparks sit on a circle and slide out along their own angle as `progress`
    /// runs `0 → 1`. Opacity is a `sin(π·progress)` arc — zero at both ends, so a
    /// spark fades in as it leaves and is gone before the track rests — and each
    /// shrinks slightly on the way out, which reads as receding rather than
    /// vanishing in place.
    private func ring(progress: Double) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                let angle = (Double(index) / Double(count)) * 2 * .pi
                let reach = travel * CGFloat(progress)
                Circle()
                    .fill(tint)
                    .frame(width: diameter, height: diameter)
                    .scaleEffect(1 - 0.5 * CGFloat(progress))
                    .opacity(sin(progress * .pi))
                    .offset(
                        x: CGFloat(cos(angle)) * reach,
                        y: CGFloat(sin(angle)) * reach
                    )
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSLikeButtonPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var liked = false
    @State private var starred = true
    @State private var saved = false
    @State private var likeCount = 128

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                // Default heart, wired to a live count — the canonical use.
                DSCard {
                    HStack(spacing: DSSpacing.md) {
                        DSLikeButton(isLiked: $liked)
                            .onChange(of: liked) { _, isLiked in
                                likeCount += isLiked ? 1 : -1
                            }
                        DSAnimatedNumber(value: Double(likeCount), style: .title2)
                        Spacer()
                        Text("Tap the heart").ds(.callout, color: DSColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Symbol variants: works for any outline/fill SF Symbol pair.
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSLikeButton(
                            isLiked: $starred,
                            filledSymbol: "star.fill",
                            outlineSymbol: "star",
                            likedColor: DSColors.warning,
                            accessibilityLabel: "Favourite"
                        )
                        DSLikeButton(
                            isLiked: $saved,
                            filledSymbol: "bookmark.fill",
                            outlineSymbol: "bookmark",
                            likedColor: DSColors.secondary,
                            haptic: .medium,
                            accessibilityLabel: "Save"
                        )
                        DSLikeButton(
                            isLiked: $liked,
                            filledSymbol: "hand.thumbsup.fill",
                            outlineSymbol: "hand.thumbsup"
                        )
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Sizes + disabled.
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSLikeButton(isLiked: $starred, size: 20)
                        DSLikeButton(isLiked: $starred, size: 32)
                        DSLikeButton(isLiked: $starred, size: 44)
                        DSLikeButton(isLiked: .constant(true))
                            .disabled(true)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Like Button — Light") {
    DSLikeButtonPreviewHost().preferredColorScheme(.light)
}

#Preview("Like Button — Dark") {
    DSLikeButtonPreviewHost().preferredColorScheme(.dark)
}
#endif
