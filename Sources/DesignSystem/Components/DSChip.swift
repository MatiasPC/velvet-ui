import SwiftUI

// MARK: - Design System Chip
// Compact, tappable pills for filtering, tagging, and multi/single selection.
// Unlike `DSBadge` (display-only) or `DSSegmentedControl` (fixed-width, single
// mutually-exclusive row), chips are individually selectable and wrap onto
// multiple lines — the pattern behind category filters, tag pickers, and
// "choose your interests" flows found in nearly every modern app.
//
// `DSChipGroup` lays chips out in a wrapping flow using a custom `Layout`
// (`DSFlowLayout`) and manages single- or multi-selection for you.

// MARK: - Style

public enum DSChipStyle {
    /// Solid accent fill when selected, subtle grey when not — bold, high contrast.
    case filled
    /// Tinted accent wash + accent border when selected, hairline outline when not.
    case outlined
}

// MARK: - Chip

public struct DSChip: View {
    private let title: String
    private let icon: String?
    private let isSelected: Bool
    private let style: DSChipStyle
    private let accent: Color
    private let showsCheckmark: Bool
    private let haptic: DSHapticStyle
    private let action: () -> Void

    public init(
        _ title: String,
        isSelected: Bool,
        icon: String? = nil,
        style: DSChipStyle = .filled,
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = false,
        haptic: DSHapticStyle = .selection,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.style = style
        self.accent = accent
        self.showsCheckmark = showsCheckmark
        self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        Button {
            DSHapticEngine.shared.fire(haptic)
            action()
        } label: {
            HStack(spacing: DSSpacing.xs) {
                if showsCheckmark && isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.xs)
            .background(backgroundColor)
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .contentShape(Capsule(style: .continuous))
            .animation(DSAnimation.springSnappy, value: isSelected)
        }
        .buttonStyle(DSChipButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Colors

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return isSelected ? DSColors.defaultPalette.textOnPrimary : DSColors.defaultPalette.textSecondary
        case .outlined:
            return isSelected ? accent : DSColors.defaultPalette.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return isSelected ? accent : DSColors.defaultPalette.backgroundSecondary
        case .outlined:
            return isSelected ? accent.opacity(0.12) : .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .filled:
            return .clear
        case .outlined:
            return isSelected ? accent : DSColors.defaultPalette.border
        }
    }
}

// MARK: - Press Style

private struct DSChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(DSAnimation.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Chip Option Model

public struct DSChipOption<Value: Hashable>: Identifiable {
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

public struct DSChipGroup<Value: Hashable>: View {
    private let options: [DSChipOption<Value>]
    @Binding private var selection: Set<Value>
    private let allowsMultipleSelection: Bool
    private let style: DSChipStyle
    private let accent: Color
    private let showsCheckmark: Bool
    private let spacing: CGFloat
    private let lineSpacing: CGFloat

    /// Multi-selection group backed by a `Set` of selected values.
    public init(
        options: [DSChipOption<Value>],
        selection: Binding<Set<Value>>,
        allowsMultipleSelection: Bool = true,
        style: DSChipStyle = .filled,
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = false,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.options = options
        self._selection = selection
        self.allowsMultipleSelection = allowsMultipleSelection
        self.style = style
        self.accent = accent
        self.showsCheckmark = showsCheckmark
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public var body: some View {
        DSFlowLayout(spacing: spacing, lineSpacing: lineSpacing) {
            ForEach(options) { option in
                DSChip(
                    option.title,
                    isSelected: selection.contains(option.value),
                    icon: option.icon,
                    style: style,
                    accent: accent,
                    showsCheckmark: showsCheckmark
                ) {
                    withAnimation(DSAnimation.springSnappy) {
                        toggle(option.value)
                    }
                }
            }
        }
    }

    private func toggle(_ value: Value) {
        if allowsMultipleSelection {
            if selection.contains(value) {
                selection.remove(value)
            } else {
                selection.insert(value)
            }
        } else {
            selection = selection.contains(value) ? [] : [value]
        }
    }
}

// MARK: - Single-Selection Convenience

public extension DSChipGroup {
    /// Single-selection group backed by an optional value (tap the active chip to clear it).
    init(
        options: [DSChipOption<Value>],
        selection: Binding<Value?>,
        style: DSChipStyle = .filled,
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = false,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        let setBinding = Binding<Set<Value>>(
            get: { selection.wrappedValue.map { Set([$0]) } ?? [] },
            set: { selection.wrappedValue = $0.first }
        )
        self.init(
            options: options,
            selection: setBinding,
            allowsMultipleSelection: false,
            style: style,
            accent: accent,
            showsCheckmark: showsCheckmark,
            spacing: spacing,
            lineSpacing: lineSpacing
        )
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Multi-selection group built directly from string titles.
    init(
        _ titles: [String],
        selection: Binding<Set<String>>,
        allowsMultipleSelection: Bool = true,
        style: DSChipStyle = .filled,
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = false,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.init(
            options: titles.map { DSChipOption($0, value: $0) },
            selection: selection,
            allowsMultipleSelection: allowsMultipleSelection,
            style: style,
            accent: accent,
            showsCheckmark: showsCheckmark,
            spacing: spacing,
            lineSpacing: lineSpacing
        )
    }

    /// Single-selection group built directly from string titles.
    init(
        _ titles: [String],
        selection: Binding<String?>,
        style: DSChipStyle = .filled,
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = false,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.init(
            options: titles.map { DSChipOption($0, value: $0) },
            selection: selection,
            style: style,
            accent: accent,
            showsCheckmark: showsCheckmark,
            spacing: spacing,
            lineSpacing: lineSpacing
        )
    }
}

// MARK: - Flow Layout

/// A simple line-wrapping layout: places subviews left-to-right, wrapping to a
/// new line whenever the next subview would overflow the proposed width.
/// Perfect for chips, tags, and any collection of variable-width pills.
public struct DSFlowLayout: Layout {
    public var spacing: CGFloat
    public var lineSpacing: CGFloat

    public init(spacing: CGFloat = DSSpacing.xs, lineSpacing: CGFloat = DSSpacing.xs) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                maxLineWidth = max(maxLineWidth, x - spacing)
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        maxLineWidth = max(maxLineWidth, x - spacing)

        let width = proposal.width ?? max(maxLineWidth, 0)
        return CGSize(width: width, height: y + rowHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.minX + maxWidth {
                x = bounds.minX
                y += rowHeight + lineSpacing
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
}

// MARK: - Preview

#Preview("Light") {
    ChipPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    ChipPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct ChipPreview: View {
    @State private var interests: Set<String> = ["Design", "Coffee"]
    @State private var sortBy: String? = "Popular"
    @State private var filters: Set<String> = ["Open now"]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Interests — multi-select").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    ["Design", "Coffee", "Travel", "Photography", "Music", "Cooking", "Fitness"],
                    selection: $interests,
                    showsCheckmark: true
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Sort — single-select").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    options: [
                        DSChipOption("Popular", value: "Popular", icon: "flame"),
                        DSChipOption("Newest", value: "Newest", icon: "sparkles"),
                        DSChipOption("Nearby", value: "Nearby", icon: "location")
                    ],
                    selection: $sortBy,
                    accent: DSColors.defaultPalette.secondary
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Filters — outlined").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    ["Open now", "Free WiFi", "Outdoor", "Pet friendly"],
                    selection: $filters,
                    style: .outlined,
                    accent: DSColors.defaultPalette.tertiary
                )
            }
        }
    }
}
