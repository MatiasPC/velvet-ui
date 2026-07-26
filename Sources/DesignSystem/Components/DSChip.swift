import SwiftUI

// MARK: - Design System Chip
// A tactile, multi-select filter chip. Unlike a badge (a static label) or a
// segmented control (single, mutually-exclusive selection), chips are
// individually toggleable — perfect for filters, interests, tags, and facets.
// When selected, the chip springs a checkmark in from the leading edge, growing
// to make room for it, while the fill crossfades into the accent color.
//
// Inspiration: Material 3 filter chips + the SwiftUI community's take on
// wrapping tag/chip layouts using the iOS 16+ `Layout` protocol.
// - https://medium.com/@kumarsuraj19111997/building-a-flexible-flow-layout-in-swiftui-like-tags-chips-750bfd45c8bd
// - https://erdoganmucahid.medium.com/multi-selection-filter-in-swiftui-using-mvvm-approach-f2e7171110f1

// MARK: - Style

public enum DSChipStyle {
    /// Soft accent tint when selected, accent-colored label — subtle, at home in dense filter bars.
    case soft
    /// Solid accent fill when selected, contrasting label — bold, for prominent selections.
    case solid
}

// MARK: - Chip

public struct DSChip: View {
    private let title: String
    private let icon: String?
    @Binding private var isSelected: Bool
    private let style: DSChipStyle
    private let accent: Color
    private let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled
    @State private var isPressed = false

    public init(
        _ title: String,
        icon: String? = nil,
        isSelected: Binding<Bool>,
        style: DSChipStyle = .soft,
        accent: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .selection
    ) {
        self.title = title
        self.icon = icon
        self._isSelected = isSelected
        self.style = style
        self.accent = accent
        self.haptic = haptic
    }

    public var body: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.xs) {
                leadingGlyph
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
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(DSAnimation.springSnappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Leading Glyph (checkmark when selected, icon otherwise)

    @ViewBuilder
    private var leadingGlyph: some View {
        if isSelected {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .transition(
                    .asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    )
                )
        } else if let icon {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .transition(.opacity)
        }
    }

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        withAnimation(DSAnimation.springSnappy) {
            isSelected.toggle()
        }
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        let palette = DSColors.defaultPalette
        switch style {
        case .soft:  return isSelected ? accent.opacity(0.14) : palette.backgroundSecondary
        case .solid: return isSelected ? accent : palette.backgroundSecondary
        }
    }

    private var foregroundColor: Color {
        let palette = DSColors.defaultPalette
        switch style {
        case .soft:  return isSelected ? accent : palette.textSecondary
        case .solid: return isSelected ? palette.textOnPrimary : palette.textPrimary
        }
    }

    private var borderColor: Color {
        let palette = DSColors.defaultPalette
        switch style {
        case .soft:  return isSelected ? accent : palette.border
        case .solid: return isSelected ? .clear : palette.border
        }
    }
}

// MARK: - Chip Group Item

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

/// A wrapping group of multi-select chips backed by a `Set` of selected values.
/// Chips flow left-to-right and wrap onto new lines to fit the available width.
public struct DSChipGroup<Value: Hashable>: View {
    @Binding private var selection: Set<Value>
    private let items: [DSChipItem<Value>]
    private let style: DSChipStyle
    private let accent: Color
    private let spacing: CGFloat
    private let haptic: DSHapticStyle

    public init(
        selection: Binding<Set<Value>>,
        items: [DSChipItem<Value>],
        style: DSChipStyle = .soft,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self._selection = selection
        self.items = items
        self.style = style
        self.accent = accent
        self.spacing = spacing
        self.haptic = haptic
    }

    public var body: some View {
        DSChipFlowLayout(spacing: spacing) {
            ForEach(items) { item in
                DSChip(
                    item.title,
                    icon: item.icon,
                    isSelected: binding(for: item.value),
                    style: style,
                    accent: accent,
                    haptic: haptic
                )
            }
        }
    }

    private func binding(for value: Value) -> Binding<Bool> {
        Binding(
            get: { selection.contains(value) },
            set: { isOn in
                if isOn { selection.insert(value) } else { selection.remove(value) }
            }
        )
    }
}

// MARK: - String Convenience

public extension DSChipGroup where Value == String {
    /// Build a chip group directly from an array of string options.
    init(
        selection: Binding<Set<String>>,
        options: [String],
        style: DSChipStyle = .soft,
        accent: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.xs,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            items: options.map { DSChipItem($0, value: $0) },
            style: style,
            accent: accent,
            spacing: spacing,
            haptic: haptic
        )
    }
}

// MARK: - Flow Layout

/// A left-aligned flow layout: places subviews sequentially, wrapping to a new
/// line whenever the next subview would overflow the available width.
struct DSChipFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // Wrap when the current subview would overflow (but never on an empty row).
            if rowWidth > 0, rowWidth + spacing + size.width > maxWidth {
                totalWidth = max(totalWidth, rowWidth)
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
            rowHeight = max(rowHeight, size.height)
        }
        totalWidth = max(totalWidth, rowWidth)
        totalHeight += rowHeight

        let resolvedWidth = maxWidth.isFinite ? min(totalWidth, maxWidth) : totalWidth
        return CGSize(width: resolvedWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // Wrap when this subview would overflow the row (but never on an empty row).
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
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
    @State private var single = true
    @State private var soft: Set<String> = ["Design"]
    @State private var solid: Set<String> = ["Coffee", "Tea"]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            HStack(spacing: DSSpacing.xs) {
                DSChip("Standalone", icon: "sparkles", isSelected: $single)
                DSChip("Off", isSelected: .constant(false))
                DSChip("Disabled", isSelected: .constant(true)).disabled(true)
            }

            DSChipGroup(
                selection: $soft,
                options: ["Design", "Engineering", "Product", "Marketing", "Data", "Support"]
            )

            DSChipGroup(
                selection: $solid,
                items: [
                    DSChipItem("Coffee", value: "Coffee", icon: "cup.and.saucer"),
                    DSChipItem("Tea", value: "Tea", icon: "leaf"),
                    DSChipItem("Juice", value: "Juice", icon: "drop"),
                    DSChipItem("Water", value: "Water", icon: "waterbottle")
                ],
                style: .solid,
                accent: DSColors.defaultPalette.secondary
            )
        }
        .frame(maxWidth: 340, alignment: .leading)
    }
}
