import SwiftUI

// MARK: - Design System Segmented Control
// A premium alternative to the system segmented picker.
// A single selection pill slides between options with a spring animation
// (matchedGeometryEffect), giving the fluid, tactile feel of Opal/Airbnb-grade UI.
// Great for view switchers, filters, and mode toggles.

public struct DSSegmentedControl<Value: Hashable>: View {
    private let items: [Value]
    private let title: (Value) -> String
    private let icon: (Value) -> String?
    private let tint: Color?
    private let cornerRadius: CGFloat
    @Binding private var selection: Value

    @Namespace private var pillNamespace

    /// Create a segmented control over any `Hashable` values.
    /// - Parameters:
    ///   - items: The selectable options, in display order (should be unique).
    ///   - selection: Binding to the currently selected value.
    ///   - tint: Optional accent for the selection pill. When `nil` (default),
    ///           the pill is an elevated surface for a native, premium look.
    ///   - cornerRadius: Outer corner radius of the track.
    ///   - icon: Optional SF Symbol name for each item.
    ///   - title: Display label for each item.
    public init(
        _ items: [Value],
        selection: Binding<Value>,
        tint: Color? = nil,
        cornerRadius: CGFloat = DSRadius.md,
        icon: @escaping (Value) -> String? = { _ in nil },
        title: @escaping (Value) -> String
    ) {
        self.items = items
        self._selection = selection
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.icon = icon
        self.title = title
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxxs) {
            ForEach(items, id: \.self) { item in
                segment(item)
            }
        }
        .padding(DSSpacing.xxs)
        .background(DSColors.defaultPalette.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .animation(DSAnimation.springSnappy, value: selection)
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(_ item: Value) -> some View {
        let isSelected = item == selection

        Button {
            guard item != selection else { return }
            DSHapticEngine.shared.fire(.selection)
            selection = item
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let symbol = icon(item) {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title(item))
                    .ds(.buttonSmall, color: isSelected ? selectedTextColor : DSColors.defaultPalette.textSecondary)
            }
            .foregroundStyle(isSelected ? selectedTextColor : DSColors.defaultPalette.textSecondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .padding(.horizontal, DSSpacing.xs)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                        .fill(tint ?? DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(tint == nil ? .sm : .none)
                        .matchedGeometryEffect(id: "pill", in: pillNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Derived Styling

    private var pillRadius: CGFloat {
        max(cornerRadius - DSSpacing.xxs, DSRadius.xs)
    }

    private var selectedTextColor: Color {
        tint == nil ? DSColors.defaultPalette.textPrimary : DSColors.defaultPalette.textOnPrimary
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer where each string is both the value and its own label.
    init(
        _ items: [String],
        selection: Binding<String>,
        tint: Color? = nil,
        cornerRadius: CGFloat = DSRadius.md
    ) {
        self.init(
            items,
            selection: selection,
            tint: tint,
            cornerRadius: cornerRadius,
            icon: { _ in nil },
            title: { $0 }
        )
    }
}

// MARK: - Preview

#Preview("DSSegmentedControl") {
    struct PreviewHost: View {
        @State private var range = "Week"
        @State private var view = "List"
        @State private var mode = "Focus"

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                DSSegmentedControl(["Day", "Week", "Month"], selection: $range)

                DSSegmentedControl(
                    ["List", "Grid", "Map"],
                    selection: $view,
                    icon: { item in
                        switch item {
                        case "List": return "list.bullet"
                        case "Grid": return "square.grid.2x2"
                        default:     return "map"
                        }
                    },
                    title: { $0 }
                )

                DSSegmentedControl(
                    ["Focus", "Relax"],
                    selection: $mode,
                    tint: DSColors.defaultPalette.primary
                )
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return PreviewHost()
}
