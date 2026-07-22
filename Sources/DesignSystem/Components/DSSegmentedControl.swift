import SwiftUI

// MARK: - Design System Segmented Control
// A polished segmented picker with a sliding "pill" that glides between
// options using matchedGeometryEffect. The premium alternative to the stock
// UISegmentedControl — perfect for filters, toggling views, and tabbed content.
// Inspired by the SwiftUI community's matched-geometry segmented pattern
// (Nil Coalescing, DevTechie).

public struct DSSegmentedControl<Value: Hashable>: View {
    private let options: [Value]
    @Binding private var selection: Value
    private let title: (Value) -> String
    private let haptic: DSHapticStyle

    @Namespace private var namespace

    /// Create a segmented control over any `Hashable` value.
    /// - Parameters:
    ///   - selection: The currently selected option.
    ///   - options: The ordered options to display, left to right.
    ///   - haptic: Tactile feedback fired on each selection change.
    ///   - title: A label to render for each option.
    public init(
        selection: Binding<Value>,
        options: [Value],
        haptic: DSHapticStyle = .selection,
        title: @escaping (Value) -> String
    ) {
        self._selection = selection
        self.options = options
        self.haptic = haptic
        self.title = title
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxs) {
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

        Text(title(option))
            .ds(
                .buttonSmall,
                color: isSelected
                    ? DSColors.defaultPalette.textPrimary
                    : DSColors.defaultPalette.textSecondary
            )
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .padding(.horizontal, DSSpacing.sm)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: Self.pillID, in: namespace)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isSelected else { return }
                DSHapticEngine.shared.fire(haptic)
                selection = option
            }
    }

    private static var pillID: String { "ds.segmented.pill" }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for plain `String` options — the label is the value itself.
    init(
        selection: Binding<String>,
        options: [String],
        haptic: DSHapticStyle = .selection
    ) {
        self.init(selection: selection, options: options, haptic: haptic) { $0 }
    }
}

// MARK: - Preview

#Preview("Segmented Control") {
    struct PreviewHost: View {
        @State private var range = "Week"
        @State private var view = "List"

        var body: some View {
            VStack(spacing: DSSpacing.xxl) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("TIME RANGE").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSegmentedControl(
                        selection: $range,
                        options: ["Day", "Week", "Month", "Year"]
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("LAYOUT").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSegmentedControl(
                        selection: $view,
                        options: ["List", "Grid"]
                    )
                }
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return Group {
        PreviewHost().preferredColorScheme(.light)
        PreviewHost().preferredColorScheme(.dark)
    }
}
