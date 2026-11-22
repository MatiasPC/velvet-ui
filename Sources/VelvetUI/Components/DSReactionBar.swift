import SwiftUI

// MARK: - Design System Reaction Bar
// A glass capsule of emoji reactions, the strip a messaging or social app shows
// over a long-pressed message, and the row a feedback card asks "how was it?"
// with. Press anywhere on it and slide: the emoji under the finger swells and
// rises, its neighbours swell a little less (a dock-style falloff), and a
// selection tick lands each time the finger crosses into a new emoji. Let go and
// that emoji is picked: it jumps and falls back, and an accent dot slides under
// it. Picking the selected emoji again takes the reaction back. Lift the finger
// well above or below the bar and nothing changes.
//
// Why these mechanisms: the magnification is a pure function of where the finger
// is, so it rides `DSAnimation.interactive` while the finger moves and springs
// home when it lifts. The jump is transient (it returns to rest), so it runs on
// one `keyframeAnimator` track fired by a trigger, like `DSLikeButton`'s pop; the
// dot is state, so it follows `selection` on a spring, whoever changed it. The
// beat belongs to the gesture: setting `selection` from code moves the dot
// quietly, with no jump and no haptic.
//
// Technique inspired by the "messenger reactions" / "jump and fall" studies in
// amosgyamfi/open-swiftui-animations (see docs/proposals/0002-motion-library.md,
// wave 2). Written from scratch on Velvet tokens; no upstream code is used.

/// The rules of the bar: which emoji a touch is over, how much each one swells,
/// and what a pick does. Pure, so tests can pin it without rendering.
enum DSReactionBarLogic {
    /// Scale of the emoji right under the finger.
    static let peakScale: CGFloat = 1.6
    /// The swell falls off to nothing this many cells away from the finger.
    static let reach: CGFloat = 1.75
    /// How far a swollen emoji rises, as a share of the growth it gained (in cells).
    static let liftFactor: CGFloat = 0.5
    /// A finger more than this many cells above or below the bar, or past either
    /// end, hovers nothing, so letting go there changes nothing.
    static let releaseSlack: CGFloat = 1.5

    /// The jump after a pick: how high it rises, and its scale at the top.
    static let jumpHeight: CGFloat = DSSpacing.md
    static let jumpScale: CGFloat = 1.2
    /// Seconds to the top of the jump, then for the fall back to rest.
    static let jumpRise: Double = 0.14
    static let jumpFall: Double = 0.36

    /// The emoji under a finger at `point`, measured from the top-leading corner of
    /// the first cell. A finger past the ends of the row is held on the end emoji,
    /// unless it is more than `releaseSlack` cells away, like one far above or
    /// below the bar: then `nil`, and letting go there cancels.
    static func index(at point: CGPoint, cell: CGFloat, count: Int, rowHeight: CGFloat) -> Int? {
        guard count > 0, cell > 0, point.x.isFinite, point.y.isFinite else { return nil }
        let slack = cell * releaseSlack
        let width = CGFloat(count) * cell
        guard point.y >= -slack, point.y <= rowHeight + slack,
              point.x >= -slack, point.x <= width + slack else { return nil }
        let raw = Int((point.x / cell).rounded(.down))
        return min(max(raw, 0), count - 1)
    }

    /// The scale of emoji `index` with the finger at `fingerX` (same space as
    /// `index(at:)`), or 1 with no finger. The finger is held between the centres
    /// of the end emoji, so the one at either end still reaches `peakScale`.
    static func scale(at index: Int, fingerX: CGFloat?, cell: CGFloat, count: Int) -> CGFloat {
        guard let fingerX, fingerX.isFinite, cell > 0, count > 0 else { return 1 }
        let half = cell / 2
        let x = min(max(fingerX, half), CGFloat(count) * cell - half)
        let distance = abs(x - (CGFloat(index) * cell + half)) / cell
        return 1 + (peakScale - 1) * max(0, 1 - distance / reach)
    }

    /// How far an emoji at `scale` rises, in points. Zero at rest.
    static func lift(forScale scale: CGFloat, cell: CGFloat) -> CGFloat {
        max(0, scale - 1) * cell * liftFactor
    }

