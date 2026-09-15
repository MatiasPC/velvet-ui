import SwiftUI

// MARK: - Design System Carousel
// A snapping, one-card-at-a-time carousel with peeking neighbours. The centred
// card is at full size; the cards on either side shrink and dim as they cross
// the edge, so focus reads instantly and the peek invites a swipe. Built on the
// iOS 17 scroll stack — `.scrollTargetBehavior(.viewAligned)` snaps each card to
// centre, `.scrollTransition` drives the depth, `.contentMargins` creates the
// peek, and `.scrollPosition(id:)` is the single source of truth for which card
// is centred. That last binding is what lets a `DSPageControl` stay in sync:
// bind both to the same selection and they drive each other.
//
// This is the paging counterpart to `DSHorizontalScroll` (a free-scrolling row):
// reach for the carousel when the row is a set of *pages* — featured content,
// onboarding, a gallery — and for `DSHorizontalScroll` when it is a shelf that
// scrolls freely.
//
// Technique: Apple's "Beyond scroll views" (WWDC23) peeking-carousel recipe,
// rebuilt on Velvet tokens, springs and haptics.

// MARK: - Metrics

private enum Metrics {
    /// Side cards shrink to 90% at the container edge — enough to read as depth
    /// without the neighbour looking like a smaller *kind* of card.
    static let restScale: CGFloat = 0.9
    /// …and dim to 55%, so the centred card is unambiguously the focus.
    static let restOpacity: Double = 0.55
}

// MARK: - DSCarousel

/// A horizontally paging carousel: one card centred at a time, its neighbours
/// peeking and dimmed. Snaps to each card and reports the centred one through
/// `selection`.
///
///     DSCarousel(features) { feature in
///         FeatureCard(feature)
///     }
///
/// Pair it with a `DSPageControl` by binding both to the same selection — the
/// carousel drives the dots on a swipe, and tapping a dot scrolls the carousel:
///
///     @State private var selected: Feature.ID?
///
///     DSCarousel(features, selection: $selected) { FeatureCard($0) }
///     DSPageControl(currentPage: pageBinding, numberOfPages: features.count)
///
/// The cards size themselves — give the content a fixed height so every page is
/// uniform, exactly as you would for a `DSImageCard` shelf.
public struct DSCarousel<Item: Identifiable, Content: View>: View {

    // MARK: Configuration

    private let items: [Item]
    private let spacing: CGFloat
    private let peek: CGFloat
    private let content: (Item) -> Content

    // MARK: State

    /// The centred card, mirrored out to the caller when a `selection` binding
    /// was provided. Scroll position is the single source of truth for "which
    /// card is centred", so this and `selection` are kept in step both ways.
    @Binding private var selection: Item.ID?
    /// What `.scrollPosition(id:)` reads and writes. Initialised from the caller's
    /// selection (or the first card) so no spurious "changed" haptic fires on
    /// appear.
    @State private var scrollID: Item.ID?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - items: The pages, in order. Each must be `Identifiable`.
    ///   - spacing: Gap between cards. Defaults to `DSSpacing.md` (16).
    ///   - peek: How much of the neighbouring cards shows on each side.
    ///     Defaults to `DSSpacing.xl` (24). Set to `0` for full-width pages.
    ///   - selection: Optional binding to the centred card's id. Bind a
    ///     `DSPageControl` to the same value to keep the two in sync.
    ///   - content: Builds the card for one item. Give it a fixed height so the
    ///     pages are uniform.
    public init(
        _ items: [Item],
        spacing: CGFloat = DSSpacing.md,
        peek: CGFloat = DSSpacing.xl,
        selection: Binding<Item.ID?>? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.peek = peek
        self.content = content
        let selectionBinding = selection ?? .constant(nil)
        self._selection = selectionBinding
        self._scrollID = State(initialValue: selectionBinding.wrappedValue ?? items.first?.id)
    }

    // MARK: Body

    public var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(items) { item in
                    content(item)
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                            view
                                .scaleEffect(scale(for: phase))
                                .opacity(opacity(for: phase))
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollID)
        .contentMargins(.horizontal, peek, for: .scrollContent)
        .scrollIndicators(.hidden)
        // Scroll → selection. Only real changes reach here (init seeded the
        // starting value), so this is the one place the centring haptic fires.
        .onChange(of: scrollID) { _, newValue in
            if selection != newValue { selection = newValue }
            DSHapticEngine.shared.fire(.selection)
        }
        // Selection → scroll. Lets a tapped `DSPageControl` page the carousel.
        // Guarded so the round trip above can't loop.
        .onChange(of: selection) { _, newValue in
            guard let newValue, scrollID != newValue else { return }
            withAnimation(DSAnimation.springSmooth) { scrollID = newValue }
        }
    }

    // MARK: Depth

    /// Full size at centre, easing to `restScale` at the container edge. Under
    /// Reduce Motion the cards hold full size — the swipe still scrolls, but
    /// nothing grows or shrinks under the finger.
    private func scale(for phase: ScrollTransitionPhase) -> CGFloat {
        guard !reduceMotion else { return 1 }
        return 1 - (1 - Metrics.restScale) * CGFloat(abs(phase.value))
    }

    /// Full opacity at centre, easing to `restOpacity` at the edge. Held flat
    /// under Reduce Motion for the same reason as `scale(for:)`.
    private func opacity(for phase: ScrollTransitionPhase) -> Double {
        guard !reduceMotion else { return 1 }
        return 1 - (1 - Metrics.restOpacity) * Double(abs(phase.value))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCarouselSample: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String

    static let all: [DSCarouselSample] = [
        .init(title: "Glass surfaces", subtitle: "Frosted material over a live gradient", symbol: "square.on.square"),
        .init(title: "One theme knob", subtitle: "Swap the gradient, the whole app re-tints", symbol: "paintpalette"),
        .init(title: "Motion on the beat", subtitle: "Springs for touch, eased curves for ambience", symbol: "waveform.path"),
        .init(title: "Haptics that fit", subtitle: "Tactile feedback on every real interaction", symbol: "hand.tap")
    ]
}

private struct DSCarouselPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var selection: DSCarouselSample.ID? = DSCarouselSample.all.first?.id

    private var pageBinding: Binding<Int> {
        Binding {
            DSCarouselSample.all.firstIndex { $0.id == selection } ?? 0
        } set: { newIndex in
            selection = DSCarouselSample.all[newIndex].id
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                DSCarousel(DSCarouselSample.all, selection: $selection) { item in
                    card(item)
                }

                DSPageControl(
                    currentPage: pageBinding,
                    numberOfPages: DSCarouselSample.all.count
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func card(_ item: DSCarouselSample) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            RoundedRectangle(cornerRadius: DSRadius.surface, style: .continuous)
                .fill(theme.gradient.linearGradient)
                .frame(height: 120)
                .overlay {
                    Image(systemName: item.symbol)
                        .dsTextStyle(.hero, color: theme.gradient.onAccent)
                }
                .dsWashEdge(radius: DSRadius.surface)

            Text(item.title).ds(.title3)
            Text(item.subtitle)
                .ds(.callout, color: DSColors.textSecondary)
                .lineLimit(2)
        }
        .padding(DSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsSurface(.glass, radius: DSRadius.card)
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
