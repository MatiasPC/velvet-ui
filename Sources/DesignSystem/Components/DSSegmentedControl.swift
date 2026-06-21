import SwiftUI

// MARK: - Design System Segmented Control
// A polished alternative to the system picker: a sliding "pill" selector
// where the highlight glides between options with spring physics.
// Great for switching views, filtering, or toggling modes.
// The motion is driven by `matchedGeometryEffect`, so the indicator
// smoothly interpolates its frame between segments.

public struct DSSegmentedControl<Value: Hashable>: View {

    // MARK: - Properties

    private let items: [Value]
    @Binding private var selection: Value
    private let icon: ((Value) -> String?)?
    private let title: (Value) -> String
    private let cornerRadius: CGFloat

    @Namespace private var namespace

    // MARK: - Init

    /// Create a segmented control over any `Hashable` value.
    /// - Parameters:
    ///   - items: The selectable values, laid out left-to-right with equal width.
    ///   - selection: The currently selected value.
    ///   - icon: Optional SF Symbol name shown before each segment's title.
    ///   - cornerRadius: Track corner radius (the pill nests inside it).
    ///   - title: The display label for each value.
    public init(
        _ items: [Value],
        selection: Binding<Value>,
        icon: ((Value) -> String?)? = nil,
        cornerRadius: CGFloat = DSRadius.md,
        title: @escaping (Value) -> String
    ) {
        self.items = items
        self._selection = selection
        self.icon = icon
        self.cornerRadius = cornerRadius
        self.title = title
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                segment(for: items[index])
            }
        }
        .padding(DSSpacing.xxs)
        .background(DSColors.defaultPalette.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .animation(DSAnimation.springSmooth, value: selection)
    }

    // MARK: - Segment

    @ViewBuilder
    private func segment(for item: Value) -> some View {
        let isSelected = item == selection

        Button {
            guard item != selection else { return }
            DSHapticEngine.shared.fire(.selection)
            selection = item
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let symbol = icon?(item) {
                    Image(systemName: symbol)
                }
                Text(title(item))
                    .lineLimit(1)
            }
            .font(DSTextStyle.buttonSmall.font)
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
                        .matchedGeometryEffect(id: "DSSegmentedPill", in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    /// The pill radius nests just inside the track for a balanced inset.
    private var pillRadius: CGFloat {
        max(cornerRadius - DSSpacing.xxs, DSRadius.xs)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for plain string segments.
    init(_ items: [String], selection: Binding<String>) {
        self.init(items, selection: selection) { $0 }
    }
}

// MARK: - Preview

private struct DSSegmentedControlPreview: View {
    @State private var view = "Day"
    @State private var sort = "Recent"

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSSegmentedControl(["Day", "Week", "Month"], selection: $view)

            DSSegmentedControl(
                ["Recent", "Popular", "Nearby"],
                selection: $sort,
                icon: { value in
                    switch value {
                    case "Recent":  return "clock"
                    case "Popular": return "flame"
                    default:        return "location"
                    }
                }
            ) { $0 }
        }
        .padding(DSSpacing.xl)
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
