import SwiftUI

// MARK: - Design System Like Button
// A favorite / like / bookmark toggle with a satisfying beat. On the way *in*
// the symbol swaps to its filled variant with a designed SF Symbols transition,
// springs up in a quick pop, and a single soft halo radiates out and fades —
// the same filled-halo mechanism as `DSSuccessCheck`, so it reads as light, not
// as a border. An optional count rolls with `.numericText`. Turning it *off* is
// quiet: the symbol swaps back, no pop, no halo.
//
// Why these mechanisms: the symbol swap and the color are plain state changes —
// they have to *hold* their end value — so they ride a `DSAnimation` spring on
// `isLiked`. The pop and the halo are transient (they return to rest), so they
// run on one `keyframeAnimator` track fired by a trigger, exactly like the seal
// pop in `DSSuccessCheck`. The pop plays only when liking and never under Reduce
// Motion; the haptic always fires so the control still confirms the tap.
//
// Symbol-replace transition pattern adapted from the SF Symbols animation
// vocabulary (iOS 17 / SF Symbols 5): hackingwithswift.com and
// blakecrosley.com/blog/symbol-effects-vocabulary. The radiating burst is
// Velvet's own, built on the design-system halo rather than a particle system.

/// Pop geometry and timing. Seconds from the moment the button becomes liked.
private enum DSLikeMetrics {
    /// Symbol glyph weight.
    static let symbolWeight: Font.Weight = .semibold
    /// Scale at the peak of the pop.
    static let popScale: Double = 1.28
    /// The pop climbs to its peak over this long.
    static let popRise: Double = 0.13
    /// The pop springs back to rest over this long (matches `springBouncy`).
    static let popSettle: Double = 0.30
    /// Peak opacity of the halo, at the start of the burst.
    static let haloOpacity: Double = 0.35
    /// The halo starts at this fraction of the symbol box and grows outward.
    static let haloStartScale: Double = 0.85
    /// Added to the start scale across the burst — final scale ≈ start + growth.
    static let haloGrowth: Double = 1.35
    /// How long the halo expands and fades.
    static let haloDuration: Double = 0.42
}

/// The transient part of the beat: a scale pop and a halo that grows and fades.
private struct DSLikePop {
    var scale: Double = 1
    var halo: Double = 0
}

/// A favorite / like / bookmark toggle with a springy pop and a radiating halo.
///
/// Bind it to a `Bool`. Tapping flips the binding and fires the haptic; liking
/// also plays the pop, the halo and the symbol-replace transition. Pass a
/// `count` to show a value beside it that rolls when it changes. Swap `symbol`
/// and `emptySymbol` for a star, a bookmark or any filled/outline SF Symbol pair.
public struct DSLikeButton: View {
    @Binding private var isLiked: Bool
    private let count: Int?
    private let size: CGFloat
    private let symbol: String
    private let emptySymbol: String
    private let tint: Color?
    private let haptic: DSHapticStyle
    private let label: String

    @State private var pulse = 0
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - isLiked: The liked state. Tapping toggles it.
    ///   - count: An optional count shown beside the symbol; rolls with `.numericText` when it changes. `nil` hides it.
    ///   - size: Point size of the symbol. Defaults to 24.
    ///   - symbol: The filled symbol shown while liked. Defaults to `"heart.fill"`.
    ///   - emptySymbol: The outline symbol shown while not liked. Defaults to `"heart"`.
    ///   - tint: Color while liked (and of the halo). Defaults to the theme accent.
    ///   - haptic: Fired on every tap. Defaults to `.soft`.
    ///   - accessibilityLabel: What VoiceOver reads for the control. Defaults to "Like".
    public init(
        isLiked: Binding<Bool>,
        count: Int? = nil,
        size: CGFloat = 24,
        symbol: String = "heart.fill",
        emptySymbol: String = "heart",
        tint: Color? = nil,
        haptic: DSHapticStyle = .soft,
        accessibilityLabel: String = "Like"
    ) {
        self._isLiked = isLiked
        self.count = count
        self.size = size
        self.symbol = symbol
        self.emptySymbol = emptySymbol
        self.tint = tint
        self.haptic = haptic
        self.label = accessibilityLabel
    }

