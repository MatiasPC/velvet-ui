import SwiftUI

// MARK: - Design System Chip Group
// Wrapping, selectable filter chips — the staple of filter, tag, and category
// UIs (App Store, Photos, Airbnb). Chips flow across as many lines as they need
// via a reusable `DSFlowLayout` (the iOS 16+ `Layout` protocol), so the group
// adapts to any container width without a horizontal scroll.
//
// Selecting a chip springs it into the accent color while its leading glyph
// swaps to a checkmark, and each tap fires tactile feedback. Works as a
// multi-select set of filters or a single-select category picker, and is
// generic over any `Hashable` value.

// MARK: - Flow Layout

/// A layout that arranges subviews left-to-right, wrapping onto a new line
/// whenever the next subview would overflow the available width. Reusable for
/// chips, tags, token fields, or any collection of variable-width elements.
public struct DSFlowLayout: Layout {
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat

    /// - Parameters:
    ///   - horizontalSpacing: Gap between items on the same line. Defaults to `DSSpacing.xs`.
    ///   - verticalSpacing: Gap between lines. Defaults to `DSSpacing.xs`.
    public init(
        horizontalSpacing: CGFloat = DSSpacing.xs,
        verticalSpacing: CGFloat = DSSpacing.xs
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        return arrange(maxWidth: maxWidth, subviews: subviews).size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let result = arrange(maxWidth: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let item = result.items[index]
            subview.place(
                at: CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(item.size)
            )
        }
    }

    // MARK: - Arrangement

    private struct Placement {
        var origin: CGPoint
        var size: CGSize
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, items: [Placement]) {
        var items: [Placement] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widestLine: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // Wrap when this item would overflow the current line (but never on the first item of a line).
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + verticalSpacing
                lineHeight = 0
            }
            items.append(Placement(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
            widestLine = max(widestLine, x - horizontalSpacing)
        }

        let totalHeight = y + lineHeight
        let totalWidth = maxWidth.isFinite ? min(widestLine, maxWidth) : widestLine
        return (CGSize(width: totalWidth, height: totalHeight), items)
    }
}

// MARK: - Chip Style

public enum DSChipStyle {
    /// Unselected chips rest on a soft neutral fill — the default filter look.
    case soft
    /// Unselected chips are outlined with a hairline border on a clear fill.
    case outline
}

// MARK: - Chip Item

/// A single option in a `DSChipGroup`, generic over any `Hashable` value.
public struct DSChipItem<Value: Hashable>: Identifiable {
    public var id: Value { value }
    public let value: Value
    public let title: String
    public let icon: String?

    /// - Parameters:
    ///   - title: The chip's label.
    ///   - value: The value this chip represents in the selection.
    ///   - icon: Optional SF Symbol shown until the chip is selected (it then
    ///     swaps to a checkmark). Defaults to `nil`.
    public init(_ title: String, value: Value, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
}

// MARK: - Chip

/// A single selectable chip. Usable on its own inside custom layouts, or via
/// `DSChipGroup` for a managed, wrapping collection.
public struct DSChip: View {
    private let title: String
    private let icon: String?
    private let isSelected: Bool
    private let style: DSChipStyle
    private let accent: Color
    private let action: () -> Void

