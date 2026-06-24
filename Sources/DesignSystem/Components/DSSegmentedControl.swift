import SwiftUI

// MARK: - Design System Segmented Control
// A polished selection control with a sliding "pill" that glides between
// options using matchedGeometryEffect + a spring. Solves the boring/jumpy
// native picker with motion that feels alive, plus tactile selection haptics.
// Generic over any Hashable item, with a clean convenience for plain strings.

public struct DSSegmentedControl<Item: Hashable>: View {
    private let items: [Item]
    @Binding private var selection: Item
    private let title: (Item) -> String
    private let icon: ((Item) -> String?)?

    @Namespace private var pillNamespace

    /// Create a segmented control over any Hashable items.
    /// - Parameters:
    ///   - items: The options to display, left to right (equal width).
    ///   - selection: The currently selected item.
    ///   - title: Maps an item to its display label.
    ///   - icon: Optional SF Symbol name shown before the label.
    public init(
        _ items: [Item],
        selection: Binding<Item>,
        title: @escaping (Item) -> String,
        icon: ((Item) -> String?)? = nil
    ) {
        self.items = items
        self._selection = selection
        self.title = title
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 0) {
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
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(.selection)
            withAnimation(DSAnimation.springSnappy) {
                selection = item
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon, let symbol = icon(item) {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(title(item))
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(
                isSelected
                    ? DSColors.defaultPalette.textPrimary
                    : DSColors.defaultPalette.textSecondary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: "pill", in: pillNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Item == String {
    /// Convenience initializer for a control whose items are their own labels.
    init(_ items: [String], selection: Binding<String>) {
        self.init(items, selection: selection, title: { $0 }, icon: nil)
    }
}

// MARK: - Preview

private struct DSSegmentedControlPreview: View {
    @State private var plan = "Monthly"
    @State private var view = "List"

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSSegmentedControl(["Monthly", "Yearly"], selection: $plan)

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
        .padding(DSSpacing.lg)
    }
}

#Preview("Light") {
    DSSegmentedControlPreview()
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    DSSegmentedControlPreview()
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}
