import SwiftUI

// MARK: - Design System Chip Group
// A wrapping set of selectable chips (a.k.a. tags / pills) for filters,
// interests, and multi-select choices. Chips flow onto as many rows as they
// need using a reusable `DSFlowLayout` built on SwiftUI's `Layout` protocol —
// something `HStack` can't do. Selection springs the accent fill in with a
// tactile press-pop and a selection tick, so picking a filter feels alive.
//
// Unlike `DSSegmentedControl` (a fixed row of equal-width segments) this scales
// to any number of options, wraps gracefully, and supports multi-select.

// MARK: - Flow Layout

/// A layout that arranges its subviews left-to-right, wrapping to a new line
/// whenever the next subview would overflow the available width. Ideal for
/// tags, chips, and token fields. Reusable on its own with any subviews.
public struct DSFlowLayout: Layout {

    /// Horizontal gap between items on the same line.
    public var spacing: CGFloat
    /// Vertical gap between wrapped lines.
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
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.reduce(0) { $0 + $1.height }
            + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
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
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    // MARK: - Row Computation

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            // Wrap to a new line when the item would overflow (but never leave a line empty).
            if !current.indices.isEmpty, x + size.width > maxWidth {
                rows.append(current)
                current = Row()
                x = 0
            }
            current.indices.append(index)
            current.height = max(current.height, size.height)
            x += size.width + spacing
            current.width = x - spacing
        }

        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Chip

/// A single selectable chip. Use it inside a `DSChipGroup`, or standalone by
/// providing an `action`. Selection crossfades the accent fill in; the press
/// gesture gives a subtle spring-scale pop.
public struct DSChip: View {
    private let title: String
    private let icon: String?
    private let isSelected: Bool
    private let color: Color
    private let action: (() -> Void)?

    /// Create a chip.
    /// - Parameters:
    ///   - title: The chip's text label.
    ///   - icon: Optional leading SF Symbol name.
    ///   - isSelected: Whether the chip renders in its selected (filled) state.
    ///   - color: Accent fill used when selected. Defaults to the primary color.
    ///   - action: Optional tap handler. When provided the chip acts as a button
    ///     and fires a selection haptic; omit it when a `DSChipGroup` owns the tap.
    public init(
        _ title: String,
        icon: String? = nil,
        isSelected: Bool = false,
        color: Color = DSColors.defaultPalette.primary,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    public var body: some View {
        if let action {
            Button {
                DSHapticEngine.shared.fire(.selection)
                action()
            } label: {
                label
            }
            .buttonStyle(DSChipButtonStyle())
        } else {
            label
        }
    }

    private var label: some View {
        HStack(spacing: DSSpacing.xxs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(title)
                .ds(.footnote, color: foreground)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, DSSpacing.sm)
        .padding(.vertical, DSSpacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? color : DSColors.defaultPalette.backgroundSecondary)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(
                    isSelected ? .clear : DSColors.defaultPalette.border,
                    lineWidth: 1
                )
        )
        .animation(DSAnimation.springSnappy, value: isSelected)
        .contentShape(Capsule(style: .continuous))
    }

    private var foreground: Color {
        isSelected
            ? DSColors.defaultPalette.textOnPrimary
            : DSColors.defaultPalette.textPrimary
    }
}

// MARK: - Chip Button Style

