import SwiftUI

// MARK: - Design System Chip Group
// Selectable, wrapping "filter chips" — the control every app reaches for when a
// set of options is too large for a segmented control and needs to flow onto
// multiple lines (filters, tags, interests, categories). Three pieces:
//
//   DSFlowLayout — a reusable wrapping layout (the `Layout` protocol) that packs
//                  variable-width subviews left-to-right and drops to a new line
//                  when it runs out of width. Animates its reflow for free when a
//                  chip changes size (e.g. a checkmark slides in).
//   DSFilterChip — one pill: wash when off, `accent` fill when on, with a
//                  checkmark that swaps in for the leading glyph on selection.
//   DSChipGroup  — binds a `Set` (multi-select) or an optional (single-select) to
//                  a flow of chips, and animates selection with the Velvet springs.
//
// Motion: selecting a chip springs its fill with `springSmooth`, the leading
// glyph cross-fades icon → checkmark, the chip presses with `DSPress`, and the
// whole row reflows on the same spring because the chip's width changes inside
// the animation. Haptic `.selection` per toggle.
//
// Distinct from `DSBadge` (display only, not selectable) and
// `DSSegmentedControl` (one exclusive choice on a single fixed-width track).
//
// Inspiration: Apple WWDC22 "Compose custom layouts with SwiftUI" (the canonical
// flow/tag layout); Khoa Pham — "How to make tag flow layout using Layout
// protocol in SwiftUI"; The Swift Dev — "Build a wrapping chip layout with the
// SwiftUI Layout protocol".

// MARK: - Flow Layout

/// A wrapping layout: lays subviews out along a row and wraps to the next line
/// when the proposed width runs out. Reusable for tags, chips, token fields.
public struct DSFlowLayout: Layout {
    /// Horizontal gap between chips on the same row.
    public let spacing: CGFloat
    /// Vertical gap between rows.
    public let lineSpacing: CGFloat
    /// Horizontal alignment of each row within the available width.
    public let alignment: HorizontalAlignment

    public init(
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        alignment: HorizontalAlignment = .leading
    ) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.alignment = alignment
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = rows(maxWidth: maxWidth, subviews: subviews)
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        let height = rows.reduce(into: CGFloat.zero) { $0 += $1.height }
            + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let rows = rows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = rowStart(for: row, in: bounds)
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                let dy = (row.height - size.height) / 2
                subviews[index].place(
                    at: CGPoint(x: x, y: y + dy),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    // MARK: Row packing

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0    // content width, excluding trailing spacing
        var height: CGFloat = 0
    }

    private func rows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if current.indices.isEmpty {
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else if current.width + spacing + size.width <= maxWidth {
                current.indices.append(index)
                current.width += spacing + size.width
                current.height = max(current.height, size.height)
            } else {
                rows.append(current)
                current = Row(indices: [index], width: size.width, height: size.height)
            }
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }

    private func rowStart(for row: Row, in bounds: CGRect) -> CGFloat {
        switch alignment {
        case .center:   return bounds.minX + (bounds.width - row.width) / 2
        case .trailing: return bounds.minX + (bounds.width - row.width)
        default:        return bounds.minX
        }
    }
}

// MARK: - Chip Item

/// One entry in a `DSChipGroup`: a display title, its backing value and an
/// optional leading SF Symbol shown while the chip is unselected.
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

// MARK: - Filter Chip

/// A single selectable pill. Usable on its own for one-off toggles, or composed
/// by `DSChipGroup`. Off: `theme.subtleFill` wash + `theme.ink` label. On:
/// `accent` fill + `theme.onAccent` label, with a leading checkmark.
public struct DSFilterChip: View {
    private let title: String
    private let icon: String?
    private let isSelected: Bool
    private let accent: Color?
    private let haptic: DSHapticStyle
    private let action: () -> Void

    @State private var isPressed = false
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        _ title: String,
        icon: String? = nil,
        isSelected: Bool,
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
        let fill = accent ?? theme.accent
        let labelColor = isSelected ? theme.onAccent : theme.ink