    public init(
        _ title: String,
        icon: String? = nil,
        isSelected: Bool,
        style: DSChipStyle = .soft,
        accent: Color = DSColors.defaultPalette.primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.style = style
        self.accent = accent
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.xxs) {
                leadingGlyph
                Text(title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(background)
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .animation(DSAnimation.springSnappy, value: isSelected)
        }
        .buttonStyle(DSChipPressStyle())
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Leading Glyph (icon ⇄ checkmark)

    @ViewBuilder
    private var leadingGlyph: some View {
        if isSelected {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .transition(.scale.combined(with: .opacity))
        } else if let icon {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Colors

    private var foreground: Color {
        if isSelected { return DSColors.defaultPalette.textOnPrimary }
        switch style {
        case .soft:    return DSColors.defaultPalette.textSecondary
        case .outline: return DSColors.defaultPalette.textPrimary
        }
    }

    private var background: Color {
        if isSelected { return accent }
        switch style {
        case .soft:    return DSColors.defaultPalette.backgroundSecondary
        case .outline: return .clear
        }
    }

    private var strokeColor: Color {
        if isSelected { return .clear }
        switch style {
        case .soft:    return .clear
        case .outline: return DSColors.defaultPalette.border
        }
    }
}

// MARK: - Press Style

private struct DSChipPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(DSAnimation.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Chip Group

public struct DSChipGroup<Value: Hashable>: View {
    private let items: [DSChipItem<Value>]
    private let style: DSChipStyle
    private let accent: Color
    private let spacing: CGFloat
    private let haptic: DSHapticStyle
    private let isSelected: (Value) -> Bool
    private let toggle: (Value) -> Void

    // MARK: - Multi-select

    /// A group where any number of chips can be selected at once — filter tags.
    /// - Parameters:
    ///   - selection: The set of currently-selected values.
    ///   - items: The chips to display.
    ///   - style: Resting appearance of unselected chips. Defaults to `.soft`.
    ///   - accent: Fill color for a selected chip. Defaults to the primary accent.
    ///   - spacing: Gap between chips, both horizontally and between lines. Defaults to `DSSpacing.xs`.
    ///   - haptic: Feedback fired on each toggle. Defaults to `.light`.
    public init(
        selection: Binding<Set<Value>>,
        items: [DSChipItem<Value>],
        style: DSChipStyle = .soft,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .light
    ) {
        self.items = items
        self.style = style
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

    // MARK: - Single-select

    /// A group where at most one chip is selected — a category picker.
    /// - Parameters:
    ///   - selection: The currently-selected value, or `nil` when none is.
    ///   - items: The chips to display.
    ///   - allowsDeselection: Whether tapping the selected chip clears it. Defaults to `true`.
    ///   - style: Resting appearance of unselected chips. Defaults to `.soft`.
    ///   - accent: Fill color for a selected chip. Defaults to the primary accent.
    ///   - spacing: Gap between chips, both horizontally and between lines. Defaults to `DSSpacing.xs`.
    ///   - haptic: Feedback fired on each toggle. Defaults to `.light`.
    public init(
        selection: Binding<Value?>,
        items: [DSChipItem<Value>],
        allowsDeselection: Bool = true,
        style: DSChipStyle = .soft,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .light
    ) {
        self.items = items
        self.style = style
        self.accent = accent
        self.spacing = spacing
        self.haptic = haptic
        self.isSelected = { selection.wrappedValue == $0 }
        self.toggle = { value in
            if selection.wrappedValue == value {
                if allowsDeselection { selection.wrappedValue = nil }
            } else {
                selection.wrappedValue = value
            }
        }
    }

    public var body: some View {
        DSFlowLayout(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(items) { item in
                DSChip(
                    item.title,
                    icon: item.icon,
                    isSelected: isSelected(item.value),
                    style: style,
                    accent: accent
                ) {
                    handleTap(item.value)
                }
            }
        }
    }

    private func handleTap(_ value: Value) {
        DSHapticEngine.shared.fire(haptic)
        withAnimation(DSAnimation.springSnappy) {
            toggle(value)
        }
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Multi-select group built directly from string options.
    init(
        selection: Binding<Set<String>>,
        options: [String],
        style: DSChipStyle = .soft,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .light
    ) {
        self.init(
            selection: selection,
            items: options.map { DSChipItem($0, value: $0) },
            style: style,
            accent: accent,
            spacing: spacing,
            haptic: haptic
        )
    }

    /// Single-select group built directly from string options.
    init(
        selection: Binding<String?>,
        options: [String],
        allowsDeselection: Bool = true,
        style: DSChipStyle = .soft,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .light
    ) {
        self.init(
            selection: selection,
            items: options.map { DSChipItem($0, value: $0) },
            allowsDeselection: allowsDeselection,
            style: style,
            accent: accent,
            spacing: spacing,
            haptic: haptic
        )
    }
}

// MARK: - Preview

#Preview("Light") {
    ChipGroupPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    ChipGroupPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct ChipGroupPreview: View {
    @State private var amenities: Set<String> = ["Wi-Fi", "Kitchen"]
    @State private var category: String? = "Popular"
    @State private var tags: Set<String> = ["Swift"]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Multi-select filters")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $amenities,
                    items: [
                        DSChipItem("Wi-Fi", value: "Wi-Fi", icon: "wifi"),
                        DSChipItem("Kitchen", value: "Kitchen", icon: "fork.knife"),
                        DSChipItem("Parking", value: "Parking", icon: "car"),
                        DSChipItem("Pool", value: "Pool", icon: "figure.pool.swim"),
                        DSChipItem("Pets OK", value: "Pets OK", icon: "pawprint")
                    ]
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Single-select category")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $category,
                    options: ["Popular", "Newest", "Price", "Rating", "Distance"],
                    accent: DSColors.defaultPalette.secondary
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Outline tags")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $tags,
                    options: ["Swift", "SwiftUI", "Combine", "Concurrency", "Metal", "Testing"],
                    style: .outline,
                    accent: DSColors.defaultPalette.tertiary
                )
            }
        }
    }
}
