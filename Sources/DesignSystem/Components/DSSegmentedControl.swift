import SwiftUI

// MARK: - Design System Segmented Control
// A polished replacement for the native segmented picker.
// A selection "pill" springs between options via matchedGeometryEffect,
// giving tab / filter / view-mode switchers a premium, tactile feel.

public struct DSSegmentedControl<Item: Hashable>: View {
    private let items: [Item]
    private let title: (Item) -> String
    @Binding private var selection: Item
    private let haptic: DSHapticStyle

    @Namespace private var namespace

    /// - Parameters:
    ///   - items: The selectable options, rendered left-to-right.
    ///   - selection: The currently selected option.
    ///   - haptic: Feedback fired when the selection changes (`.selection` by default).
    ///   - title: Maps an option to its display label.
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
        .background(
            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .fill(DSColors.defaultPalette.backgroundSecondary)
        )
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(for item: Item) -> some View {
        let isSelected = item == selection

        Text(title(item))
            .ds(
                .footnote,
                color: isSelected
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
                        .matchedGeometryEffect(id: selectionPillID, in: namespace)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { select(item) }
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
    /// Convenience for plain string options — the label is the value itself.
    init(
        _ items: [String],
        selection: Binding<String>,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(items, selection: selection, haptic: haptic, title: { $0 })
    }
}

// MARK: - Matched Geometry ID

/// Shared identifier for the sliding selection pill.
private let selectionPillID = "DSSegmentedControl.pill"

// MARK: - Preview

#Preview("DSSegmentedControl") {
    struct PreviewHost: View {
        @State private var view = "List"
        @State private var range = "Week"

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                DSSegmentedControl(["List", "Grid", "Map"], selection: $view)

                DSSegmentedControl(["Day", "Week", "Month", "Year"], selection: $range)

                Text("Showing: \(view) · \(range)")
                    .ds(.callout, color: DSColors.defaultPalette.textSecondary)
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
