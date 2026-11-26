import SwiftUI

// MARK: - Design System Card Stack
// A pile of related cards that sits collapsed, the first card on top and the next
// two peeking out under it, and fans out into a column when tapped. Grouped
// notifications, a wallet of passes or tickets, a thread of messages from one
// sender, several alerts about the same order.
//
// Collapsed, each card behind the top one is a step smaller and a step lower, so
// only its bottom edge shows; cards past the third wait, invisible, behind the
// last peeking one. Expanded, the cards stand in a column with `DSSpacing.sm`
// between them, full size. Between the two, every card travels from its place in
// the pile to its place in the column, and the stack's height follows every frame,
// so the content below it moves with the cards instead of jumping.
//
// Cards are solid (`.solid` surface, `DSRadius.card`), not glass: stacked glass
// shows every card through the one above it and turns muddy (see `DSSwipeDeck`).
//
// Motion: one `progress` (0 collapsed, 1 expanded) drives everything: it is the
// `animatableData` of a private `Layout`, and the scale and opacity of each card
// read the same value, so they never drift apart. It animates on `springSmooth`
// from the state, not the tap, so an owner that collapses the stack ("Show less")
// animates too. The collapsed stack dips on press (`DSPress`) and the tap that
// expands it fires `haptic`. Under Reduce Motion the change runs on
// `DSAnimation.fast` with no spring, the same end state.
//
// VoiceOver: collapsed, the stack is one button ("Notifications", "3 cards,
// collapsed") whose action expands it. Expanded, the cards are separate elements
// in reading order. Collapse it from your own control ("Show less"). Both come
// from one `.accessibilityRepresentation`, so nothing from a collapsed card leaks.
//
// Technique: the grouped-notification stack of iOS Notification Center and the
// "stacked cards" SwiftUI tutorials (Kavsoft, Sarunw), rebuilt on one animatable
// custom `Layout` instead of a ZStack/VStack swap, with the geometry in a pure
// `DSCardStackLogic` so it can be tested.

// MARK: - Logic

/// The geometry behind `DSCardStack`, kept out of the generic view so it can be tested.
/// Heights are the cards' natural heights at the stack's width, in points; `progress` is
/// 0 when the stack is collapsed and 1 when it is expanded.
enum DSCardStackLogic {
    /// Cards that peek out under the top one when collapsed.
    static let peekDepth = 2
    /// Each step back, a collapsed card is this much smaller (anchored at its bottom edge)…
    static let scaleStep: CGFloat = 0.05
    /// …and its bottom edge sits this much lower: DSSpacing.sm (12).
    static let peekStep: CGFloat = DSSpacing.sm
    /// Gap between expanded cards: DSSpacing.sm (12).
    static let spacing: CGFloat = DSSpacing.sm

    /// `progress` clamped to 0...1. A spring overshoots both ends; a card must not
    /// travel past its place in the column or above the top of the pile.
    static func clamped(_ progress: Double) -> CGFloat {
        guard progress.isFinite else { return 0 }
        return CGFloat(min(1, max(0, progress)))
    }

    /// How far back a card sits in the collapsed pile: 0 for the top card, at most `peekDepth`.
    static func depth(index: Int) -> Int {
        min(max(0, index), peekDepth)
    }

    /// True when a tap has something to show: there is more than one card.
    static func canExpand(count: Int) -> Bool {
        count > 1
    }

    /// Top edge of each card in the collapsed pile. The top card sits at 0; a card behind
    /// it is placed so its bottom edge lands one `peekStep` per step of depth below the
    /// top card's, and never higher than the top of the pile (a taller card behind just
    /// shows more of itself).
    static func collapsedOrigins(heights: [CGFloat]) -> [CGFloat] {
        guard let top = heights.first.map({ sanitized($0) }) else { return [] }
        return heights.enumerated().map { index, height in
            guard index > 0 else { return 0 }
            let bottom = top + peekStep * CGFloat(depth(index: index))
            return max(0, bottom - sanitized(height))
        }
    }

    /// Height of the collapsed pile: the lowest bottom edge among the cards that show.
    static func collapsedHeight(heights: [CGFloat]) -> CGFloat {
        let origins = collapsedOrigins(heights: heights)
        let shown = min(heights.count, peekDepth + 1)
        return (0..<shown).map { origins[$0] + sanitized(heights[$0]) }.max() ?? 0
    }

    /// Top edge of each card in the expanded column.
    static func expandedOrigins(heights: [CGFloat], spacing: CGFloat = DSCardStackLogic.spacing) -> [CGFloat] {
        var y: CGFloat = 0
        return heights.map { height in
            defer { y += sanitized(height) + spacing }
            return y
        }
    }

