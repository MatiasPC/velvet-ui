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
// pop in `DSSuccessCheck`. The haptic lands on the peak of that pop, the way the
// seal's does; with no pop (turning off, or Reduce Motion) it fires on the tap.
//
// Why not `DSParticleField` or `dsConfetti`: the first is an emitter for a drag
// (a continuously ticking timeline of 1–2.5 pt motes that draws nothing under
// Reduce Transparency) and the second throws paper over the whole host with
// gravity for 2 s. Neither draws one filled disc that blooms and fades behind a
// 24 pt glyph, and a timeline per row would cost a feed a frame loop per like.
//
// Symbol-replace transition pattern adapted from the SF Symbols animation
// vocabulary (iOS 17 / SF Symbols 5): hackingwithswift.com and
// blakecrosley.com/blog/symbol-effects-vocabulary. The radiating halo is
// Velvet's own, built on the design-system halo rather than a particle system.

/// Timeline and geometry of the beat. Seconds from the tap that likes.
enum DSLikeButtonTimeline {
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

    /// The beat: the pop peaks, and the haptic fires with it.
    static var peak: Double { popRise }
    /// End of the whole choreography.
    static var total: Double { max(popRise + popSettle, haloDuration) }

    /// What a tap does.
    struct Plan: Equatable {
        /// Whether the pop and halo play.
        var pops: Bool
        /// Seconds after the tap that the haptic fires.
        var hapticDelay: Double
    }

    /// The pop and halo play only when liking, and never under Reduce Motion. The
    /// haptic rides the peak of the pop; with no pop it fires on the tap, so the
    /// control still confirms it.
    static func plan(turningOn: Bool, reduceMotion: Bool) -> Plan {
        guard turningOn, !reduceMotion else { return Plan(pops: false, hapticDelay: 0) }
        return Plan(pops: true, hapticDelay: peak)
    }

    /// VoiceOver value: "Liked" or "Not liked", with the count appended when present.
    static func accessibilityValue(isLiked: Bool, count: Int?) -> String {
        let state = isLiked ? "Liked" : "Not liked"
        guard let count else { return state }
        return "\(state), \(count)"
    }
}

private enum Metrics {
    /// Symbol glyph weight.
    static let symbolWeight: Font.Weight = .semibold
    /// Apple's 44pt minimum tap target, built from tokens rather than hardcoded:
    /// DSSpacing.xxl (32) + DSSpacing.sm (12) = 44.
    static let hitTarget: CGFloat = DSSpacing.xxl + DSSpacing.sm
    /// Opacity of a disabled control, the same as `DSToggle`.
    static let disabledOpacity: Double = 0.5
}

/// The transient part of the beat: a scale pop and a halo that grows and fades.
private struct DSLikePop {
    var scale: Double = 1
    var halo: Double = 0
}

/// A favorite / like / bookmark toggle with a springy pop and a radiating halo.
///
/// Bind it to a `Bool`. Tapping flips the binding; liking also plays the pop, the
/// halo and the symbol-replace transition, with the haptic on the peak of the pop.
/// Pass a `count` to show a value beside it that rolls when it changes. Swap
/// `symbol` and `emptySymbol` for a star, a bookmark or any filled/outline SF
/// Symbol pair, and pass a matching `accessibilityLabel`.
///
/// The beat belongs to the tap. Setting `isLiked` from code (restoring saved
/// state, a double-tap on a photo) swaps the symbol quietly, so a feed that loads
/// already-liked posts never pops or buzzes. The halo extends past `size`, so
/// leave a little room around it.
public struct DSLikeButton: View {
    @Binding private var isLiked: Bool
    private let count: Int?
    private let size: CGFloat
    private let symbol: String
    private let emptySymbol: String
    private let tint: Color?
    private let haptic: DSHapticStyle
    private let label: String

