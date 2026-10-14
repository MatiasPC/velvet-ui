import SwiftUI

// MARK: - Design System Carousel
// A snapping, peeking horizontal carousel built on the native iOS 17 scroll
// stack — `scrollTargetLayout` + `.viewAligned` for the snap, `scrollPosition`
// for the live selection, and `scrollTransition` for the depth: the centred
// item sits at full size while its neighbours shrink and fade, so the row reads
// as cards passing under a spotlight. Each settle fires a `.selection` tick, the
// same feel as a picker.
//
// Pairs with `DSPageControl` — the dots below reflect the live page and spring
// between states as you swipe. Pass a `selection` binding to drive or observe
// the centred item from outside, or omit it and let the carousel own its state.
//
// Reduce Motion keeps the snapping (it is structure, not decoration) but settles
// the neighbours at full size and opacity, so nothing shrinks or fades.

public struct DSCarousel<Item: Identifiable, Content: View>: View {

    // MARK: - Configuration

    private let items: [Item]
    private let height: CGFloat
    private let spacing: CGFloat
    private let sidePeek: CGFloat
    private let minScale: CGFloat
    private let minOpacity: Double
    private let showsPageControl: Bool
    private let haptics: Bool
    private let content: (Item) -> Content

    // MARK: - State

    @Binding private var selection: Item.ID?
    /// Drives `scrollPosition`; mirrored to `selection` when one is bound.
    @State private var scrolledID: Item.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Bound Initializer

    /// A carousel whose centred item is driven and observed through `selection`.
    /// - Parameters:
    ///   - items: The items to page through. Must be `Identifiable`.
    ///   - selection: Binding to the id of the centred item. Set it to scroll
    ///     programmatically; read it to react to the user paging.
    ///   - height: Height of the carousel row. Items are framed to this height.
    ///     Defaults to `220`.
    ///   - spacing: Gap between items. Defaults to `DSSpacing.md`.
    ///   - sidePeek: How much of the neighbouring items shows past the centred
    ///     one. Defaults to `DSSpacing.xl`.
    ///   - minScale: Scale of an item at the edge of the row. Defaults to `0.9`.
    ///   - minOpacity: Opacity of an item at the edge of the row. Defaults to `0.55`.
    ///   - showsPageControl: Show a `DSPageControl` beneath the row. Defaults to `true`.
    ///   - haptics: Fire a `.selection` tick each time a new item settles. Defaults to `true`.
    ///   - content: Builds the view for one item.
    public init(
        _ items: [Item],
        selection: Binding<Item.ID?>,
        height: CGFloat = 220,
        spacing: CGFloat = DSSpacing.md,
        sidePeek: CGFloat = DSSpacing.xl,
        minScale: CGFloat = 0.9,
        minOpacity: Double = 0.55,
        showsPageControl: Bool = true,
        haptics: Bool = true,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self._selection = selection
        self.height = height
        self.spacing = spacing
        self.sidePeek = max(0, sidePeek)
        self.minScale = min(max(minScale, 0), 1)
        self.minOpacity = min(max(minOpacity, 0), 1)
        self.showsPageControl = showsPageControl
        self.haptics = haptics
        self.content = content
    }

    // MARK: - Self-managed Initializer

    /// A carousel that owns its own paging state. Use this when nothing outside
    /// needs to read or set the centred item.
    public init(
        _ items: [Item],
        height: CGFloat = 220,
        spacing: CGFloat = DSSpacing.md,
        sidePeek: CGFloat = DSSpacing.xl,
        minScale: CGFloat = 0.9,
        minOpacity: Double = 0.55,
        showsPageControl: Bool = true,
        haptics: Bool = true,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.init(
            items,
            selection: .constant(nil),
            height: height,
            spacing: spacing,
            sidePeek: sidePeek,
            minScale: minScale,
            minOpacity: minOpacity,
            showsPageControl: showsPageControl,
            haptics: haptics,
            content: content
        )
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: DSSpacing.md) {
            GeometryReader { proxy in
                let itemWidth = max(0, proxy.size.width - sidePeek * 2)

                ScrollView(.horizontal) {
                    LazyHStack(spacing: spacing) {
                        ForEach(items) { item in
                            content(item)
                                .frame(width: itemWidth, height: proxy.size.height)
                                .scrollTransition { view, phase in
                                    view
                                        .scaleEffect(phase.isIdentity ? 1 : restScale)
                                        .opacity(phase.isIdentity ? 1 : restOpacity)
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, sidePeek)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledID, anchor: .center)
                .scrollIndicators(.hidden)
            }
            .frame(height: height)

            if showsPageControl, items.count > 1 {
                DSPageControl(
                    currentPage: pageBinding,
                    numberOfPages: items.count,
                    allowsTap: false
                )
            }
        }
        .onAppear {
            if scrolledID == nil {
                scrolledID = selection ?? items.first?.id
            }
        }
        .onChange(of: scrolledID) { old, new in
            if selection != new { selection = new }
            // Skip the tick for the initial assignment (old == nil).
            guard old != nil, haptics else { return }
            DSHapticEngine.shared.fire(.selection)
        }
        .onChange(of: selection) { _, new in
            guard let new, new != scrolledID else { return }
            withAnimation(DSAnimation.springSmooth) { scrolledID = new }
        }
    }

    // MARK: - Derived Values

    /// Neighbour scale at the row edge — flattened to 1 under Reduce Motion.
    private var restScale: CGFloat { reduceMotion ? 1 : minScale }
    /// Neighbour opacity at the row edge — flattened to 1 under Reduce Motion.
    private var restOpacity: Double { reduceMotion ? 1 : minOpacity }

    /// Read-only page index for `DSPageControl`, derived from the centred id.
    private var pageBinding: Binding<Int> {
        Binding(
            get: { items.firstIndex { $0.id == scrolledID } ?? 0 },
            set: { _ in }
        )
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCarouselPreviewHost: View {
    @State private var theme = DSTheme()

    private struct Feature: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let symbol: String
    }

    private let features: [Feature] = [
        Feature(title: "Glass over gradient", subtitle: "The Velvet surface language", symbol: "square.stack.3d.up.fill"),
        Feature(title: "Springs, not ramps", subtitle: "Every touch answers back", symbol: "waveform.path"),
        Feature(title: "No borders. Ever.", subtitle: "Edges are light, not strokes", symbol: "sparkles"),
        Feature(title: "Tokens only", subtitle: "One knob re-themes the tree", symbol: "paintpalette.fill")
    ]

    @State private var selected: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                Text("Featured").ds(.overline, color: DSColors.textSecondary)
                DSCarousel(features, selection: $selected) { feature in
                    featureCard(feature)
                }

                Text("Self-managed, no page control")
                    .ds(.overline, color: DSColors.textSecondary)
                DSCarousel(features, height: 140, showsPageControl: false) { feature in
                    featureCard(feature)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func featureCard(_ feature: Feature) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Image(systemName: feature.symbol)
                .font(.system(size: 28))
                .foregroundStyle(theme.gradient.accent)
            Spacer(minLength: 0)
            Text(feature.title).ds(.title3)
            Text(feature.subtitle).ds(.callout, color: DSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(DSSpacing.lg)
        .dsSurface(.glass, radius: DSRadius.card)
    }
}

#Preview("Carousel — Light") {
    DSCarouselPreviewHost().preferredColorScheme(.light)
}

#Preview("Carousel — Dark") {
    DSCarouselPreviewHost().preferredColorScheme(.dark)
}
#endif
