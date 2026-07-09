import SwiftUI

// MARK: - Design System Segmented Control
// A tactile segmented picker with a spring-driven pill that glides
// between options. Fills a gap in the DS — the first selection control.
// The sliding indicator uses `matchedGeometryEffect` so the highlight
// physically travels to the tapped segment instead of cross-fading.

public struct DSSegmentedControl<Value: Hashable>: View {
    private let items: [Value]
    private let title: (Value) -> String
    private let systemImage: (Value) -> String?
    @Binding private var selection: Value

    @Namespace private var namespace

    /// The shared identity for the sliding indicator across all segments.
    private let indicatorID = "DSSegmentedControlIndicator"

    public init(
        _ items: [Value],
        selection: Binding<Value>,
        title: @escaping (Value) -> String,
        systemImage: @escaping (Value) -> String? = { _ in nil }
    ) {
        self.items = items
        self._selection = selection
        self.title = title
        self.systemImage = systemImage
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
                if let icon = systemImage(item) {
                    Image(systemName: icon)
                }
                Text(title(item))
            }
            .font(DSTextStyle.buttonSmall.font)
            .foregroundStyle(
                isSelected
                    ? DSColors.defaultPalette.textPrimary
                    : DSColors.defaultPalette.textSecondary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.sm)
            .padding(.horizontal, DSSpacing.xs)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: indicatorID, in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for plain string options where each option is
    /// both the value and its own label.
    init(_ items: [String], selection: Binding<String>) {
        self.init(items, selection: selection, title: { $0 })
    }
}

// MARK: - Preview

private struct DSSegmentedControlPreview: View {
    @State private var period = "Week"
    @State private var view = "List"

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("PLAIN").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSegmentedControl(
                    ["Day", "Week", "Month", "Year"],
                    selection: $period
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("WITH ICONS").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSegmentedControl(
                    ["List", "Grid"],
                    selection: $view,
                    title: { $0 },
                    systemImage: { $0 == "List" ? "list.bullet" : "square.grid.2x2" }
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
