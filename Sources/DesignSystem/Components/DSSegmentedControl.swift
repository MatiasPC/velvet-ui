import SwiftUI

// MARK: - Design System Segmented Control
// A polished, animated alternative to the native segmented picker.
// A single "pill" glides between options with a spring, giving selection
// a premium, tactile feel — perfect for tabs, filters, and mode switches.

public struct DSSegmentedControl<Value: Hashable>: View {
    private let options: [Value]
    private let title: (Value) -> String
    private let icon: (Value) -> String?
    private let cornerRadius: CGFloat
    private let haptic: DSHapticStyle
    @Binding private var selection: Value

    @Namespace private var namespace

    /// Inset of the sliding pill from the track edges.
    private let trackInset: CGFloat = DSSpacing.xxs

    public init(
        _ options: [Value],
        selection: Binding<Value>,
        cornerRadius: CGFloat = DSRadius.md,
        haptic: DSHapticStyle = .selection,
        icon: @escaping (Value) -> String? = { _ in nil },
        title: @escaping (Value) -> String
    ) {
        self.options = options
        self._selection = selection
        self.cornerRadius = cornerRadius
        self.haptic = haptic
        self.icon = icon
        self.title = title
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                segment(for: option)
            }
        }
        .padding(trackInset)
        .background(DSColors.defaultPalette.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(for option: Value) -> some View {
        let isSelected = option == selection

        HStack(spacing: DSSpacing.xxs) {
            if let systemName = icon(option) {
                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(title(option))
                .font(DSTextStyle.buttonSmall.font)
                .lineLimit(1)
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
                RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                    .fill(DSColors.defaultPalette.backgroundElevated)
                    .dsShadow(.sm)
                    .matchedGeometryEffect(id: "pill", in: namespace)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard option != selection else { return }
            DSHapticEngine.shared.fire(haptic)
            selection = option
        }
        .animation(DSAnimation.springSnappy, value: selection)
    }

    /// Pill corner radius, inset to nest cleanly inside the track.
    private var pillRadius: CGFloat {
        max(cornerRadius - trackInset, DSRadius.xs)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for a control whose options are their own labels.
    init(
        _ options: [String],
        selection: Binding<String>,
        cornerRadius: CGFloat = DSRadius.md,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            options,
            selection: selection,
            cornerRadius: cornerRadius,
            haptic: haptic,
            icon: { _ in nil },
            title: { $0 }
        )
    }
}

// MARK: - Preview

private struct DSSegmentedControlPreview: View {
    @State private var plan = "Monthly"
    @State private var view = "List"

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Text segments").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSegmentedControl(["Monthly", "Yearly"], selection: $plan)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Icon + text segments").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSegmentedControl(
                    ["List", "Grid", "Map"],
                    selection: $view,
                    icon: { option in
                        switch option {
                        case "List": return "list.bullet"
                        case "Grid": return "square.grid.2x2"
                        default:     return "map"
                        }
                    },
                    title: { $0 }
                )
            }
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