    /// Height of the expanded column.
    static func expandedHeight(heights: [CGFloat], spacing: CGFloat = DSCardStackLogic.spacing) -> CGFloat {
        guard !heights.isEmpty else { return 0 }
        return heights.map { sanitized($0) }.reduce(0, +) + spacing * CGFloat(heights.count - 1)
    }

    /// Where every card is, and how tall the stack is, at `progress`.
    static func layout(
        heights: [CGFloat],
        progress: Double,
        spacing: CGFloat = DSCardStackLogic.spacing
    ) -> (origins: [CGFloat], height: CGFloat) {
        let t = clamped(progress)
        let collapsed = collapsedOrigins(heights: heights)
        let expanded = expandedOrigins(heights: heights, spacing: spacing)
        let origins = zip(collapsed, expanded).map { lerp($0, $1, t) }
        let height = lerp(collapsedHeight(heights: heights), expandedHeight(heights: heights, spacing: spacing), t)
        return (origins, height)
    }

    /// Scale of the card at `index`: a step smaller per step of depth when collapsed,
    /// full size when expanded.
    static func scale(index: Int, progress: Double) -> CGFloat {
        let collapsed = max(0, 1 - scaleStep * CGFloat(depth(index: index)))
        return lerp(collapsed, 1, clamped(progress))
    }

    /// Opacity of the card at `index`: the top card and the ones that peek are always
    /// shown; the ones waiting behind them fade in as the stack opens.
    static func opacity(index: Int, progress: Double) -> Double {
        index <= peekDepth ? 1 : Double(clamped(progress))
    }

    /// VoiceOver value of the stack: "3 cards, collapsed", "1 card".
    static func accessibilityValue(count: Int, isExpanded: Bool) -> String {
        let total = max(0, count)
        let cards = total == 1 ? "1 card" : "\(total) cards"
        guard canExpand(count: total) else { return cards }
        return cards + (isExpanded ? ", expanded" : ", collapsed")
    }

    private static func sanitized(_ value: CGFloat) -> CGFloat {
        value.isFinite ? max(0, value) : 0
    }

    private static func lerp(_ from: CGFloat, _ to: CGFloat, _ t: CGFloat) -> CGFloat {
        from + (to - from) * t
    }
}

// MARK: - Layout

/// Places the cards for one `progress` between the pile (0) and the column (1).
/// `progress` is the layout's `animatableData`, so the spring interpolates it and
/// every frame is a real layout: the stack's height follows the cards. Each card is
/// measured at the stack's width and its natural height, so text never re-wraps.
struct DSCardStackLayout: Layout {
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = Self.width(proposal: proposal, subviews: subviews)
        let heights = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height }
        return CGSize(width: width, height: DSCardStackLogic.layout(heights: heights, progress: progress).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let card = ProposedViewSize(width: bounds.width, height: nil)
        let heights = subviews.map { $0.sizeThatFits(card).height }
        let origins = DSCardStackLogic.layout(heights: heights, progress: progress).origins
        for (subview, y) in zip(subviews, origins) {
            subview.place(at: CGPoint(x: bounds.minX, y: bounds.minY + y), anchor: .topLeading, proposal: card)
        }
    }

    /// The proposed width when there is one; otherwise (an ideal-size probe, or an
    /// infinite width) the widest card's own width, so the stack never echoes infinity.
    private static func width(proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        if let width = proposal.width, width.isFinite { return width }
        return subviews.map { $0.sizeThatFits(.unspecified).width }.filter(\.isFinite).max() ?? 0
    }
}

// MARK: - Card Stack

/// A pile of related cards that fans out into a column when tapped.
///
/// Collapsed, the first item is on top and the next two peek out under it; tapping the
/// pile expands it. Collapse it from your own control by setting `isExpanded` to `false`
/// (a "Show less" button above it, for example). Every card gets a solid surface and
/// `DSSpacing.md` padding; the content is yours. Cards of similar height stack best.
///
/// While collapsed, controls inside the cards don't take touches: the whole pile is one
/// tap target. Once expanded, every card's content is live.
public struct DSCardStack<Item: Identifiable, Content: View>: View {
    private let items: [Item]
    @Binding private var isExpanded: Bool
    private let haptic: DSHapticStyle
    private let accessibilityLabel: String
    private let content: (Item) -> Content

    /// The collapsed pile is held down: it dips like a button.
    @State private var isPressed = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - items: The cards, top card first.
    ///   - isExpanded: Whether the cards stand in a column. A tap on the pile sets it to `true`.
    ///   - haptic: Fired when a tap expands the pile. Defaults to `.light`.
    ///   - accessibilityLabel: What VoiceOver calls the pile ("Notifications"). Defaults to "Stack".
    ///   - content: One card's content. The stack pads it and puts it on a solid surface.
    public init(
        _ items: [Item],
        isExpanded: Binding<Bool>,
        haptic: DSHapticStyle = .light,
        accessibilityLabel: String = "Stack",
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self._isExpanded = isExpanded
        self.haptic = haptic
        self.accessibilityLabel = accessibilityLabel
        self.content = content
    }

