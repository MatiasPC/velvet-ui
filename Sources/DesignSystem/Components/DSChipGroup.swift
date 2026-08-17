import SwiftUI

// MARK: - Design System Chip Group
// A wrapping group of selectable chips — the go-to control for filters, tags,
// categories, and interest pickers. Chips flow onto the next line when they run
// out of horizontal room (like CSS `flex-wrap`) via a custom `Layout`, so the
// group never clips or forces a horizontal scroll. Selecting a chip crossfades
// it into the accent color with a snappy spring and fires tactile feedback.
//
// Supports both single-selection (one active chip, optionally deselectable) and
// multi-selection (a set of active chips) through two clean initializers, plus
// string convenience inits so the common case is a one-liner.

// MARK: - Flow Layout

/// A layout that arranges its subviews left-to-right and wraps to a new line
/// when the next subview would overflow the available width. Reusable anywhere
/// a self-wrapping row of variable-width content is needed.
public struct DSFlowLayout: Layout {
    /// Horizontal gap between chips on the same line.
    public var spacing: CGFloat
    /// Vertical gap between wrapped lines.
    public var lineSpacing: CGFloat
    /// Horizontal alignment of each line within the available width.
    public var alignment: HorizontalAlignment

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
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)

        var totalHeight: CGFloat = 0
        var widestRow: CGFloat = 0
        for (rowIndex, row) in rows.enumerated() {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            let rowWidth = row.reduce(0) { $0 + subviews[$1].sizeThatFits(.unspecified).width }
                + spacing * CGFloat(max(0, row.count - 1))
            widestRow = max(widestRow, rowWidth)
            totalHeight += rowHeight
            if rowIndex > 0 { totalHeight += lineSpacing }
        }

        let containerWidth: CGFloat
        if let width = proposal.width, width != .infinity {
            containerWidth = width
        } else {
            containerWidth = widestRow
        }
        return CGSize(width: containerWidth, height: totalHeight)
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
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            let rowWidth = row.reduce(0) { $0 + subviews[$1].sizeThatFits(.unspecified).width }
                + spacing * CGFloat(max(0, row.count - 1))

            var x = bounds.minX
            if alignment == .center {
                x += (bounds.width - rowWidth) / 2
            } else if alignment == .trailing {
                x += bounds.width - rowWidth
            }

            for index in row {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (rowHeight - size.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += rowHeight + lineSpacing
        }
    }

    /// Group subview indices into lines that each fit within `maxWidth`.
    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [[Int]] {
        var rows: [[Int]] = []
        var current: [Int] = []
        var x: CGFloat = 0

        for index in subviews.indices {
            let width = subviews[index].sizeThatFits(.unspecified).width
            if !current.isEmpty, x + spacing + width > maxWidth {
                rows.append(current)
                current = [index]
                x = width
            } else {
                x = current.isEmpty ? width : x + spacing + width
                current.append(index)
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Single Chip

/// A single capsule-shaped, selectable chip. Usable on its own or, more
/// commonly, composed by `DSChipGroup`.
public struct DSChip: View {
    private let title: String
    private let systemImage: String?
    private let isSelected: Bool
    private let tint: Color
    private let haptic: DSHapticStyle?
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    /// - Parameters:
    ///   - title: The chip's text label.
    ///   - systemImage: Optional leading SF Symbol.
    ///   - isSelected: Whether the chip is currently active.
    ///   - tint: Fill color used when selected. Defaults to the primary accent.
    ///   - haptic: Feedback fired on tap, or `nil` for none. Defaults to `.light`.
    ///   - action: Called when the chip is tapped.
    public init(
        _ title: String,
        systemImage: String? = nil,
        isSelected: Bool,
        tint: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle? = .light,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.tint = tint
        self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        Button {
            if let haptic { DSHapticEngine.shared.fire(haptic) }
            action()
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(DSTextStyle.buttonSmall.font)
                        .imageScale(.small)
                }
                Text(title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(DSChipButtonStyle())
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var foreground: Color {
        isSelected
            ? DSColors.defaultPalette.textOnPrimary
            : DSColors.defaultPalette.textSecondary
    }

    private var background: Color {
        isSelected ? tint : DSColors.defaultPalette.backgroundSecondary
    }

    private var borderColor: Color {
        isSelected ? .clear : DSColors.defaultPalette.border
    }
}

// MARK: - Chip Button Style

/// Adds a springy press-down scale to a chip for a tactile feel.
private struct DSChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(DSAnimation.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Chip Group

/// A wrapping, selectable group of chips backed by `DSFlowLayout`.
public struct DSChipGroup<Value: Hashable>: View {

    // MARK: Selection Mode

    private enum SelectionMode {
        case single(Binding<Value?>, allowsDeselection: Bool)
        case multiple(Binding<Set<Value>>)
    }

    // MARK: Configuration

    private let options: [Value]
    private let titleFor: (Value) -> String
    private let iconFor: (Value) -> String?
    private let tint: Color
    private let spacing: CGFloat
    private let lineSpacing: CGFloat
    private let alignment: HorizontalAlignment
    private let selection: SelectionMode

    // MARK: Multi-selection Initializer

    /// A chip group where any number of chips can be active at once.
    /// - Parameters:
    ///   - options: The values to render as chips, in order.
    ///   - selection: The set of currently selected values.
    ///   - tint: Fill color for selected chips. Defaults to the primary accent.
    ///   - spacing: Horizontal gap between chips. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped lines. Defaults to `DSSpacing.xs`.
    ///   - alignment: Horizontal alignment of each line. Defaults to `.leading`.
    ///   - title: Maps a value to its chip label.
    ///   - icon: Maps a value to an optional leading SF Symbol. Defaults to none.
    public init(
        _ options: [Value],
        selection: Binding<Set<Value>>,
        tint: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        alignment: HorizontalAlignment = .leading,
        title: @escaping (Value) -> String,
        icon: @escaping (Value) -> String? = { _ in nil }
    ) {
        self.options = options
        self.selection = .multiple(selection)
        self.tint = tint
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.alignment = alignment
        self.titleFor = title
        self.iconFor = icon
    }

    // MARK: Single-selection Initializer

    /// A chip group where at most one chip is active at a time.
    /// - Parameters:
    ///   - options: The values to render as chips, in order.
    ///   - selection: The currently selected value, or `nil` for none.
    ///   - allowsDeselection: Whether tapping the active chip clears the
    ///     selection. Defaults to `true`.
    ///   - tint: Fill color for the selected chip. Defaults to the primary accent.
    ///   - spacing: Horizontal gap between chips. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped lines. Defaults to `DSSpacing.xs`.
    ///   - alignment: Horizontal alignment of each line. Defaults to `.leading`.
    ///   - title: Maps a value to its chip label.
    ///   - icon: Maps a value to an optional leading SF Symbol. Defaults to none.
    public init(
        _ options: [Value],
        selection: Binding<Value?>,
        allowsDeselection: Bool = true,
        tint: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        alignment: HorizontalAlignment = .leading,
        title: @escaping (Value) -> String,
        icon: @escaping (Value) -> String? = { _ in nil }
    ) {
        self.options = options
        self.selection = .single(selection, allowsDeselection: allowsDeselection)
        self.tint = tint
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.alignment = alignment
        self.titleFor = title
        self.iconFor = icon
    }

    // MARK: Body

    public var body: some View {
        DSFlowLayout(spacing: spacing, lineSpacing: lineSpacing, alignment: alignment) {
            ForEach(options, id: \.self) { option in
                DSChip(
                    titleFor(option),
                    systemImage: iconFor(option),
                    isSelected: selectedValues.contains(option),
                    tint: tint,
                    haptic: nil
                ) {
                    toggle(option)
                }
            }
        }
        .animation(DSAnimation.springSnappy, value: selectedValues)
    }

    // MARK: Selection Helpers

    private var selectedValues: Set<Value> {
        switch selection {
        case let .single(binding, _):
            return binding.wrappedValue.map { [$0] } ?? []
        case let .multiple(binding):
            return binding.wrappedValue
        }
    }

    private func toggle(_ option: Value) {
        DSHapticEngine.shared.fire(.light)
        switch selection {
        case let .single(binding, allowsDeselection):
            if binding.wrappedValue == option {
                if allowsDeselection { binding.wrappedValue = nil }
            } else {
                binding.wrappedValue = option
            }
        case let .multiple(binding):
            if binding.wrappedValue.contains(option) {
                binding.wrappedValue.remove(option)
            } else {
                binding.wrappedValue.insert(option)
            }
        }
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Multi-selection group of string chips, where each chip's label is the
    /// string itself.
    init(
        _ options: [String],
        selection: Binding<Set<String>>,
        tint: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        alignment: HorizontalAlignment = .leading
    ) {
        self.init(
            options,
            selection: selection,
            tint: tint,
            spacing: spacing,
            lineSpacing: lineSpacing,
            alignment: alignment,
            title: { $0 }
        )
    }

    /// Single-selection group of string chips, where each chip's label is the
    /// string itself.
    init(
        _ options: [String],
        selection: Binding<String?>,
        allowsDeselection: Bool = true,
        tint: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        alignment: HorizontalAlignment = .leading
    ) {
        self.init(
            options,
            selection: selection,
            allowsDeselection: allowsDeselection,
            tint: tint,
            spacing: spacing,
            lineSpacing: lineSpacing,
            alignment: alignment,
            title: { $0 }
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
    @State private var sort: String? = "Popular"
    @State private var interests: Set<String> = ["Design", "Coffee"]
    @State private var sizes: Set<String> = ["M"]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Sort by (single)")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    ["Popular", "Newest", "Price", "Rating"],
                    selection: $sort
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Interests (multi, wraps, icons)")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    ["Design", "Coffee", "Travel", "Photography", "Music", "Cooking", "Fitness", "Reading"],
                    selection: $interests,
                    title: { $0 },
                    icon: { icon(for: $0) }
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Size (multi, secondary tint)")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    ["XS", "S", "M", "L", "XL"],
                    selection: $sizes,
                    tint: DSColors.defaultPalette.secondary
                )
            }
        }
    }

    private func icon(for interest: String) -> String? {
        switch interest {
        case "Design":      return "paintbrush"
        case "Coffee":      return "cup.and.saucer"
        case "Travel":      return "airplane"
        case "Photography": return "camera"
        case "Music":       return "music.note"
        case "Cooking":     return "fork.knife"
        case "Fitness":     return "figure.run"
        case "Reading":     return "book"
        default:            return nil
        }
    }
}
