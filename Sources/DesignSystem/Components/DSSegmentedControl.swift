import SwiftUI

// MARK: - Design System Segmented Control
// An animated segmented picker with a sliding pill indicator.
// The selected segment's background glides between options using
// matchedGeometryEffect + a spring, giving native-feeling motion that
// the system UISegmentedControl doesn't animate. Great for switching
// between views, ranges, or filters (Day / Week / Month, List / Grid, …).

public struct DSSegmentedControl<Item: Hashable>: View {
    private let items: [Item]
    @Binding private var selection: Item
    private let haptic: DSHapticStyle
    private let icon: ((Item) -> String?)?
    private let title: (Item) -> String

    @Namespace private var indicatorNamespace

    /// Create a segmented control over any `Hashable` items.
    /// - Parameters:
    ///   - items: The segments to display, in order.
    ///   - selection: Binding to the currently selected item.
    ///   - haptic: Feedback fired when the selection changes (default `.selection`).
    ///   - icon: Optional SF Symbol name for each item.
    ///   - title: The label to display for each item.
    public init(
        _ items: [Item],
        selection: Binding<Item>,
        haptic: DSHapticStyle = .selection,
        icon: ((Item) -> String?)? = nil,
        title: @escaping (Item) -> String
    ) {
        self.items = items
        self._selection = selection
        self.haptic = haptic
        self.icon = icon
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

    // MARK: - Segment

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
            HStack(spacing: DSSpacing.xxs) {
                if let icon, let symbol = icon(item) {
                    Image(systemName: symbol)
                }
                Text(title(item))
            }
            .font(DSTextStyle.footnote.font)
            .foregroundStyle(
                isSelected
                    ? DSColors.defaultPalette.textPrimary
                    : DSColors.defaultPalette.textSecondary
            )
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: "indicator", in: indicatorNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Item == String {
    /// Ergonomic initializer for the common case of plain string segments.
    /// `DSSegmentedControl(["Day", "Week", "Month"], selection: $range)`
    init(
        _ titles: [String],
        selection: Binding<String>,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            titles,
            selection: selection,
            haptic: haptic,
            icon: nil,
            title: { $0 }
        )
    }
}

// MARK: - Preview

#Preview("Light") {
    DSSegmentedControlPreview()
        .padding(DSSpacing.lg)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    DSSegmentedControlPreview()
        .padding(DSSpacing.lg)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct DSSegmentedControlPreview: View {
    @State private var range = "Week"
    @State private var layout = "List"

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSSegmentedControl(["Day", "Week", "Month", "Year"], selection: $range)

            DSSegmentedControl(
                ["List", "Grid"],
                selection: $layout,
                icon: { $0 == "List" ? "list.bullet" : "square.grid.2x2" },
                title: { $0 }
            )
        }
    }
}
