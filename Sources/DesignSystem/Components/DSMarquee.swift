import SwiftUI

// MARK: - Design System Marquee
// A seamless auto-scrolling ticker for content that is wider than the space
// it's given. Perfect for "now playing" bars, breaking-news tickers, stock
// strips, or any long label/title squeezed into a constrained row.
//
// The motion is a true infinite loop: two copies of the content chase each
// other so the seam is never visible, driven by `TimelineView(.animation)` for
// buttery, frame-synced scrolling. When the content already fits, the marquee
// renders statically — no pointless motion. Tap to pause and read; tap again
// to resume, right where it left off. Soft edge fades keep the entrance and
// exit graceful, and Reduce Motion is honored by holding the content still.
//
// Fully generic over any `View`, with a `Text` convenience for the common case.
//
// Inspiration: the classic UIKit `MarqueeLabel` reimagined in pure SwiftUI, and
// the community `TimelineView`-driven ticker pattern (Swift with Majid —
// "Mastering TimelineView in SwiftUI").

// MARK: - Direction

public enum DSMarqueeDirection: Sendable {
    /// Content scrolls toward the leading edge (right-to-left in LTR) — the
    /// familiar news-ticker feel.
    case leading
    /// Content scrolls toward the trailing edge (left-to-right in LTR).
    case trailing
}

// MARK: - Marquee

public struct DSMarquee<Content: View>: View {

    // MARK: - Configuration

    private let velocity: CGFloat
    private let spacing: CGFloat
    private let direction: DSMarqueeDirection
    private let fadeWidth: CGFloat
    private let pausable: Bool
    private let content: Content

    // MARK: - Measurement

    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    // MARK: - Playback State

    /// Anchor for elapsed-time math. Shifted forward by the paused duration on
    /// resume so scrolling continues exactly where it froze.
    @State private var startDate = Date()
    @State private var pauseDate = Date()
    @State private var isPaused = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Create a marquee that scrolls its content when it overflows the
    /// available width.
    /// - Parameters:
    ///   - velocity: Scroll speed in points per second. Defaults to `40`.
    ///   - spacing: Gap between the repeated copies of the content. Defaults to
    ///     `DSSpacing.xxl` — the breathing room before the loop repeats.
    ///   - direction: Which way the content travels. Defaults to `.leading`.
    ///   - fadeWidth: Length of the soft fade at each edge. Pass `0` to disable.
    ///     Defaults to `DSSpacing.xl`.
    ///   - pausable: Whether tapping pauses and resumes the scroll. Defaults to `true`.
    ///   - content: The view to scroll (kept to a single line).
    public init(
        velocity: CGFloat = 40,
        spacing: CGFloat = DSSpacing.xxl,
        direction: DSMarqueeDirection = .leading,
        fadeWidth: CGFloat = DSSpacing.xl,
        pausable: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.velocity = max(1, velocity)
        self.spacing = max(0, spacing)
        self.direction = direction
        self.fadeWidth = max(0, fadeWidth)
        self.pausable = pausable
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        TimelineView(.animation(paused: !isAnimating || isPaused)) { context in
            strip(offset: offset(for: context.date))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: ContainerWidthKey.self, value: geo.size.width)
            }
        )
        .clipped()
        .mask { edgeMask }
        .contentShape(Rectangle())
        .onPreferenceChange(ContentWidthKey.self) { contentWidth = $0 }
        .onPreferenceChange(ContainerWidthKey.self) { containerWidth = $0 }
        .onChange(of: contentWidth) { _, _ in resetAnchor() }
        .onChange(of: containerWidth) { _, _ in resetAnchor() }
        .onTapGesture { togglePause() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(pausable && isAnimating ? .isButton : [])
    }

    // MARK: - Scrolling Strip

    private func strip(offset: CGFloat) -> some View {
        HStack(spacing: spacing) {
            cell
            if isAnimating {
                cell.accessibilityHidden(true)
            }
        }
        .offset(x: offset)
    }

    /// One measured copy of the content, laid out at its natural width.
    private var cell: some View {
        content
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ContentWidthKey.self, value: geo.size.width)
                }
            )
    }

    // MARK: - Edge Fade

    @ViewBuilder
    private var edgeMask: some View {
        if isAnimating && fadeWidth > 0 {
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: fadeWidth)

                Color.black

                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: fadeWidth)
            }
        } else {
            Color.black
        }
    }

    // MARK: - Motion Math

    /// The content overflows and motion is allowed.
    private var isAnimating: Bool {
        !reduceMotion && containerWidth > 0 && contentWidth > containerWidth + 1
    }

    /// Distance the loop travels before repeating.
    private var travel: CGFloat {
        contentWidth + spacing
    }

    /// Current horizontal offset for the given tick, wrapped seamlessly.
    private func offset(for date: Date) -> CGFloat {
        guard isAnimating, travel > 0 else { return 0 }
        let elapsed = CGFloat(date.timeIntervalSince(startDate))
        let distance = (elapsed * velocity).truncatingRemainder(dividingBy: travel)
        let wrapped = distance < 0 ? distance + travel : distance
        switch direction {
        case .leading:  return -wrapped
        case .trailing: return wrapped - travel
        }
    }

    // MARK: - Playback Control

    private func resetAnchor() {
        startDate = Date()
        isPaused = false
    }

    private func togglePause() {
        guard pausable, isAnimating else { return }
        if isPaused {
            // Shift the anchor forward by the paused duration so the offset
            // resumes exactly where it froze.
            startDate = startDate.addingTimeInterval(Date().timeIntervalSince(pauseDate))
            isPaused = false
        } else {
            pauseDate = Date()
            isPaused = true
        }
        DSHapticEngine.shared.fire(.soft)
    }
}