/// Gives chips a spring-scale press-pop without changing their layout footprint.
private struct DSChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(DSAnimation.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Chip Group

/// A wrapping group of selectable chips. Supports single-select (bound to an
/// optional value) and multi-select (bound to a `Set`). Chips reflow across
/// rows automatically via `DSFlowLayout`.
public struct DSChipGroup: View {

    // MARK: Selection Mode

    private enum Selection {
        case single(Binding<String?>, allowsDeselection: Bool)
        case multi(Binding<Set<String>>)
    }

    private let options: [String]
    private let color: Color
    private let spacing: CGFloat
    private let lineSpacing: CGFloat
    private let selection: Selection

    // MARK: Multi-select

    /// A group where any number of chips can be selected at once.
    /// - Parameters:
    ///   - options: The chip titles, in display order.
    ///   - selection: Binding to the set of currently selected titles.
    ///   - color: Accent fill for selected chips. Defaults to the primary color.
    ///   - spacing: Horizontal gap between chips. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped rows. Defaults to `DSSpacing.xs`.
    public init(
        options: [String],
        selection: Binding<Set<String>>,
        color: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.options = options
        self.color = color
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.selection = .multi(selection)
    }

    // MARK: Single-select

    /// A group where at most one chip is selected at a time.
    /// - Parameters:
    ///   - options: The chip titles, in display order.
    ///   - selection: Binding to the selected title (`nil` when nothing is selected).
    ///   - allowsDeselection: When `true`, tapping the selected chip clears it.
    ///     Defaults to `true`.
    ///   - color: Accent fill for the selected chip. Defaults to the primary color.
    ///   - spacing: Horizontal gap between chips. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped rows. Defaults to `DSSpacing.xs`.
    public init(
        options: [String],
        selection: Binding<String?>,
        allowsDeselection: Bool = true,
        color: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.options = options
        self.color = color
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.selection = .single(selection, allowsDeselection: allowsDeselection)
    }

    // MARK: Body

    public var body: some View {
        DSFlowLayout(spacing: spacing, lineSpacing: lineSpacing) {
            ForEach(options, id: \.self) { option in
                Button {
                    toggle(option)
                } label: {
                    DSChip(option, isSelected: isSelected(option), color: color)
                }
                .buttonStyle(DSChipButtonStyle())
                .accessibilityAddTraits(.isButton)
                .accessibilityAddTraits(isSelected(option) ? .isSelected : AccessibilityTraits())
            }
        }
    }

    // MARK: Selection Logic

    private func isSelected(_ option: String) -> Bool {
        switch selection {
        case let .single(binding, _):
            return binding.wrappedValue == option
        case let .multi(binding):
            return binding.wrappedValue.contains(option)
        }
    }

    private func toggle(_ option: String) {
        DSHapticEngine.shared.fire(.selection)
        withAnimation(DSAnimation.springSnappy) {
            switch selection {
            case let .single(binding, allowsDeselection):
                if binding.wrappedValue == option {
                    if allowsDeselection { binding.wrappedValue = nil }
                } else {
                    binding.wrappedValue = option
                }
            case let .multi(binding):
                if binding.wrappedValue.contains(option) {
                    binding.wrappedValue.remove(option)
                } else {
                    binding.wrappedValue.insert(option)
                }
            }
        }
    }
}

// MARK: - Preview

private struct DSChipGroupPreviewHost: View {
    @State private var interests: Set<String> = ["Design", "Coffee"]
    @State private var sort: String? = "Popular"

    private let interestOptions = [
        "Design", "Coding", "Coffee", "Travel", "Photography",
        "Music", "Reading", "Fitness", "Cooking", "Gaming"
    ]
    private let sortOptions = ["Popular", "Newest", "Price", "Rating"]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Interests — multi-select")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(options: interestOptions, selection: $interests)
                Text("\(interests.count) selected")
                    .ds(.footnote, color: DSColors.defaultPalette.textTertiary)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Sort by — single-select")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    options: sortOptions,
                    selection: $sort,
                    color: DSColors.defaultPalette.secondary
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Standalone chips")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSFlowLayout {
                    DSChip("Filters", icon: "line.3.horizontal.decrease")
                    DSChip("Verified", icon: "checkmark.seal.fill", isSelected: true)
                    DSChip("Nearby", icon: "location.fill",
                           color: DSColors.defaultPalette.tertiary)
                }
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColors.defaultPalette.backgroundPrimary)
    }
}

#Preview("Chip Group — Light") {
    DSChipGroupPreviewHost()
        .preferredColorScheme(.light)
}

#Preview("Chip Group — Dark") {
    DSChipGroupPreviewHost()
        .preferredColorScheme(.dark)
}
