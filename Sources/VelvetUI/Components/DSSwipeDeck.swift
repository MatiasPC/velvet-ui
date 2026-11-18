import SwiftUI

// MARK: - Design System Swipe Deck
// A stack of cards to decide on one at a time: drag the top card right or left
// past the line (or flick it) and it flies off that way; let go short of the line
// and it springs back. Dating and recipe pickers, flashcards ("Again" / "Got it"),
// inbox or photo triage ("Keep" / "Archive"), onboarding interests.
//
// Two cards wait behind the top one, each a step smaller and a step lower so
// their bottom edges fan out below it. As the top card nears the line, the one
// behind grows into its place, so when the top card leaves nothing jumps: the
// deck is already in its next state. A chip with the direction's label
// ("Like" / "Pass") fades in on the side the card is leaving from.
//
// Cards are solid (`.solid` surface, `DSRadius.card`), not glass: stacked glass
// shows every card through the one above it and turns muddy.
//
// Motion: the top card follows the finger 1:1 with no animation and leans up to
// 12° around its bottom edge. Release springs back on `springSnappy`, a commit
// flies out on `springSnappy` and the stack settles on `springSmooth`. Crossing
// the line fires one `.selection` tick (re-armed when the card comes back), and
// the commit fires `haptic`. Under Reduce Motion the card neither leans nor flies
// out: it follows the finger, and a commit fades it where it is.
//
// VoiceOver reads the top card's content as one element, with the number of
// cards left as its value and the two directions as actions ("Like", "Pass"),
// so nobody has to drag. Every card behind it is hidden.
//
// Technique: the drag-to-decide card stack common to SwiftUI tutorials (Kavsoft,
// Sarunw's DragGesture articles), rewritten on Velvet tokens, springs and haptics,
// with the commit rules in a pure `DSSwipeDeckLogic` so they can be tested.

/// Which way a card left the deck. Physical, so it doesn't flip in right-to-left layouts:
/// it's the way the finger moved.
public enum DSSwipeDirection: String, CaseIterable, Sendable {
    case left
    case right
}

// MARK: - Logic

/// The rules behind `DSSwipeDeck`, kept out of the generic view so they can be tested.
/// Distances are in points along the horizontal axis; `width` is the deck's width.
enum DSSwipeDeckLogic {
    /// The commit line, as a fraction of the width: past it, letting go commits.
    static let commitFraction: CGFloat = 0.4
    /// A flick commits when the predicted end of the drag lands this far out
    /// (fraction of the width)…
    static let flingFraction: CGFloat = 1
    /// …and the card has already moved at least this far (fraction of the width)
    /// the same way, so a tap with a twitch never throws a card.
    static let flingMinimumFraction: CGFloat = 0.1
    /// Lean, in degrees, when the card has travelled a full width.
    static let maxLean: Double = 12
    /// A leaving card ends this many widths out, well past the edge with its lean.
    static let exitFraction: CGFloat = 1.6
    /// The card follows vertical drag at this fraction, so it feels loose without wandering.
    static let verticalFollow: CGFloat = 0.25
    /// Cards drawn at once: the top card and two behind it.
    static let visibleDepth = 3
    /// Each step back, a card is this much smaller…
    static let scaleStep: CGFloat = 0.05
    /// …and this much lower: DSSpacing.sm (12).
    static let offsetStep: CGFloat = DSSpacing.sm

    /// Room under the top card for the fanned edges of the cards behind it.
    static var stackRoom: CGFloat { offsetStep * CGFloat(visibleDepth - 1) }

    /// How many cards to draw for a deck of `count`.
    static func visibleCount(_ count: Int) -> Int {
        max(0, min(count, visibleDepth))
    }

    /// The way a horizontal distance points, or `nil` for none.
    static func direction(of x: CGFloat) -> DSSwipeDirection? {
        guard x.isFinite else { return nil }
        if x > 0 { return .right }
        if x < 0 { return .left }
        return nil
    }

    /// Signed progress toward the commit line: 0 at rest, ±1 on the line and beyond.
    static func progress(translation: CGFloat, width: CGFloat) -> Double {
        let line = width * commitFraction
        guard line > 0, translation.isFinite else { return 0 }
        return Double(max(-1, min(1, translation / line)))
    }

