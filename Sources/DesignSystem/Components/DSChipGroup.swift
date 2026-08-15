import SwiftUI

// MARK: - Design System Chip Group
// Wrapping, tappable filter chips — the pattern every app reaches for when it
// needs tags, categories, interests, or quick filters, and which SwiftUI has no
// stock control for. Chips flow onto as many lines as they need via a custom
// `Layout`, springs between selected/unselected states, and ticks a haptic on
// every toggle. Ships in three cohesive pieces:
//   • `DSFlowLayout`  — a reusable wrapping layout (left-to-right, top-to-bottom)
//   • `DSChip`        — a single selectable capsule you can drop in anywhere
//   • `DSChipGroup`   — a selection container over `[String]`, single or multi
//
// Inspiration: Apple's `Layout` protocol (WWDC22 "Compose custom layouts with
// SwiftUI"), and the wrapping-tags pattern popularized by Swift with Majid
// (https://swiftwithmajid.com/2022/11/16/building-custom-layout-in-swiftui/).

// MARK: - Flow Layout

/// A layout that arranges its subviews in horizontal rows, wrapping to a new
/// row whenever the next subview would overflow the proposed width. Each
/// subview keeps its ideal size — ideal for chips, tags, and token fields.
public struct DSFlowLayout: Layout {
    /// Horizontal gap between items on the same row.
    public var spacing: CGFloat
    /// Vertical gap between rows.
    public var lineSpacing: CGFloat

    public init(spacing: CGFloat = DSSpacing.xs, lineSpacing: CGFloat = DSSpacing.xs) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0      // content width of the current row (no trailing gap)
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > maxWidth {
                // Commit the finished row and start a new one with this item.
                totalHeight += rowHeight + lineSpacing
                widestRow = max(widestRow, rowWidth)
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }
        // Commit the final row.
        totalHeight += rowHeight
        widestRow = max(widestRow, rowWidth)

        return CGSize(width: maxWidth.isFinite ? maxWidth : widestRow, height: totalHeight)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        guard !subviews.isEmpty else { return }

        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                // Wrap to the next row.
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

// MARK: - Chip

/// A single selectable capsule. Use it standalone for one-off toggles, or let
/// `DSChipGroup` manage a whole set. Selecting fills the chip with the accent
/// color, springs a subtle pop, and (for chips with an icon) bounces the symbol.
public struct DSChip: View {
    private let title: String
    private let systemImage: String?
    private let isSelected: Bool
    private let accent: Color
    private let haptic: DSHapticStyle
    private let action: () -> Void

    @State private var isPressed = false
    @Environment(\.isEnabled) private var isEnabled

    /// - Parameters:
    ///   - title: The chip's label.
    ///   - systemImage: Optional leading SF Symbol. Bounces when selection changes.
    ///   - isSelected: Whether the chip renders in its selected (filled) state.
    ///   - accent: Fill color when selected. Defaults to the primary color.
    ///   - haptic: Feedback fired on tap. Defaults to a selection tick.
    ///   - action: Called when the chip is tapped.
    public init(
        _ title: String,
        systemImage: String? = nil,
        isSelected: Bool = false,
        accent: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .selection,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.accent = accent
        self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        Button {
            DSHapticEngine.shared.fire(haptic)
            action()
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .symbolEffect(.bounce, value: isSelected)
                }
                Text(title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(isSelected ? accent : DSColors.defaultPalette.backgroundSecondary)
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? .clear : DSColors.defaultPalette.border, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(DSAnimation.springSnappy, value: isSelected)
        .animation(DSAnimation.springSnappy, value: isPressed)
        .phaseAnimator([1.0, 1.08, 1.0], trigger: isSelected) { content, scale in
            content.scaleEffect(scale)
        } animation: { _ in DSAnimation.springBouncy }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if isEnabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var foreground: Color {
        isSelected
            ? DSColors.defaultPalette.textOnPrimary
            : DSColors.defaultPalette.textPrimary
    }
}

// MARK: - Chip Group

/// A wrapping group of `DSChip`s that manages selection for you. Bind to a
/// `Set<String>` for multi-select (filters, interests) or an optional `String`
/// for single-select (a category picker where tapping again clears it).
public struct DSChipGroup: View {
    private let options: [String]
    private let isSelected: (String) -> Bool
    private let toggle: (String) -> Void
    private let accent: Color
    private let spacing: CGFloat
    private let lineSpacing: CGFloat

    /// Multi-select group. Each chip toggles its membership in `selection`.
    /// - Parameters:
    ///   - options: The chip titles, in display order.
    ///   - selection: The set of currently selected titles.
    ///   - accent: Fill color for selected chips. Defaults to the primary color.
    ///   - spacing: Horizontal gap between chips. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped rows. Defaults to `DSSpacing.xs`.
    public init(
        _ options: [String],
        selection: Binding<Set<String>>,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.options = options
        self.accent = accent
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

    /// Single-select group. Selecting a chip replaces the current choice;
    /// tapping the selected chip again clears it back to `nil`.
    /// - Parameters:
    ///   - options: The chip titles, in display order.
    ///   - selection: The currently selected title, or `nil` for none.
    ///   - accent: Fill color for the selected chip. Defaults to the primary color.
    ///   - spacing: Horizontal gap between chips. Defaults to `DSSpacing.xs`.
    ///   - lineSpacing: Vertical gap between wrapped rows. Defaults to `DSSpacing.xs`.
    public init(
        _ options: [String],
        selection: Binding<String?>,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs
    ) {
        self.options = options
        self.accent = accent
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.isSelected = { selection.wrappedValue == $0 }
        self.toggle = { value in
            selection.wrappedValue = (selection.wrappedValue == value) ? nil : value
        }
    }

    public var body: some View {
        DSFlowLayout(spacing: spacing, lineSpacing: lineSpacing) {
            ForEach(options, id: \.self) { option in
                DSChip(option, isSelected: isSelected(option), accent: accent) {
                    withAnimation(DSAnimation.springSnappy) {
                        toggle(option)
                    }
                }
            }
        }
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
    @State private var interests: Set<String> = ["Design", "Coffee"]
    @State private var category: String? = "All"

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Multi-select").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    ["Design", "Coffee", "Travel", "Music", "Reading", "Fitness", "Photography"],
                    selection: $interests
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Single-select").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSChipGroup(
                    ["All", "Photos", "Videos", "Docs"],
                    selection: $category,
                    accent: DSColors.defaultPalette.secondary
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Standalone chip").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                HStack(spacing: DSSpacing.xs) {
                    DSChip("Featured", systemImage: "star.fill", isSelected: true,
                           accent: DSColors.defaultPalette.warning) { }
                    DSChip("Nearby", systemImage: "location") { }
                }
            }
        }
    }
}
