import SwiftUI

// MARK: - Design System Segmented Control
// A tactile alternative to the system segmented control with a sliding pill
// that glides between options using matchedGeometryEffect + a snappy spring.
// Great for switching between a small set of views, filters, or modes.
//
// Inspired by the classic SwiftUI community pattern (Nil Coalescing / Natalia Panferova):
// https://nilcoalescing.com/blog/CustomSegmentedControlWithMatchedGeometryEffect/

public struct DSSegmentedControl<Value: Hashable>: View {

    // MARK: - Configuration

    private let options: [Value]
    private let title: (Value) -> String
    private let icon: (Value) -> String?
    private let haptic: DSHapticStyle

    @Binding private var selection: Value
    @Namespace private var pillNamespace

    /// Create a segmented control over any set of `Hashable` values.
    /// - Parameters:
    ///   - options: The selectable values, rendered left-to-right.
    ///   - selection: A binding to the currently selected value.
    ///   - haptic: Feedback fired when the user changes selection (default `.selection`).
    ///   - icon: Optional SF Symbol name shown before the title for a value (default none).
    ///   - title: The label shown for a value.
    public init(
        _ options: [Value],
        selection: Binding<Value>,
        haptic: DSHapticStyle = .selection,
        icon: @escaping (Value) -> String? = { _ in nil },
        title: @escaping (Value) -> String
    ) {
        self.options = options
        self._selection = selection
        self.haptic = haptic
        self.icon = icon
        self.title = title
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                segment(for: option)
            }
        }
        .padding(DSSpacing.xxs)
        .background(DSColors.defaultPalette.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        .animation(DSAnimation.springSnappy, value: selection)
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(for option: Value) -> some View {
        let isSelected = option == selection

        HStack(spacing: DSSpacing.xxs) {
            if let symbol = icon(option) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(title(option))
                .ds(
                    .buttonSmall,
                    color: isSelected
                        ? DSColors.defaultPalette.textPrimary
                        : DSColors.defaultPalette.textSecondary
                )
        }
        .foregroundStyle(
            isSelected
                ? DSColors.defaultPalette.textPrimary
                : DSColors.defaultPalette.textSecondary
        )
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.xs)
        .padding(.horizontal, DSSpacing.xs)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                    .fill(DSColors.defaultPalette.backgroundElevated)
                    .dsShadow(.sm)
                    .matchedGeometryEffect(id: "dsSegmentedPill", in: pillNamespace)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard option != selection else { return }
            DSHapticEngine.shared.fire(haptic)
            selection = option
        }
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for a control whose values are their own labels.
    init(
        _ options: [String],
        selection: Binding<String>,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            options,
            selection: selection,
            haptic: haptic,
            title: { $0 }
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewHost: View {
        @State private var mode = "Overview"
        @State private var period = "Week"
        @State private var view = "list"

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                DSSegmentedControl(
                    ["Overview", "Activity", "Settings"],
                    selection: $mode
                )

                DSSegmentedControl(
                    ["Day", "Week", "Month"],
                    selection: $period
                )

                DSSegmentedControl(
                    ["list", "grid"],
                    selection: $view,
                    icon: { $0 == "list" ? "list.bullet" : "square.grid.2x2" },
                    title: { $0.capitalized }
                )
            }
            .padding(DSSpacing.xl)
        }
    }

    return VStack(spacing: DSSpacing.xxl) {
        PreviewHost()
            .background(DSColors.defaultPalette.backgroundPrimary)
            .environment(\.colorScheme, .light)

        PreviewHost()
            .background(DSColors.defaultPalette.backgroundPrimary)
            .environment(\.colorScheme, .dark)
    }
}
