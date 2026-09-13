import SwiftUI

// MARK: - Design System Carousel
// A horizontally paging carousel where the centred card sits at full size and
// its neighbours shrink and dim as they leave centre — the App Store "featured"
// feel, translated to Velvet glass.
//
// It is the motion-rich counterpart to `DSHorizontalScroll` (Layout): that one
// is a plain edge-to-edge row, this one snaps, focuses the centre and ticks a
// `.selection` haptic as each card takes the middle. Built entirely on the
// iOS 17 scroll stack — `scrollTargetLayout` / `scrollTargetBehavior(.viewAligned)`
// for the snap, `containerRelativeFrame` for the page width, `contentMargins`
// for the peek, and a `scrollTransition(.interactive)` that tracks the drag 1:1
// so the focus effect follows the finger instead of animating after it.
//
// Technique from Apple's WWDC23 "Beyond scroll views" and the community App
// Store-carousel pattern (AppCoda, Insub). Rewritten on Velvet tokens: spacing
// and peek from `DSSpacing`, haptics through `DSHapticEngine`, height driven by
// the caller's content (no forced frame), Reduce Motion honoured as a resting
// state rather than a skip.

public struct DSCarousel<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Identifiable {

    private let data: Data
    private let spacing: CGFloat
    private let peek: CGFloat
    private let minScale: CGFloat
    private let minOpacity: Double
    private let haptics: Bool
    private let content: (Data.Element) -> Content

    /// The id of the card currently holding the centre. Drives the `.selection`
    /// haptic and stays internal — a caller who needs to observe or drive the
    /// position is a second use case that can add a binding later.
    @State private var centeredID: Data.Element.ID?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - data: The items to page through. Each must be `Identifiable`; its id
    ///     is what the snap and the haptic track.
    ///   - spacing: Gap between cards. Defaults to `DSSpacing.md`.
    ///   - peek: How much of the neighbouring cards shows past the centred one,
    ///     on each side. Defaults to `DSSpacing.xl`; pass `0` for a full-width
    ///     pager with no peek.
    ///   - minScale: Scale of a card at the edge of the transition (centre stays
    ///     `1`). Defaults to `0.86`.
    ///   - minOpacity: Opacity of a card at the edge of the transition (centre
    ///     stays `1`). Defaults to `0.55`.
    ///   - haptics: Fire a `.selection` tick each time a new card takes the
    ///     centre. Defaults to `true`.
    ///   - content: Builds the card for one item. It is sized to the page width
    ///     automatically; give it its own height.
    public init(
        _ data: Data,
        spacing: CGFloat = DSSpacing.md,
        peek: CGFloat = DSSpacing.xl,
        minScale: CGFloat = 0.86,
        minOpacity: Double = 0.55,
        haptics: Bool = true,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.spacing = spacing
        self.peek = peek
        self.minScale = minScale
        self.minOpacity = minOpacity
        self.haptics = haptics
        self.content = content
    }

    public var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(data) { element in
                    content(element)
                        // Each card fills the page width; `contentMargins` below
                        // narrows that page so the neighbours peek by `peek`.
                        .containerRelativeFrame(.horizontal)
                        // `.interactive` tracks the drag 1:1: the focus follows
                        // the finger rather than catching up after the snap.
                        .scrollTransition(.interactive) { view, phase in
                            view
                                .scaleEffect(scale(for: phase))
                                .opacity(opacity(for: phase))
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, peek, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $centeredID)
        .scrollIndicators(.hidden)
        .onChange(of: centeredID) { oldValue, newValue in
            // No tick on the initial layout (nil → first id): only when the
            // user actually moves a new card into the centre.
            guard haptics, oldValue != nil, newValue != nil else { return }
            DSHapticEngine.shared.fire(.selection)
        }
    }

    // MARK: - Focus effect

    /// `phase.value` is `0` at the centre and approaches `±1` at the edges, so
    /// `abs` gives a clean 0→1 "distance from centre". Under Reduce Motion the
    /// card rests at full size — the shrink is decoration, not information.
    private func scale(for phase: ScrollTransitionPhase) -> CGFloat {
        guard !reduceMotion else { return 1 }
        return 1 - (1 - minScale) * CGFloat(abs(phase.value))
    }

    private func opacity(for phase: ScrollTransitionPhase) -> Double {
        guard !reduceMotion else { return 1 }
        return 1 - (1 - minOpacity) * abs(phase.value)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCarouselPreviewItem: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let symbol: String
}

private struct DSCarouselPreviewHost: View {
    @State private var theme = DSTheme()

    private let items: [DSCarouselPreviewItem] = [
        .init(id: 0, title: "Golden hour", subtitle: "Sunset walk · 2.4 km", symbol: "sun.max.fill"),
        .init(id: 1, title: "Deep focus", subtitle: "45 min · no distractions", symbol: "moon.stars.fill"),
        .init(id: 2, title: "Morning brew", subtitle: "Pour-over · 3 cups", symbol: "cup.and.saucer.fill"),
        .init(id: 3, title: "Trail run", subtitle: "6.1 km · 312 kcal", symbol: "figure.run")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                Text("Featured").ds(.title2)
                    .dsScreenPadding()

                DSCarousel(items) { item in
                    poster(item)
                }

                Text("No peek, gentler focus").ds(.footnote, color: DSColors.textSecondary)
                    .dsScreenPadding()

                DSCarousel(items, peek: 0, minScale: 0.94, minOpacity: 0.8) { item in
                    poster(item)
                }
            }
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func poster(_ item: DSCarouselPreviewItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous)
                .fill(theme.gradient.linearGradient)

            Image(systemName: item.symbol)
                .font(.largeTitle)
                .foregroundStyle(theme.gradient.onAccent.opacity(0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(DSSpacing.lg)

            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(item.title).ds(.title2, color: theme.gradient.onAccent)
                Text(item.subtitle).ds(.callout, color: theme.gradient.onAccent.opacity(0.85))
            }
            .padding(DSSpacing.lg)
        }
        .frame(height: 220)
        .dsWashEdge(radius: DSRadius.card)
        .dsShadow(.md)
    }
}

#Preview("Carousel — Light") {
    DSCarouselPreviewHost().preferredColorScheme(.light)
}

#Preview("Carousel — Dark") {
    DSCarouselPreviewHost().preferredColorScheme(.dark)
}
#endif
