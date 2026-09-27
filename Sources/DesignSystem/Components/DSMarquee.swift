import SwiftUI

// MARK: - Design System Marquee
// Seamless, self-scrolling content for a strip too narrow to hold it: a
// now-playing line, a live ticker, a scrolling announcement, an overflowing
// label. Ambient motion in the DSMotion sense — eased constant speed, not a
// spring — so it belongs with the loops, not the interactions. No haptics: like
// DSThinkingIndicator and DSTypewriterText it is a status surface, not a control.
//
// The loop is a pure function of time. Two copies of the content ride an HStack
// and the offset is the elapsed distance taken modulo one copy-plus-gap, so the
// instant the first copy clears the left edge the second sits exactly where it
// began — no seam, no snap, no animation to restart. Technique adapted from the
// SwiftUI community's TimelineView marquees (objc.io Swift Talk "Interactive
// Marquee", Canopas "Infinite Marquee"); rewritten on Velvet tokens.
//
// It only scrolls when the content actually overflows; a line that fits sits
// still, leading-aligned. Under Reduce Motion nothing travels — the content
// settles static and the trailing edge fades where it is clipped, rather than
// the effect being skipped. Both fade edges use black/clear as a *mask* (alpha,
// not colour), the same structural trick DSWash uses with white for the edge
// highlight, so the strip stays theme-agnostic.

public struct DSMarquee<Content: View>: View {
    private let content: Content
    private let velocity: CGFloat
    private let spacing: CGFloat
    private let fade: CGFloat

    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var start = Date()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A strip that scrolls its content only when the content is wider than the
    /// space it is given.
    /// - Parameters:
    ///   - velocity: Scroll speed in points per second. Clamped to at least 1.
    ///   - spacing: Gap between the end of one pass and the start of the next.
    ///   - fade: Width of the soft fade at each edge, so content emerges and
    ///     leaves instead of hard-clipping. Pass `0` for a crisp edge.
    ///   - content: Any view. Text is the common case; an icon-plus-label row,
    ///     a set of badges or a "Live" tag all work.
    public init(
        velocity: CGFloat = 40,
        spacing: CGFloat = DSSpacing.xxl,
        fade: CGFloat = DSSpacing.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.velocity = max(velocity, 1)
        self.spacing = max(spacing, 0)
        self.fade = max(fade, 0)
    }

    /// The content needs to move only when it cannot fit. The 0.5pt slack keeps a
    /// content width that lands a hair over the container from starting a scroll
    /// that travels almost nothing.
    private var overflowing: Bool { contentWidth > containerWidth + 0.5 }

    /// Travel for one seamless cycle: one copy of the content plus the gap.
    private var distance: CGFloat { contentWidth + spacing }

    public var body: some View {
        track
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: DSMarqueeContainerKey.self, value: proxy.size.width)
                }
            )
            .onPreferenceChange(DSMarqueeContainerKey.self) { containerWidth = $0 }
            .mask { fadeMask }
            .overlay { measuringCopy }
            .onAppear { start = Date() }
    }

    // MARK: - Track

    @ViewBuilder
    private var track: some View {
        if overflowing && !reduceMotion {
            TimelineView(.animation) { timeline in
                movingRow.offset(x: wrappedOffset(at: timeline.date))
            }
        } else {
            // Fits, or Reduce Motion: rest at the leading edge. If it still
            // overflows here, the fade mask clips the trailing end softly.
            content.fixedSize()
        }
    }

    private var movingRow: some View {
        HStack(spacing: spacing) {
            content
            // The trailing copy is the same words again — hide it from
            // VoiceOver so the line is announced once.
            content.accessibilityHidden(true)
        }
        .fixedSize()
    }

    /// Offset as a pure function of elapsed time, wrapped into `[-distance, 0]`.
    /// At `-distance` the trailing copy has reached the leading copy's start, so
    /// the wrap back to `0` is invisible.
    private func wrappedOffset(at date: Date) -> CGFloat {
        guard distance > 0 else { return 0 }
        let travelled = max(0, date.timeIntervalSince(start)) * Double(velocity)
        return -CGFloat(travelled.truncatingRemainder(dividingBy: Double(distance)))
    }

    // MARK: - Measurement

    /// An invisible single copy laid out at its intrinsic width, read only to
    /// decide whether the content overflows. `.hidden()` keeps it out of the
    /// render and out of accessibility while preserving its size.
    private var measuringCopy: some View {
        content
            .fixedSize()
            .hidden()
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: DSMarqueeContentKey.self, value: proxy.size.width)
                }
            )
            .onPreferenceChange(DSMarqueeContentKey.self) { contentWidth = $0 }
            .allowsHitTesting(false)
    }

    // MARK: - Edge Fade

    /// A left-to-right alpha ramp: clear → opaque → opaque → clear. `black`/`clear`
    /// carry alpha only, so this masks (and clips) without introducing colour.
    /// When the content fits, the fade fraction collapses to zero and the mask is
    /// fully opaque.
    private var fadeMask: some View {
        GeometryReader { proxy in
            let fraction = (overflowing && proxy.size.width > 0)
                ? min(fade / proxy.size.width, 0.5)
                : 0
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: fraction),
                    .init(color: .black, location: 1 - fraction),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Width Preference Keys

private struct DSMarqueeContentKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct DSMarqueeContainerKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Preview

#if DEBUG
private struct DSMarqueePreviewHost: View {
    @State private var theme = DSTheme()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                label("Now playing — scrolls, it overflows")
                DSCard {
                    HStack(spacing: DSSpacing.sm) {
                        Image(systemName: "waveform")
                            .foregroundStyle(theme.gradient.accent)
                            .dsBreathe(.subtle)
                        DSMarquee {
                            Text("Midnight City — M83 · from the album Hurry Up, We're Dreaming")
                                .ds(.body)
                        }
                    }
                }

                label("Live ticker — mixed content")
                DSCard {
                    DSMarquee(velocity: 55) {
                        HStack(spacing: DSSpacing.md) {
                            tickerItem("AAPL", "+1.2%", DSColors.success)
                            tickerItem("TSLA", "−0.8%", DSColors.error)
                            tickerItem("BTC", "+3.4%", DSColors.success)
                            tickerItem("EURUSD", "+0.1%", DSColors.success)
                        }
                    }
                }

                label("Fits — stays still, leading-aligned")
                DSCard {
                    DSMarquee {
                        Text("All good here").ds(.body)
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func label(_ text: String) -> some View {
        Text(text).ds(.overline, color: DSColors.textSecondary)
    }

    private func tickerItem(_ symbol: String, _ change: String, _ color: Color) -> some View {
        HStack(spacing: DSSpacing.xxs) {
            Text(symbol).ds(.footnote)
            Text(change).ds(.footnote, color: color)
        }
    }
}

#Preview("Marquee — Light") {
    DSMarqueePreviewHost().preferredColorScheme(.light)
}

#Preview("Marquee — Dark") {
    DSMarqueePreviewHost().preferredColorScheme(.dark)
}
#endif
