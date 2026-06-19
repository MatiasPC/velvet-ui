import SwiftUI

// MARK: - Design System Segmented Control
// An animated segmented control with a sliding selection indicator.
// The pill glides between options with a spring, paired with a selection
// tick — a small, satisfying micro-interaction that makes switching views,
// filters, or modes feel responsive. A clean alternative to the system
// `Picker(.segmented)` that matches the Velvet visual language.

// MARK: - Segment Model

/// A single option inside a `DSSegmentedControl`.
/// `Value` is any `Hashable` (an enum case, an index, a string, …) so the
/// control can drive your own model directly — just like `Picker`.
public struct DSSegmentItem<Value: Hashable>: Identifiable {
    public var id: Value { value }

    public let value: Value
    public let title: String
    public let icon: String?

    /// - Parameters:
    ///   - title: The visible label.
    ///   - value: The model value bound to this segment.
    ///   - icon: Optional leading SF Symbol name.
    public init(_ title: String, value: Value, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
}

// MARK: - Segmented Control

public struct DSSegmentedControl<Value: Hashable>: View {
    private let items: [DSSegmentItem<Value>]
    @Binding private var selection: Value
    private let haptic: DSHapticStyle

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dsTheme) private var theme
    @Namespace private var indicator

    /// - Parameters:
    ///   - selection: The currently selected value.
    ///   - items: The segments to display, left to right.
    ///   - haptic: Tactile feedback fired when the selection changes.
    public init(
        selection: Binding<Value>,
        items: [DSSegmentItem<Value>],
        haptic: DSHapticStyle = .selection
    ) {
        self._selection = selection
        self.items = items
        self.haptic = haptic
    }

    private var palette: DSColorPalette { theme.palette(for: colorScheme) }

    public var body: some View {
        HStack(spacing: DSSpacing.xxxs) {
            ForEach(items) { item in
                segment(for: item)
            }
        }
        .padding(DSSpacing.xxs)
        .background(
            Capsule(style: .continuous)
                .fill(palette.backgroundSecondary)
        )
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(for item: DSSegmentItem<Value>) -> some View {
        let isSelected = item.value == selection

        Button {
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(haptic)
            withAnimation(DSAnimation.springSnappy) {
                selection = item.value
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon = item.icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(item.title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(isSelected ? palette.textPrimary : palette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(palette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: "indicator", in: indicator)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Build a control from plain titles, using each title as its own value.
    /// Handy for quick text-only segments.
    init(
        selection: Binding<String>,
        titles: [String],
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            items: titles.map { DSSegmentItem($0, value: $0) },
            haptic: haptic
        )
    }
}

// MARK: - Preview

#Preview("Light") {
    DSSegmentedControlPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DSSegmentedControlPreview()
        .preferredColorScheme(.dark)
}

private struct DSSegmentedControlPreview: View {
    @State private var tab = "Overview"
    @State private var layout = 0

    @Environment(\.colorScheme) private var colorScheme
    private var palette: DSColorPalette { DSTheme().palette(for: colorScheme) }

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("TEXT").ds(.overline, color: palette.textSecondary)
                DSSegmentedControl(
                    selection: $tab,
                    titles: ["Overview", "Activity", "Settings"]
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("ICONS").ds(.overline, color: palette.textSecondary)
                DSSegmentedControl(
                    selection: $layout,
                    items: [
                        DSSegmentItem("List", value: 0, icon: "list.bullet"),
                        DSSegmentItem("Grid", value: 1, icon: "square.grid.2x2"),
                        DSSegmentItem("Map", value: 2, icon: "map")
                    ]
                )
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.backgroundPrimary)
    }
}
