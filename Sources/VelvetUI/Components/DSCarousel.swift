import SwiftUI

// MARK: - Design System Carousel
// A snapping, peeking carousel. Each item takes the full width minus a `peek`
// margin on both sides, so `peek - spacing` of each neighbour shows at the edges. Scrolling snaps to
// whole items (`.viewAligned`), and the items lean away with depth as they leave
// the centre: a little smaller, a little dimmer, a few degrees of yaw.
//
// The page index is a plain Int so it pairs directly with `DSPageControl`.
//
// Under Reduce Motion the depth effect rests at identity; the snapping scroll
// itself stays, because it is the interaction rather than decoration.

/// Private geometry constants for the depth effect.
private enum Metrics {
    /// Scale of an item one full page away from the centre.
    static let edgeScale: CGFloat = 0.9
    /// Opacity of an item one full page away from the centre.
    static let edgeOpacity: Double = 0.6
    /// Yaw (degrees, around the vertical axis) of an item one full page away.
    static let edgeYaw: Double = 4
    /// Perspective for the yaw, as `rotation3DEffect` expects (0 = none, ~0.5 = default).
    static let perspective: CGFloat = 0.6
}

/// The pure maths behind `DSCarousel`, kept out of the generic view so it can be tested directly.
enum DSCarouselMath {
    /// Depth for a scroll-transition phase value. `phaseValue` is 0 when the item is
    /// centred and ±1 when it is a full page away; anything beyond is clamped.
    /// Positive values (items to the trailing side) yaw towards the centre.
    static func depth(for phaseValue: Double) -> (scale: CGFloat, opacity: Double, yaw: Double) {
        let t = min(max(abs(phaseValue), 0), 1)
        let sign: Double = phaseValue < 0 ? -1 : 1
        return (
            scale: 1 - (1 - Metrics.edgeScale) * CGFloat(t),
            opacity: 1 - (1 - Metrics.edgeOpacity) * t,
            yaw: -sign * Metrics.edgeYaw * t
        )
    }

    /// `page` clamped into `0..<count` (0 when empty).
    static func clampedPage(_ page: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(page, 0), count - 1)
    }

    /// 1-based "Page N of M".
    static func accessibilityValue(page: Int, count: Int) -> String {
        "Page \(clampedPage(page, count: count) + 1) of \(count)"
    }
}

