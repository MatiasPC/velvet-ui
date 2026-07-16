import SwiftUI

// MARK: - Design System Segmented Control
// A tactile picker with a sliding "pill" indicator that glides between options.
// The animated selection uses matchedGeometryEffect for a fluid, premium feel —
// perfect for switching tabs, filters, or view modes.

public struct DSSegmentedControl<Value: Hashable>: View {
    private let segments: [Value]
    private let title: (Value) -> String
    private let icon: (Value) -> String?
    private let haptic: DSHapticStyle
    @Binding private var selection: Value

    @Namespace private var indicatorNamespace

    /// Create a segmented control over any Hashable value.
    /// - Parameters:
    ///   - segments: The available options, rendered left-to-right.
    ///   - selection: The currently selected value.
    ///   - haptic: Feedback fired when the selection changes (default: `.selection`).
    ///   - title: Provides the label text for each segment.
    ///   - icon: Optional SF Symbol name shown before the label for each segment.
    public init(
        _ segments: [Value],
        selection: Binding<Value>,
        haptic: DSHapticStyle = .selection,
        title: @escaping (Value) -> String,
        icon: @escaping (Value) -> String? = { _ in nil }
    ) {
        self.segments = segments
        self._selection = selection
        self.haptic = haptic
        self.title = title
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxs) {
            ForEach(segments, id: \.self) { segment in
                segmentButton(for: segment)
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
    private func segmentButton(for segment: Value) -> some View {
        let isSelected = segment == selection

        Button {
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(haptic)
            withAnimation(DSAnimation.springSnappy) {
                selection = segment
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let symbol = icon(segment) {
                    Image(systemName: symbol)
                }
                Text(title(segment))
            }
            .font(DSTextStyle.buttonSmall.font)
            .foregroundStyle(
                isSelected
                    ? DSColors.defaultPalette.textPrimary
                    : DSColors.defaultPalette.textSecondary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background(indicator(isSelected: isSelected))
            .contentShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sliding Indicator

    @ViewBuilder
    private func indicator(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .fill(DSColors.defaultPalette.backgroundElevated)
                .dsShadow(.sm)
                .matchedGeometryEffect(id: "dsSegmentIndicator", in: indicatorNamespace)
        }
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Create a segmented control from a list of string labels.
    init(
        _ segments: [String],
        selection: Binding<String>,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            segments,
            selection: selection,
            haptic: haptic,
            title: { $0 }
        )
    }
}

// MARK: - Preview

#Preview("Segmented Control") {
    struct PreviewWrapper: View {
        @State private var view = "List"
        @State private var range = "Week"

        var body: some View {
            VStack(spacing: DSSpacing.xxl) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("ICON + LABEL")
                        .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSegmentedControl(
                        ["List", "Grid", "Map"],
                        selection: $view,
                        title: { $0 },
                        icon: { value in
                            switch value {
                            case "List": return "list.bullet"
                            case "Grid": return "square.grid.2x2"
                            default:     return "map"
                            }
                        }
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("LABEL ONLY")
                        .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSegmentedControl(
                        ["Day", "Week", "Month", "Year"],
                        selection: $range
                    )
                }
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return PreviewWrapper()
}
