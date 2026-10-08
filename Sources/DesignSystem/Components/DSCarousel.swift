import SwiftUI

// MARK: - Design System Carousel
// A horizontal, snapping carousel with a depth-of-field feel: the centered card
// sits at full size while its neighbours recede and dim, and a sliver of each
// neighbour peeks in to invite the swipe. Built entirely on the iOS 17 scroll
// APIs — `scrollTargetBehavior(.viewAligned)` for the snap, `scrollTransition`
// for the depth, and `scrollPosition(id:)` to track and drive the centered card.
//
// It is generic over any `Identifiable` item and renders whatever the caller's
// `content` closure returns, so it carries product cards, onboarding panels,
// photos or stats without knowing what they are. Pair the `selection` binding
// with `DSPageControl` for a dot indicator that stays in sync both ways.
//
// Motion is the Velvet signature: the recede/dim rides the scroll offset
// continuously (`.interactive`), and a `.selection` tick fires each time a new
// card lands in the centre — the same feel as a picker detent. Under Reduce
// Motion the scale travel is dropped (items stay full size); the dim stays,
// since opacity is a static depth cue, not motion.
//
// Inspiration: Apple WWDC23 "Beyond scroll views" (viewAligned + content
// margins); the peeking-card carousel pattern popularised by Donny Wals and
// Kavsoft. Rewritten on Velvet tokens; no upstream code is reproduced.

public struct DSCarousel<Item: Identifiable, Content: View>: View {

    // MARK: - Metrics

    /// Tuning for the depth effect. Named so there are no bare scalars in `body`.
    private enum Metrics {
        /// The centered card's scale — full size.
        static let restingScale: CGFloat = 1
        /// Off-center cards sit back slightly, reading as depth rather than a jump.
        static let recedingScale: CGFloat = 0.9
        /// …and dim toward the backdrop so the centre draws the eye.
        static let recedingOpacity: Double = 0.55
    }

    private let items: [Item]
    @Binding private var selection: Item.ID?
    private let peek: CGFloat
    private let spacing: CGFloat
    private let haptic: DSHapticStyle
    private let content: (Item) -> Content

    @State private var containerWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - items: The cards to show, in order. Any `Identifiable` type.
    ///   - selection: The id of the centered card. Updates as the user scrolls,
    ///     and scrolls the carousel when set programmatically (e.g. from a page
    ///     control). Hold it as `@State var id: Item.ID?`.
    ///   - peek: How much of the neighbouring cards shows on each side. Also the
    ///     inset that lets the first and last card reach the centre. Defaults to
    ///     `DSSpacing.xxl` (32).
    ///   - spacing: Gap between cards. Defaults to `DSSpacing.md` (16).
    ///   - haptic: Fired each time a new card lands in the centre. Defaults to
    ///     `.selection` (the picker-detent tick).
    ///   - content: Builds the view for one item. The carousel sizes its width;
    ///     the card decides its own height.
    public init(
        _ items: [Item],
        selection: Binding<Item.ID?>,
        peek: CGFloat = DSSpacing.xxl,
        spacing: CGFloat = DSSpacing.md,
        haptic: DSHapticStyle = .selection,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self._selection = selection
        self.peek = peek
        self.spacing = spacing
        self.haptic = haptic
        self.content = content
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: spacing) {
                ForEach(items) { item in
                    content(item)
                        .frame(width: cardWidth)
                        .scrollTransition(.interactive) { view, phase in
                            view
                                .scaleEffect(scale(for: phase))
                                .opacity(phase.isIdentity ? 1 : Metrics.recedingOpacity)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, peek, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selection, anchor: .center)
        .scrollIndicators(.hidden)
        .background {
            // Measure the scroll container so each card is exactly the width that
            // leaves `peek` showing of its neighbours — deterministic, no reliance
            // on how `containerRelativeFrame` reads the content margins.
            GeometryReader { proxy in
                Color.clear
                    .onAppear { containerWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, width in
                        containerWidth = width
                    }
            }
        }
        .onChange(of: selection) { _, _ in
            DSHapticEngine.shared.fire(haptic)
        }
    }

    // MARK: - Geometry

    /// Full container minus a `peek` sliver on each side. Clamped so the first
    /// layout pass (width still 0) never asks for a negative frame.
    private var cardWidth: CGFloat {
        max(containerWidth - peek * 2, 0)
    }

    private func scale(for phase: ScrollTransitionPhase) -> CGFloat {
        guard !reduceMotion else { return Metrics.restingScale }
        return phase.isIdentity ? Metrics.restingScale : Metrics.recedingScale
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCarouselPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var selection: Int? = 0

    private struct Slide: Identifiable {
        let id: Int
        let title: String
        let subtitle: String
        let symbol: String
    }

    private let slides = [
        Slide(id: 0, title: "Weekly recap", subtitle: "4 sessions · 2 h 35 min", symbol: "chart.bar.fill"),
        Slide(id: 1, title: "New arrivals", subtitle: "Fresh picks for you", symbol: "sparkles"),
        Slide(id: 2, title: "Saved places", subtitle: "12 spots nearby", symbol: "mappin.and.ellipse"),
        Slide(id: 3, title: "Your streak", subtitle: "9 days and counting", symbol: "flame.fill")
    ]

    // Two-way bridge so the dot indicator and the carousel drive each other.
    private var page: Binding<Int> {
        Binding(get: { selection ?? 0 }, set: { selection = $0 })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                DSCarousel(slides, selection: $selection) { slide in
                    DSCard(style: .elevated) {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Image(systemName: slide.symbol)
                                .font(.title)
                                .foregroundStyle(theme.gradient.accent)
                            Spacer(minLength: 0)
                            Text(slide.title).ds(.title2)
                            Text(slide.subtitle)
                                .ds(.callout, color: DSColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: DSSpacing.massive * 2)
                    }
                }

                DSPageControl(currentPage: page, numberOfPages: slides.count)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, DSSpacing.xl)
        }
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
