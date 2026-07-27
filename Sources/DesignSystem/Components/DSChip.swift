import SwiftUI

// MARK: - Design System Chip
// A compact, tappable pill for filters, tags, and multi-select choices.
// Selecting a chip fills it with the accent color and springs a checkmark
// in from the leading edge — the surrounding row reflows fluidly as chips
// grow and shrink. `DSChipGroup` arranges any number of chips in a wrapping
// `DSFlowLayout`, so choices flow onto new rows as space runs out.
//
// Distinct from `DSBadge` (static, display-only) and `DSSegmentedControl`
// (single row, fixed set): chips are interactive, wrap freely, and support
// both single- and multi-selection.
//
// Inspiration: the iOS 16+ `Layout` protocol pattern for wrapping tag/chip
// rows, popularised by the SwiftUI community.
// - The Swift Dev — "Build a wrapping chip layout with the SwiftUI Layout protocol"
//   (https://www.theswift.dev/posts/swiftui-layout-protocol-wrapping-chips/)
// - Swift with Konstantin — "Building a wrapping HStack with the SwiftUI Layout protocol"
//   (https://ksemianov.github.io/articles/wrapping-hstack/)

// MARK: - Chip

public struct DSChip: View {

    private let title: String
    private let icon: String?
    private let isSelected: Bool
    private let tint: Color
    private let showsCheckmark: Bool
    private let haptic: DSHapticStyle
    private let action: () -> Void

    @State private var isPressed = false
    @Environment(\.isEnabled) private var isEnabled

    /// A single selectable chip.
    /// - Parameters:
    ///   - title: The label shown inside the chip.
    ///   - icon: Optional leading SF Symbol shown when the chip is *not*
    ///     selected (or always, when `showsCheckmark` is `false`).
    ///   - isSelected: Whether the chip is currently selected.
    ///   - tint: Fill color used in the selected state. Defaults to the primary accent.
    ///   - showsCheckmark: Whether a checkmark springs in when selected,
    ///     replacing the icon. Defaults to `true`.
    ///   - haptic: Tactile feedback fired on tap. Defaults to `.selection`.
    ///   - action: Invoked when the chip is tapped.
    public init(
        _ title: String,
        icon: String? = nil,
        isSelected: Bool = false,
        tint: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = true,
        haptic: DSHapticStyle = .selection,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.tint = tint
        self.showsCheckmark = showsCheckmark
        self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        Button {
            DSHapticEngine.shared.fire(haptic)
            action()
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                leadingGlyph
                Text(title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? tint : DSColors.defaultPalette.backgroundSecondary)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        isSelected ? .clear : DSColors.defaultPalette.border,
                        lineWidth: 1
                    )
            )
            .contentShape(Capsule(style: .continuous))
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
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Leading Glyph

    @ViewBuilder
    private var leadingGlyph: some View {
        if showsCheckmark && isSelected {
            Image(systemName: "checkmark")
                .font(DSTextStyle.buttonSmall.font)
                .transition(.scale.combined(with: .opacity))
        } else if let icon {
            Image(systemName: icon)
                .font(DSTextStyle.buttonSmall.font)
        }
    }

    private var foregroundColor: Color {
        isSelected ? DSColors.defaultPalette.textOnPrimary : DSColors.defaultPalette.textPrimary
    }
}

// MARK: - Chip Group

/// A wrapping group of selectable chips, generic over any `Hashable` value.
///
/// Provide the full list of `options`; the group renders one `DSChip` per
/// option inside a `DSFlowLayout` and keeps the caller's selection in sync.
/// Two modes are available via the initializer used:
/// - **Multi-select** — bind a `Set` and each chip toggles independently.
/// - **Single-select** — bind an optional value and picking one clears the rest.
public struct DSChipGroup<Value: Hashable>: View {

    private let options: [Value]
    private let label: (Value) -> String
    private let icon: (Value) -> String?
    private let tint: Color
    private let showsCheckmark: Bool
    private let spacing: CGFloat
    private let lineSpacing: CGFloat

    private let isSelected: (Value) -> Bool
    private let toggle: (Value) -> Void

    // MARK: - Multi-select

