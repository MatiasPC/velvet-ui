import SwiftUI

// MARK: - Design System Chip Group
// Selectable filter / choice chips that fluidly wrap onto multiple lines.
// Chips are everywhere — category filters, interest pickers, tag selectors —
// yet SwiftUI ships no wrapping container for them. `DSChipGroup` pairs a
// spring-animated, haptic chip with a reusable `DSFlowLayout` (custom `Layout`)
// so a variable number of chips flow left-to-right and wrap like text.
//
// Supports single-select (`Binding<Value?>`, tap again to clear) and
// multi-select (`Binding<Set<Value>>`), is generic over any `Hashable`, and
// themes entirely through the semantic palette for light + dark.
//
// Inspiration: Apple's custom `Layout` protocol (WWDC22 "Compose custom
// layouts with SwiftUI") and the flow-layout pattern popularised across the
// SwiftUI community (Swift with Majid, Sarunw).

// MARK: - Flow Layout

/// A `Layout` that arranges its subviews left-to-right, wrapping to a new line
/// whenever the next subview would overflow the proposed width — the SwiftUI
/// equivalent of a wrapping `HStack`. Reusable anywhere tags need to flow.
public struct DSFlowLayout: Layout {
    /// Horizontal gap between chips on the same line.
    public var spacing: CGFloat
    /// Vertical gap between lines.
    public var lineSpacing: CGFloat

    public init(
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        return arrange(maxWidth: maxWidth, subviews: subviews).size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let offsets = arrange(maxWidth: bounds.width, subviews: subviews).offsets
        for (index, subview) in subviews.enumerated() {
            let origin = offsets[index]
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(subview.sizeThatFits(.unspecified))
            )
        }
    }

    // MARK: - Row Solving

    /// Computes each subview's top-leading offset and the overall bounding size
    /// for a given available width. Shared by sizing and placement so the two
    /// passes never disagree.
    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, offsets: [CGPoint]) {
        var offsets: [CGPoint] = []
        offsets.reserveCapacity(subviews.count)

        var cursorX: CGFloat = 0
        var cursorY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widestLine: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Wrap to the next line when this chip would overflow — but never
            // wrap the very first chip of a line (cursorX == 0).
            if cursorX > 0, cursorX + size.width > maxWidth {
                widestLine = max(widestLine, cursorX - spacing)
                cursorX = 0
                cursorY += lineHeight + lineSpacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: cursorX, y: cursorY))
            cursorX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        widestLine = max(widestLine, cursorX - spacing)
        let totalWidth = max(0, widestLine)
        let totalHeight = cursorY + lineHeight
        return (CGSize(width: totalWidth, height: totalHeight), offsets)
    }
}

// MARK: - Chip

/// A single selectable, pill-shaped chip. Presentational: it renders the given
/// `isSelected` state and calls `action` on tap (the owner flips the state).
public struct DSChip: View {
    private let title: String
    private let icon: String?
    private let isSelected: Bool
    private let accent: Color
    private let showsCheckmark: Bool
    private let haptic: DSHapticStyle
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isPressed = false