// MARK: - Preference Keys

private struct DSMarqueeContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct DSMarqueeContainerWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private typealias ContentWidthKey = DSMarqueeContentWidthKey
private typealias ContainerWidthKey = DSMarqueeContainerWidthKey

// MARK: - Text Convenience

public extension DSMarquee where Content == Text {
    /// Create a marquee from a string, styled with a Design System text style.
    /// - Parameters:
    ///   - text: The string to scroll.
    ///   - style: The Design System text style. Defaults to `.body`.
    ///   - color: Text color. Defaults to the primary text color.
    ///   - velocity: Scroll speed in points per second. Defaults to `40`.
    ///   - spacing: Gap between repeated copies. Defaults to `DSSpacing.xxl`.
    ///   - direction: Scroll direction. Defaults to `.leading`.
    ///   - fadeWidth: Edge fade length. Pass `0` to disable. Defaults to `DSSpacing.xl`.
    ///   - pausable: Whether tapping pauses and resumes. Defaults to `true`.
    init(
        _ text: String,
        style: DSTextStyle = .body,
        color: Color = DSColors.defaultPalette.textPrimary,
        velocity: CGFloat = 40,
        spacing: CGFloat = DSSpacing.xxl,
        direction: DSMarqueeDirection = .leading,
        fadeWidth: CGFloat = DSSpacing.xl,
        pausable: Bool = true
    ) {
        self.init(
            velocity: velocity,
            spacing: spacing,
            direction: direction,
            fadeWidth: fadeWidth,
            pausable: pausable
        ) {
            Text(text)
                .font(style.font)
                .kerning(style.kerning)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

#Preview {
    struct MarqueePreview: View {
        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.xxl) {

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("News ticker")
                        .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSMarquee(
                        "Breaking: Velvet UI now ships a seamless, tappable marquee for tickers and long labels — pure SwiftUI, iOS 17+.",
                        style: .callout,
                        color: DSColors.defaultPalette.textSecondary
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Now playing")
                        .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    HStack(spacing: DSSpacing.sm) {
                        Image(systemName: "music.note")
                            .foregroundStyle(DSColors.defaultPalette.primary)
                        DSMarquee(
                            "Midnight City · M83 · Hurry Up, We're Dreaming",
                            style: .footnote,
                            color: DSColors.defaultPalette.textPrimary
                        )
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Trailing, faster")
                        .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSMarquee(
                        "This one drifts the other way, a touch quicker — great for contrast.",
                        style: .callout,
                        color: DSColors.defaultPalette.secondary,
                        velocity: 60,
                        direction: .trailing
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Fits — stays still")
                        .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSMarquee("Short label", style: .callout)
                }
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return Group {
        MarqueePreview()
            .preferredColorScheme(.light)
        MarqueePreview()
            .preferredColorScheme(.dark)
    }
}
