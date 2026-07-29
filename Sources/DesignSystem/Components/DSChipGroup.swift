import SwiftUI

// MARK: - Design System Chip Group
// A wrapping group of selectable "chips" (a.k.a. choice / filter / tag pills) that
// automatically flow onto new lines when they run out of horizontal room. Each chip
// toggles with a spring scale-pop, an animated checkmark slide-in, an accent-fill
// crossfade, and a selection haptic — while the whole group fluidly reflows as chip
// widths change. Supports both single- and multi-selection and is fully generic over
// any Hashable value, making it ideal for filters, interests, categories, and tags
// across any app.
//
// The wrapping is powered by `DSFlowLayout`, a reusable pure-SwiftUI container built
// on the iOS 16+ `Layout` protocol — no `GeometryReader` hacks required.
//
// Inspiration:
// - Apple — "Compose custom layouts with SwiftUI" (WWDC22)
// - The Swift Dev — "Build a wrapping chip layout with the SwiftUI Layout protocol"
//   (https://www.theswift.dev/posts/swiftui-layout-protocol-wrapping-chips/)
// - Swift with Konstantin — "Building a wrapping HStack with the SwiftUI Layout protocol"
//   (https://ksemianov.github.io/articles/wrapping-hstack/)

// MARK: - Selection Mode

public enum DSChipSelectionMode: Sendable {
    /// Any number of chips may be selected at once — classic filter chips.
    case multiple
    /// Exactly one chip stays selected — choice chips (tapping the selected chip is a no-op).
    case single
}

// MARK: - Chip Item

public struct DSChipItem<Value: Hashable>: Identifiable {
    public var id: Value { value }
    public let value: Value
    public let title: String
    public let icon: String?

    /// - Parameters:
    ///   - title: The visible label.
    ///   - value: The underlying value bound to selection.
    ///   - icon: Optional SF Symbol shown while the chip is *unselected*
    ///     (a checkmark replaces it once selected).
    public init(_ title: String, value: Value, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
}

// MARK: - Chip Group

public struct DSChipGroup<Value: Hashable>: View {
    @Binding private var selection: Set<Value>
    private let items: [DSChipItem<Value>]
    private let mode: DSChipSelectionMode
    private let accent: Color
    private let spacing: CGFloat
    private let haptic: DSHapticStyle

    public init(
        _ items: [DSChipItem<Value>],
        selection: Binding<Set<Value>>,
        mode: DSChipSelectionMode = .multiple,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.items = items
        self._selection = selection
        self.mode = mode
        self.accent = accent
        self.spacing = spacing
        self.haptic = haptic
    }

    public var body: some View {
        DSFlowLayout(spacing: spacing, lineSpacing: spacing) {
            ForEach(items) { item in
                DSChipView(
                    item: item,
                    isSelected: selection.contains(item.value),
                    accent: accent
                ) {
                    handleTap(item.value)
                }
            }
        }
    }

    private func handleTap(_ value: Value) {
        var newSelection = selection
        switch mode {
        case .multiple:
            if newSelection.contains(value) {
                newSelection.remove(value)
            } else {
                newSelection.insert(value)
            }
        case .single:
            guard !newSelection.contains(value) else { return } // keep one selected
            newSelection = [value]
        }
        DSHapticEngine.shared.fire(haptic)
        withAnimation(DSAnimation.springSnappy) {
            selection = newSelection
        }
    }
}

// MARK: - Single-Selection Convenience

public extension DSChipGroup {
    /// Single-selection chip group bound to a single value (choice chips).
    init(
        _ items: [DSChipItem<Value>],
        selection: Binding<Value>,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        let setBinding = Binding<Set<Value>>(
            get: { [selection.wrappedValue] },
            set: { newValue in
                if let first = newValue.first { selection.wrappedValue = first }
            }
        )
        self.init(items, selection: setBinding, mode: .single, accent: accent, spacing: spacing, haptic: haptic)
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Multi-selection chip group built directly from string titles.
    init(
        _ titles: [String],
        selection: Binding<Set<String>>,
        mode: DSChipSelectionMode = .multiple,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            titles.map { DSChipItem($0, value: $0) },
            selection: selection,
            mode: mode,
            accent: accent,
            spacing: spacing,
            haptic: haptic
        )
    }

