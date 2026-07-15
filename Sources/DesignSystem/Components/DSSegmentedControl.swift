import SwiftUI

// MARK: - Design System Segmented Control
// A refined replacement for the native segmented picker.
// A soft pill glides between segments with a spring, giving selection
// a premium, tactile feel that the stock control can't express.

public struct DSSegmentedControl<Value: Hashable>: View {
    private let items: [Value]
    @Binding private var selection: Value
    private let haptic: DSHapticStyle
    private let titleForItem: (Value) -> String
    private let iconForItem: (Value) -> String?

    @Namespace private var namespace

    /// Create a segmented control over any `Hashable` values.
    /// - Parameters:
    ///   - selection: The currently selected value.
    ///   - items: The ordered segments to display.
    ///   - haptic: Feedback fired on selection change (defaults to a selection tick).
    ///   - title: Maps a value to its label text.
    ///   - icon: Optional SF Symbol shown before the label.
    public init(
        selection: Binding<Value>,
        items: [Value],
        haptic: DSHapticStyle = .selection,
        title: @escaping (Value) -> String,
        icon: @escaping (Value) -> String? = { _ in nil }
    ) {
        self._selection = selection
        self.items = items
        self.haptic = haptic
        self.titleForItem = title
        self.iconForItem = icon
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
    private func segment(for item: Value) -> some View {
        let isSelected = item == selection

        Button {
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(haptic)
            withAnimation(DSAnimation.springSnappy) {
                selection = item
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon = iconForItem(item) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(titleForItem(item))
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
                        .matchedGeometryEffect(id: Self.pillID, in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private static var pillID: String { "ds-segmented-pill" }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for plain string options where the value is its own label.
    init(
        selection: Binding<String>,
        options: [String],
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            items: options,
            haptic: haptic,
            title: { $0 }
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewHost: View {
        @State private var plan = "Monthly"
        @State private var view = "List"

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                DSSegmentedControl(
                    selection: $plan,
                    options: ["Weekly", "Monthly", "Yearly"]
                )

                DSSegmentedControl(
                    selection: $view,
                    items: ["List", "Grid", "Map"],
                    title: { $0 },
                    icon: { option in
                        switch option {
                        case "List": return "list.bullet"
                        case "Grid": return "square.grid.2x2"
                        default:     return "map"
                        }
                    }
                )
            }
            .padding(DSSpacing.lg)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return VStack(spacing: 0) {
        PreviewHost()
            .environment(\.colorScheme, .light)
        PreviewHost()
            .environment(\.colorScheme, .dark)
    }
}
