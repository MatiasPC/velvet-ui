import SwiftUI

// MARK: - Design System Chip Group
// A wrapping group of selectable "chips" (a.k.a. tags / filter pills) that flows
// onto as many lines as it needs, powered by a reusable `Layout`-protocol flow
// layout. Selecting a chip springs in a checkmark and crossfades the fill into
// the accent color, with a selection tick of haptic feedback. Ideal for filters,
// tag pickers, category selectors, and interests — anywhere a fixed row (like a
// segmented control) would clip or scroll.
//
// Three public pieces ship here, from lowest to highest level:
//   • `DSFlowLayout`  — a reusable wrapping layout (use it with any subviews).
//   • `DSChip`        — a single selectable chip.
//   • `DSChipGroup`   — a bound, multi/single-select group that wraps chips.
//
// Inspiration: the SwiftUI community's `Layout`-protocol flow/chip layouts —
// objc.io Swift Talk "The Layout Protocol"
// (https://talk.objc.io/episodes/S01E308-the-layout-protocol), The Swift Dev
// "Build A Wrapping Chip Layout With The SwiftUI Layout Protocol"
// (https://www.theswift.dev/posts/swiftui-layout-protocol-wrapping-chips/), and
// Khoa Pham "How to make tag flow layout using Layout protocol in SwiftUI"
// (https://medium.com/@onmyway133/how-to-make-tag-flow-layout-using-layout-protocol-in-swiftui-57c45654aeab).

// MARK: - Flow Layout

/// A layout that arranges its subviews left-to-right, wrapping to a new line
/// whenever the next subview would overflow the available width — the SwiftUI
/// equivalent of CSS `flex-wrap: wrap`. Each row is as tall as its tallest
/// subview. Works with any content, not just chips.
public struct DSFlowLayout: Layout {
    /// Horizontal gap between subviews on the same line.
    public var spacing: CGFloat
    /// Vertical gap between wrapped lines.
    public var lineSpacing: CGFloat

    public init(spacing: CGFloat = DSSpacing.xs, lineSpacing: CGFloat = DSSpacing.xs) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return arrange(sizes: sizes, maxWidth: maxWidth).size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let positions = arrange(sizes: sizes, maxWidth: bounds.width).positions
        for (index, subview) in subviews.enumerated() {
            let origin = CGPoint(x: bounds.minX + positions[index].x,
                                 y: bounds.minY + positions[index].y)
            subview.place(at: origin, anchor: .topLeading, proposal: ProposedViewSize(sizes[index]))
        }
    }

    /// Walk the subview sizes, breaking to a new line whenever the next one would
    /// exceed `maxWidth`, and report both the total size and each item's origin.
    private func arrange(sizes: [CGSize], maxWidth: CGFloat) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for size in sizes {
            // Wrap when the current row already has content and this item overflows.
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            usedWidth = max(usedWidth, x - spacing)
        }

        let totalHeight = y + rowHeight
        let totalWidth = maxWidth.isFinite ? min(usedWidth, maxWidth) : usedWidth
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

// MARK: - Chip

/// A single selectable chip. Renders a pill that fills with `accent` when
/// selected, springing in a checkmark; unselected it shows a subtle outline.
/// Fires a haptic tick on tap. Use it standalone, or let `DSChipGroup` manage a
/// collection for you.
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

    /// - Parameters:
    ///   - title: The chip's text label.
    ///   - icon: Optional leading SF Symbol shown when unselected (replaced by
    ///     the checkmark when selected, if `showsCheckmark` is `true`).
    ///   - isSelected: Whether the chip is currently selected.
    ///   - accent: Fill color when selected. Defaults to the primary accent.
    ///   - showsCheckmark: Whether a checkmark springs in on selection. Defaults to `true`.
    ///   - haptic: Feedback fired on tap. Defaults to a selection tick.
    ///   - action: Called when the chip is tapped.
    public init(
        _ title: String,
        icon: String? = nil,
        isSelected: Bool = false,
        accent: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = true,
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
                if showsCheck {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }

                Text(title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? accent : DSColors.defaultPalette.backgroundSecondary)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? .clear : DSColors.defaultPalette.border, lineWidth: 1)
            )
            .contentShape(Capsule())
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
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var showsCheck: Bool { isSelected && showsCheckmark }

    private var foreground: Color {
        isSelected ? DSColors.defaultPalette.textOnPrimary : DSColors.defaultPalette.textPrimary
    }

    private func tap() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        action()
    }
}

