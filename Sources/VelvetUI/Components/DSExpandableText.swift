import SwiftUI

// MARK: - Design System Expandable Text
// A block of copy that collapses to a few lines and springs open on tap, with
// a rotating chevron and a crossfading "Show more" / "Show less" affordance.
// Long descriptions, reviews, bios and terms all need this; the stock answer is
// a truncated `Text` with no way back. DSExpandableText measures the real
// wrapped height, only shows the toggle when the copy is actually clipped, and
// reveals the rest with the Velvet height spring.

public struct DSExpandableText: View {
    private let text: String
    private let lineLimit: Int
    private let expandLabel: String
    private let collapseLabel: String
    private let style: DSTextStyle
    private let color: Color?
    private let haptic: DSHapticStyle

    @State private var isExpanded = false
    @State private var collapsedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - text: The copy to show. Read in full by VoiceOver even while clipped.
    ///   - lineLimit: Lines shown while collapsed. Defaults to 3.
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

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(text)
                .ds(style, color: color)
                .lineLimit(isExpanded ? nil : lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(alignment: .topLeading) { measurement }

            if isTruncated {
                toggleButton
            }
        }
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
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isExpanded ? collapseLabel : expandLabel))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Truncation measurement
    // Two off-screen copies — one clamped to `lineLimit`, one unbounded — laid
    // out at the real text width. The toggle appears only when the unbounded
    // copy is taller, and the result never flips mid-reveal because neither
    // probe depends on `isExpanded`.

    private var measurement: some View {
        ZStack(alignment: .topLeading) {
            Text(text)
                .ds(style)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { collapsedHeight = $0 }

            Text(text)
                .ds(style)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { fullHeight = $0 }
        }
        .hidden()
        .allowsHitTesting(false)
    }

    private var isTruncated: Bool {
        fullHeight - collapsedHeight > 0.5
    }

    private var revealAnimation: Animation? {
        reduceMotion ? nil : DSAnimation.springSmooth
    }

    private func toggle() {
        DSHapticEngine.shared.fire(haptic)
        withAnimation(revealAnimation) {
            isExpanded.toggle()
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    ExpandableTextPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ExpandableTextPreview()
        .preferredColorScheme(.dark)
}

private struct ExpandableTextPreview: View {
    @State private var theme = DSTheme(gradient: .aurora)

    private let bio = """
    Velvet UI is a small, opinionated SwiftUI library: frosted glass over a \
    gradient theme, spring motion on everything you touch, and haptics that \
    make the interface feel alive. Every component honors Reduce Motion, Reduce \
    Transparency and Dynamic Type out of the box, so you spend your time on the \
    app and not on the plumbing underneath it.
    """

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
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
                            color: theme.palette.textSecondary
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