    /// What picking `reaction` does: picks it, or takes it back if it was the reaction.
    static func picked(_ reaction: String, current: String?) -> String? {
        reaction == current ? nil : reaction
    }

    /// One VoiceOver swipe. Up moves to the next reaction (from none, the first;
    /// the last stays put); down moves to the previous one, and down from the
    /// first takes the reaction back. A selection that isn't in `reactions` reads
    /// as none.
    static func adjusted(_ current: String?, in reactions: [String], increment: Bool) -> String? {
        guard !reactions.isEmpty else { return current }
        let position = current.flatMap { reactions.firstIndex(of: $0) }
        if increment {
            guard let position else { return reactions[0] }
            return reactions[min(position + 1, reactions.count - 1)]
        }
        guard let position, position > 0 else { return nil }
        return reactions[position - 1]
    }

    /// The haptic a change of reaction earns: `.soft` for a pick, `.light` for
    /// taking it back, nothing when nothing changed.
    static func haptic(from old: String?, to new: String?) -> DSHapticStyle? {
        guard old != new else { return nil }
        return new == nil ? .light : .soft
    }

    /// Whether the picked emoji jumps: only for a new pick, and never under Reduce Motion.
    static func jumps(from old: String?, to new: String?, reduceMotion: Bool) -> Bool {
        new != nil && old != new && !reduceMotion
    }

    /// VoiceOver value: the emoji itself (VoiceOver speaks its name), or "None".
    static func accessibilityValue(_ selection: String?) -> String {
        selection ?? "None"
    }
}

/// One drag across the bar: the emoji under the finger and when a tick is due.
struct DSReactionBarTracker: Equatable {
    /// The emoji the finger is over, or `nil` when it is outside the bar.
    private(set) var hovered: Int?
    /// The finger's x while it hovers an emoji, for the swell.
    private(set) var fingerX: CGFloat?
    /// Whether a drag is in progress.
    private(set) var isTracking = false
    /// The last emoji the finger was over, kept while it is outside the bar.
    private var lastHovered: Int?

    /// Moves the finger. Returns `true` when it crossed into a different emoji
    /// than the last one it was over, which earns a selection tick. The first
    /// touch never ticks (the pick on release confirms it), and leaving the bar
    /// and coming back to the same emoji is silent.
    mutating func move(to index: Int?, x: CGFloat) -> Bool {
        let first = !isTracking
        isTracking = true
        hovered = index
        fingerX = index == nil ? nil : x
        guard let index else { return false }
        defer { lastHovered = index }
        return !first && lastHovered != nil && lastHovered != index
    }

    /// Ends the drag and returns the emoji to pick, if the finger was over one.
    mutating func end() -> Int? {
        let picked = hovered
        self = DSReactionBarTracker()
        return picked
    }
}

private enum Metrics {
    /// One emoji's cell: Apple's 44 pt target, from tokens (32 + 12).
    static let cell: CGFloat = DSSpacing.xxl + DSSpacing.sm
    /// Inset between the cells and the capsule's edge.
    static let inset: CGFloat = DSSpacing.xxs
    /// The selected-reaction dot.
    static let dot: CGFloat = DSSpacing.xxs
    /// Gap between the dot and the bottom of the cell.
    static let dotGap: CGFloat = DSSpacing.xxxs
    /// Opacity of a disabled bar, the same as `DSToggle`.
    static let disabledOpacity: Double = 0.5
}

/// The transient part of a pick: a jump up with a little swell, then a fall back.
private struct DSReactionJump {
    var lift: CGFloat = 0
    var scale: CGFloat = 1
}

