import SwiftUI

// MARK: - Design System Segmented Control
// A premium segmented selector with a sliding indicator that glides between
// options using matchedGeometryEffect. Perfect for switching views, filters,
// or modes — the motion makes the selection feel physical and responsive.
//
// Inspiration / technique:
// - matchedGeometryEffect sliding pill — https://nilcoalescing.com/blog/CustomSegmentedControlWithMatchedGeometryEffect/
// - Generic animated segment control — https://medium.com/@maysam.shahsavari/a-generic-swiftui-animated-segment-control-f3b0b9d3ed08

public enum DSSegmentedControlStyle {
    /// Neutral track with an elevated indicator (classic iOS feel)
    case subtle
    /// Neutral track with a primary-colored indicator (bolder emphasis)
    case accent
}

public struct DSSegmentedControl<Value: Hashable>: View {
    private let options: [Value]
    private let title: (Value) -> String
    private let icon: (Value) -> String?
    private let style: DSSegmentedControlStyle
    @Binding private var selection: Value

    @Namespace private var namespace

    private static var indicatorID: String { "ds.segmented.indicator" }

    // MARK: - Init

    /// Create a segmented control over any `Hashable` value.
    /// - Parameters:
    ///   - options: The selectable values, rendered left-to-right.
    ///   - selection: A binding to the currently selected value.
    ///   - style: Visual emphasis of the sliding indicator.
    ///   - icon: Optional SF Symbol name shown before each option's title.
    ///   - title: A label for each option.
    public init(
        _ options: [Value],
        selection: Binding<Value>,
        style: DSSegmentedControlStyle = .subtle,
        icon: @escaping (Value) -> String? = { _ in nil },
        title: @escaping (Value) -> String
    ) {
        self.options = options
        self._selection = selection
        self.style = style
        self.icon = icon
        self.title = title
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxxs) {
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
                .font(DSTextStyle.footnote.font)
        }
        .foregroundStyle(foregroundColor(isSelected: isSelected))
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.xs)
        .padding(.horizontal, DSSpacing.xs)
        .background(indicator(isSelected: isSelected))
        .contentShape(Rectangle())
        .onTapGesture { select(option) }
    }

    @ViewBuilder
    private func indicator(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .fill(indicatorColor)
                .dsShadow(style == .subtle ? .sm : .none)
                .matchedGeometryEffect(id: Self.indicatorID, in: namespace)
        }
    }

    // MARK: - Selection

    private func select(_ option: Value) {
        guard option != selection else { return }
        DSHapticEngine.shared.fire(.selection)
        selection = option
    }

    // MARK: - Colors

    private var indicatorColor: Color {
        let palette = DSColors.defaultPalette
        switch style {
        case .subtle: return palette.backgroundElevated
        case .accent: return palette.primary
        }
    }

    private func foregroundColor(isSelected: Bool) -> Color {
        let palette = DSColors.defaultPalette
        guard isSelected else { return palette.textSecondary }
        switch style {
        case .subtle: return palette.textPrimary
        case .accent: return palette.textOnPrimary
        }
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for a list of string titles.
    init(
        _ titles: [String],
        selection: Binding<String>,
        style: DSSegmentedControlStyle = .subtle
    ) {
        self.init(titles, selection: selection, style: style, icon: { _ in nil }, title: { $0 })
    }
}

// MARK: - Preview

#Preview {
    struct PreviewHost: View {
        @State private var mode = "Overview"
        @State private var filter = "All"
        @State private var view = "List"

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                DSSegmentedControl(
                    ["Overview", "Activity", "Settings"],
                    selection: $mode
                )

                DSSegmentedControl(
                    ["All", "Unread", "Flagged"],
                    selection: $filter,
                    style: .accent
                )

                DSSegmentedControl(
                    ["List", "Grid"],
                    selection: $view,
                    icon: { $0 == "List" ? "list.bullet" : "square.grid.2x2" },
                    title: { $0 }
                )
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return Group {
        PreviewHost()
            .preferredColorScheme(.light)
        PreviewHost()
            .preferredColorScheme(.dark)
    }
}
