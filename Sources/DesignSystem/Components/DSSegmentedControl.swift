import SwiftUI

// MARK: - Design System Segmented Control
// A custom-drawn segmented control with a selection indicator that fluidly
// slides between options using `matchedGeometryEffect`. Two looks are provided:
// a filled sliding pill (iOS-native feel) and a sliding underline (tab-bar feel).
// Fully generic over any Hashable value — ideal for view switches, filters,
// and mode toggles across any app.
//
// Inspiration: Nil Coalescing — "SwiftUI matched geometry effect in a custom
// segmented control" (https://nilcoalescing.com/blog/CustomSegmentedControlWithMatchedGeometryEffect/)

// MARK: - Style

public enum DSSegmentedControlStyle {
    /// Filled sliding pill on a rounded track — mirrors the native iOS control.
    case pill
    /// Sliding accent underline beneath the labels — tab-bar style.
    case underline
}

// MARK: - Segment Model

public struct DSSegment<Value: Hashable>: Identifiable {
    public var id: Value { value }
    public let value: Value
    public let title: String
    public let icon: String?

    public init(_ title: String, value: Value, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
}

// MARK: - Segmented Control

public struct DSSegmentedControl<Value: Hashable>: View {
    @Binding private var selection: Value
    private let segments: [DSSegment<Value>]
    private let style: DSSegmentedControlStyle
    private let accent: Color
    private let haptic: DSHapticStyle

    @Namespace private var namespace

    public init(
        selection: Binding<Value>,
        segments: [DSSegment<Value>],
        style: DSSegmentedControlStyle = .pill,
        accent: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .selection
    ) {
        self._selection = selection
        self.segments = segments
        self.style = style
        self.accent = accent
        self.haptic = haptic
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxs) {
            ForEach(segments) { segment in
                segmentButton(segment)
            }
        }
        .padding(style == .pill ? DSSpacing.xxs : 0)
        .background(track)
    }

    // MARK: - Segments

    private func segmentButton(_ segment: DSSegment<Value>) -> some View {
        let isSelected = segment.value == selection
        return Button {
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(haptic)
            withAnimation(DSAnimation.springSnappy) {
                selection = segment.value
            }
        } label: {
            HStack(spacing: DSSpacing.xs) {
                if let icon = segment.icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(segment.title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(labelColor(isSelected: isSelected))
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.sm)
            .padding(.horizontal, DSSpacing.xs)
            .background(indicator(isSelected: isSelected))
            .contentShape(Rectangle())
            .animation(DSAnimation.micro, value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selection Indicator

    @ViewBuilder
    private func indicator(isSelected: Bool) -> some View {
        if isSelected {
            switch style {
            case .pill:
                Capsule(style: .continuous)
                    .fill(DSColors.defaultPalette.backgroundElevated)
                    .matchedGeometryEffect(id: "indicator", in: namespace)
                    .dsShadow(.sm)
            case .underline:
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Capsule(style: .continuous)
                        .fill(accent)
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "indicator", in: namespace)
                }
            }
        }
    }

    // MARK: - Track

    @ViewBuilder
    private var track: some View {
        switch style {
        case .pill:
            Capsule(style: .continuous)
                .fill(DSColors.defaultPalette.backgroundSecondary)
        case .underline:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Rectangle()
                    .fill(DSColors.defaultPalette.divider)
                    .frame(height: 1)
            }
        }
    }

    // MARK: - Colors

    private func labelColor(isSelected: Bool) -> Color {
        let palette = DSColors.defaultPalette
        switch style {
        case .pill:
            return isSelected ? palette.textPrimary : palette.textSecondary
        case .underline:
            return isSelected ? accent : palette.textSecondary
        }
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Build a segmented control directly from an array of string options.
    init(
        selection: Binding<String>,
        options: [String],
        style: DSSegmentedControlStyle = .pill,
        accent: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            segments: options.map { DSSegment($0, value: $0) },
            style: style,
            accent: accent,
            haptic: haptic
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var pill = "Day"
        @State private var underline = "Overview"
        @State private var iconSelection = "grid"

        var body: some View {
            VStack(spacing: DSSpacing.xxl) {
                DSSegmentedControl(
                    selection: $pill,
                    options: ["Day", "Week", "Month"]
                )

                DSSegmentedControl(
                    selection: $underline,
                    options: ["Overview", "Details", "Reviews"],
                    style: .underline
                )

                DSSegmentedControl(
                    selection: $iconSelection,
                    segments: [
                        DSSegment("Grid", value: "grid", icon: "square.grid.2x2"),
                        DSSegment("List", value: "list", icon: "list.bullet"),
                        DSSegment("Map", value: "map", icon: "map")
                    ],
                    accent: DSColors.defaultPalette.secondary
                )
            }
            .padding(DSSpacing.xl)
        }
    }

    return PreviewWrapper()
        .background(DSColors.defaultPalette.backgroundPrimary)
}
