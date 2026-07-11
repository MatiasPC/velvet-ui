import SwiftUI

// MARK: - Design System Segmented Control
// An animated segmented control with a sliding selection indicator.
// The pill glides between segments using `matchedGeometryEffect` + a DS spring,
// giving the tactile, polished feel of a native control with full DS styling.
// Generic over any Hashable item, with a String convenience for the common case.
//
// Inspiration / attribution:
//  - Nil Coalescing — "SwiftUI matched geometry effect in a custom segmented control"
//    https://nilcoalescing.com/blog/CustomSegmentedControlWithMatchedGeometryEffect/
//  - DevTechie / Kavsoft — "Sliding Pill Animation with matchedGeometryEffect"

public struct DSSegmentedControl<Item: Hashable>: View {
    private let items: [Item]
    private let titleFor: (Item) -> String
    private let iconFor: (Item) -> String?
    @Binding private var selection: Item

    @Namespace private var indicatorNamespace

    /// Create a segmented control over any Hashable item.
    /// - Parameters:
    ///   - items: The ordered segments to display.
    ///   - selection: A binding to the currently selected item.
    ///   - icon: Optional SF Symbol name shown before each segment's title.
    ///   - title: The label text for each item.
    public init(
        _ items: [Item],
        selection: Binding<Item>,
        icon: @escaping (Item) -> String? = { _ in nil },
        title: @escaping (Item) -> String
    ) {
        self.items = items
        self._selection = selection
        self.iconFor = icon
        self.titleFor = title
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
    private func segment(for item: Item) -> some View {
        let isSelected = item == selection
        let labelColor = isSelected
            ? DSColors.defaultPalette.textPrimary
            : DSColors.defaultPalette.textSecondary

        Button {
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(.selection)
            withAnimation(DSAnimation.springSmooth) {
                selection = item
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon = iconFor(item) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(labelColor)
                }
                Text(titleFor(item))
                    .ds(.footnote, color: labelColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .contentShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: "dsSegmentIndicator", in: indicatorNamespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Item == String {
    /// Convenience initializer for a plain list of string segments.
    init(
        _ items: [String],
        selection: Binding<String>,
        icon: @escaping (String) -> String? = { _ in nil }
    ) {
        self.init(items, selection: selection, icon: icon, title: { $0 })
    }
}

// MARK: - Preview

#Preview {
    struct PreviewHost: View {
        @State private var period = "Week"
        @State private var view = "List"
        @State private var scheme: ColorScheme

        init(scheme: ColorScheme) {
            _scheme = State(initialValue: scheme)
        }

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                DSSegmentedControl(["Day", "Week", "Month"], selection: $period)

                DSSegmentedControl(
                    ["List", "Grid"],
                    selection: $view,
                    icon: { $0 == "List" ? "list.bullet" : "square.grid.2x2" }
                )

                Text("Showing \(view) for this \(period)")
                    .ds(.callout, color: DSColors.defaultPalette.textSecondary)
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
            .preferredColorScheme(scheme)
        }
    }

    return VStack(spacing: 0) {
        PreviewHost(scheme: .light)
        PreviewHost(scheme: .dark)
    }
}