    /// Bumped once per tap that pops. Fires the keyframe track and the haptic task.
    @State private var pulse = 0
    @DSThemed private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - isLiked: The liked state. Tapping toggles it.
    ///   - count: An optional count shown beside the symbol; rolls with `.numericText` when it changes. `nil` hides it.
    ///   - size: Point size of the symbol. Defaults to `DSSpacing.xl` (24). The tap target is at least 44 pt whatever the size.
    ///   - symbol: The filled symbol shown while liked. Defaults to `"heart.fill"`.
    ///   - emptySymbol: The outline symbol shown while not liked. Defaults to `"heart"`.
    ///   - tint: Color while liked (and of the halo). Defaults to the theme accent.
    ///   - haptic: Fired on every tap, on the peak of the pop when liking. Defaults to `.soft`.
    ///   - accessibilityLabel: What VoiceOver reads for the control. Defaults to "Like".
    public init(
        isLiked: Binding<Bool>,
        count: Int? = nil,
        size: CGFloat = DSSpacing.xl,
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
                        .contentTransition(reduceMotion ? .identity : .numericText(value: Double(count)))
                        .animation(reduceMotion ? nil : DSAnimation.springSnappy, value: count)
                        .accessibilityHidden(true)
                }
            }
            .animation(stateAnimation, value: isLiked)
            .frame(minWidth: Metrics.hitTarget, minHeight: Metrics.hitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(DSLikeButtonStyle())
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
        .task(id: pulse) { await fireHapticOnPeak() }
        .accessibilityLabel(label)
        .accessibilityValue(DSLikeButtonTimeline.accessibilityValue(isLiked: isLiked, count: count))
        .accessibilityAddTraits(.isToggle)
    }

    // MARK: Glyph

    /// The symbol swap and the color are state: they hold their end value and ride a
    /// spring on `isLiked`. Under Reduce Motion the swap crossfades quickly instead.
    private var stateAnimation: Animation {
        reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy
    }

    private func glyph(likedColor: Color, restColor: Color) -> some View {
        // The keyframe closures are `@Sendable` and run off the view's actor, so they get
        // plain values and constants, never `self`.
        let liked = isLiked
        return Image(systemName: liked ? symbol : emptySymbol)
            .font(.system(size: size, weight: Metrics.symbolWeight))
            .foregroundStyle(liked ? likedColor : restColor)
            .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
            .keyframeAnimator(initialValue: DSLikePop(), trigger: pulse) { view, pop in
                // Gated on `liked`, so unliking mid-beat ends it on the spot: turning
                // off is quiet even if the pop of a quick like is still in flight.
                view
                    .scaleEffect(liked ? pop.scale : 1)
                    .background {
                        // A filled halo that flashes bright, then expands and fades.
                        // Rendered only while the burst is in flight, so nothing
                        // lingers behind the symbol at rest.
                        if liked && pop.halo > 0 {
                            Circle()
                                .fill(likedColor.opacity(DSLikeButtonTimeline.haloOpacity * (1 - pop.halo)))
                                .scaleEffect(DSLikeButtonTimeline.haloStartScale + DSLikeButtonTimeline.haloGrowth * pop.halo)
                                .allowsHitTesting(false)
                        }
                    }
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(DSLikeButtonTimeline.popScale, duration: DSLikeButtonTimeline.popRise)
                    // Same feel as DSAnimation.springBouncy (response 0.45, damping 0.5).
                    SpringKeyframe(1, duration: DSLikeButtonTimeline.popSettle, spring: Spring(response: 0.45, dampingRatio: 0.5))
                }
                KeyframeTrack(\.halo) {
                    CubicKeyframe(1, duration: DSLikeButtonTimeline.haloDuration)
                }
            }
    }

    // MARK: Behavior

    private func toggle() {
        let turningOn = !isLiked
        isLiked = turningOn
        let plan = DSLikeButtonTimeline.plan(turningOn: turningOn, reduceMotion: reduceMotion)
        if plan.pops {
            // One trigger, one track: the keyframe animator restarts rather than
            // stacking, and the haptic task below is replaced along with it.
            pulse += 1
        } else {
            DSHapticEngine.shared.fire(haptic)
        }
    }

    /// Waits for the peak of the pop, then fires the haptic, unless the button was
    /// turned off, tapped again or removed in the meantime (the task is cancelled
    /// when `pulse` changes or the view goes away).
    private func fireHapticOnPeak() async {
        guard pulse > 0 else { return }
        try? await Task.sleep(for: .seconds(DSLikeButtonTimeline.peak))
        guard !Task.isCancelled, isLiked else { return }
        DSHapticEngine.shared.fire(haptic)
    }
}

// MARK: - Button Style

private struct DSLikeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DSPress.iconScale : 1.0)
            .animation(DSPress.animation, value: configuration.isPressed)
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
