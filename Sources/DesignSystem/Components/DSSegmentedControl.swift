import SwiftUI

// MARK: - Design System Segmented Control
// A tactile, animated segmented control with a sliding pill indicator.
// The selected thumb glides between segments using matchedGeometryEffect,
// giving the springy, premium feel of a native picker — fully themed and haptic.

public struct DSSegmentedControl<Item: Hashable>: View {
    private let items: [Item]
    private let cornerRadius: CGFloat
    private let haptic: DSHapticStyle
    private let title: (Item) -> String
    private let icon: (Item) -> String?

    @Binding private var selection: Item
    @Namespace private var thumbNamespace

    /// Inset of the sliding thumb from the track edges.
    private let thumbInset: CGFloat = DSSpacing.xxs

    public init(
        _ items: [Item],
        selection: Binding<Item>,
        cornerRadius: CGFloat = DSRadius.md,
        haptic: DSHapticStyle = .selection,
        title: @escaping (Item) -> String,
        icon: @escaping (Item) -> String? = { _ in nil }
    ) {
        self.items = items
        self._selection = selection
        self.cornerRadius = cornerRadius
        self.haptic = haptic
        self.title = title
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                segment(for: item)
            }
        }
        .padding(thumbInset)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(DSColors.defaultPalette.backgroundSecondary)
        )
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(for item: Item) -> some View {
        let isSelected = item == selection

        HStack(spacing: DSSpacing.xxs) {
            if let symbol = icon(item) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(title(item))
                .ds(
                    .footnote,
                    color: isSelected
                        ? DSColors.defaultPalette.textPrimary
                        : DSColors.defaultPalette.textSecondary
                )
        }
        .foregroundStyle(
            isSelected
                ? DSColors.defaultPalette.textPrimary
                : DSColors.defaultPalette.textSecondary
        )
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.xs)
        .background(thumb(isSelected: isSelected))
        .contentShape(Rectangle())
        .onTapGesture { select(item) }
    }

    // MARK: - Sliding Thumb

    @ViewBuilder
    private func thumb(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                .fill(DSColors.defaultPalette.backgroundElevated)
                .dsShadow(.sm)
                .matchedGeometryEffect(id: "dsSegmentThumb", in: thumbNamespace)
        }
    }

    /// Radius of the nested thumb, tucked inside the track by `thumbInset`.
    private var innerRadius: CGFloat {
        max(cornerRadius - thumbInset, DSRadius.xs)
    }

    // MARK: - Selection

    private func select(_ item: Item) {
        guard item != selection else { return }
        DSHapticEngine.shared.fire(haptic)
        withAnimation(DSAnimation.springSnappy) {
            selection = item
        }
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Item == String {
    /// Convenience initializer for plain string segments.
    init(
        _ items: [String],
        selection: Binding<String>,
        cornerRadius: CGFloat = DSRadius.md,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            items,
            selection: selection,
            cornerRadius: cornerRadius,
            haptic: haptic,
            title: { $0 }
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewHost: View {
        @State private var period = "Week"
        @State private var view = "List"

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                DSSegmentedControl(
                    ["Day", "Week", "Month"],
                    selection: $period
                )

                DSSegmentedControl(
                    ["List", "Grid", "Map"],
                    selection: $view,
                    title: { $0 },
                    icon: { item in
                        switch item {
                        case "List": return "list.bullet"
                        case "Grid": return "square.grid.2x2"
                        default:     return "map"
                        }
                    }
                )
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return VStack(spacing: 0) {
        PreviewHost().environment(\.colorScheme, .light)
        PreviewHost().environment(\.colorScheme, .dark)
    }
}
