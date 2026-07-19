import SwiftUI

// MARK: - Design System Segmented Control
// A sliding-pill segmented control for switching between a small set of options.
// The selection indicator glides between segments with matchedGeometryEffect,
// giving the tactile, premium feel of a native control — with DS styling.
// Great for filters, view switchers, and tab-like navigation.

public struct DSSegmentedControl<Item: Hashable>: View {
    private let items: [Item]
    private let title: (Item) -> String
    private let tint: Color
    private let cornerRadius: CGFloat

    @Binding private var selection: Item
    @Namespace private var namespace

    /// Create a segmented control over any `Hashable` items.
    /// - Parameters:
    ///   - items: The options to display, left to right.
    ///   - selection: A binding to the currently selected item.
    ///   - tint: Accent color for the selected segment's label. Defaults to the primary color.
    ///   - cornerRadius: Outer corner radius of the track. Defaults to `DSRadius.md`.
    ///   - title: Maps an item to its display label.
    public init(
        items: [Item],
        selection: Binding<Item>,
        tint: Color = DSColors.defaultPalette.primary,
        cornerRadius: CGFloat = DSRadius.md,
        title: @escaping (Item) -> String
    ) {
        self.items = items
        self._selection = selection
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.title = title
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                segment(for: item)
            }
        }
        .padding(DSSpacing.xxs)
        .background(DSColors.defaultPalette.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(for item: Item) -> some View {
        let isSelected = item == selection

        Text(title(item))
            .font(DSTextStyle.buttonSmall.font)
            .foregroundStyle(isSelected ? tint : DSColors.defaultPalette.textSecondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background {
                if isSelected {
                    RoundedRectangle(
                        cornerRadius: max(cornerRadius - DSSpacing.xxs, DSRadius.xs),
                        style: .continuous
                    )
                    .fill(DSColors.defaultPalette.backgroundElevated)
                    .dsShadow(.sm)
                    .matchedGeometryEffect(id: "dsSegmentedPill", in: namespace)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isSelected else { return }
                DSHapticEngine.shared.fire(.selection)
                withAnimation(DSAnimation.springSmooth) {
                    selection = item
                }
            }
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Item == String {
    /// Convenience initializer for plain `String` options, where each item is its own label.
    init(
        _ items: [String],
        selection: Binding<String>,
        tint: Color = DSColors.defaultPalette.primary,
        cornerRadius: CGFloat = DSRadius.md
    ) {
        self.init(
            items: items,
            selection: selection,
            tint: tint,
            cornerRadius: cornerRadius,
            title: { $0 }
        )
    }
}

// MARK: - Preview

private struct DSSegmentedControlPreview: View {
    @State private var view = "List"
    @State private var period = "Week"

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSSegmentedControl(["List", "Grid", "Map"], selection: $view)

            DSSegmentedControl(
                ["Day", "Week", "Month"],
                selection: $period,
                tint: DSColors.defaultPalette.secondary
            )

            Text("Showing \(view) · \(period)")
                .ds(.callout, color: DSColors.defaultPalette.textSecondary)
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
    }
}

#Preview("Segmented Control") {
    DSSegmentedControlPreview()
}
