import SwiftUI

// MARK: - Design System Carousel
// A snapping, peeking horizontal carousel — the Velvet reading of a "featured
// content" rail. Cards are laid out edge to edge, the scroll snaps each one to
// centre, and neighbours peek in from both sides so the rail always says "there
// is more this way". The focused card sits at full size while the ones drifting
// off shrink and dim, so attention tracks the centre without a single border.
//
// Built on the iOS 17 scroll stack — `scrollTargetBehavior(.viewAligned)`,
// `scrollTargetLayout()`, `containerRelativeFrame` for the card width,
// `contentMargins` for the peek gutter, `scrollTransition` for the scale/opacity
// falloff and `scrollPosition(id:)` for the two-way page binding. No timers, no
// gesture math, no `GeometryReader`: the scroll view owns the motion.
//
// `selection` is an optional two-way `Binding<Int>`: the carousel writes the
// centred page into it as the user swipes and scrolls to a page the app sets
// programmatically (a "Next" button, a deep link). The built-in indicator is a
// display-only `DSPageControl`, so paging stays a swipe — one gesture, one
// source of truth. A `.selection` haptic ticks on every page the finger lands
// on; a programmatic move stays silent so the caller owns that feedback.

// MARK: - Metrics

private enum Metrics {
    /// Scale of a card once it has fully drifted off-centre. Shrinks just enough
    /// to seat the focused card forward without the neighbours reading as a
    /// different, smaller size. No spacing/scale token exists for this shaping
    /// value — it mirrors how `DSMotion` keeps its scale envelopes local.
    static let restScale: CGFloat = 0.90
    /// Opacity of a fully off-centre card. Dims the periphery so the centre
    /// reads as the subject, not so far that the neighbours look disabled.
    static let restOpacity: Double = 0.55
}

// MARK: - DSCarousel

/// A centre-snapping horizontal carousel with peeking neighbours and a focus
/// falloff, over any collection.
///
///     DSCarousel(trips) { trip in
///         DSImageCard(imageURL: trip.cover, title: trip.name, subtitle: trip.price)
///     }
///
/// Drive it from outside — a "Next" button, an auto-advance, a deep link — with
/// the selection binding:
///
///     DSCarousel(pages, selection: $page) { page in
///         OnboardingSlide(page)
///     }
///
/// Set `peek` to `0` for a full-bleed pager (each card fills the width, the next
/// one is fully off-screen); leave it at the default for the peeking rail.
public struct DSCarousel<Data: RandomAccessCollection, Content: View>: View {

    // MARK: Configuration

    private let data: Data
    private let selection: Binding<Int>?
    private let peek: CGFloat
    private let spacing: CGFloat
    private let showsIndicator: Bool
    private let content: (Data.Element) -> Content

    // MARK: State

    /// The centred page index, kept in sync with the scroll view. Optional
    /// because `scrollPosition(id:)` reports `nil` mid-fling between targets.
    @State private var position: Int?
    /// Set while the carousel is scrolling itself to a programmatically chosen
    /// page, so that move doesn't fire the swipe haptic (the caller owns it).
    @State private var isProgrammaticMove = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - data: The pages to show, in order. Indexed by position (0-based), so
    ///     `selection` and the indicator speak in page indices.
    ///   - selection: Optional two-way binding to the centred page index. The
    ///     carousel writes the landed page as the user swipes and animates to a
    ///     page the binding is set to from outside.
    ///   - peek: How far the neighbouring cards peek in from each edge. The card
    ///     is `containerWidth - 2 · peek` wide; a peeking neighbour shows
    ///     `peek - spacing`. `0` gives a full-bleed pager. Defaults to `DSSpacing.xl`.
    ///   - spacing: Gap between cards. Defaults to `DSSpacing.md`.
    ///   - showsIndicator: Draw a display-only `DSPageControl` under the rail.
    ///     Defaults to `true`.
    ///   - content: Builds a card for a page. Give it its own height — the rail
    ///     sizes itself to the tallest card.
    public init(
        _ data: Data,
        selection: Binding<Int>? = nil,
        peek: CGFloat = DSSpacing.xl,
        spacing: CGFloat = DSSpacing.md,
        showsIndicator: Bool = true,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.selection = selection
        self.peek = peek
        self.spacing = spacing
        self.showsIndicator = showsIndicator
        self.content = content
        self._position = State(initialValue: selection?.wrappedValue ?? 0)
    }

