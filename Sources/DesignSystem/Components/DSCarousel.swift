import SwiftUI

// MARK: - Design System Carousel
// A snapping, paged carousel where the centred item sits at full size and its
// neighbours recede — scaled down and dimmed — the moment they drift off centre.
// The depth tracks the finger: items grow and brighten as they scroll into the
// middle and settle on a crisp snap, the way App Store cards and onboarding
// decks move.
//
// This is NOT `DSHorizontalScroll` (a free-scrolling Airbnb-style row). This one
// is one-item-per-page: it snaps with `.scrollTargetBehavior(.viewAligned)`,
// reveals the neighbours as a peek via `contentMargins`, drives the scale/opacity
// falloff with `.scrollTransition`, and exposes the centred item as a binding so
// it pairs directly with `DSPageControl`. Fully generic over any `Identifiable`
// collection — product cards, onboarding slides, story tiles.
//
// Inspiration: Apple's iOS 17 scroll APIs (WWDC23 "Beyond scroll views") and the
// community "snap carousel with scaling" pattern
// (https://www.kodeco.com / Kavsoft — scrollTransition carousels).

public struct DSCarousel<Data, Content>: View
where Data: RandomAccessCollection, Data.Element: Identifiable, Content: View {

    private let data: Data
    private let externalSelection: Binding<Data.Element.ID?>?
    private let spacing: CGFloat
    private let sidePeek: CGFloat
    private let minScale: CGFloat
    private let minOpacity: Double
    private let content: (Data.Element) -> Content

    /// Owns the centred item when the caller doesn't bind one. Seeded lazily from
    /// the first element on appear via `scrollPosition`.
    @State private var internalSelection: Data.Element.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - data: Any `Identifiable` collection — one page per element.
    ///   - selection: The id of the centred item. Optional: bind it to drive a
    ///     `DSPageControl` or to scroll programmatically; leave it `nil` and the
    ///     carousel tracks the page internally.
    ///   - spacing: Gap between pages. Defaults to `DSSpacing.md` (16).
    ///   - sidePeek: How much of the neighbouring pages shows on each edge.
    ///     Defaults to `DSSpacing.xl` (24). Set to `0` for an edge-to-edge pager.
    ///   - minScale: Scale of a page once fully off-centre. Defaults to `0.9`.
    ///   - minOpacity: Opacity of a page once fully off-centre. Defaults to `0.6`.
    ///   - content: The view for one element.
    public init(
        _ data: Data,
        selection: Binding<Data.Element.ID?>? = nil,
        spacing: CGFloat = DSSpacing.md,
        sidePeek: CGFloat = DSSpacing.xl,
        minScale: CGFloat = 0.9,
        minOpacity: Double = 0.6,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.externalSelection = selection
        self.spacing = spacing
        self.sidePeek = sidePeek
        self.minScale = minScale
        self.minOpacity = minOpacity
        self.content = content
    }

    public var body: some View {
        // Use the caller's binding when given, otherwise our own state.
        let selection = externalSelection ?? $internalSelection

        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(data) { item in
                    content(item)
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition { view, phase in
                            view
                                .scaleEffect(scale(phase))
                                .opacity(opacity(phase))
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, sidePeek, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: selection)
        .scrollIndicators(.hidden)
        .onChange(of: selection.wrappedValue) { oldValue, _ in
            // Tick on every page settle, like a picker. Skip the first nil → id
            // seed on appear so there is no haptic the instant the view shows.
            guard oldValue != nil else { return }
            DSHapticEngine.shared.fire(.selection)
        }
    }

    // MARK: - Scroll falloff

    /// Full size in the centre, easing to `minScale` at the edges. Scaling is the
    /// motion, so Reduce Motion pins it to 1 — the dimming stays as a focus cue.
    private func scale(_ phase: ScrollTransitionPhase) -> CGFloat {
        if reduceMotion { return 1 }
        return phase.isIdentity ? 1 : minScale
    }

    private func opacity(_ phase: ScrollTransitionPhase) -> Double {
        phase.isIdentity ? 1 : minOpacity
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCarouselPreviewSlide: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
}

private struct DSCarouselPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var selection: Int? = 0

    private let slides = [
        DSCarouselPreviewSlide(id: 0, title: "Glass over gradient", subtitle: "One surface language, three themes", icon: "square.stack.3d.up.fill"),
        DSCarouselPreviewSlide(id: 1, title: "Springs, not ramps", subtitle: "Every touch answers with a spring", icon: "waveform.path"),
        DSCarouselPreviewSlide(id: 2, title: "No borders. Ever.", subtitle: "Edge highlight and wash instead", icon: "sparkles"),
        DSCarouselPreviewSlide(id: 3, title: "Haptics built in", subtitle: "Feedback lives in the component", icon: "hand.tap.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Paired with DSPageControl").ds(.overline, color: DSColors.textSecondary)

                    DSCarousel(slides, selection: $selection) { slide in
                        slideCard(slide)
                    }
                    .frame(height: 200)

                    DSPageControl(
                        currentPage: Binding(
                            get: { selection ?? 0 },
                            set: { selection = $0 }
                        ),
                        numberOfPages: slides.count
                    )
                    .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Edge-to-edge, no peek").ds(.overline, color: DSColors.textSecondary)

                    DSCarousel(slides, sidePeek: 0) { slide in
                        slideCard(slide)
                    }
                    .frame(height: 160)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func slideCard(_ slide: DSCarouselPreviewSlide) -> some View {
        DSCard(style: .elevated) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Image(systemName: slide.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(theme.gradient.accent)
                Spacer(minLength: 0)
                Text(slide.title).ds(.title3)
                Text(slide.subtitle).ds(.callout, color: DSColors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

#Preview("Carousel — Light") {
    DSCarouselPreviewHost().preferredColorScheme(.light)
}

#Preview("Carousel — Dark") {
    DSCarouselPreviewHost().preferredColorScheme(.dark)
}
#endif