    /// Single-selection chip group built directly from string titles.
    init(
        _ titles: [String],
        selection: Binding<String>,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            titles.map { DSChipItem($0, value: $0) },
            selection: selection,
            accent: accent,
            spacing: spacing,
            haptic: haptic
        )
    }
}

// MARK: - Chip

private struct DSChipView<Value: Hashable>: View {
    let item: DSChipItem<Value>
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.xxs) {
                leadingGlyph
                Text(item.title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(
                isSelected
                    ? DSColors.defaultPalette.textOnPrimary
                    : DSColors.defaultPalette.textSecondary
            )
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? accent : DSColors.defaultPalette.backgroundSecondary)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        isSelected ? Color.clear : DSColors.defaultPalette.border,
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule(style: .continuous))
            .dsShadow(isSelected ? .sm : .none)
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(DSAnimation.springSnappy, value: isSelected)
            .animation(DSAnimation.springSnappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    @ViewBuilder
    private var leadingGlyph: some View {
        if isSelected {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .transition(.scale.combined(with: .opacity))
        } else if let icon = item.icon {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Flow Layout

/// A container that arranges its subviews left-to-right, wrapping onto a new line
/// whenever the next subview would overflow the available width. Built on the
/// iOS 16+ `Layout` protocol. Reusable anywhere content should flow like text —
/// tags, chips, keywords, token fields.
public struct DSFlowLayout: Layout {
    public var spacing: CGFloat
    public var lineSpacing: CGFloat
    public var alignment: HorizontalAlignment

    /// - Parameters:
    ///   - spacing: Horizontal gap between items on the same line.
    ///   - lineSpacing: Vertical gap between lines (defaults to `spacing`).
    ///   - alignment: Horizontal alignment of each line within the container.
    public init(
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat? = nil,
        alignment: HorizontalAlignment = .leading
    ) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing ?? spacing
        self.alignment = alignment
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let contentWidth = rows.map(\.width).max() ?? 0
        let contentHeight = rows.reduce(0) { $0 + $1.height }
            + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? contentWidth, height: contentHeight)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            if alignment == .center {
                x = bounds.minX + (bounds.width - row.width) / 2
            } else if alignment == .trailing {
                x = bounds.minX + (bounds.width - row.width)
            }
            for element in row.items {
                subviews[element.index].place(
                    at: CGPoint(x: x, y: y + (row.height - element.size.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(element.size)
                )
                x += element.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    // MARK: - Row Computation

    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let projectedWidth = current.items.isEmpty
                ? size.width
                : current.width + spacing + size.width

            if current.items.isEmpty || projectedWidth <= maxWidth {
                current.width = projectedWidth
                current.height = max(current.height, size.height)
                current.items.append((index, size))
            } else {
                rows.append(current)
                current = Row()
                current.width = size.width
                current.height = size.height
                current.items.append((index, size))
            }
        }

        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var interests: Set<String> = ["Design", "SwiftUI"]
        @State private var priority = "Medium"

        private let priorities = [
            DSChipItem("Low", value: "Low", icon: "arrow.down"),
            DSChipItem("Medium", value: "Medium", icon: "equal"),
            DSChipItem("High", value: "High", icon: "arrow.up")
        ]

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xxl) {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("MULTI-SELECT (FILTERS)")
                            .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                        DSChipGroup(
                            ["Design", "SwiftUI", "Animation", "Haptics", "Layout",
                             "Accessibility", "Motion", "Prototyping"],
                            selection: $interests
                        )
                    }

                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("SINGLE-SELECT (CHOICE)")
                            .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                        DSChipGroup(
                            priorities,
                            selection: $priority,
                            accent: DSColors.defaultPalette.secondary
                        )
                    }
                }
                .padding(DSSpacing.xl)
            }
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return PreviewWrapper()
}