    // MARK: Body

    public var body: some View {
        VStack(spacing: DSSpacing.md) {
            rail

            if showsIndicator && count > 1 {
                DSPageControl(
                    currentPage: indicatorBinding,
                    numberOfPages: count,
                    allowsTap: false
                )
            }
        }
        .onChange(of: position) { _, newValue in
            handlePositionChange(to: newValue)
        }
        .onChange(of: selection?.wrappedValue) { _, newValue in
            handleSelectionChange(to: newValue)
        }
    }

    // MARK: Rail

    private var rail: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, element in
                    content(element)
                        .containerRelativeFrame(.horizontal) { width, _ in
                            max(width - peek * 2, 0)
                        }
                        .scrollTransition { view, phase in
                            view
                                .scaleEffect(scale(for: phase))
                                .opacity(opacity(for: phase))
                        }
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, peek, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $position, anchor: .center)
        .scrollIndicators(.hidden)
    }

    // MARK: Focus falloff

    /// Full size at centre, `restScale` once fully off-centre. Held flat under
    /// Reduce Motion so nothing grows or shrinks as the rail scrolls.
    private func scale(for phase: ScrollTransitionPhase) -> CGFloat {
        guard !reduceMotion else { return 1 }
        return phase.isIdentity ? 1 : Metrics.restScale
    }

    /// Full opacity at centre, `restOpacity` once fully off-centre. Also held
    /// flat under Reduce Motion — the dim reads as motion here, tied to travel.
    private func opacity(for phase: ScrollTransitionPhase) -> Double {
        guard !reduceMotion else { return 1 }
        return phase.isIdentity ? 1 : Metrics.restOpacity
    }

    // MARK: Sync

    private var count: Int { data.count }

    /// Display-only feed for the indicator: it mirrors the centred page and
    /// never writes back (paging is a swipe, `allowsTap: false`).
    private var indicatorBinding: Binding<Int> {
        Binding(get: { position ?? 0 }, set: { _ in })
    }

    /// The finger landed on a new page: publish it and tick — unless we put it
    /// there ourselves, in which case swallow the tick and clear the flag.
    private func handlePositionChange(to newValue: Int?) {
        guard let newValue else { return }
        if selection?.wrappedValue != newValue {
            selection?.wrappedValue = newValue
        }
        if isProgrammaticMove {
            isProgrammaticMove = false
        } else {
            DSHapticEngine.shared.fire(.selection)
        }
    }

    /// The app moved the selection: glide there. The resulting `position` change
    /// is marked programmatic so `handlePositionChange` keeps it silent.
    private func handleSelectionChange(to newValue: Int?) {
        guard let newValue, newValue != position else { return }
        isProgrammaticMove = true
        withAnimation(DSAnimation.springSmooth) {
            position = newValue
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCarouselPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var featured = 0

    private struct Slide: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
    }

    private let slides: [Slide] = [
        Slide(title: "Cabaña en el bosque", subtitle: "$120 / noche"),
        Slide(title: "Loft con vista al mar", subtitle: "$210 / noche"),
        Slide(title: "Estudio en el centro", subtitle: "$95 / noche"),
        Slide(title: "Casa de campo", subtitle: "$160 / noche")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Peeking — neighbours drift and dim").ds(.title3)
                    DSCarousel(slides, selection: $featured) { slide in
                        card(slide.title, slide.subtitle)
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Programmatic control").ds(.title3)
                    HStack(spacing: DSSpacing.sm) {
                        DSButton("Back", variant: .outline, size: .small) {
                            featured = max(0, featured - 1)
                        }
                        DSButton("Next", variant: .primary, size: .small) {
                            featured = min(slides.count - 1, featured + 1)
                        }
                        Spacer()
                        Text("Page \(featured + 1)")
                            .ds(.footnote, color: DSColors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Full-bleed pager — peek: 0").ds(.title3)
                    DSCarousel(slides, peek: 0) { slide in
                        card(slide.title, slide.subtitle)
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func card(_ title: String, _ subtitle: String) -> some View {
        DSCard(style: .elevated) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                RoundedRectangle(cornerRadius: DSRadius.surface, style: .continuous)
                    .fill(theme.gradient.horizontalGradient)
                    .frame(height: DSSpacing.massive + DSSpacing.huge)
                    .dsHueDrift()
                Text(title).ds(.title3)
                Text(subtitle).ds(.callout, color: DSColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
