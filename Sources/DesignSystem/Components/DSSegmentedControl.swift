import SwiftUI

// MARK: - Design System Segmented Control
// An animated segmented control with a selection indicator that smoothly
// slides between segments via `matchedGeometryEffect`.
// A premium replacement for the system `Picker(.segmented)` — perfect for
// switching between views, time ranges, or filters with a tactile, fluid feel.
// Inspired by the matchedGeometryEffect pattern popularized across the SwiftUI
// community (Nil Coalescing, Sarunw, Kavsoft).

public enum DSSegmentedControlStyle {
    /// Floating capsule thumb on a track — the classic native-style control
    case pill
    /// Tab-bar style with a sliding underline indicator (no track)
    case underline
}

public struct DSSegmentedControl<Value: Hashable>: View {
    @Binding private var selection: Value
    private let items: [Value]
    private let style: DSSegmentedControlStyle
    private let title: (Value) -> String

    @Namespace private var indicator

    public init(
        selection: Binding<Value>,
        items: [Value],
        style: DSSegmentedControlStyle = .pill,
        title: @escaping (Value) -> String
    ) {
        self._selection = selection
        self.items = items
        self.style = style
        self.title = title
    }

    public var body: some View {
        HStack(spacing: style == .underline ? DSSpacing.lg : 0) {
            ForEach(items, id: \.self) { item in
                segment(for: item)
            }
        }
        .padding(containerPadding)
        .background(track)
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
            Text(title(item))
                .ds(.buttonSmall, color: isSelected ? selectedTextColor : DSColors.defaultPalette.textSecondary)
                .padding(.vertical, DSSpacing.xs)
                .padding(.horizontal, DSSpacing.sm)
                .frame(maxWidth: style == .pill ? .infinity : nil)
                .background(pillThumb(isSelected: isSelected))
                .overlay(alignment: .bottom) { underlineThumb(isSelected: isSelected) }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selection Indicators

    @ViewBuilder
    private func pillThumb(isSelected: Bool) -> some View {
        if style == .pill, isSelected {
            Capsule(style: .continuous)
                .fill(DSColors.defaultPalette.backgroundElevated)
                .dsShadow(.sm)
                .matchedGeometryEffect(id: "dsSegmentIndicator", in: indicator)
        }
    }

    @ViewBuilder
    private func underlineThumb(isSelected: Bool) -> some View {
        if style == .underline, isSelected {
            Capsule(style: .continuous)
                .fill(DSColors.defaultPalette.primary)
                .frame(height: 2)
                .matchedGeometryEffect(id: "dsSegmentIndicator", in: indicator)
        }
    }

    // MARK: - Styling

    @ViewBuilder
    private var track: some View {
        if style == .pill {
            Capsule(style: .continuous)
                .fill(DSColors.defaultPalette.backgroundSecondary)
        }
    }

    private var containerPadding: CGFloat {
        style == .pill ? DSSpacing.xxs : 0
    }

    private var selectedTextColor: Color {
        style == .pill ? DSColors.defaultPalette.textPrimary : DSColors.defaultPalette.primary
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for plain string options.
    init(
        selection: Binding<String>,
        options: [String],
        style: DSSegmentedControlStyle = .pill
    ) {
        self.init(selection: selection, items: options, style: style) { $0 }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewHarness: View {
        @State private var range = "Week"
        @State private var tab = "Activity"

        var body: some View {
            VStack(spacing: DSSpacing.xxl) {
                DSSegmentedControl(
                    selection: $range,
                    options: ["Day", "Week", "Month"]
                )

                DSSegmentedControl(
                    selection: $tab,
                    options: ["Activity", "Stats", "Profile"],
                    style: .underline
                )
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return VStack(spacing: 0) {
        PreviewHarness()
            .environment(\.colorScheme, .light)
        PreviewHarness()
            .environment(\.colorScheme, .dark)
    }
}
