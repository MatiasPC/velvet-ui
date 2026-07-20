import SwiftUI

// MARK: - Design System Segmented Control
// A polished segmented picker with a sliding "pill" indicator.
// The selection background glides between segments using matchedGeometryEffect,
// giving the crisp, premium feel of Apple's own controls — but fully themeable.
// Great for view-mode switches, filters, and tab-style navigation.
//
// Inspired by the matchedGeometryEffect sliding-pill technique:
// https://nilcoalescing.com/blog/CustomSegmentedControlWithMatchedGeometryEffect/

public struct DSSegmentedControl<Item: Hashable>: View {
    private let items: [Item]
    private let title: (Item) -> String
    @Binding private var selection: Item
    private let haptic: DSHapticStyle

    @Namespace private var namespace

    /// Create a segmented control over any `Hashable` items.
    /// - Parameters:
    ///   - items: The ordered segments to display.
    ///   - selection: The currently selected item.
    ///   - haptic: Feedback fired on selection change (default `.selection`).
    ///   - title: Maps an item to its display label.
    public init(
        _ items: [Item],
        selection: Binding<Item>,
        haptic: DSHapticStyle = .selection,
        title: @escaping (Item) -> String
    ) {
        self.items = items
        self._selection = selection
        self.haptic = haptic
        self.title = title
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxxs) {
            ForEach(items, id: \.self) { item in
                segment(for: item)
            }
        }
        .padding(DSSpacing.xxs)
        .background(DSColors.defaultPalette.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
    }

    @ViewBuilder
    private func segment(for item: Item) -> some View {
        let isSelected = item == selection

        Button {
            guard item != selection else { return }
            DSHapticEngine.shared.fire(haptic)
            withAnimation(DSAnimation.springSnappy) {
                selection = item
            }
        } label: {
            Text(title(item))
                .ds(
                    .buttonSmall,
                    color: isSelected
                        ? DSColors.defaultPalette.textPrimary
                        : DSColors.defaultPalette.textSecondary
                )
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DSSpacing.xs)
                .padding(.horizontal, DSSpacing.sm)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                            .fill(DSColors.defaultPalette.backgroundElevated)
                            .dsShadow(.sm)
                            .matchedGeometryEffect(id: "dsSegmentedSelection", in: namespace)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Item == String {
    /// Convenience initializer for plain `String` segments where the label is the value itself.
    init(
        _ items: [String],
        selection: Binding<String>,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(items, selection: selection, haptic: haptic) { $0 }
    }
}

// MARK: - Preview

#Preview("Segmented Control") {
    struct PreviewHost: View {
        @State private var view = "List"
        @State private var period = "Week"

        var body: some View {
            VStack(spacing: DSSpacing.xxl) {
                DSSegmentedControl(["List", "Grid", "Map"], selection: $view)

                DSSegmentedControl(["Day", "Week", "Month", "Year"], selection: $period)

                Text("Selected: \(view) · \(period)")
                    .ds(.footnote, color: DSColors.defaultPalette.textSecondary)
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
