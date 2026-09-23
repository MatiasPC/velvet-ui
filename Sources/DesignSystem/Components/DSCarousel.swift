import SwiftUI

// MARK: - Design System Carousel
// A snapping, paged carousel for featured content: onboarding pages, hero cards,
// image galleries. Each item spans the carousel width and snaps to centre; as a
// card slides off it scales down and fades, so the incoming card reads as coming
// forward — the App-Store "featured" feel, on Velvet tokens.
//
// This is the motion-rich sibling of `DSHorizontalScroll` (a plain, non-snapping
// Airbnb-style row). Reach for `DSCarousel` when there is a *current* item worth
// tracking — it reports the centred index, ticks a selection haptic on every
// page change, and can draw a `DSPageControl` beneath itself that stays in sync
// and scrolls the deck when tapped.
//
// Built entirely on the iOS 17 scroll APIs — `scrollTargetBehavior(.viewAligned)`
// for the snap, `scrollPosition(id:)` for the centred item, and an interactive
// `scrollTransition` for the depth effect — so both platforms build with no
// UIKit. Technique from Apple's "Beyond scroll views" (WWDC23) and the community
// write-ups linked in the PR; no upstream code is reproduced.

public struct DSCarousel<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {

    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    private let spacing: CGFloat
    private let restScale: CGFloat
    private let restOpacity: Double
    private let showsPageControl: Bool
    private let accent: Color?
    private let onIndexChange: ((Int) -> Void)?
    private let content: (Data.Element) -> Content

    @State private var scrolledID: ID?
    /// Swallows the first `scrolledID` settle (the initial layout picking the
    /// first card) so the carousel doesn't tick a haptic just for appearing.
    @State private var hasSettledOnce = false
    /// Set when a page-control tap drives the scroll, so the resulting settle
    /// doesn't double up on the tap's own `.selection` haptic.
    @State private var suppressHaptic = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Create a carousel.
    /// - Parameters:
    ///   - data: The items to page through.
    ///   - id: Key path to each item's stable identity.
    ///   - spacing: Gap between cards. Defaults to `DSSpacing.md`.
    ///   - restScale: Scale of a card once fully swiped off-centre (1 = no shrink).
    ///   - restOpacity: Opacity of a card once fully swiped off-centre (1 = no fade).
    ///   - showsPageControl: Draw a synced `DSPageControl` beneath the deck.
    ///   - accent: Active page-dot / indicator color. Defaults to the theme accent.
    ///   - onIndexChange: Called with the centred index whenever it changes.
    ///   - content: Card builder. Each card is laid out at the carousel's width.
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        spacing: CGFloat = DSSpacing.md,
        restScale: CGFloat = 0.86,
        restOpacity: Double = 0.5,
        showsPageControl: Bool = true,
        accent: Color? = nil,
        onIndexChange: ((Int) -> Void)? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.id = id
        self.spacing = spacing
        self.restScale = restScale
        self.restOpacity = restOpacity
        self.showsPageControl = showsPageControl
        self.accent = accent
        self.onIndexChange = onIndexChange
        self.content = content
    }

    public var body: some View {
        VStack(spacing: DSSpacing.md) {
            deck

            if showsPageControl && data.count > 1 {
                DSPageControl(
                    currentPage: pageBinding,
                    numberOfPages: data.count,
                    activeColor: accent
                )
            }
        }
        .onAppear {
            // Seed the centred item so the page control is correct from frame one.
            if scrolledID == nil { scrolledID = data.first?[keyPath: id] }
        }
        .onChange(of: scrolledID) { _, _ in
            guard hasSettledOnce else {
                hasSettledOnce = true
                onIndexChange?(currentIndex)
                return
            }
            if suppressHaptic {
                suppressHaptic = false
            } else {
                DSHapticEngine.shared.fire(.selection)
            }
            onIndexChange?(currentIndex)
        }
    }

    // MARK: - Deck

    private var deck: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(data, id: id) { item in
                    content(item)
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(.interactive) { view, phase in
                            view
                                .scaleEffect(scale(for: phase))
                                .opacity(opacity(for: phase))
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledID)
        .scrollIndicators(.hidden)
    }

    // MARK: - Scroll transition

    /// Off-centre cards shrink toward `restScale`. Reduce Motion pins them at 1 —
    /// the snap still works, the depth effect just turns off.
    private func scale(for phase: ScrollTransitionPhase) -> CGFloat {
        let amount = reduceMotion ? 0 : (1 - restScale)
        return 1 - CGFloat(abs(phase.value)) * amount
    }

    /// Off-centre cards fade toward `restOpacity`. Reduce Motion keeps them opaque.
    private func opacity(for phase: ScrollTransitionPhase) -> Double {
        let amount = reduceMotion ? 0 : (1 - restOpacity)
        return 1 - abs(phase.value) * amount
    }

    // MARK: - Index plumbing

    /// The zero-based position of the centred card, or 0 before the first settle.
    private var currentIndex: Int {
        guard
            let scrolledID,
            let index = data.firstIndex(where: { $0[keyPath: id] == scrolledID })
        else { return 0 }
        return data.distance(from: data.startIndex, to: index)
    }

    /// Bridges the `Int`-indexed `DSPageControl` to the id-based scroll position:
    /// reading gives the centred index, writing scrolls the deck to that page.
    private var pageBinding: Binding<Int> {
        Binding(
            get: { currentIndex },
            set: { newIndex in
                guard !data.isEmpty else { return }
                let clamped = max(0, min(newIndex, data.count - 1))
                let target = data.index(data.startIndex, offsetBy: clamped)
                suppressHaptic = true
                withAnimation(reduceMotion ? nil : DSAnimation.springSmooth) {
                    scrolledID = data[target][keyPath: id]
                }
            }
        )
    }
}