    /// A group where any number of chips can be selected at once.
    /// - Parameters:
    ///   - options: All selectable values, in display order.
    ///   - selection: The set of currently-selected values.
    ///   - tint: Fill color for selected chips. Defaults to the primary accent.
    ///   - showsCheckmark: Whether selected chips show a checkmark. Defaults to `true`.
    ///   - spacing: Horizontal gap between chips on a row. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped rows. Defaults to `DSSpacing.xs`.
    ///   - label: Maps a value to its chip title.
    ///   - icon: Maps a value to an optional leading SF Symbol. Defaults to none.
    public init(
        _ options: [Value],
        selection: Binding<Set<Value>>,
        tint: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = true,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        label: @escaping (Value) -> String,
        icon: @escaping (Value) -> String? = { _ in nil }
    ) {
        self.options = options
        self.label = label
        self.icon = icon
        self.tint = tint
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

    // MARK: - Single-select

    /// A group where at most one chip is selected. Tapping the selected chip
    /// again clears the selection.
    /// - Parameters:
    ///   - options: All selectable values, in display order.
    ///   - selection: The currently-selected value, or `nil` when none is chosen.
    ///   - tint: Fill color for the selected chip. Defaults to the primary accent.
    ///   - showsCheckmark: Whether the selected chip shows a checkmark. Defaults to `true`.
    ///   - spacing: Horizontal gap between chips on a row. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped rows. Defaults to `DSSpacing.xs`.
    ///   - label: Maps a value to its chip title.
    ///   - icon: Maps a value to an optional leading SF Symbol. Defaults to none.
    public init(
        _ options: [Value],
        selection: Binding<Value?>,
        tint: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = true,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        label: @escaping (Value) -> String,
        icon: @escaping (Value) -> String? = { _ in nil }
    ) {
        self.options = options
        self.label = label
        self.icon = icon
        self.tint = tint
        self.showsCheckmark = showsCheckmark
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.isSelected = { selection.wrappedValue == $0 }
        self.toggle = { value in
            selection.wrappedValue = (selection.wrappedValue == value) ? nil : value
        }
    }

    public var body: some View {
        DSFlowLayout(horizontalSpacing: spacing, verticalSpacing: lineSpacing) {
            ForEach(options, id: \.self) { value in
                DSChip(
                    label(value),
                    icon: icon(value),
                    isSelected: isSelected(value),
                    tint: tint,
                    showsCheckmark: showsCheckmark
                ) {
                    withAnimation(DSAnimation.springSnappy) {
                        toggle(value)
                    }
                }
            }
        }
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Multi-select group built directly from string options, using each
    /// string as its own label.
    init(
        _ options: [String],
        selection: Binding<Set<String>>,
        tint: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = true,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.init(
            options,
            selection: selection,
            tint: tint,
            showsCheckmark: showsCheckmark,
            spacing: spacing,
            lineSpacing: lineSpacing,
            label: { $0 }
        )
    }

    /// Single-select group built directly from string options, using each
    /// string as its own label.
    init(
        _ options: [String],
        selection: Binding<String?>,
        tint: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = true,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.init(
            options,
            selection: selection,
            tint: tint,
            showsCheckmark: showsCheckmark,
            spacing: spacing,
            lineSpacing: lineSpacing,
            label: { $0 }
        )
    }
}

// MARK: - Flow Layout

/// A layout that arranges its subviews left-to-right, wrapping onto a new row
/// whenever the next subview would overflow the available width. Row height
/// adapts to the tallest chip in each row, so it stays correct at large
/// Dynamic Type sizes. Reusable for any wrapping arrangement of views —
/// tags, chips, token fields, and more.
public struct DSFlowLayout: Layout {

    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat

    public init(
        horizontalSpacing: CGFloat = DSSpacing.xs,
        verticalSpacing: CGFloat = DSSpacing.xs
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let needed = rowWidth == 0 ? size.width : rowWidth + horizontalSpacing + size.width

            if needed > maxWidth && rowWidth > 0 {
                // Overflow: commit the current row and start a new one.
                totalHeight += rowHeight + verticalSpacing
                widestRow = max(widestRow, rowWidth)
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth = needed
                rowHeight = max(rowHeight, size.height)
            }
        }

        totalHeight += rowHeight
        widestRow = max(widestRow, rowWidth)

        let width = maxWidth == .infinity ? widestRow : maxWidth
        return CGSize(width: width, height: totalHeight)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Wrap to the next row when the subview would overflow this one.
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )

            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Preview

#Preview {
    struct ChipPreview: View {
        @State private var interests: Set<String> = ["Design", "Travel"]
        @State private var sort: String? = "Popular"

        private let allInterests = [
            "Design", "Travel", "Coffee", "Photography",
            "Cooking", "Music", "Reading", "Fitness", "Gaming"
        ]

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Multi-select interests")
                        .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSChipGroup(allInterests, selection: $interests)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Single-select sort")
                        .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSChipGroup(
                        ["Popular", "Newest", "Price"],
                        selection: $sort,
                        tint: DSColors.defaultPalette.secondary
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("With icons")
                        .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSChipGroup(
                        ["Home", "Work", "Saved"],
                        selection: .constant(["Home"]),
                        tint: DSColors.defaultPalette.tertiary,
                        label: { $0 },
                        icon: { value in
                            switch value {
                            case "Home": return "house"
                            case "Work": return "briefcase"
                            default: return "bookmark"
                            }
                        }
                    )
                }
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return Group {
        ChipPreview()
            .preferredColorScheme(.light)
        ChipPreview()
            .preferredColorScheme(.dark)
    }
}
