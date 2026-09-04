import SwiftUI

// MARK: - Design System Chip Group
// A set of rounded, tappable chips that fluidly wrap onto multiple lines as
// they run out of horizontal room — the classic pattern for filter bars, tag
// pickers, interest selection and category filters. Wrapping is handled by a
// custom SwiftUI `Layout`, so chips flow naturally at any width without a
// fixed grid. Selection springs in with a color fill and a subtle press
// squish, and every tap fires a selection tick.
//
// Two selection modes share one look:
//   • multi-select — bound to a `Set<Value>` (tap to add/remove)
//   • single-select — bound to an optional `Value?` (tap again to clear)
//
// Fully generic over any `Hashable` value, with a string convenience that
// mirrors `DSSegmentedControl`.
//
// Inspiration: the wrapping "flow layout" pattern popularised by the SwiftUI
// `Layout` protocol (Swift with Majid — "Building a flow layout with the
// Layout protocol": https://swiftwithmajid.com/2022/11/16/building-flow-layout-with-layout-protocol-in-swiftui/)

// MARK: - Chip Model

public struct DSChip<Value: Hashable>: Identifiable {
    public var id: Value { value }
    public let value: Value
    public let title: String
    public let icon: String?

    /// - Parameters:
    ///   - title: The visible label.
    ///   - value: The identity used for selection. Must be unique in the group.
    ///   - icon: Optional leading SF Symbol name.
    public init(_ title: String, value: Value, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
}

// MARK: - Chip Group

public struct DSChipGroup<Value: Hashable>: View {
    private let chips: [DSChip<Value>]
    private let tint: Color
    private let spacing: CGFloat
    private let lineSpacing: CGFloat
    private let haptic: DSHapticStyle
    private let isSelected: (Value) -> Bool
    private let toggle: (Value) -> Void

    // MARK: - Multi-select Initializer

    /// A chip group where any number of chips can be selected.
    /// - Parameters:
    ///   - selection: The set of currently-selected values. Tapping a chip
    ///     adds or removes its value.
    ///   - chips: The chips to display.
    ///   - tint: Fill color for selected chips. Defaults to the primary accent.
    ///   - spacing: Horizontal gap between chips. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped lines. Defaults to `DSSpacing.xs`.
    ///   - haptic: Feedback fired on each toggle. Defaults to `.selection`.
    public init(
        selection: Binding<Set<Value>>,
        chips: [DSChip<Value>],
        tint: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.chips = chips
        self.tint = tint
        self.spacing = spacing
        self.lineSpacing = lineSpacing
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

    // MARK: - Single-select Initializer

    /// A chip group where at most one chip is selected at a time.
    /// Tapping the selected chip again clears the selection.
    /// - Parameters:
    ///   - selection: The currently-selected value, or `nil` when none.
    ///   - chips: The chips to display.
    ///   - tint: Fill color for the selected chip. Defaults to the primary accent.
    ///   - spacing: Horizontal gap between chips. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped lines. Defaults to `DSSpacing.xs`.
    ///   - haptic: Feedback fired on each toggle. Defaults to `.selection`.
    public init(
        selection: Binding<Value?>,
        chips: [DSChip<Value>],
        tint: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.chips = chips
        self.tint = tint
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.haptic = haptic
        self.isSelected = { selection.wrappedValue == $0 }
        self.toggle = { value in
            selection.wrappedValue = (selection.wrappedValue == value) ? nil : value
        }
    }

    // MARK: - Body

    public var body: some View {
        DSChipFlowLayout(spacing: spacing, lineSpacing: lineSpacing) {
            ForEach(chips) { chip in
                chipButton(chip)
            }
        }
        .animation(DSAnimation.springSmooth, value: chips.map(\.value))
    }

    @ViewBuilder
    private func chipButton(_ chip: DSChip<Value>) -> some View {
        let selected = isSelected(chip.value)
        DSChipButton(
            title: chip.title,
            icon: chip.icon,
            isSelected: selected,
            tint: tint
        ) {
            DSHapticEngine.shared.fire(haptic)
            toggle(chip.value)
        }
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Multi-select group built directly from an array of string options.
    init(
        selection: Binding<Set<String>>,
        options: [String],
        tint: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            chips: options.map { DSChip($0, value: $0) },
            tint: tint,
            spacing: spacing,
            lineSpacing: lineSpacing,
            haptic: haptic
        )
    }

    /// Single-select group built directly from an array of string options.
    init(
        selection: Binding<String?>,
        options: [String],
        tint: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            chips: options.map { DSChip($0, value: $0) },
            tint: tint,
            spacing: spacing,
            lineSpacing: lineSpacing,
            haptic: haptic
        )
    }
}

// MARK: - Chip Button

private struct DSChipButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(foreground)
                }
                Text(title).ds(.buttonSmall, color: foreground)
            }
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? tint : DSColors.defaultPalette.backgroundSecondary)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        isSelected ? Color.clear : DSColors.defaultPalette.border,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(DSAnimation.springSnappy, value: isSelected)
        .animation(DSAnimation.springSnappy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var foreground: Color {
        isSelected
            ? DSColors.defaultPalette.textOnPrimary
            : DSColors.defaultPalette.textPrimary
    }
}

// MARK: - Flow Layout

/// Lays subviews out left-to-right, wrapping to a new line whenever the next
/// subview would overflow the proposed width. Used internally by `DSChipGroup`.
private struct DSChipFlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let width = proposal.width ?? (rows.map(\.width).max() ?? 0)
        let height = rows.reduce(CGFloat.zero) { $0 + $1.height }
            + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    // MARK: Row Computation

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0   // total width of subviews + interior spacing
        var height: CGFloat = 0  // tallest subview in the row
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if current.indices.isEmpty {
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else if current.width + spacing + size.width > maxWidth {
                rows.append(current)
                current = Row()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else {
                current.indices.append(index)
                current.width += spacing + size.width
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Preview

#Preview {
    struct ChipGroupPreview: View {
        @State private var interests: Set<String> = ["Design", "Coffee"]
        @State private var filter: String? = "All"
        @State private var withIcons: Set<String> = ["swift"]

        private let iconChips = [
            DSChip("SwiftUI", value: "swift", icon: "swift"),
            DSChip("Design", value: "design", icon: "paintbrush.fill"),
            DSChip("Music", value: "music", icon: "music.note"),
            DSChip("Camera", value: "camera", icon: "camera.fill"),
            DSChip("Coding", value: "code", icon: "chevron.left.forwardslash.chevron.right")
        ]

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Multi-select — interests")
                            .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                        DSChipGroup(
                            selection: $interests,
                            options: ["Design", "Code", "Music", "Travel",
                                      "Coffee", "Photography", "Fitness", "Reading"]
                        )
                    }

                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Single-select — filter")
                            .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                        DSChipGroup(
                            selection: $filter,
                            options: ["All", "Active", "Archived", "Shared"],
                            tint: DSColors.defaultPalette.secondary
                        )
                    }

                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("With icons")
                            .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                        DSChipGroup(
                            selection: $withIcons,
                            chips: iconChips,
                            tint: DSColors.defaultPalette.tertiary
                        )
                    }
                }
                .padding(DSSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return Group {
        ChipGroupPreview()
            .preferredColorScheme(.light)
        ChipGroupPreview()
            .preferredColorScheme(.dark)
    }
}
