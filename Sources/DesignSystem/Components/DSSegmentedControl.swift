import SwiftUI

// MARK: - Design System Segmented Control
// A polished picker with a sliding "pill" indicator that glides between
// segments using matchedGeometryEffect. The workhorse alternative to the
// system segmented control — with DS tokens, springs, and selection haptics.

public struct DSSegmentedControl<Item: Hashable>: View {
    private let items: [Item]
    @Binding private var selection: Item
    private let icon: (Item) -> String?
    private let title: (Item) -> String

    @Namespace private var namespace

    /// Create a segmented control over any Hashable items.
    /// - Parameters:
    ///   - items: The selectable options, shown left-to-right.
    ///   - selection: The currently selected item.
    ///   - icon: Optional SF Symbol name shown before each label.
    ///   - title: The visible label for an item.
    public init(
        _ items: [Item],
        selection: Binding<Item>,
        icon: @escaping (Item) -> String? = { _ in nil },
        title: @escaping (Item) -> String
    ) {
        self.items = items
        self._selection = selection
        self.icon = icon
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
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        .animation(DSAnimation.springSmooth, value: selection)
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(for item: Item) -> some View {
        let isSelected = item == selection

        Button {
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(.selection)
            selection = item
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let name = icon(item) {
                    Image(systemName: name)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title(item))
                    .font(isSelected ? DSTextStyle.buttonSmall.font : DSTextStyle.footnote.font)
            }
            .foregroundStyle(
                isSelected
                    ? DSColors.defaultPalette.textPrimary
                    : DSColors.defaultPalette.textSecondary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: "indicator", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Item == String {
    /// Convenience initializer for plain string options.
    init(_ items: [String], selection: Binding<String>) {
        self.init(items, selection: selection, icon: { _ in nil }, title: { $0 })
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var period = "Week"
        @State private var view = "List"

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                DSSegmentedControl(
                    ["Day", "Week", "Month"],
                    selection: $period
                )

                DSSegmentedControl(
                    ["List", "Grid"],
                    selection: $view,
                    icon: { $0 == "List" ? "list.bullet" : "square.grid.2x2" },
                    title: { $0 }
                )
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return VStack(spacing: 0) {
        PreviewWrapper()
            .environment(\.colorScheme, .light)
        PreviewWrapper()
            .environment(\.colorScheme, .dark)
    }
}