// MARK: - Identifiable convenience

public extension DSCarousel where Data.Element: Identifiable, ID == Data.Element.ID {
    /// Create a carousel over `Identifiable` items.
    init(
        _ data: Data,
        spacing: CGFloat = DSSpacing.md,
        restScale: CGFloat = 0.86,
        restOpacity: Double = 0.5,
        showsPageControl: Bool = true,
        accent: Color? = nil,
        onIndexChange: ((Int) -> Void)? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(
            data,
            id: \.id,
            spacing: spacing,
            restScale: restScale,
            restOpacity: restOpacity,
            showsPageControl: showsPageControl,
            accent: accent,
            onIndexChange: onIndexChange,
            content: content
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
        let icon: String
    }

    private let features: [Feature] = [
        Feature(title: "Glass over gradient", subtitle: "One selectable theme, every surface.", icon: "square.stack.3d.up.fill"),
        Feature(title: "Springs, not ramps", subtitle: "Everything you touch answers back.", icon: "hand.tap.fill"),
        Feature(title: "Haptics on the beat", subtitle: "Tactile feedback where it counts.", icon: "waveform.path"),
        Feature(title: "Both platforms build", subtitle: "Pure SwiftUI, iOS and macOS.", icon: "checkmark.seal.fill")
    ]

    @State private var current = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                Text("Featured — page \(current + 1) of \(features.count)")
                    .ds(.footnote, color: DSColors.textSecondary)

                DSCarousel(features, onIndexChange: { current = $0 }) { feature in
                    DSCard(style: .elevated) {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(theme.gradient.horizontalGradient)
                            Text(feature.title).ds(.title2)
                            Text(feature.subtitle)
                                .ds(.callout, color: DSColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                    }
                }

                Text("No page control")
                    .ds(.footnote, color: DSColors.textSecondary)

                DSCarousel(features, showsPageControl: false) { feature in
                    DSImageCard(title: feature.title, subtitle: feature.subtitle, badge: "Featured")
                }
            }
            .dsScreenPadding()
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
