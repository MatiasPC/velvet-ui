import SwiftUI

// MARK: - Design System Segmented Control
// A custom picker with a sliding "pill" that glides between segments.
// Solves the UX problem of switching between a small set of mutually
// exclusive options (filters, view modes, tabs) with motion that feels
// physical instead of the flat, jumpy native SegmentedPickerStyle.
//
// The selection indicator slides via `matchedGeometryEffect`, so the
// highlight animates smoothly from the old segment to the new one.

public struct DSSegmentedControl<Value: Hashable>: View {
    private let items: [Value]
    private let height: CGFloat
    private let titleForValue: (Value) -> String
    private let iconForValue: (Value) -> String?

    @Binding private var selection: Value
    @Namespace private var pillNamespace

    /// Create a segmented control over any `Hashable` value.
    /// - Parameters:
    ///   - items: The available options, rendered left-to-right.
    ///   - selection: Binding to the currently selected value.
    ///   - height: Control height (default 40pt).
    ///   - title: Maps a value to its visible label.
    ///   - icon: Optional SF Symbol shown before the label for a value.
    public init(
        _ items: [Value],
        selection: Binding<Value>,
        height: CGFloat = 40,
        title: @escaping (Value) -> String,
        icon: @escaping (Value) -> String? = { _ in nil }
    ) {
        self.items = items
        self._selection = selection
        self.height = height
        self.titleForValue = title
        self.iconForValue = icon
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxs) {
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
            DSHapticEngine.shared.fire(.selection)
            withAnimation(DSAnimation.springSnappy) {
                selection = item
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon = iconForValue(item) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(titleForValue(item))
                    .font(DSTextStyle.buttonSmall.font)
                    .lineLimit(1)
            }
            .foregroundStyle(
                isSelected
                    ? DSColors.defaultPalette.textPrimary
                    : DSColors.defaultPalette.textSecondary
            )
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: "dsSegmentedPill", in: pillNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience for the common case: plain text segments whose label
    /// is the value itself.
    init(
        _ titles: [String],
        selection: Binding<String>,
        height: CGFloat = 40
    ) {
        self.init(
            titles,
            selection: selection,
            height: height,
            title: { $0 },
            icon: { _ in nil }
        )
    }
}

// MARK: - Preview

private struct DSSegmentedControlPreview: View {
    @State private var range = "Week"
    @State private var layout = "grid"

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSSegmentedControl(["Day", "Week", "Month"], selection: $range)

            DSSegmentedControl(
                ["list", "grid", "map"],
                selection: $layout,
                title: { $0.capitalized },
                icon: { value in
                    switch value {
                    case "list": return "list.bullet"
                    case "grid": return "square.grid.2x2"
                    default:     return "map"
                    }
                }
            )

            Text("Selected: \(range) · \(layout)")
                .ds(.footnote, color: DSColors.defaultPalette.textSecondary)
        }
        .padding(DSSpacing.xl)
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
