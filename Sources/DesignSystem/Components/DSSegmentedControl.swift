import SwiftUI

// MARK: - Design System Segmented Control
// A polished, generic segmented control with a sliding "pill" indicator.
// The selected segment is highlighted by an elevated capsule that glides
// between options using matchedGeometryEffect + a DS spring — the kind of
// micro-interaction that makes a tab/filter switch feel premium.
//
// Inspiration / pattern reference:
//   Nil Coalescing — "Matched geometry effect in a custom segmented control"
//   https://nilcoalescing.com/blog/CustomSegmentedControlWithMatchedGeometryEffect/

public struct DSSegmentedControl<Item: Hashable>: View {

    // MARK: - Stored Properties

    @Binding private var selection: Item
    private let items: [Item]
    private let title: (Item) -> String
    private let icon: (Item) -> String?

    @Environment(\.dsTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var namespace

    private static var pillID: String { "DSSegmentedControl.pill" }

    // MARK: - Init

    /// Create a segmented control over any `Hashable` items.
    /// - Parameters:
    ///   - selection: The currently selected item.
    ///   - items: The options to display, left to right.
    ///   - title: Maps an item to its visible label.
    ///   - icon: Optional SF Symbol name shown before the label.
    public init(
        selection: Binding<Item>,
        items: [Item],
        title: @escaping (Item) -> String,
        icon: @escaping (Item) -> String? = { _ in nil }
    ) {
        self._selection = selection
        self.items = items
        self.title = title
        self.icon = icon
    }

    // MARK: - Body

    public var body: some View {
        let palette = theme.palette(for: colorScheme)

        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                segment(for: item, palette: palette)
            }
        }
        .padding(DSSpacing.xxs)
        .background(palette.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(for item: Item, palette: DSColorPalette) -> some View {
        let isSelected = item == selection

        Button {
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(.selection)
            withAnimation(DSAnimation.springSmooth) {
                selection = item
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let symbol = icon(item) {
                    Image(systemName: symbol)
                }
                Text(title(item))
                    .lineLimit(1)
            }
            .dsTextStyle(
                .buttonSmall,
                color: isSelected ? palette.textPrimary : palette.textSecondary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(palette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: Self.pillID, in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Item == String {
    /// Convenience initializer for plain string options.
    init(selection: Binding<String>, options: [String]) {
        self.init(selection: selection, items: options, title: { $0 })
    }
}

// MARK: - Preview

#Preview("Segmented Control") {
    @Previewable @State var plan = "Monthly"
    @Previewable @State var view = "list"

    return VStack(spacing: DSSpacing.xxl) {
        DSSegmentedControl(
            selection: $plan,
            options: ["Weekly", "Monthly", "Yearly"]
        )

        DSSegmentedControl(
            selection: $view,
            items: ["list", "grid", "map"],
            title: { $0.capitalized },
            icon: { item in
                switch item {
                case "list": return "list.bullet"
                case "grid": return "square.grid.2x2"
                default:     return "map"
                }
            }
        )
    }
    .padding(DSSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DSColors.defaultPalette.backgroundPrimary)
}