/// A glass capsule of emoji reactions. Press and slide to scrub across them, let
/// go to pick one.
///
/// Bind it to a `String?`: the picked emoji, or `nil` for no reaction. Picking the
/// selected emoji again sets it back to `nil`. The emoji under the finger swells
/// and rises with its neighbours, a tick lands on each new emoji, and the pick
/// jumps and falls back while an accent dot slides under it. Letting go well
/// above or below the bar cancels.
///
/// Show it where your app asks for a reaction: over a long-pressed message, under
/// a post, or in a feedback card with your own scale (`["😡", "🙁", "😐", "🙂", "😍"]`).
/// Keep the list short (up to about seven) so it fits a phone at large text sizes.
/// The swollen emoji rise above the capsule, so leave a little room over it.
///
/// ```swift
/// @State private var reaction: String?
///
/// DSReactionBar(selection: $reaction)
/// ```
public struct DSReactionBar: View {
    /// 👍 ❤️ 😂 😮 😢 🙏
    public static let defaultReactions: [String] = ["👍", "❤️", "😂", "😮", "😢", "🙏"]

    @Binding private var selection: String?
    private let reactions: [String]
    private let accent: Color?
    private let label: String

    // MARK: State

    @State private var tracker = DSReactionBarTracker()
    /// Bumped once per pick that jumps. Fires the keyframe track.
    @State private var jump = 0
    /// Whether the finger is on the bar. A `GestureState`, so it also clears when
    /// the system cancels the touch without calling `onEnded`.
    @GestureState private var isPressing = false
    @ScaledMetric(relativeTo: .largeTitle) private var cell: CGFloat = Metrics.cell
    @Namespace private var namespace

    @DSThemed private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - selection: The picked emoji, or `nil` for none. A pick sets it; picking it again clears it.
    ///   - reactions: The emoji to offer, in order. Defaults to `DSReactionBar.defaultReactions`.
    ///   - accent: Color of the dot under the picked emoji. Defaults to the theme accent.
    ///   - accessibilityLabel: What VoiceOver calls the bar. Defaults to "Reaction".
    public init(
        selection: Binding<String?>,
        reactions: [String] = DSReactionBar.defaultReactions,
        accent: Color? = nil,
        accessibilityLabel: String = "Reaction"
    ) {
        self._selection = selection
        self.reactions = reactions
        self.accent = accent
        self.label = accessibilityLabel
    }

