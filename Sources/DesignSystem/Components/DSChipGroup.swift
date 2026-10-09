import SwiftUI

// MARK: - Design System Chip Group
// Multi-select filter chips that wrap across as many lines as they need. Tags,
// categories, filters — the pattern nearly every app reaches for and the one
// thing SwiftUI's stacks can't do, because no stack wraps on its own.
//
// Three pieces, smallest first:
//   DSFlowLayout — a reusable `Layout` that lays subviews out left-to-right and
//                  drops to a new line when the next one would overflow.
//   DSChip       — one selectable pill: accent fill when on, glass wash when off.
//   DSChipGroup  — binds a `Set` of selected values to a flow of `DSChip`s.
//
// Distinct from `DSBadge` (a static status label) and `DSSegmentedControl`
// (single choice, fixed width): this is many-of-N selection that reflows.

// MARK: - Flow Layout

/// Lays its subviews out in rows, wrapping to the next line whenever the next
/// subview would run past the proposed width — an `HStack` that breaks lines.
/// Subviews keep their ideal size; a subview wider than the container is not
/// truncated. Reusable on its own for tag clouds, token fields and keypads.
public struct DSFlowLayout: Layout {
    /// Gap between chips on the same row.
    public var horizontalSpacing: CGFloat
    /// Gap between rows.
    public var verticalSpacing: CGFloat

