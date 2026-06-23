import SwiftUI

// MARK: - Design System Segmented Control
// An animated segmented picker with a sliding "pill" selection indicator.
// The pill glides between segments using matchedGeometryEffect for a fluid,
// premium feel — perfect for tab-style switching, filters, and mode toggles.

public struct DSSegmentedControl<Value: Hashable>: View {
    private let items: [Value]
    @Binding private var selection: Value
    private let tint: Color?
    private let haptic: DSHapticStyle
    private let title: (Value) -> String

    @Namespace private var pillNamespace

    /// Create a segmented control over any `Hashable` values.
    /// - Parameters:
    ///   - items: The options to display, in order.
    ///   - selection: The currently selected value.
    ///   - tint: Optional accent color for the selection pill. When `nil`,
    ///     a neutral elevated pill is used (iOS-native style).
    ///   - haptic: Tactile feedback fired when the selection changes.
    ///   - title: Maps each value to its display label.
    public init(
        _ items: [Value],
        selection: Binding<Value>,
        tint: Color? = nil,
        haptic: DSHapticStyle = .selection,
        title: @escaping (Value) -> String
    ) {
        self.items = items
        self._selection = selection
        self.tint = tint
        self.haptic = haptic
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
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(for item: Value) -> some View {
        let isSelected = item == selection

        Button {
            guard item != selection else { return }
            DSHapticEngine.shared.fire(haptic)
            withAnimation(DSAnimation.springSnappy) {
                selection = item
            }
        } label: {
            Text(title(item))
                .font(DSTextStyle.buttonSmall.font)
                .foregroundStyle(labelColor(isSelected: isSelected))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DSSpacing.xs)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                            .fill(pillColor)
                            .dsShadow(tint == nil ? .sm : .none)
                            .matchedGeometryEffect(id: "pill", in: pillNamespace)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Colors

    private var pillColor: Color {
        tint ?? DSColors.defaultPalette.backgroundElevated
    }

    private func labelColor(isSelected: Bool) -> Color {
        guard isSelected else { return DSColors.defaultPalette.textSecondary }
        return tint == nil ? DSColors.defaultPalette.textPrimary
                           : DSColors.defaultPalette.textOnPrimary
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience for the common case of `String` options, where each value
    /// is its own label.
    init(
        _ items: [String],
        selection: Binding<String>,
        tint: Color? = nil,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(items, selection: selection, tint: tint, haptic: haptic) { $0 }
    }
}

// MARK: - Preview

private struct DSSegmentedControlPreview: View {
    @State private var view = "List"
    @State private var range = "Week"

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSSegmentedControl(["List", "Grid", "Map"], selection: $view)

            DSSegmentedControl(
                ["Day", "Week", "Month"],
                selection: $range,
                tint: DSColors.defaultPalette.primary
            )
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
    }
}

#Preview("Light") {
    DSSegmentedControlPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DSSegmentedControlPreview()
        .preferredColorScheme(.dark)
}
