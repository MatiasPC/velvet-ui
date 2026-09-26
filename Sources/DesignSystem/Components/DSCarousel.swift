import SwiftUI

// MARK: - Design System Carousel
// A snapping, peeking horizontal carousel built on the iOS 17+ scroll APIs
// (`scrollTargetBehavior(.viewAligned)`, `scrollTransition`, `scrollPosition`,
// `containerRelativeFrame`). Each card fills the viewport when centred; its
// neighbours peek in from the sides and drift smaller + dimmer as they leave
// centre, so the focused card always reads as the subject. Snapping to a new
// card fires a `.selection` tick, the same feel as the native picker.
//
// It is the paged container `DSPageControl` was always meant to sit under, and
// it hosts any view — `DSImageCard`, `DSCard`, a chart. Bind `selection` to the
// centred item's id to drive a `DSPageControl` or scroll it programmatically.
//
// Pure SwiftUI, no borders: separation is the peek gutter and the scale/opacity
// falloff, not a frame. Under Reduce Motion the scale/opacity transition
// collapses to a plain paged scroll (cards still snap, they just don't shrink).

// MARK: - Motion Metrics

/// Off-centre falloff for carousel cards. Named constants rather than inline
/// literals, in the spirit of `DSPress` / `DSMotion`.
private enum DSCarouselMetrics {
    /// Scale of a card once it is a full page away from centre.
    static let minScale: Double = 0.88
    /// Opacity of a card once it is a full page away from centre.
    static let minOpacity: Double = 0.55
}

// MARK: - Carousel

public struct DSCarousel<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Identifiable {
    private let data: Data
    private let spacing: CGFloat
    private let peek: CGFloat
    private let haptic: DSHapticStyle
    private let selection: Binding<Data.Element.ID?>?
    private let content: (Data.Element) -> Content

    @State private var activeID: Data.Element.ID? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - data: The items to page through. Elements are `Identifiable`; their
    ///     `id` is what `selection` reports and scrolls to.
    ///   - spacing: Gap between cards. Defaults to `DSSpacing.md` (16).
    ///   - peek: How far the neighbouring cards peek in from each edge. Defaults
    ///     to `DSSpacing.xl` (24). Pass `0` for full-bleed, one-card-at-a-time
    ///     paging with no peek.
    ///   - selection: Optional two-way binding to the centred item's id. Set it
    ///     to scroll programmatically (e.g. from a `DSPageControl`); read it to
    ///     follow the user's swipes.
    ///   - haptic: Fired each time the carousel snaps to a new card. Defaults to
    ///     `.selection`.
    ///   - content: The card for one item.
    public init(
        _ data: Data,
        spacing: CGFloat = DSSpacing.md,
        peek: CGFloat = DSSpacing.xl,
        selection: Binding<Data.Element.ID?>? = nil,
        haptic: DSHapticStyle = .selection,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.spacing = spacing
        self.peek = peek
        self.selection = selection
        self.haptic = haptic
        self.content = content
    }

    public var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(data) { item in
                    content(item)
                        .containerRelativeFrame(.horizontal) { length, _ in
                            max(length - peek * 2, 0)
                        }
                        .scrollTransition(.interactive) { view, phase in
                            let distance = min(abs(phase.value), 1)   // 0 at centre → 1 a page away
                            let scale: CGFloat = reduceMotion ? 1 : CGFloat(1 - (1 - DSCarouselMetrics.minScale) * distance)
                            let opacity: Double = reduceMotion ? 1 : 1 - (1 - DSCarouselMetrics.minOpacity) * distance
                            return view
                                .scaleEffect(scale)
                                .opacity(opacity)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(.horizontal, peek)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: positionBinding)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .onChange(of: positionBinding.wrappedValue) { oldValue, _ in
            // Skip the initial nil → first-id settle so appearing never buzzes.
            guard oldValue != nil else { return }
            DSHapticEngine.shared.fire(haptic)
        }
    }

    /// The caller's binding when given, otherwise our own tracked id.
    private var positionBinding: Binding<Data.Element.ID?> {
        selection ?? $activeID
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCarouselPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var current: Int? = 0

    private struct Slide: Identifiable {
        let id: Int
        let title: String
        let subtitle: String
        let badge: String?
    }

    private let slides: [Slide] = [
        Slide(id: 0, title: "Cabaña en el bosque", subtitle: "$120 / noche", badge: "Nuevo"),
        Slide(id: 1, title: "Loft en la ciudad", subtitle: "$210 / noche", badge: nil),
        Slide(id: 2, title: "Casa junto al mar", subtitle: "$340 / noche", badge: "Popular"),
        Slide(id: 3, title: "Refugio en la montaña", subtitle: "$95 / noche", badge: nil)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Peeking gallery").ds(.title3)
                        .dsScreenPadding()

                    DSCarousel(slides, selection: $current) { slide in
                        DSImageCard(title: slide.title, subtitle: slide.subtitle, badge: slide.badge)
                    }

                    DSPageControl(
                        currentPage: Binding(
                            get: { current ?? 0 },
                            set: { newValue in
                                withAnimation(DSAnimation.springSmooth) { current = newValue }
                            }
                        ),
                        numberOfPages: slides.count
                    )
                    .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Full-bleed stat cards").ds(.title3)
                        .dsScreenPadding()

                    DSCarousel(slides, peek: 0) { slide in
                        DSCard {
                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                Text(slide.title).ds(.title2)
                                Text(slide.subtitle)
                                    .ds(.callout, color: DSColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        }
                        .dsScreenPadding()
                    }
                }
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