    // MARK: Body

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(reactions.indices, id: \.self) { index in
                emoji(at: index)
            }
        }
        .padding(Metrics.inset)
        .background {
            Color.clear
                .dsSurface(.glass, radius: DSRadius.chip)
                .dsShadow(.md)
        }
        .animation(reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy, value: selection)
        .contentShape(Capsule(style: .continuous))
        .gesture(dragGesture, including: isEnabled ? .all : .none)
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
        .onChange(of: isPressing) { _, pressing in
            // A touch the system took away never reaches `onEnded`: settle without picking.
            if !pressing && tracker.isTracking {
                withAnimation(motion(DSAnimation.springSnappy)) { _ = tracker.end() }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(DSReactionBarLogic.accessibilityValue(selection))
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            switch direction {
            case .increment: adjust(increment: true)
            case .decrement: adjust(increment: false)
            @unknown default: break
            }
        }
    }

    // MARK: Emoji

    private func emoji(at index: Int) -> some View {
        let reaction = reactions[index]
        let isSelected = reaction == selection
        let swell = reduceMotion ? 1 : DSReactionBarLogic.scale(
            at: index, fingerX: tracker.fingerX, cell: cell, count: reactions.count
        )
        let rise = DSReactionBarLogic.lift(forScale: swell, cell: cell)
        let isHovered = tracker.hovered == index
        let dotColor = accent ?? theme.accent

        return Text(reaction)
            .dsFont(.largeTitle)
            .lineLimit(1)
            .fixedSize()
            .scaleEffect(swell, anchor: .bottom)
            .offset(y: -rise)
            .keyframeAnimator(initialValue: DSReactionJump(), trigger: jump) { view, pop in
                // Gated on the selection, so only the emoji just picked jumps. The
                // closure is `@Sendable`, so it reads a captured `Bool`, not `self`.
                view
                    .scaleEffect(isSelected ? pop.scale : 1, anchor: .bottom)
                    .offset(y: isSelected ? -pop.lift : 0)
            } keyframes: { _ in
                KeyframeTrack(\.lift) {
                    CubicKeyframe(DSReactionBarLogic.jumpHeight, duration: DSReactionBarLogic.jumpRise)
                    // Same feel as DSAnimation.springBouncy (response 0.45, damping 0.5).
                    SpringKeyframe(0, duration: DSReactionBarLogic.jumpFall, spring: Spring(response: 0.45, dampingRatio: 0.5))
                }
                KeyframeTrack(\.scale) {
                    CubicKeyframe(DSReactionBarLogic.jumpScale, duration: DSReactionBarLogic.jumpRise)
                    SpringKeyframe(1, duration: DSReactionBarLogic.jumpFall, spring: Spring(response: 0.45, dampingRatio: 0.5))
                }
            }
            .frame(width: cell, height: cell)
            .background {
                // Under Reduce Motion nothing swells, so a flat wash shows the hover.
                if reduceMotion && isHovered {
                    Circle().fill(theme.subtleFill)
                }
            }
            .overlay(alignment: .bottom) {
                if isSelected {
                    Circle()
                        .fill(dotColor)
                        .frame(width: Metrics.dot, height: Metrics.dot)
                        .matchedGeometryEffect(id: "dot", in: namespace)
                        .padding(.bottom, Metrics.dotGap)
                        .transition(.opacity)
                }
            }
            .zIndex(Double(swell))
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isPressing) { _, state, _ in state = true }
            .onChanged { gesture in
                guard isEnabled else { return }
                let point = CGPoint(x: gesture.location.x - Metrics.inset, y: gesture.location.y - Metrics.inset)
                let index = DSReactionBarLogic.index(at: point, cell: cell, count: reactions.count, rowHeight: cell)
                let ticks = withAnimation(motion(DSAnimation.interactive)) {
                    tracker.move(to: index, x: point.x)
                }
                if ticks { DSHapticEngine.shared.fire(.selection) }
            }
            .onEnded { _ in
                let picked = withAnimation(motion(DSAnimation.springSnappy)) { tracker.end() }
                guard isEnabled, let picked, reactions.indices.contains(picked) else { return }
                pick(reactions[picked])
            }
    }

    // MARK: Behavior

    /// A pick from the gesture: sets or clears the selection, buzzes, and jumps.
    private func pick(_ reaction: String) {
        let old = selection
        let new = DSReactionBarLogic.picked(reaction, current: old)
        selection = new
        if let haptic = DSReactionBarLogic.haptic(from: old, to: new) {
            DSHapticEngine.shared.fire(haptic)
        }
        if DSReactionBarLogic.jumps(from: old, to: new, reduceMotion: reduceMotion) {
            jump += 1
        }
    }

    /// The VoiceOver adjustable action: steps through the reactions, no jump.
    private func adjust(increment: Bool) {
        let new = DSReactionBarLogic.adjusted(selection, in: reactions, increment: increment)
        guard new != selection else { return }
        selection = new
        DSHapticEngine.shared.fire(.selection)
    }

    /// `animation`, or none under Reduce Motion.
    private func motion(_ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

// MARK: - Preview

#if DEBUG
private struct DSReactionBarPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var reaction: String? = "❤️"
    @State private var mood: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    DSReactionBar(selection: $reaction)
                    Text("Dinner at eight? I booked the place by the river.")
                        .ds(.body)
                        .padding(DSSpacing.md)
                        .dsSurface(.glass, radius: DSRadius.card)
                    Text(reaction.map { "You reacted \($0)" } ?? "No reaction")
                        .ds(.footnote, color: DSColors.textSecondary)
                }
                .padding(.top, DSSpacing.xl)

                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        Text("How was your ride?").ds(.title3)
                        DSReactionBar(selection: $mood, reactions: ["😡", "🙁", "😐", "🙂", "😍"],
                                      accessibilityLabel: "Ride rating")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("ReactionBar — Light") {
    DSReactionBarPreviewHost().preferredColorScheme(.light)
}

#Preview("ReactionBar — Dark") {
    DSReactionBarPreviewHost().preferredColorScheme(.dark)
}
#endif
