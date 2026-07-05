import SwiftUI

// MARK: - Design System Segmented Control
// A tactile, animated segmented picker with a sliding "pill" selection.
// The active indicator glides between segments using matchedGeometryEffect,
// giving a premium, fluid feel that stock `Picker(.segmented)` can't match.
// Generic over any Hashable value — strings, enums, model types.
//
// Inspiration / technique (matchedGeometryEffect sliding pill):
// https://nilcoalescing.com/blog/CustomSegmentedControlWithMatchedGeometryEffect/

public struct DSSegmentedControl<Item: Hashable>: View {
    @Binding private var selection: Item
    private let items: [Item]
    private let haptic: DSHapticStyle
    private let systemImage: ((Item) -> String?)?
    private let title: (Item) -> String

    @Namespace private var pillNamespace

    /// Create a segmented control over any Hashable items.
    /// - Parameters:
    ///   - selection: The currently selected item.
    ///   - items: The segments to display, in order.
    ///   - haptic: Feedback fired when the selection changes (default `.selection`).
    ///   - systemImage: Optional SF Symbol shown before each segment's title.
    ///   - title: A label for each item.
    public init(
        selection: Binding<Item>,
        items: [Item],
        haptic: DSHapticStyle = .selection,
        systemImage: ((Item) -> String?)? = nil,
        title: @escaping (Item) -> String
    ) {
        self._selection = selection
        self.items = items
        self.haptic = haptic
        self.systemImage = systemImage
        self.title = title
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                segment(item)
            }
        }
        .padding(DSSpacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .fill(DSColors.defaultPalette.backgroundSecondary)
        )
        .animation(DSAnimation.springSnappy, value: selection)
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(_ item: Item) -> some View {
        let isSelected = item == selection

        Button {
            guard selection != item else { return }
            DSHapticEngine.shared.fire(haptic)
            selection = item
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon = systemImage?(item) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title(item))
                    .ds(.footnote, color: isSelected
                        ? DSColors.defaultPalette.textPrimary
                        : DSColors.defaultPalette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: "dsSegmentPill", in: pillNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Item == String {
    /// Create a segmented control directly from an array of string labels.
    init(
        _ items: [String],
        selection: Binding<String>,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            items: items,
            haptic: haptic,
            systemImage: nil,
            title: { $0 }
        )
    }
}

// MARK: - Preview

private struct DSSegmentedControlPreview: View {
    @State private var tab = "Overview"
    @State private var view = "list"

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSSegmentedControl(
                ["Overview", "Activity", "Settings"],
                selection: $tab
            )

            DSSegmentedControl(
                selection: $view,
                items: ["list", "grid", "map"],
                systemImage: { item in
                    switch item {
                    case "list": return "list.bullet"
                    case "grid": return "square.grid.2x2"
                    default:     return "map"
                    }
                },
                title: { $0.capitalized }
            )
        }
        .dsScreenPadding()
    }
}

#Preview {
    DSSegmentedControlPreview()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
}
