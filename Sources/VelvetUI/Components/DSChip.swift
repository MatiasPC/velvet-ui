import SwiftUI

// MARK: - Design System Chip
// A compact, tappable pill for filters, tags, categories and interest pickers.
// Unlike `DSBadge` (a static status label), a chip is interactive: tapping it
// springs the fill from the subtle surface into the accent and ticks a selection
// haptic. Group chips with `DSChipGroup`, which wraps them onto as many lines as
// it needs with a custom `Layout` and manages single- or multi-selection.
//
// No borders: an unselected chip reads through the `theme.subtleFill` surface and
// a selected one through the accent fill and a soft lift, so the two states
// crossfade cleanly under `DSAnimation.springSnappy`.
//
// Layout reference: Apple, "Compose custom layouts with SwiftUI" (WWDC22,
// https://developer.apple.com/videos/play/wwdc2022/10056/). Flow pattern after
// the community `Layout`-protocol write-ups (e.g. tevelee/SwiftUI-Flow).

public struct DSChip: View {
    private let title: String
    private let icon: String?
    private let isSelected: Bool
    private let accent: Color?
    private let haptic: DSHapticStyle
    private let action: () -> Void

    @State private var isPressed = false
    @DSThemed private var theme

    /// - Parameters:
    ///   - title: The chip's label. Also its VoiceOver label.
    ///   - icon: Optional leading SF Symbol. Decorative — hidden from VoiceOver.
    ///   - isSelected: Whether the chip is currently selected.
    ///   - accent: Fill when selected. Defaults to the theme accent.
    ///   - haptic: Fired on tap. Defaults to `.selection` (a selection tick).
    ///   - action: Called on tap. In a `DSChipGroup` this toggles selection.
    public init(
        _ title: String,
        icon: String? = nil,
        isSelected: Bool = false,
        accent: Color? = nil,
        haptic: DSHapticStyle = .selection,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.accent = accent
        self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        Button {
            DSHapticEngine.shared.fire(haptic)
            action()
        } label: {
            HStack(spacing: DSSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.xs)
            .background {
                Capsule(style: .continuous)
                    .fill(isSelected ? (accent ?? theme.accent) : theme.subtleFill)
            }
            .clipShape(Capsule(style: .continuous))
            .dsShadow(isSelected ? .sm : .none)
            .contentShape(Capsule(style: .continuous))
            .scaleEffect(isPressed ? DSPress.scale : 1)
            .animation(DSAnimation.springSnappy, value: isSelected)
            .animation(DSPress.animation, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var foreground: Color {
        guard isSelected else { return theme.palette.textPrimary }
        // Mirror DSBadge: the theme accent carries its own on-accent color; a
        // custom accent falls back to the palette's text-on-primary (white).
        return accent == nil ? theme.onAccent : theme.palette.textOnPrimary
    }
}

// MARK: - Chip Item

/// One option in a `DSChipGroup`, identified by its `value`.
public struct DSChipItem<Value: Hashable>: Identifiable {
    public var id: Value { value }
    public let value: Value
    public let title: String
    public let icon: String?

    public init(_ title: String, value: Value, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
}

// MARK: - Chip Group

/// A wrapping group of selectable `DSChip`s. Generic over any `Hashable` value,
/// so it drives filters, tag editors and multi-select pickers in any app. The
/// chips flow onto as many lines as the width needs; selection is single
/// (`Binding<Value?>`) or multiple (`Binding<Set<Value>>`).
public struct DSChipGroup<Value: Hashable>: View {

    private enum SelectionMode {
        case single(Binding<Value?>)
        case multiple(Binding<Set<Value>>)
    }

    private let items: [DSChipItem<Value>]
    private let mode: SelectionMode
    private let spacing: CGFloat
    private let accent: Color?

    /// Multiple selection: tapping a chip inserts or removes its value.
    /// - Parameters:
    ///   - items: The chips to show, in order.
    ///   - selection: The set of selected values.
    ///   - spacing: Gap between chips and between lines. Defaults to `DSSpacing.xs`.
    ///   - accent: Fill for selected chips. Defaults to the theme accent.
    public init(
        _ items: [DSChipItem<Value>],
        selection: Binding<Set<Value>>,
        spacing: CGFloat = DSSpacing.xs,
        accent: Color? = nil
    ) {
        self.items = items
        self.mode = .multiple(selection)
        self.spacing = spacing
        self.accent = accent
    }

    /// Single selection: tapping a chip selects it; tapping the selected chip
    /// clears the selection (`nil`).
    /// - Parameters:
    ///   - items: The chips to show, in order.
    ///   - selection: The selected value, or `nil` for none.
    ///   - spacing: Gap between chips and between lines. Defaults to `DSSpacing.xs`.
    ///   - accent: Fill for the selected chip. Defaults to the theme accent.
    public init(
        _ items: [DSChipItem<Value>],
        selection: Binding<Value?>,
        spacing: CGFloat = DSSpacing.xs,
        accent: Color? = nil
    ) {
        self.items = items
        self.mode = .single(selection)
        self.spacing = spacing
        self.accent = accent
    }

    public var body: some View {
        DSFlowLayout(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(items) { item in
                DSChip(
                    item.title,
                    icon: item.icon,
                    isSelected: isSelected(item.value),
                    accent: accent
                ) {
                    toggle(item.value)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Selection

    private func isSelected(_ value: Value) -> Bool {
        switch mode {
        case .single(let binding):   return binding.wrappedValue == value
        case .multiple(let binding): return binding.wrappedValue.contains(value)
        }
    }

    private func toggle(_ value: Value) {
        switch mode {
        case .single(let binding):
            binding.wrappedValue = (binding.wrappedValue == value) ? nil : value
        case .multiple(let binding):
            if binding.wrappedValue.contains(value) {
                binding.wrappedValue.remove(value)
            } else {
                binding.wrappedValue.insert(value)
            }
        }
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Multiple selection from plain string options (each option is its own value).
    init(
        _ options: [String],
        selection: Binding<Set<String>>,
        spacing: CGFloat = DSSpacing.xs,
        accent: Color? = nil
    ) {
        self.init(
            options.map { DSChipItem($0, value: $0) },
            selection: selection,
            spacing: spacing,
            accent: accent
        )
    }

    /// Single selection from plain string options (each option is its own value).
    init(
        _ options: [String],
        selection: Binding<String?>,
        spacing: CGFloat = DSSpacing.xs,
        accent: Color? = nil
    ) {
        self.init(
            options.map { DSChipItem($0, value: $0) },
            selection: selection,
            spacing: spacing,
            accent: accent
        )
    }
}

// MARK: - Flow Layout

/// A line-wrapping layout: it lays subviews left to right and breaks onto a new
/// line whenever the next subview would overflow the proposed width. No stock
/// stack wraps, so `DSChipGroup` needs this. Kept private — it is an
/// implementation detail of the chip group, not a public layout primitive.
private struct DSFlowLayout: Layout {
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return arrange(sizes: sizes, maxWidth: maxWidth).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let origins = arrange(sizes: sizes, maxWidth: bounds.width).origins
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + origins[index].x, y: bounds.minY + origins[index].y),
                anchor: .topLeading,
                proposal: ProposedViewSize(sizes[index])
            )
        }
    }

    /// Walk the subviews with an x/y cursor, wrapping to a new line whenever the
    /// next one would cross `maxWidth`. Returns each subview's top-left origin and
    /// the total size the lines occupy.
    private func arrange(sizes: [CGSize], maxWidth: CGFloat) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        origins.reserveCapacity(sizes.count)

        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widestLine: CGFloat = 0

        for size in sizes {
            // Wrap before placing, but never leave a line empty (a single
            // oversized chip just overflows its own line).
            if x > 0, x + size.width > maxWidth {
                widestLine = max(widestLine, x - horizontalSpacing)
                x = 0
                y += lineHeight + verticalSpacing
                lineHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
        widestLine = max(widestLine, x - horizontalSpacing)

        let totalWidth = maxWidth.isFinite ? maxWidth : max(widestLine, 0)
        let totalHeight = y + lineHeight
        return (CGSize(width: totalWidth, height: totalHeight), origins)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSChipPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var filters: Set<String> = ["Design"]
    @State private var sort: String? = "Trending"
    @State private var tags: Set<String> = []

    private let topics = [
        "Design", "Engineering", "Marketing", "Product", "Research",
        "Operations", "Finance", "People", "Legal"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Filter — multiple").ds(.overline, color: DSColors.textSecondary)
                    DSChipGroup(topics, selection: $filters)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Sort — single").ds(.overline, color: DSColors.textSecondary)
                    DSChipGroup(["Trending", "Newest", "Top rated", "Nearby"], selection: $sort)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("With icons").ds(.overline, color: DSColors.textSecondary)
                    DSChipGroup(
                        [
                            DSChipItem("Photos", value: "photos", icon: "photo"),
                            DSChipItem("Videos", value: "videos", icon: "video"),
                            DSChipItem("Audio", value: "audio", icon: "waveform"),
                            DSChipItem("Docs", value: "docs", icon: "doc")
                        ],
                        selection: $tags,
                        accent: DSColors.secondary
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Standalone").ds(.overline, color: DSColors.textSecondary)
                    HStack(spacing: DSSpacing.xs) {
                        DSChip("Add tag", icon: "plus") {}
                        DSChip("Selected", isSelected: true) {}
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Chip — Light") {
    DSChipPreviewHost().preferredColorScheme(.light)
}

#Preview("Chip — Dark") {
    DSChipPreviewHost().preferredColorScheme(.dark)
}
#endif