    public var body: some View {
        let likedColor = tint ?? theme.accent
        let restColor = theme.palette.textSecondary

        Button(action: toggle) {
            HStack(spacing: DSSpacing.xs) {
                glyph(likedColor: likedColor, restColor: restColor)

                if let count {
                    Text(count, format: .number)
                        .ds(.numeric, color: isLiked ? likedColor : restColor)
                        .contentTransition(.numericText(value: Double(count)))
                        .animation(DSAnimation.springSnappy, value: count)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isLiked ? .isSelected : [])
    }

    // MARK: Glyph

    private func glyph(likedColor: Color, restColor: Color) -> some View {
        Image(systemName: isLiked ? symbol : emptySymbol)
            .font(.system(size: size, weight: DSLikeMetrics.symbolWeight))
            .foregroundStyle(isLiked ? likedColor : restColor)
            .contentTransition(.symbolEffect(.replace))
            .animation(DSAnimation.springSnappy, value: isLiked)
            .keyframeAnimator(initialValue: DSLikePop(), trigger: pulse) { view, pop in
                view
                    .scaleEffect(pop.scale)
                    .background { halo(color: likedColor, pop: pop) }
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(DSLikeMetrics.popScale, duration: DSLikeMetrics.popRise)
                    // Same feel as DSAnimation.springBouncy (response 0.45, damping 0.5).
                    SpringKeyframe(1, duration: DSLikeMetrics.popSettle, spring: Spring(response: 0.45, dampingRatio: 0.5))
                }
                KeyframeTrack(\.halo) {
                    CubicKeyframe(1, duration: DSLikeMetrics.haloDuration)
                }
            }
    }

    /// A filled halo that flashes bright, then expands and fades. Rendered only
    /// while the burst is in flight, so nothing lingers behind the symbol at rest.
    @ViewBuilder
    private func halo(color: Color, pop: DSLikePop) -> some View {
        if pop.halo > 0 {
            Circle()
                .fill(color.opacity(DSLikeMetrics.haloOpacity * (1 - pop.halo)))
                .scaleEffect(DSLikeMetrics.haloStartScale + DSLikeMetrics.haloGrowth * pop.halo)
                .allowsHitTesting(false)
        }
    }

    // MARK: Behavior

    private func toggle() {
        let nowLiked = !isLiked
        isLiked = nowLiked
        DSHapticEngine.shared.fire(haptic)
        // The pop and halo play on the way in only, and never under Reduce Motion.
        if nowLiked && !reduceMotion {
            pulse += 1
        }
    }

    private var accessibilityValue: String {
        let state = isLiked ? "Liked" : "Not liked"
        if let count { return "\(state), \(count)" }
        return state
    }
}

// MARK: - Preview

#if DEBUG
private struct DSLikeButtonPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var liked = false
    @State private var saved = true
    @State private var starred = false
    @State private var postLiked = false
    @State private var postCount = 128

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        Text("Tap to like").ds(.title3)
                        HStack(spacing: DSSpacing.xl) {
                            DSLikeButton(isLiked: $liked, accessibilityLabel: "Like")
                            DSLikeButton(isLiked: $starred, symbol: "star.fill", emptySymbol: "star",
                                         tint: DSColors.warning, accessibilityLabel: "Favorite")
                            DSLikeButton(isLiked: $saved, size: 22, symbol: "bookmark.fill",
                                         emptySymbol: "bookmark", accessibilityLabel: "Save")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard(padding: 0) {
                    DSListCell(title: "Weekend in Lisbon", subtitle: "\(postCount) people like this") {
                        Image(systemName: "mappin.circle")
                    } trailing: {
                        DSLikeButton(
                            isLiked: $postLiked,
                            count: postCount,
                            accessibilityLabel: "Like post"
                        )
                    }
                }
                .onChange(of: postLiked) { _, liked in
                    postCount += liked ? 1 : -1
                }

                Text("Large, for a detail screen").ds(.footnote, color: DSColors.textSecondary)
                DSLikeButton(isLiked: $liked, count: liked ? 1 : 0, size: 40)
                    .frame(maxWidth: .infinity)
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("LikeButton — Light") {
    DSLikeButtonPreviewHost().preferredColorScheme(.light)
}

#Preview("LikeButton — Dark") {
    DSLikeButtonPreviewHost().preferredColorScheme(.dark)
}
#endif