/// A horizontally scrolling carousel that snaps to items and lets their neighbours peek in.
public struct DSCarousel<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    private let data: Data
    private let externalPage: Binding<Int>?
    private let peek: CGFloat
    private let spacing: CGFloat
    private let haptic: DSHapticStyle?
    private let content: (Data.Element) -> Content

    @State private var internalPage = 0
    @State private var scrollID: Data.Element.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A carousel whose page index you own, e.g. to drive a `DSPageControl`.
    /// - Parameters:
    ///   - data: The items. Each element's `id` identifies its page.
    ///   - currentPage: The page index. Changing it scrolls there; scrolling updates it. Out-of-range values are clamped.
    ///   - peek: Margin on each side of the centred item; `peek - spacing` of each neighbour shows. Defaults to `DSSpacing.xxxl`.
    ///   - spacing: Gap between items. Defaults to `DSSpacing.sm`.
    ///   - haptic: Fired once per page change. `nil` for none. Defaults to `.selection`.
    ///   - content: The view for one item.
    public init(
        _ data: Data,
        currentPage: Binding<Int>,
        peek: CGFloat = DSSpacing.xxxl,
        spacing: CGFloat = DSSpacing.sm,
        haptic: DSHapticStyle? = .selection,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.externalPage = currentPage
        self.peek = peek
        self.spacing = spacing
        self.haptic = haptic
        self.content = content
    }

    /// A carousel that keeps its own page index.
    /// - Parameters:
    ///   - data: The items. Each element's `id` identifies its page.
    ///   - peek: Margin on each side of the centred item; `peek - spacing` of each neighbour shows. Defaults to `DSSpacing.xxxl`.
    ///   - spacing: Gap between items. Defaults to `DSSpacing.sm`.
    ///   - haptic: Fired once per page change. `nil` for none. Defaults to `.selection`.
    ///   - content: The view for one item.
    public init(
        _ data: Data,
        peek: CGFloat = DSSpacing.xxxl,
        spacing: CGFloat = DSSpacing.sm,
        haptic: DSHapticStyle? = .selection,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.externalPage = nil
        self.peek = peek
        self.spacing = spacing
        self.haptic = haptic
        self.content = content
    }

    private var pageBinding: Binding<Int> {
        externalPage ?? $internalPage
    }

    private var ids: [Data.Element.ID] { data.map(\.id) }

    public var body: some View {
        let reduceMotion = reduceMotion
        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(data) { item in
                    content(item)
                        // Inside a ScrollView, containerRelativeFrame measures the scroll view's
                        // bounds minus its content margins, so each item is (viewport - 2 * peek)
                        // wide and `peek - spacing` of each neighbour shows (verified in the
                        // simulator on iOS 18).
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                            let depth = reduceMotion
                                ? DSCarouselMath.depth(for: 0)
                                : DSCarouselMath.depth(for: phase.value)
                            // Shrink toward the centre item (anchor on the edge that faces it),
                            // so the neighbour's visible peek isn't scaled away.
                            return effect
                                .scaleEffect(depth.scale, anchor: phase.value > 0 ? .leading : .trailing)
                                .opacity(depth.opacity)
                                .rotation3DEffect(
                                    .degrees(depth.yaw),
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: Metrics.perspective
                                )
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, peek, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrollID)
        .onAppear { syncScrollToPage(animated: false) }
        .onChange(of: scrollID) { _, newID in
            guard let newID, let index = ids.firstIndex(of: newID) else { return }
            guard index != pageBinding.wrappedValue else { return }
            pageBinding.wrappedValue = index
            if let haptic { DSHapticEngine.shared.fire(haptic) }
        }
        .onChange(of: pageBinding.wrappedValue) { _, _ in
            syncScrollToPage(animated: true)
        }
        .onChange(of: data.count) { _, _ in
            syncScrollToPage(animated: false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Carousel")
        .accessibilityValue(DSCarouselMath.accessibilityValue(page: pageBinding.wrappedValue, count: data.count))
    }

    /// Scrolls to the (clamped) bound page, writing the clamp back if it changed.
    private func syncScrollToPage(animated: Bool) {
        let ids = ids
        guard !ids.isEmpty else { return }
        let page = DSCarouselMath.clampedPage(pageBinding.wrappedValue, count: ids.count)
        if page != pageBinding.wrappedValue { pageBinding.wrappedValue = page }
        let target = ids[page]
        guard scrollID != target else { return }
        if animated && !reduceMotion {
            withAnimation(DSAnimation.springSmooth) { scrollID = target }
        } else {
            scrollID = target
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCarouselPreviewItem: Identifiable {
    let id: Int
    let title: String
}

private struct DSCarouselPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var page = 0
    private let items = [
        DSCarouselPreviewItem(id: 0, title: "Lisbon"),
        DSCarouselPreviewItem(id: 1, title: "Kyoto"),
        DSCarouselPreviewItem(id: 2, title: "Oaxaca"),
        DSCarouselPreviewItem(id: 3, title: "Reykjavik")
    ]

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSPreviewThemeDots(theme: theme)

            DSCarousel(items, currentPage: $page) { item in
                Text(item.title)
                    .ds(.title2)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .dsSurface(.glass, radius: DSRadius.card)
            }
            .frame(height: 200)

            DSPageControl(currentPage: $page, numberOfPages: items.count)
            Spacer()
        }
        .padding(.vertical, DSSpacing.xl)
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Carousel — Light") {
    DSCarouselPreviewHost().preferredColorScheme(.light)
}

#Preview("Carousel — Dark") {
    DSCarouselPreviewHost().preferredColorScheme(.dark)
}
#endif