        Button {
            DSHapticEngine.shared.fire(haptic)
            action()
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let symbol = leadingSymbol {
                    Image(systemName: symbol)
                        .font(DSTextStyle.buttonSmall.font)
                        .foregroundStyle(labelColor)
                        .id(symbol)
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
                Text(title).ds(.buttonSmall, color: labelColor)
            }
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background {
                Capsule(style: .continuous)
                    .fill(isSelected ? fill : theme.subtleFill)
            }
            .contentShape(Capsule(style: .continuous))
            .dsShadow(isSelected ? .sm : .none)
            .scaleEffect(isPressed ? DSPress.scale : 1)
            .animation(DSPress.animation, value: isPressed)
            .animation(DSAnimation.springSmooth, value: isSelected)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The leading glyph: a checkmark when selected, otherwise the item icon.
    private var leadingSymbol: String? {
        isSelected ? "checkmark" : icon
    }
}

// MARK: - Chip Group

/// A wrapping group of `DSFilterChip`s bound to a selection. Use the
/// `Set`-based initializer for multi-select filters, or the optional-based one
/// for a single-choice picker that can also be cleared.
public struct DSChipGroup<Value: Hashable>: View {
    private let items: [DSChipItem<Value>]
    private let isSelected: (Value) -> Bool
    private let toggle: (Value) -> Void
    private let accent: Color?
    private let spacing: CGFloat
    private let haptic: DSHapticStyle

    /// Multi-select: each chip flips its membership in `selection`.
    public init(
        selection: Binding<Set<Value>>,
        items: [DSChipItem<Value>],
        accent: Color? = nil,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.items = items
        self.accent = accent
        self.spacing = spacing
        self.haptic = haptic
        self.isSelected = { selection.wrappedValue.contains($0) }
        self.toggle = { value in
            if selection.wrappedValue.contains(value) {
                selection.wrappedValue.remove(value)
            } else {
                selection.wrappedValue.insert(value)
            }
        }
    }

    /// Single-select: selecting a chip replaces the choice; selecting the current
    /// choice clears it (`nil`).
    public init(
        selection: Binding<Value?>,
        items: [DSChipItem<Value>],
        accent: Color? = nil,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.items = items
        self.accent = accent
        self.spacing = spacing
        self.haptic = haptic
        self.isSelected = { selection.wrappedValue == $0 }
        self.toggle = { value in
            selection.wrappedValue = (selection.wrappedValue == value) ? nil : value
        }
    }

    public var body: some View {
        DSFlowLayout(spacing: spacing, lineSpacing: spacing) {
            ForEach(items) { item in
                DSFilterChip(
                    item.title,
                    icon: item.icon,
                    isSelected: isSelected(item.value),
                    accent: accent,
                    haptic: haptic
                ) {
                    withAnimation(DSAnimation.springSmooth) {
                        toggle(item.value)
                    }
                }
            }
        }
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Multi-select group built directly from string options.
    init(
        selection: Binding<Set<String>>,
        options: [String],
        accent: Color? = nil,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            items: options.map { DSChipItem($0, value: $0) },
            accent: accent,
            spacing: spacing,
            haptic: haptic
        )
    }

    /// Single-select group built directly from string options.
    init(
        selection: Binding<String?>,
        options: [String],
        accent: Color? = nil,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            items: options.map { DSChipItem($0, value: $0) },
            accent: accent,
            spacing: spacing,
            haptic: haptic
        )
    }
}

// MARK: - Preview

#if DEBUG
private struct DSChipGroupPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var interests: Set<String> = ["Design", "Coffee"]
    @State private var sort: String? = "Popular"

    private let categories = [
        DSChipItem("All", value: "all", icon: "square.grid.2x2"),
        DSChipItem("Nearby", value: "near", icon: "location"),
        DSChipItem("Top rated", value: "top", icon: "star"),
        DSChipItem("Open now", value: "open", icon: "clock")
    ]
    @State private var category: String? = "all"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Multi-select — interests").ds(.footnote, color: DSColors.textSecondary)
                        DSChipGroup(
                            selection: $interests,
                            options: ["Design", "Coffee", "Travel", "Photography",
                                      "Music", "Cooking", "Reading", "Fitness"]
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Single-select with icons — category").ds(.footnote, color: DSColors.textSecondary)
                        DSChipGroup(selection: $category, items: categories, accent: DSColors.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Single-select — sort").ds(.footnote, color: DSColors.textSecondary)
                        DSChipGroup(
                            selection: $sort,
                            options: ["Popular", "Newest", "Price: low", "Price: high"]
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Chips — Light") {
    DSChipGroupPreviewHost().preferredColorScheme(.light)
}

#Preview("Chips — Dark") {
    DSChipGroupPreviewHost().preferredColorScheme(.dark)
}
#endif