    public init(
        horizontalSpacing: CGFloat = DSSpacing.xs,
        verticalSpacing: CGFloat = DSSpacing.xs
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    /// Cache the ideal size of each subview — it doesn't depend on the proposal,
    /// so measuring once keeps both passes cheap (see Swift with Majid's series).
    public func makeCache(subviews: Subviews) -> [CGSize] {
        subviews.map { $0.sizeThatFits(.unspecified) }
    }

    public func updateCache(_ cache: inout [CGSize], subviews: Subviews) {
        cache = subviews.map { $0.sizeThatFits(.unspecified) }
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout [CGSize]
    ) -> CGSize {
        arrange(sizes: cache, maxWidth: proposal.width ?? .infinity).size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout [CGSize]
    ) {
        let offsets = arrange(sizes: cache, maxWidth: bounds.width).offsets
        for index in subviews.indices where index < offsets.count {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + offsets[index].x, y: bounds.minY + offsets[index].y),
                proposal: ProposedViewSize(cache[index])
            )
        }
    }

    /// Single source of truth for the wrapping math: walk the sizes once,
    /// advancing an `x`/`y` cursor and breaking the line when `x` would overflow.
    /// Returns the total size and each subview's top-left offset.
    private func arrange(sizes: [CGSize], maxWidth: CGFloat) -> (size: CGSize, offsets: [CGPoint]) {
        var offsets: [CGPoint] = []
        offsets.reserveCapacity(sizes.count)

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for size in sizes {
            if x > 0 && x + size.width > maxWidth {
                widestRow = max(widestRow, x - horizontalSpacing)
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            offsets.append(CGPoint(x: x, y: y))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        widestRow = max(widestRow, x - horizontalSpacing)
        let width = maxWidth.isFinite ? min(widestRow, maxWidth) : widestRow
        return (CGSize(width: max(width, 0), height: y + rowHeight), offsets)
    }
}

// MARK: - Chip

/// One selectable pill. On: accent fill with `onAccent` text. Off: the glass
/// wash with secondary text. Presses dip with `DSPress`; a selection tick fires
/// on tap. Use it directly for custom layouts, or let `DSChipGroup` manage a set.
public struct DSChip: View {
    private let title: String
    private let icon: String?
    private let isSelected: Bool
    private let color: Color?
    private let haptic: DSHapticStyle
    private let action: () -> Void

    @State private var isPressed = false
    @DSThemed private var theme

    /// - Parameters:
    ///   - icon: Optional leading SF Symbol.
    ///   - color: Selected fill. Defaults to the theme accent.
    ///   - haptic: Fired on tap. Defaults to the selection tick.
    public init(
        _ title: String,
        icon: String? = nil,
        isSelected: Bool,
        color: Color? = nil,
        haptic: DSHapticStyle = .selection,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.color = color
        self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        Button {
            DSHapticEngine.shared.fire(haptic)
            action()
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(labelColor)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(fill)
            .clipShape(Capsule(style: .continuous))
            .contentShape(Capsule(style: .continuous))
            .animation(DSAnimation.micro, value: isSelected)
            .scaleEffect(isPressed ? DSPress.scale : 1)
            .animation(DSPress.animation, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var fill: some View {
        Capsule(style: .continuous)
            .fill(isSelected ? (color ?? theme.accent) : theme.subtleFill)
    }

    private var labelColor: Color {
        guard isSelected else { return theme.palette.textSecondary }
        return color == nil ? theme.onAccent : theme.palette.textOnPrimary
    }
}

// MARK: - Chip Model

/// One option in a `DSChipGroup`, carrying its selection `value`.
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

/// Multi-select filter chips bound to a `Set`. Tapping a chip toggles its value
/// in the binding with a snappy spring; the flow wraps the chips across lines.
/// Generic over any `Hashable` value — for a single choice, reach for
/// `DSSegmentedControl` instead.
public struct DSChipGroup<Value: Hashable>: View {
    @Binding private var selection: Set<Value>
    private let items: [DSChipItem<Value>]
    private let color: Color?
    private let haptic: DSHapticStyle
    private let spacing: CGFloat

    /// - Parameters:
    ///   - color: Selected-chip fill. Defaults to the theme accent.
    ///   - haptic: Fired on each toggle. Defaults to the selection tick.
    ///   - spacing: Gap between chips, both across and down.
    public init(
        selection: Binding<Set<Value>>,
        items: [DSChipItem<Value>],
        color: Color? = nil,
        haptic: DSHapticStyle = .selection,
        spacing: CGFloat = DSSpacing.xs
    ) {
        self._selection = selection
        self.items = items
        self.color = color
        self.haptic = haptic
        self.spacing = spacing
    }

    public var body: some View {
        DSFlowLayout(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(items) { item in
                DSChip(
                    item.title,
                    icon: item.icon,
                    isSelected: selection.contains(item.value),
                    color: color,
                    haptic: haptic
                ) {
                    withAnimation(DSAnimation.springSnappy) {
                        toggle(item.value)
                    }
                }
            }
        }
    }

    private func toggle(_ value: Value) {
        if selection.contains(value) {
            selection.remove(value)
        } else {
            selection.insert(value)
        }
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Build a chip group directly from an array of string options.
    init(
        selection: Binding<Set<String>>,
        options: [String],
        color: Color? = nil,
        haptic: DSHapticStyle = .selection,
        spacing: CGFloat = DSSpacing.xs
    ) {
        self.init(
            selection: selection,
            items: options.map { DSChipItem($0, value: $0) },
            color: color,
            haptic: haptic,
            spacing: spacing
        )
    }
}

// MARK: - Preview

#if DEBUG
private struct DSChipGroupPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var cuisines: Set<String> = ["Italian", "Thai"]
    @State private var amenities: Set<String> = ["Wifi"]

    private let amenityItems: [DSChipItem<String>] = [
        DSChipItem("Wifi", value: "Wifi", icon: "wifi"),
        DSChipItem("Parking", value: "Parking", icon: "car.fill"),
        DSChipItem("Pool", value: "Pool", icon: "figure.pool.swim"),
        DSChipItem("Kitchen", value: "Kitchen", icon: "fork.knife"),
        DSChipItem("Workspace", value: "Workspace", icon: "laptopcomputer")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Cuisine").ds(.overline, color: DSColors.textSecondary)
                    DSChipGroup(
                        selection: $cuisines,
                        options: ["Italian", "Japanese", "Thai", "Mexican", "Indian", "Mediterranean", "Korean BBQ"]
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Amenities").ds(.overline, color: DSColors.textSecondary)
                    DSChipGroup(
                        selection: $amenities,
                        items: amenityItems,
                        color: DSColors.secondary
                    )
                }
                .padding(DSSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsSurface(.glass, radius: DSRadius.card)
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Chips — Light") {
    DSChipGroupPreviewHost().preferredColorScheme(.light)
}

#Preview("Chips — Dark") {
    DSChipGroupPreviewHost().preferredColorScheme(.dark)
}
#endif