    public var body: some View {
        let progress: Double = isExpanded ? 1 : 0
        let canExpand = DSCardStackLogic.canExpand(count: items.count)
        let isCollapsed = !isExpanded && canExpand

        DSCardStackLayout(progress: progress) {
            ForEach(Array(items.enumerated()), id: \.element.id) { pair in
                card(pair.element, index: pair.offset, progress: progress)
            }
        }
        .animation(reduceMotion ? DSAnimation.fast : DSAnimation.springSmooth, value: isExpanded)
        .overlay {
            if isCollapsed {
                Button(action: expand) {
                    Color.clear.contentShape(Rectangle())
                }
                .buttonStyle(DSCardStackPressStyle(isPressed: $isPressed))
            }
        }
        .scaleEffect(isPressed && isCollapsed ? DSPress.scale : 1)
        .animation(DSPress.animation, value: isPressed)
        // Toggling `.accessibilityElement(children: .ignore)` left the collapsed cards'
        // text findable (the Gallery UI test caught it), the same leak DSSwipeDeck hit.
        // The whole stack is replaced for assistive technologies instead.
        .accessibilityRepresentation { representation(isCollapsed: isCollapsed) }
    }

    // MARK: Accessibility

    /// What VoiceOver gets in place of the stack. Collapsed: one button named by
    /// `accessibilityLabel` that expands the pile, and nothing from the cards.
    /// Expanded: the cards' content in a column laid out like the real one (same
    /// padding and gaps), so each element sits where its card is.
    @ViewBuilder
    private func representation(isCollapsed: Bool) -> some View {
        let value = DSCardStackLogic.accessibilityValue(count: items.count, isExpanded: isExpanded)
        if isCollapsed {
            // The label fills the pile, so the element's frame is the pile's: VoiceOver
            // outlines the whole stack and a tap at the element's centre lands on it.
            Button(action: expand) {
                Text(accessibilityLabel).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .accessibilityValue(value)
        } else {
            VStack(alignment: .leading, spacing: DSCardStackLogic.spacing) {
                ForEach(items) { item in
                    content(item)
                        .padding(DSSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(value)
        }
    }

    // MARK: Card

    private func card(_ item: Item, index: Int, progress: Double) -> some View {
        content(item)
            .padding(DSSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsSurface(.solid, radius: DSRadius.card)
            .dsShadow(index == 0 ? .md : .sm)
            .scaleEffect(DSCardStackLogic.scale(index: index, progress: progress), anchor: .bottom)
            .opacity(DSCardStackLogic.opacity(index: index, progress: progress))
            .zIndex(Double(items.count - index))
            .allowsHitTesting(isExpanded)
    }

    // MARK: Actions

    private func expand() {
        guard !isExpanded, DSCardStackLogic.canExpand(count: items.count) else { return }
        DSHapticEngine.shared.fire(haptic)
        isExpanded = true
    }
}

/// Reports the press of the collapsed pile's tap target, so the whole pile dips
/// (the target itself is clear). A `ButtonStyle`, not a `DragGesture`, so a touch
/// that turns into a scroll releases the press.
private struct DSCardStackPressStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCardStackPreviewAlert: Identifiable {
    let id: String
    let detail: String
}

private struct DSCardStackPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var isExpanded = false

    private let alerts = [
        DSCardStackPreviewAlert(id: "Your order shipped", detail: "Arrives Thursday"),
        DSCardStackPreviewAlert(id: "Out for delivery", detail: "Driver is 4 stops away"),
        DSCardStackPreviewAlert(id: "Delivered", detail: "Left at the front door"),
        DSCardStackPreviewAlert(id: "Rate your order", detail: "Tell us how it went"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                DSPreviewThemeDots(theme: theme)

                HStack {
                    Text("Orders").ds(.title3)
                    Spacer()
                    if isExpanded {
                        DSButton("Show less", variant: .ghost, size: .small) { isExpanded = false }
                    }
                }

                DSCardStack(alerts, isExpanded: $isExpanded, accessibilityLabel: "Order updates") { alert in
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text(alert.id).ds(.title3)
                        Text(alert.detail).ds(.callout, color: DSColors.textSecondary)
                    }
                }

                Text("Below the stack").ds(.footnote, color: DSColors.textSecondary)
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Card Stack — Light") {
    DSCardStackPreviewHost().preferredColorScheme(.light)
}

#Preview("Card Stack — Dark") {
    DSCardStackPreviewHost().preferredColorScheme(.dark)
}
#endif
