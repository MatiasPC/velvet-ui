import SwiftUI

// MARK: - Design System Segmented Control
// A tactile selector with a sliding indicator that springs between options.
// The workhorse for view switchers, filters, and settings toggles.
// The indicator glides via `matchedGeometryEffect`, so switching segments
// always feels physical rather than a hard cut.

public enum DSSegmentedStyle {
    /// Neutral elevated pill on a recessed track — iOS-native feel.
    case pill
    /// Accent-colored pill — bolder, for primary view switchers.
    case filled
}

public struct DSSegmentedControl<Item: Hashable>: View {
    @Binding private var selection: Item
    private let items: [Item]
    private let style: DSSegmentedStyle
    private let tint: Color
    private let haptic: DSHapticStyle
    private let title: (Item) -> String
    private let icon: (Item) -> String?

    @Namespace private var indicatorNamespace

    public init(
        selection: Binding<Item>,
        items: [Item],
        style: DSSegmentedStyle = .pill,
        tint: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .selection,
        title: @escaping (Item) -> String,
        icon: @escaping (Item) -> String? = { _ in nil }
    ) {
        self._selection = selection
        self.items = items
        self.style = style
        self.tint = tint
        self.haptic = haptic
        self.title = title
        self.icon = icon
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
    private func segment(for item: Item) -> some View {
        let isSelected = item == selection

        Button {
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(haptic)
            withAnimation(DSAnimation.springSnappy) {
                selection = item
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let symbol = icon(item) {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title(item))
                    .font(DSTextStyle.footnote.font)
            }
            .foregroundStyle(labelColor(isSelected: isSelected))
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .padding(.horizontal, DSSpacing.xs)
            .background {
                if isSelected {
                    indicator
                        .matchedGeometryEffect(id: "dsSegmentedIndicator", in: indicatorNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Indicator

    private var indicator: some View {
        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
            .fill(indicatorColor)
            .dsShadow(style == .pill ? .sm : .none)
    }

    // MARK: - Colors

    private var indicatorColor: Color {
        switch style {
        case .pill:   return DSColors.defaultPalette.backgroundElevated
        case .filled: return tint
        }
    }

    private func labelColor(isSelected: Bool) -> Color {
        let palette = DSColors.defaultPalette
        guard isSelected else { return palette.textSecondary }
        switch style {
        case .pill:   return palette.textPrimary
        case .filled: return palette.textOnPrimary
        }
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Item == String {
    /// Convenience initializer for plain string options.
    init(
        selection: Binding<String>,
        options: [String],
        style: DSSegmentedStyle = .pill,
        tint: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            items: options,
            style: style,
            tint: tint,
            haptic: haptic,
            title: { $0 },
            icon: { _ in nil }
        )
    }
}

// MARK: - Preview

#Preview("Light") {
    DSSegmentedControlPreview()
        .padding()
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    DSSegmentedControlPreview()
        .padding()
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct DSSegmentedControlPreview: View {
    @State private var view = "List"
    @State private var range = "Week"
    @State private var sort = "Recent"

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSSegmentedControl(
                selection: $view,
                items: ["List", "Grid", "Map"],
                title: { $0 },
                icon: { item in
                    switch item {
                    case "List": return "list.bullet"
                    case "Grid": return "square.grid.2x2"
                    default:     return "map"
                    }
                }
            )

            DSSegmentedControl(
                selection: $range,
                options: ["Day", "Week", "Month", "Year"]
            )

            DSSegmentedControl(
                selection: $sort,
                options: ["Recent", "Popular", "Nearby"],
                style: .filled
            )
        }
    }
}
