import SwiftUI

// MARK: - Design System Segmented Control
// A tactile, animated segmented picker with a sliding selection indicator.
// The thumb glides between segments with a spring (matchedGeometryEffect),
// giving the classic "premium" feel found in Apple's own controls — but fully
// themeable through DS tokens. Great for filters, view modes, and small toggles.

/// Sizing options for `DSSegmentedControl`.
public enum DSSegmentedControlSize {
    /// 32pt track — compact toolbars and dense layouts
    case small
    /// 40pt track — default
    case medium

    var height: CGFloat {
        switch self {
        case .small:  return 32
        case .medium: return 40
        }
    }

    var textStyle: DSTextStyle {
        switch self {
        case .small:  return .buttonSmall
        case .medium: return .button
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small:  return 13
        case .medium: return 15
        }
    }
}

// MARK: - Segmented Control

/// A horizontally laid-out picker that animates a thumb under the selected option.
///
/// Generic over any `Hashable` value, so it works with enums, strings, or models.
///
/// ```swift
/// enum Mode: String, CaseIterable { case day, week, month }
/// @State private var mode: Mode = .week
///
/// DSSegmentedControl(selection: $mode, options: Mode.allCases) { mode in
///     mode.rawValue.capitalized
/// }
/// ```
public struct DSSegmentedControl<Value: Hashable>: View {
    private let options: [Value]
    private let size: DSSegmentedControlSize
    private let title: (Value) -> String
    private let icon: (Value) -> String?
    @Binding private var selection: Value

    @Namespace private var thumbNamespace

    /// Create a segmented control with a title (and optional SF Symbol) per option.
    /// - Parameters:
    ///   - selection: Binding to the currently selected value.
    ///   - options: The selectable values, laid out left-to-right.
    ///   - size: Track height and typography. Defaults to `.medium`.
    ///   - icon: Optional SF Symbol name for each option. Defaults to none.
    ///   - title: Display label for each option.
    public init(
        selection: Binding<Value>,
        options: [Value],
        size: DSSegmentedControlSize = .medium,
        icon: @escaping (Value) -> String? = { _ in nil },
        title: @escaping (Value) -> String
    ) {
        self._selection = selection
        self.options = options
        self.size = size
        self.icon = icon
        self.title = title
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                segment(for: option)
            }
        }
        .padding(DSSpacing.xxs)
        .background(DSColors.defaultPalette.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
    }

    @ViewBuilder
    private func segment(for option: Value) -> some View {
        let isSelected = option == selection

        Button {
            guard option != selection else { return }
            DSHapticEngine.shared.fire(.selection)
            withAnimation(DSAnimation.springSnappy) {
                selection = option
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let symbol = icon(option) {
                    Image(systemName: symbol)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }
                Text(title(option))
                    .font(size.textStyle.font)
            }
            .foregroundStyle(
                isSelected
                    ? DSColors.defaultPalette.textPrimary
                    : DSColors.defaultPalette.textSecondary
            )
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: "dsSegmentedThumb", in: thumbNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for a control whose options are their own labels.
    ///
    /// ```swift
    /// DSSegmentedControl(selection: $tab, options: ["Photos", "Albums"])
    /// ```
    init(
        selection: Binding<String>,
        options: [String],
        size: DSSegmentedControlSize = .medium
    ) {
        self.init(
            selection: selection,
            options: options,
            size: size,
            icon: { _ in nil },
            title: { $0 }
        )
    }
}

// MARK: - Preview

#Preview("Segmented Control") {
    struct PreviewWrapper: View {
        enum Mode: String, CaseIterable { case day, week, month, year }
        @State private var mode: Mode = .week
        @State private var view: String = "List"
        @State private var compact: String = "All"

        var body: some View {
            VStack(spacing: DSSpacing.xxl) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("ENUM + TITLE").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSegmentedControl(selection: $mode, options: Mode.allCases) {
                        $0.rawValue.capitalized
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("WITH ICONS").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSegmentedControl(
                        selection: $view,
                        options: ["List", "Grid", "Map"],
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

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("SMALL").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSegmentedControl(
                        selection: $compact,
                        options: ["All", "Unread"],
                        size: .small
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