    /// True once the card is on or past the commit line. Drives the one `.selection` tick.
    static func isArmed(translation: CGFloat, width: CGFloat) -> Bool {
        abs(progress(translation: translation, width: width)) >= 1
    }

    /// What letting go does: a direction to commit, or `nil` to spring back.
    /// Past the line commits that way. Short of it, a flick commits when its predicted
    /// end is far enough out, the card already moved that way, and both agree.
    static func decision(translation: CGFloat, predicted: CGFloat, width: CGFloat) -> DSSwipeDirection? {
        guard width > 0, let moved = direction(of: translation) else { return nil }
        if abs(translation) >= width * commitFraction { return moved }
        guard predicted.isFinite,
              abs(translation) >= width * flingMinimumFraction,
              abs(predicted) >= width * flingFraction,
              direction(of: predicted) == moved
        else { return nil }
        return moved
    }

    /// Lean in degrees for a drag: follows the card out to `maxLean` at a full width.
    static func lean(translation: CGFloat, width: CGFloat) -> Double {
        guard width > 0, translation.isFinite else { return 0 }
        return Double(max(-1, min(1, translation / width))) * maxLean
    }

    /// Where a leaving card ends up, horizontally.
    static func exitOffset(_ direction: DSSwipeDirection, width: CGFloat) -> CGFloat {
        let distance = max(width, offsetStep) * exitFraction
        return direction == .right ? distance : -distance
    }

    /// How far back a card sits: 0 for the top card. The card behind moves forward as
    /// the top card nears the line, so it is already in place when that one leaves.
    static func depth(index: Int, progress: Double) -> Double {
        guard index > 0 else { return 0 }
        return max(0, Double(index) - min(1, abs(progress)))
    }

    /// Scale for a card at `depth` (anchored at its bottom edge).
    static func scale(depth: Double) -> CGFloat {
        max(0, 1 - scaleStep * CGFloat(depth))
    }

    /// Downward offset for a card at `depth`.
    static func offset(depth: Double) -> CGFloat {
        offsetStep * CGFloat(depth)
    }

    /// VoiceOver value of the top card.
    static func accessibilityValue(remaining: Int) -> String {
        remaining == 1 ? "1 card left" : "\(max(0, remaining)) cards left"
    }

    /// Announced after a card leaves, so a VoiceOver user hears what happened and what's next.
    static func announcement(label: String, remaining: Int) -> String {
        remaining > 0 ? "\(label). \(accessibilityValue(remaining: remaining))" : "\(label). No cards left"
    }
}

private enum Metrics {
    /// A drag starts after this much movement, so taps on buttons inside a card still land.
    static let dragStart: CGFloat = DSSpacing.xs
    /// The direction chip grows from this scale to full size as the card nears the line.
    static let chipStartScale: CGFloat = 0.8
}

// MARK: - Swipe Deck

/// A stack of cards to decide on one at a time: swipe the top card right or left.
///
/// Bind it to an array. The first element is the top card. When a card is swiped away
/// the deck removes it from the binding and calls `onSwipe` with the card and the
/// direction, so you only record the decision. Insert at index 0 to bring a card back
/// (undo) and append to refill; both animate. Give the deck a size (a frame or an
/// aspect ratio): every card fills it.
///
/// Cards are drawn on a solid surface clipped to `DSRadius.card`; the content is yours,
/// so pad it yourself and let photos run to the edge. Put the deck outside a vertical
/// `ScrollView`, or the scroll and the drag fight over the same touch.
public struct DSSwipeDeck<Item: Identifiable, Content: View>: View {
    @Binding private var items: [Item]
    private let leftLabel: String
    private let rightLabel: String
    private let haptic: DSHapticStyle
    private let onSwipe: (Item, DSSwipeDirection) -> Void
    private let content: (Item) -> Content