    public init(
        _ title: String,
        icon: String? = nil,
        isSelected: Bool,
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = false,
        haptic: DSHapticStyle = .selection,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.accent = accent
        self.showsCheckmark = showsCheckmark
        self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        Button(action: tap) {
            HStack(spacing: DSSpacing.xxs) {
                if showsCheckmark, isSelected {
                    Image(systemName: "checkmark")
                        .font(DSTextStyle.buttonSmall.font)
                        .transition(.scale.combined(with: .opacity))
                }
                if let icon {
                    Image(systemName: icon)
                        .font(DSTextStyle.buttonSmall.font)
                }
                Text(title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(background)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(isSelected ? .clear : DSColors.defaultPalette.border, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(DSAnimation.springSnappy, value: isSelected)
            .animation(DSAnimation.springSnappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var foreground: Color {
        isSelected
            ? DSColors.defaultPalette.textOnPrimary
            : DSColors.defaultPalette.textPrimary
    }

    private var background: Color {
        isSelected ? accent : DSColors.defaultPalette.backgroundSecondary
    }

    private func tap() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        action()
    }
}

// MARK: - Chip Group

/// A wrapping group of selectable chips backed by a `Binding`.
///
/// Use the `Binding<Set<Value>>` initializer for multi-select (filters) or the
/// `Binding<Value?>` initializer for single-select (tap the active chip again
/// to clear it). Generic over any `Hashable` value.
public struct DSChipGroup<Value: Hashable>: View {

    // MARK: Item

    /// One chip in the group: the underlying value plus its display title/icon.
    public struct Item: Identifiable {
        public let value: Value
        public let title: String
        public let icon: String?
        public var id: Value { value }

        public init(_ title: String, value: Value, icon: String? = nil) {
            self.title = title
            self.value = value
            self.icon = icon
        }
    }

    private let items: [Item]
    private let accent: Color
    private let showsCheckmark: Bool
    private let spacing: CGFloat
    private let lineSpacing: CGFloat
    private let isSelected: (Value) -> Bool
    private let toggle: (Value) -> Void

    // MARK: Multi-select

    public init(
        selection: Binding<Set<Value>>,
        items: [Item],
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = true,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.items = items
        self.accent = accent
        self.showsCheckmark = showsCheckmark
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.isSelected = { selection.wrappedValue.contains($0) }
        self.toggle = { value in
            if selection.wrappedValue.contains(value) {
                selection.wrappedValue.remove(value)
            } else {
                selection.wrappedValue.insert(value)
            }
        }
    }

    // MARK: Single-select

    public init(
        selection: Binding<Value?>,
        items: [Item],
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = false,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.items = items
        self.accent = accent
        self.showsCheckmark = showsCheckmark
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.isSelected = { selection.wrappedValue == $0 }
        self.toggle = { value in
            selection.wrappedValue = (selection.wrappedValue == value) ? nil : value
        }
    }

    public var body: some View {
        DSFlowLayout(spacing: spacing, lineSpacing: lineSpacing) {
            ForEach(items) { item in
                DSChip(
                    item.title,
                    icon: item.icon,
                    isSelected: isSelected(item.value),
                    accent: accent,
                    showsCheckmark: showsCheckmark
                ) {
                    withAnimation(DSAnimation.springSnappy) {
                        toggle(item.value)
                    }
                }
            }
        }
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Multi-select over plain string options (title == value).
    init(
        selection: Binding<Set<String>>,
        options: [String],
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = true,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.init(
            selection: selection,
            items: options.map { Item($0, value: $0) },
            accent: accent,
            showsCheckmark: showsCheckmark,
            spacing: spacing,
            lineSpacing: lineSpacing
        )
    }

    /// Single-select over plain string options (title == value).
    init(
        selection: Binding<String?>,
        options: [String],
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = false,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.init(
            selection: selection,
            items: options.map { Item($0, value: $0) },
            accent: accent,
            showsCheckmark: showsCheckmark,
            spacing: spacing,
            lineSpacing: lineSpacing
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
    @State private var interests: Set<String> = ["Design", "Coffee"]
    @State private var category: String? = "All"
    @State private var priorities: Set<String> = ["High"]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Interests — multi-select")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $interests,
                    options: ["Design", "Coffee", "Travel", "Music", "Photography", "Cooking", "Reading", "Fitness"]
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Category — single-select")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $category,
                    items: [
                        .init("All", value: "All", icon: "square.grid.2x2"),
                        .init("Nearby", value: "Nearby", icon: "location"),
                        .init("Trending", value: "Trending", icon: "flame"),
                        .init("Top Rated", value: "Top", icon: "star")
                    ],
                    accent: DSColors.defaultPalette.secondary
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Priority — custom accent")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $priorities,
                    options: ["Low", "Medium", "High", "Urgent"],
                    accent: DSColors.defaultPalette.success
                )
            }
        }
    }
}
