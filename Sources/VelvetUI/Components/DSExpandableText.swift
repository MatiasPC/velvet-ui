import SwiftUI

// MARK: - Design System Expandable Text
// A block of copy that collapses to a few lines and springs open on tap, with
// a rotating chevron and a crossfading "Show more" / "Show less" affordance.
// Long descriptions, reviews, bios and terms all need this; the stock answer is
// a truncated `Text` with no way back. DSExpandableText measures the real
// wrapped height, only shows the toggle when the copy is actually clipped, and
// reveals the rest by animating a clipped frame with the Velvet height spring.
//
// The text itself never re-flows while the height moves: it is laid out in full
// and the frame uncovers it from the top, so no line jumps or re-wraps
// mid-spring. Only the ellipsis on the last collapsed line is swapped, at the
// two instants (the start of an expand, the end of a collapse) when it is
// hidden behind the clip.

// MARK: - Layout rules

/// The pure rules behind `DSExpandableText`, kept apart from SwiftUI so they can
/// be unit tested: how many lines are really shown, when the copy counts as
/// truncated, and how tall the clipped frame is.
enum DSExpandableTextLayout {
    /// Heights are floats from two separate layouts; ignore differences below this.
    static let truncationTolerance: CGFloat = 0.5

    /// A limit of zero or less would show nothing, so it means one line.
    static func lines(for requested: Int) -> Int {
        max(requested, 1)
    }

    /// The copy is truncated when the unbounded layout is taller than the
    /// layout clamped to the line limit.
    static func isTruncated(collapsedHeight: CGFloat, fullHeight: CGFloat) -> Bool {
        fullHeight - collapsedHeight > truncationTolerance
    }

    /// Height the copy frame is held to, or `nil` before both probes have
    /// measured (the text then lays out on its own, which is the collapsed
    /// height, so the first measurement changes nothing on screen).
    static func revealHeight(isExpanded: Bool, collapsedHeight: CGFloat, fullHeight: CGFloat) -> CGFloat? {
        guard collapsedHeight > 0, fullHeight > 0 else { return nil }
        return isExpanded ? fullHeight : collapsedHeight
    }
}

// MARK: - Expandable Text

public struct DSExpandableText: View {
    private let text: String
    private let lineLimit: Int
    private let expandLabel: String
    private let collapseLabel: String
    private let style: DSTextStyle
    private let color: Color?
    private let haptic: DSHapticStyle

    /// The target state: drives the frame height, the chevron and the label.
    @State private var isExpanded = false
    /// Whether the copy is laid out without a line limit. True while expanded and
    /// until a collapse has finished, so the clipped frame always has the whole
    /// paragraph to uncover.
    @State private var showsFullCopy = false
    @State private var collapsedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - text: The copy to show. Read in full by VoiceOver even while clipped.
    ///   - lineLimit: Lines shown while collapsed. Defaults to 3; values below 1 mean 1.
    ///   - expandLabel: The reveal affordance. Defaults to "Show more".
    ///   - collapseLabel: The collapse affordance. Defaults to "Show less".
    ///   - style: Text style for the copy. Defaults to `.body`.
    ///   - color: Copy color. `nil` follows the theme (`textPrimary`).
    ///   - haptic: Feedback fired on toggle. Defaults to `.light`.
    public init(
        _ text: String,
        lineLimit: Int = 3,
        expandLabel: String = "Show more",
        collapseLabel: String = "Show less",
        style: DSTextStyle = .body,
        color: Color? = nil,
        haptic: DSHapticStyle = .light
    ) {
        self.text = text
        self.lineLimit = lineLimit
        self.expandLabel = expandLabel
        self.collapseLabel = collapseLabel
        self.style = style
        self.color = color
        self.haptic = haptic
    }

    private var lines: Int { DSExpandableTextLayout.lines(for: lineLimit) }