    /// The top card's drag, or its exit while it flies out.
    @State private var drag: CGSize = .zero
    @State private var width: CGFloat = 0
    /// The card that is leaving; no drag or action starts until it's gone.
    @State private var leaving: Item.ID?
    /// On or past the commit line: the `.selection` tick fires once per crossing.
    @State private var armed = false
    /// True while a finger is down. Resets on end *and* on cancel, which `onEnded`
    /// alone misses, so a card can never be left hanging mid-drag.
    @GestureState private var isTouching = false

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - items: The cards, top card first. A swiped card is removed from it.
    ///   - leftLabel: The left swipe's name, on its chip and as a VoiceOver action. Defaults to "Pass".
    ///   - rightLabel: The right swipe's name, on its chip and as a VoiceOver action. Defaults to "Like".
    ///   - haptic: Fired when a card leaves. Defaults to `.medium`.
    ///   - onSwipe: Called after a card has left and been removed, with that card and the direction.
    ///   - content: One card's content. It fills the card; pad it yourself.
    public init(
        _ items: Binding<[Item]>,
        leftLabel: String = "Pass",
        rightLabel: String = "Like",
        haptic: DSHapticStyle = .medium,
        onSwipe: @escaping (Item, DSSwipeDirection) -> Void = { _, _ in },
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self._items = items
        self.leftLabel = leftLabel
        self.rightLabel = rightLabel
        self.haptic = haptic
        self.onSwipe = onSwipe
        self.content = content
    }

    public var body: some View {
        let visible = Array(items.prefix(DSSwipeDeckLogic.visibleCount(items.count)))
        let progress = DSSwipeDeckLogic.progress(translation: drag.width, width: width)

        ZStack {
            ForEach(Array(visible.enumerated()), id: \.element.id) { pair in
                card(pair.element, index: pair.offset, progress: progress)
            }
        }
        .padding(.bottom, DSSwipeDeckLogic.stackRoom)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            width = newWidth
        }
        // A cancelled drag (the system takes the touch) never calls `onEnded`, but it
        // does reset `isTouching`: spring back from here. Harmless after a normal end.
        .onChange(of: isTouching) { _, touching in
            if !touching, leaving == nil, drag != .zero { settle() }
        }
    }

    // MARK: Card

    private func card(_ item: Item, index: Int, progress: Double) -> some View {
        let isTop = index == 0
        let depth = DSSwipeDeckLogic.depth(index: index, progress: progress)
        let lean = isTop && !reduceMotion ? DSSwipeDeckLogic.lean(translation: drag.width, width: width) : 0
        let fadesOut = isTop && reduceMotion && leaving == item.id

        return content(item)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dsSurface(.solid, radius: DSRadius.card)
            .overlay(alignment: .top) {
                if isTop { chips(progress: progress) }
            }
            .dsShadow(isTop ? .lg : .sm)
            .scaleEffect(DSSwipeDeckLogic.scale(depth: depth), anchor: .bottom)
            .offset(y: DSSwipeDeckLogic.offset(depth: depth))
            .offset(isTop ? CGSize(width: drag.width, height: drag.height * DSSwipeDeckLogic.verticalFollow) : .zero)
            .rotationEffect(.degrees(lean), anchor: .bottom)
            .opacity(fadesOut ? 0 : 1)
            .zIndex(Double(DSSwipeDeckLogic.visibleDepth - index))
            .allowsHitTesting(isTop && leaving == nil)
            .gesture(dragGesture, including: isTop ? .all : .subviews)
            .transition(.scale(scale: DSSwipeDeckLogic.scale(depth: 1), anchor: .bottom).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityValue(DSSwipeDeckLogic.accessibilityValue(remaining: items.count))
            .accessibilityAction(named: Text(rightLabel)) { commit(.right) }
            .accessibilityAction(named: Text(leftLabel)) { commit(.left) }
            .accessibilityHidden(!isTop)
    }

    /// The direction's label fades in on the side the card is leaving from: the right
    /// swipe's chip at the top left, the left swipe's at the top right. Laid out left to
    /// right on purpose, because the drag is physical.
    private func chips(progress: Double) -> some View {
        HStack(alignment: .top) {
            chip(rightLabel, fill: theme.accent, text: theme.onAccent, strength: max(0, progress))
            Spacer(minLength: DSSpacing.sm)
            chip(leftLabel, fill: theme.ink, text: theme.palette.backgroundElevated, strength: max(0, -progress))
        }
        .padding(DSSpacing.md)
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func chip(_ label: String, fill: Color, text: Color, strength: Double) -> some View {
        let grow = reduceMotion ? 1 : Metrics.chipStartScale + (1 - Metrics.chipStartScale) * CGFloat(strength)
        return Text(label)
            .ds(.buttonSmall, color: text)
            .lineLimit(1)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xxs)
            .background(fill, in: Capsule())
            .scaleEffect(grow)
            .opacity(strength)
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        // Global space: the card moves under the finger, so its local space would
        // feed its own offset back into the translation.
        DragGesture(minimumDistance: Metrics.dragStart, coordinateSpace: .global)
            .updating($isTouching) { _, state, _ in state = true }
            .onChanged { value in
                guard leaving == nil else { return }
                // 1:1 with no animation: a card that lags behind the finger feels broken.
                drag = value.translation
                let nowArmed = DSSwipeDeckLogic.isArmed(translation: drag.width, width: width)
                if nowArmed != armed {
                    armed = nowArmed
                    if nowArmed { DSHapticEngine.shared.fire(.selection) }
                }
            }
            .onEnded { value in
                guard leaving == nil else { return }
                if let direction = DSSwipeDeckLogic.decision(
                    translation: value.translation.width,
                    predicted: value.predictedEndTranslation.width,
                    width: width
                ) {
                    commit(direction)
                } else {
                    settle()
                }
            }
    }

    /// Short of the line: spring back to rest. Safe to call twice (end, then the reset).
    private func settle() {
        armed = false
        withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy) {
            drag = .zero
        }
    }

    /// Sends the top card out `direction`, then removes it and reports it. Used by the
    /// drag and by the VoiceOver actions.
    private func commit(_ direction: DSSwipeDirection) {
        guard leaving == nil, let top = items.first else { return }
        armed = false
        DSHapticEngine.shared.fire(haptic)
        let exit = DSSwipeDeckLogic.exitOffset(direction, width: width)
        let motion = reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy
        withAnimation(motion, completionCriteria: .logicallyComplete) {
            leaving = top.id
            // Under Reduce Motion the card fades where it is instead of flying out.
            if !reduceMotion { drag = CGSize(width: exit, height: drag.height) }
        } completion: {
            finish(top, direction)
        }
    }

    private func finish(_ item: Item, _ direction: DSSwipeDirection) {
        withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springSmooth) {
            items.removeAll { $0.id == item.id }
            drag = .zero
            leaving = nil
        }
        onSwipe(item, direction)
        let label = direction == .right ? rightLabel : leftLabel
        AccessibilityNotification.Announcement(
            DSSwipeDeckLogic.announcement(label: label, remaining: items.count)
        ).post()
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSwipeDeckPreviewTrip: Identifiable {
    let id: String
    let country: String
    let symbol: String
}