// MARK: - Chip Item

/// A value-carrying descriptor for one chip in a `DSChipGroup`.
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

/// A wrapping, selectable group of chips bound to a set of selected values.
/// Multi-select by default; pass `allowsMultipleSelection: false` for a
/// single-select filter. Selection changes animate with a snappy spring and each
/// chip fires its own haptic tick.
public struct DSChipGroup<Value: Hashable>: View {
    @Binding private var selection: Set<Value>
    private let items: [DSChipItem<Value>]
    private let accent: Color
    private let spacing: CGFloat
    private let lineSpacing: CGFloat
    private let allowsMultipleSelection: Bool
    private let showsCheckmark: Bool

    /// - Parameters:
    ///   - selection: The set of currently selected values.
    ///   - items: The chips to display.
    ///   - accent: Fill color for selected chips. Defaults to the primary accent.
    ///   - spacing: Horizontal gap between chips. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped rows. Defaults to `DSSpacing.xs`.
    ///   - allowsMultipleSelection: Allow more than one selected chip. Defaults to `true`.
    ///   - showsCheckmark: Show a checkmark on selected chips. Defaults to `true`.
    public init(
        selection: Binding<Set<Value>>,
        items: [DSChipItem<Value>],
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        allowsMultipleSelection: Bool = true,
        showsCheckmark: Bool = true
    ) {
        self._selection = selection
        self.items = items
        self.accent = accent
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.allowsMultipleSelection = allowsMultipleSelection
        self.showsCheckmark = showsCheckmark
    }

    public var body: some View {
        DSFlowLayout(spacing: spacing, lineSpacing: lineSpacing) {
            ForEach(items) { item in
                DSChip(
                    item.title,
                    icon: item.icon,
                    isSelected: selection.contains(item.value),
                    accent: accent,
                    showsCheckmark: showsCheckmark
                ) {
                    toggle(item.value)
                }
            }
        }
    }

    private func toggle(_ value: Value) {
        withAnimation(DSAnimation.springSnappy) {
            if selection.contains(value) {
                selection.remove(value)
            } else {
                if !allowsMultipleSelection { selection.removeAll() }
                selection.insert(value)
            }
        }
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Build a chip group directly from an array of string options, where each
    /// string is both the label and the selected value.
    init(
        selection: Binding<Set<String>>,
        options: [String],
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        allowsMultipleSelection: Bool = true,
        showsCheckmark: Bool = true
    ) {
        self.init(
            selection: selection,
            items: options.map { DSChipItem($0, value: $0) },
            accent: accent,
            spacing: spacing,
            lineSpacing: lineSpacing,
            allowsMultipleSelection: allowsMultipleSelection,
            showsCheckmark: showsCheckmark
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
    @State private var sort: Set<String> = ["Popular"]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Interests (multi-select)")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $interests,
                    options: ["Design", "Coffee", "Travel", "Photography",
                              "Cooking", "Music", "Reading", "Fitness"]
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Sort by (single-select)")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    selection: $sort,
                    items: [
                        DSChipItem("Popular", value: "Popular", icon: "flame"),
                        DSChipItem("Newest", value: "Newest", icon: "sparkles"),
                        DSChipItem("Price", value: "Price", icon: "tag")
                    ],
                    accent: DSColors.defaultPalette.secondary,
                    allowsMultipleSelection: false
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