    private var isTruncated: Bool {
        DSExpandableTextLayout.isTruncated(collapsedHeight: collapsedHeight, fullHeight: fullHeight)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            copy
            if isTruncated {
                toggleButton
            }
        }
    }

    // MARK: - Copy

    private var copy: some View {
        Text(text)
            .ds(style, color: color)
            .lineLimit(showsFullCopy ? nil : lines)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Held to the measured height and pinned to the top, so the spring
            // uncovers lines instead of re-centring a text whose height changes.
            .frame(
                height: DSExpandableTextLayout.revealHeight(
                    isExpanded: isExpanded,
                    collapsedHeight: collapsedHeight,
                    fullHeight: fullHeight
                ),
                alignment: .top
            )
            .clipped()
            .background(alignment: .topLeading) { measurement }
    }

    // MARK: - Toggle

    private var toggleButton: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.xxs) {
                Text(isExpanded ? collapseLabel : expandLabel)
                    .ds(.buttonSmall, color: theme.ink)
                    .contentTransition(.opacity)
                Image(systemName: "chevron.down")
                    .dsFont(.buttonSmall)
                    .foregroundStyle(theme.ink)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .accessibilityHidden(true)
            }
            // Room above and below so the tap target is more than the text line.
            .padding(.vertical, DSSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isExpanded ? collapseLabel : expandLabel))
        .accessibilityValue(Text(isExpanded ? "Expanded" : "Collapsed"))
    }

    // MARK: - Truncation measurement
    // Two off-screen copies — one clamped to the line limit, one unbounded — laid
    // out at the real text width. The toggle appears only when the unbounded
    // copy is taller, and the result never flips mid-reveal because neither
    // probe depends on `isExpanded`.

    private var measurement: some View {
        ZStack(alignment: .topLeading) {
            Text(text)
                .ds(style)
                .lineLimit(lines)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { collapsedHeight = $0 }

            Text(text)
                .ds(style)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { fullHeight = $0 }
        }
        .hidden()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Toggle action

    private func toggle() {
        DSHapticEngine.shared.fire(haptic)

        // Reduce Motion: no spring and no sweeping chevron, just the new state.
        guard !reduceMotion else {
            isExpanded.toggle()
            showsFullCopy = isExpanded
            return
        }

        if isExpanded {
            // Keep the full copy until the frame has closed over it, then bring
            // back the ellipsis while the last line is the only thing showing.
            withAnimation(DSAnimation.springSmooth) {
                isExpanded = false
            } completion: {
                if !isExpanded { showsFullCopy = false }
            }
        } else {
            // Lay the full copy out first (nothing moves, the clip still holds
            // the collapsed height), then let the spring uncover it.
            showsFullCopy = true
            withAnimation(DSAnimation.springSmooth) {
                isExpanded = true
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSExpandableTextPreviewHost: View {
    @State private var theme = DSTheme(style: .aurora)

    private let bio = """
    Velvet UI is a small, opinionated SwiftUI library: frosted glass over a \
    page tone, spring motion on everything you touch, and haptics that \
    make the interface feel alive. Every component honors Reduce Motion, Reduce \
    Transparency and Dynamic Type out of the box, so you spend your time on the \
    app and not on the plumbing underneath it.
    """

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("About").ds(.title3)
                        DSExpandableText(bio)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Two lines, custom labels").ds(.title3)
                        DSExpandableText(
                            bio,
                            lineLimit: 2,
                            expandLabel: "Read more",
                            collapseLabel: "Read less",
                            style: .callout,
                            color: DSColors.textSecondary
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Short — no toggle").ds(.title3)
                        DSExpandableText("One line of copy that fits and never clips.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.lg)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Expandable Text — Light") {
    DSExpandableTextPreviewHost().preferredColorScheme(.light)
}

#Preview("Expandable Text — Dark") {
    DSExpandableTextPreviewHost().preferredColorScheme(.dark)
}
#endif
