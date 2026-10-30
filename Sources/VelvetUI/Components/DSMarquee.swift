import SwiftUI

// MARK: - Design System Marquee
// Content that scrolls horizontally in a seamless loop — but only when it is too
// wide to fit. A "now playing" line, a long chip title, a ticker of stats: text
// that would otherwise truncate keeps moving so all of it can be read.
//
// The loop is two copies of the content laid end to end with a gap, translated by
// exactly one copy's width and then wrapped — so the seam never shows. Content
// that already fits stays put, left-aligned, with no motion at all. Soft edge
// fades (a gradient mask, not a border) tell the eye the text runs past the edge.
//
// Pure SwiftUI, both platforms. It measures with `onGeometryChange` (iOS 18 /
// macOS 15), scrolls with a linear `DSAnimation` rate and rests completely under
// Reduce Motion, where the content is shown static with a trailing fade.
//
// Inspiration: the duplicated-content loop is the common SwiftUI marquee recipe —
// Canopas, "iOS — Infinite Marquee Animation with SwiftUI"
// (https://canopas.com/ios-infinite-marquee-nimation-with-swiftui-e15419083ca2),
// harflabs/MarqueeText (scroll-only-on-overflow, configurable spacing) and Monty
// Harper's "MarqueeView" write-up. Rewritten on Velvet tokens; no upstream code
// is reproduced.

public struct DSMarquee<Content: View>: View {

    /// Scroll rate in points per second. Linear, so the speed reads constant
    /// regardless of how long the content is.
    private let velocity: CGFloat
    /// Gap between the end of one copy and the start of the next.
    private let spacing: CGFloat
    /// Width of the soft edge fade on each side. `0` disables the fade.
    private let fade: CGFloat
    private let content: Content

    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - velocity: Scroll speed in points per second. Defaults to a calm 40.
    ///   - spacing: Gap between the looping copies. Defaults to `DSSpacing.xxxl`.
    ///   - fade: Edge-fade width on each side. Defaults to `DSSpacing.lg`; pass `0` for hard edges.
    ///   - content: The content to scroll. Keep it to a single line (text, a badge, a small row).
    public init(
        velocity: CGFloat = DSMarquee.defaultVelocity,
        spacing: CGFloat = DSSpacing.xxxl,
        fade: CGFloat = DSSpacing.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.velocity = velocity
        self.spacing = spacing
        self.fade = fade
        self.content = content()
    }

    /// Default scroll rate. Not a spacing/size token, so it lives here as a named
    /// constant rather than a magic number at the call site.
    public static var defaultVelocity: CGFloat { 40 }

    /// The content runs past the container, so there is something to scroll to.
    private var overflowing: Bool { contentWidth > containerWidth + 0.5 }
    /// Scroll only when it overflows, motion is allowed and the rate is positive.
    private var animates: Bool { overflowing && !reduceMotion && velocity > 0 }

    public var body: some View {
        let distance = contentWidth + spacing
        return Group {
            if animates {
                DSMarqueeTrack(distance: distance, velocity: velocity, spacing: spacing, content: singleCopy)
                    // Remount (and so restart at offset 0) whenever the measured
                    // geometry or the configured rate changes.
                    .id("\(Int(contentWidth.rounded()))·\(Int(containerWidth.rounded()))·\(Int(spacing))·\(Int(velocity))")
            } else {
                singleCopy
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(alignment: .leading) { measuringCopy }
        .clipped()
        .mask { fadeMask }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Copies

    /// One natural-width, single-line copy of the content.
    private var singleCopy: some View {
        content
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    /// A hidden copy, laid out behind the marquee, whose width we measure.
    private var measuringCopy: some View {
        content
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .hidden()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
            .accessibilityHidden(true)
    }

    // MARK: - Edge fade

    /// A horizontal gradient used as a mask: `.black` shows, `.clear` hides. Both
    /// edges fade while scrolling; a static overflow fades only the trailing edge;
    /// content that fits is fully opaque.
    private var fadeMask: some View {
        let total = max(containerWidth, 1)
        let lead = animates ? fade : 0
        let trail = (animates || (overflowing && reduceMotion)) ? fade : 0
        let leadFrac = min(max(lead / total, 0), 0.5)
        let trailFrac = min(max(trail / total, 0), 0.5)
        return LinearGradient(
            stops: [
                .init(color: leadFrac > 0 ? .clear : .black, location: 0),
                .init(color: .black, location: leadFrac),
                .init(color: .black, location: 1 - trailFrac),
                .init(color: trailFrac > 0 ? .clear : .black, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Track

/// The scrolling layer: two copies end to end, translated by one copy's width plus
/// the gap and looped forever. Kept as its own view so a changed `.id` remounts it
/// and the animation restarts cleanly at offset 0.
private struct DSMarqueeTrack<Content: View>: View {
    let distance: CGFloat
    let velocity: CGFloat
    let spacing: CGFloat
    let content: Content

    @State private var offset: CGFloat = 0

    var body: some View {
        HStack(spacing: spacing) {
            content
            content.accessibilityHidden(true)
        }
        .offset(x: offset)
        .onAppear {
            let duration = Double(max(distance, 1) / max(velocity, 1))
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                offset = -distance
            }
        }
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

                label("Overflowing text — scrolls")
                DSCard {
                    DSMarquee {
                        Text("Now playing — Midnight City · M83 · Hurry Up, We're Dreaming")
                            .ds(.callout)
                    }
                }

                label("Fits — stays put")
                DSCard {
                    DSMarquee {
                        Text("Short label").ds(.callout)
                    }
                }

                label("Mixed content — a badge rides along")
                DSCard {
                    DSMarquee(velocity: 28) {
                        HStack(spacing: DSSpacing.xs) {
                            DSBadge("LIVE", color: DSColors.error, variant: .filled)
                            Text("Breaking: Velvet UI ships a seamless marquee with glass edge fades")
                                .ds(.footnote)
                        }
                    }
                }

                label("A row of stats")
                DSMarquee(spacing: DSSpacing.xxl) {
                    HStack(spacing: DSSpacing.xxl) {
                        stat("Steps", "8,420")
                        stat("Calories", "612 kcal")
                        stat("Distance", "6.1 km")
                        stat("Active", "1 h 12 m")
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

    private func stat(_ title: String, _ value: String) -> some View {
        HStack(spacing: DSSpacing.xs) {
            Text(title).ds(.caption1, color: DSColors.textSecondary)
            Text(value).ds(.numeric)
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
