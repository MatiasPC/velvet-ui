import SwiftUI

// MARK: - Design System Chip Group
// A set of tappable chips that wrap onto as many lines as needed and spring
// between selected / unselected states. Ideal for filters, tags, categories,
// and interest pickers — the reusable, multi-select counterpart to the
// fixed-width `DSSegmentedControl` (and the interactive sibling of the static
// `DSBadge`). Wrapping is handled by `DSFlowLayout`, a pure-SwiftUI `Layout`
// that reflows chips to the available width.
//
// Inspiration: Apple's iOS 16 `Layout` protocol for a native flow layout, and
// the App Store / Photos "filter chip" pattern.

// MARK: - Chip Item

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

public struct DSChipGroup<Value: Hashable>: View {
    private let items: [DSChipItem<Value>]
    private let accent: Color
    private let spacing: CGFloat
    private let lineSpacing: CGFloat
    private let haptic: DSHapticStyle

    private let isSelected: (Value) -> Bool
    private let onTap: (Value) -> Void

    // MARK: Single-select

    /// Single-select group. Tapping the active chip clears the selection when
    /// `allowsDeselection` is `true`.
    public init(
        selection: Binding<Value?>,
        items: [DSChipItem<Value>],
        allowsDeselection: Bool = true,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.items = items
        self.accent = accent
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.haptic = haptic
        self.isSelected = { selection.wrappedValue == $0 }
        self.onTap = { value in
            if selection.wrappedValue == value {
                if allowsDeselection { selection.wrappedValue = nil }
            } else {
                selection.wrappedValue = value
            }
        }
    }

    // MARK: Multi-select

    /// Multi-select group backed by a `Set`. Tapping toggles membership.
    public init(
        selection: Binding<Set<Value>>,
        items: [DSChipItem<Value>],
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.items = items
        self.accent = accent
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.haptic = haptic
        self.isSelected = { selection.wrappedValue.contains($0) }
        self.onTap = { value in
            if selection.wrappedValue.contains(value) {
                selection.wrappedValue.remove(value)
            } else {
                selection.wrappedValue.insert(value)
            }
        }
    }

    public var body: some View {
        DSFlowLayout(spacing: spacing, lineSpacing: lineSpacing) {
            ForEach(items) { item in
                chip(item)
            }
        }
    }

    // MARK: - Chip

    private func chip(_ item: DSChipItem<Value>) -> some View {
        let selected = isSelected(item.value)
        return Button {
            DSHapticEngine.shared.fire(haptic)
            withAnimation(DSAnimation.springSnappy) {
                onTap(item.value)
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon = item.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(item.title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(selected ? DSColors.defaultPalette.textOnPrimary : DSColors.defaultPalette.textPrimary)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? accent : DSColors.defaultPalette.backgroundSecondary)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(selected ? .clear : DSColors.defaultPalette.border, lineWidth: 1)
            )
            .dsShadow(selected ? .sm : .none)
            .contentShape(Capsule(style: .continuous))
            .animation(DSAnimation.springSnappy, value: selected)
        }
        .buttonStyle(DSChipButtonStyle())
    }
}

// MARK: - Chip Button Style

private struct DSChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(DSAnimation.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Flow Layout

/// A `Layout` that arranges its subviews left-to-right, wrapping onto a new
/// line whenever the next subview would overflow the available width. Sizes
/// each subview at its ideal size — perfect for chips, tags, and token fields.
public struct DSFlowLayout: Layout {
    public var spacing: CGFloat
    public var lineSpacing: CGFloat

    public init(spacing: CGFloat = DSSpacing.xs, lineSpacing: CGFloat = DSSpacing.xs) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity

        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0 && rowWidth + spacing + size.width > maxWidth {
                // Wrap to the next line.
                totalWidth = max(totalWidth, rowWidth)
                totalHeight += rowHeight + lineSpacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalWidth = max(totalWidth, rowWidth)
        totalHeight += rowHeight

        return CGSize(width: proposal.width ?? totalWidth, height: totalHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                // Wrap to the next line.
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

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Single-select group built directly from string options.
    init(
        selection: Binding<String?>,
        options: [String],
        allowsDeselection: Bool = true,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            items: options.map { DSChipItem($0, value: $0) },
            allowsDeselection: allowsDeselection,
            accent: accent,
            spacing: spacing,
            lineSpacing: lineSpacing,
            haptic: haptic
        )
    }

    /// Multi-select group built directly from string options.
    init(
        selection: Binding<Set<String>>,
        options: [String],
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            items: options.map { DSChipItem($0, value: $0) },
            accent: accent,
            spacing: spacing,
            lineSpacing: lineSpacing,
            haptic: haptic
        )
    }
}

// MARK: - Preview

#Preview("Light") {
    ChipGroupPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    ChipGroupPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct ChipGroupPreview: View {
    @State private var filter: String? = "All"
    @State private var tags: Set<String> = ["Swift", "SwiftUI"]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Single-select").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $filter,
                    options: ["All", "Popular", "Recent", "Nearby", "Top Rated"]
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Multi-select").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $tags,
                    options: ["Swift", "SwiftUI", "Combine", "Concurrency", "Core Data", "Metal", "WidgetKit"],
                    accent: DSColors.defaultPalette.secondary
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("With icons").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $tags,
                    items: [
                        DSChipItem("Home", value: "Home", icon: "house.fill"),
                        DSChipItem("Work", value: "Work", icon: "briefcase.fill"),
                        DSChipItem("Travel", value: "Travel", icon: "airplane"),
                        DSChipItem("Fitness", value: "Fitness", icon: "figure.run")
                    ],
                    accent: DSColors.defaultPalette.tertiary
                )
            }
        }
    }
}
