import SwiftUI

// MARK: - Design System Chip Group
// Multi-select filter chips that wrap onto as many rows as they need. This is the
// interactive counterpart to `DSBadge` (which is a static label): chips toggle,
// spring between a glass "off" state and an accent-filled "on" state that lights
// up over the backdrop, and tick a selection haptic on every change.
//
// The wrapping is a real `Layout` (`DSFlowLayout`), not a fixed `LazyVGrid`: rows
// break on content width, so long labels and mixed sizes pack naturally the way a
// tag cloud or a filter bar should. `DSFlowLayout` is public and reusable on its
// own for anything that needs left-to-right, top-to-bottom wrapping.
//
// Selection is a `Set`, so the same control drives interests, filters, tags and
// categories. For a single-choice row use `DSSegmentedControl` instead.

// MARK: - Flow Layout

/// A wrapping stack: places subviews left to right, breaking to a new run whenever
/// the next subview would overflow the proposed width. Each run is as tall as its
/// tallest subview. Reusable for chips, tags, token fields — anything that should
/// wrap rather than clip or scroll.
public struct DSFlowLayout: Layout {
    /// Horizontal gap between subviews in a run.
    public var spacing: CGFloat
    /// Vertical gap between runs.
    public var runSpacing: CGFloat

    public init(spacing: CGFloat = DSSpacing.xs, runSpacing: CGFloat = DSSpacing.xs) {
        self.spacing = spacing
        self.runSpacing = runSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.replacingUnspecifiedDimensions().width
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let height = totalHeight(of: sizes, in: maxWidth)
        return CGSize(width: maxWidth, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    /// Walk the same wrapping the placement uses, but only to measure total height.
    private func totalHeight(of sizes: [CGSize], in maxWidth: CGFloat) -> CGFloat {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for size in sizes {
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return y + rowHeight
    }
}

// MARK: - Chip Group

public struct DSChipGroup<Item: Hashable>: View {

    // MARK: Configuration

    private let items: [Item]
    @Binding private var selection: Set<Item>
    private let label: (Item) -> String
    private let icon: (Item) -> String?
    private let spacing: CGFloat
    private let runSpacing: CGFloat
    private let haptics: Bool

    // MARK: Generic Initializer

    /// A wrapping group of multi-select chips over any `Hashable` model.
    /// - Parameters:
    ///   - items: The values to show, one chip each. Expected to be unique.
    ///   - selection: The set of currently-selected values. Tapping a chip toggles it.
    ///   - spacing: Horizontal gap between chips in a row. Defaults to `DSSpacing.xs`.
    ///   - runSpacing: Vertical gap between rows. Defaults to `DSSpacing.xs`.
    ///   - haptics: Whether to fire a selection tick on each toggle. Defaults to `true`.
    ///   - icon: Optional leading SF Symbol for a value. Return `nil` for no icon.
    ///   - label: The text shown on the chip for a value.
    public init(
        _ items: [Item],
        selection: Binding<Set<Item>>,
        spacing: CGFloat = DSSpacing.xs,
        runSpacing: CGFloat = DSSpacing.xs,
        haptics: Bool = true,
        icon: @escaping (Item) -> String? = { _ in nil },
        label: @escaping (Item) -> String
    ) {
        self.items = items
        self._selection = selection
        self.spacing = spacing
        self.runSpacing = runSpacing
        self.haptics = haptics
        self.icon = icon
        self.label = label
    }

    // MARK: Body

    public var body: some View {
        DSFlowLayout(spacing: spacing, runSpacing: runSpacing) {
            ForEach(items, id: \.self) { item in
                DSChip(
                    label: label(item),
                    icon: icon(item),
                    isSelected: selection.contains(item),
                    haptics: haptics
                ) {
                    toggle(item)
                }
            }
        }
        .animation(DSAnimation.springSnappy, value: selection)
    }

    private func toggle(_ item: Item) {
        if selection.contains(item) {
            selection.remove(item)
        } else {
            selection.insert(item)
        }
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Item == String {
    /// A wrapping group of multi-select chips from plain string labels — the common
    /// case for filters and tags. The label is the value itself.
    /// - Parameters:
    ///   - items: The chip labels. Expected to be unique.
    ///   - selection: The set of currently-selected labels.
    ///   - spacing: Horizontal gap between chips in a row. Defaults to `DSSpacing.xs`.
    ///   - runSpacing: Vertical gap between rows. Defaults to `DSSpacing.xs`.
    ///   - haptics: Whether to fire a selection tick on each toggle. Defaults to `true`.
    init(
        _ items: [String],
        selection: Binding<Set<String>>,
        spacing: CGFloat = DSSpacing.xs,
        runSpacing: CGFloat = DSSpacing.xs,
        haptics: Bool = true
    ) {
        self.init(
            items,
            selection: selection,
            spacing: spacing,
            runSpacing: runSpacing,
            haptics: haptics,
            icon: { _ in nil },
            label: { $0 }
        )
    }
}

// MARK: - Single Chip

/// One selectable chip. Private on purpose — the group owns the public surface.
private struct DSChip: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let haptics: Bool
    let action: () -> Void

    @State private var isPressed = false
    @DSThemed private var theme

    var body: some View {
        Button {
            if haptics { DSHapticEngine.shared.fire(.selection) }
            action()
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(label)
            }
            // buttonSmall carries the icon too — SF Symbols inherit the font, so
            // the glyph scales with the label without a raw point size.
            .font(DSTextStyle.buttonSmall.font)
            .foregroundStyle(isSelected ? theme.onAccent : theme.palette.textPrimary)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background {
                Capsule(style: .continuous)
                    .fill(isSelected ? theme.accent : theme.subtleFill)
            }
            .clipShape(Capsule(style: .continuous))
            .overlay {
                // No border. Unselected chips carry the same specular edge every
                // glass surface draws; selected chips read by fill + glow instead.
                if !isSelected {
                    Capsule(style: .continuous)
                        .strokeBorder(theme.washEdge, lineWidth: DSWash.edgeWidth)
                }
            }
            // Selected chips light up over the backdrop, the same "on" glow a
            // toggle uses.
            .dsShadow(isSelected ? .glow(theme.accent) : .none)
            .scaleEffect(isPressed ? DSPress.scale : 1)
            .animation(DSPress.animation, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSChipGroupPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var interests: Set<String> = ["SwiftUI", "Motion"]
    @State private var categories: Set<String> = ["Nature"]

    private let categoryIcons: [String: String] = [
        "Nature": "leaf.fill",
        "Food": "fork.knife",
        "Travel": "airplane",
        "Music": "music.note",
        "Sports": "figure.run",
        "Art": "paintpalette.fill"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Interests").ds(.overline, color: DSColors.textSecondary)
                    DSChipGroup(
                        ["SwiftUI", "UIKit", "Motion", "Haptics", "Accessibility",
                         "Design Systems", "Animation", "Layout"],
                        selection: $interests
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Categories (icons)").ds(.overline, color: DSColors.textSecondary)
                    DSChipGroup(
                        Array(categoryIcons.keys).sorted(),
                        selection: $categories,
                        icon: { categoryIcons[$0] },
                        label: { $0 }
                    )
                }

                Text("Selected: \(interests.count + categories.count)")
                    .ds(.footnote, color: DSColors.textSecondary)
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Chip Group — Light") {
    DSChipGroupPreviewHost().preferredColorScheme(.light)
}

#Preview("Chip Group — Dark") {
    DSChipGroupPreviewHost().preferredColorScheme(.dark)
}
#endif