private struct DSSwipeDeckPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var trips = DSSwipeDeckPreviewHost.all
    @State private var liked: [String] = []

    static let all = [
        DSSwipeDeckPreviewTrip(id: "Lisbon", country: "Portugal", symbol: "sun.max"),
        DSSwipeDeckPreviewTrip(id: "Kyoto", country: "Japan", symbol: "leaf"),
        DSSwipeDeckPreviewTrip(id: "Oslo", country: "Norway", symbol: "snowflake"),
        DSSwipeDeckPreviewTrip(id: "Cusco", country: "Peru", symbol: "mountain.2"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            DSPreviewThemeDots(theme: theme)

            DSSwipeDeck($trips, leftLabel: "Skip", rightLabel: "Save", onSwipe: { trip, direction in
                if direction == .right { liked.append(trip.id) }
            }) { trip in
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Image(systemName: trip.symbol)
                        .font(.largeTitle)
                        .foregroundStyle(theme.style.accent)
                        .accessibilityHidden(true)
                    Spacer()
                    Text(trip.id).ds(.title1)
                    Text(trip.country).ds(.callout, color: DSColors.textSecondary)
                }
                .padding(DSSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 360)

            HStack {
                Text("Saved: \(liked.joined(separator: ", "))").ds(.footnote, color: DSColors.textSecondary)
                Spacer()
                DSButton("Start over", variant: .ghost, size: .small) {
                    trips = Self.all
                    liked = []
                }
            }
        }
        .dsScreenPadding()
        .padding(.vertical, DSSpacing.xl)
        .frame(maxHeight: .infinity, alignment: .top)
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Swipe Deck — Light") {
    DSSwipeDeckPreviewHost().preferredColorScheme(.light)
}

#Preview("Swipe Deck — Dark") {
    DSSwipeDeckPreviewHost().preferredColorScheme(.dark)
}
#endif
