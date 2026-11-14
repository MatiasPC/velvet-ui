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
    private let accent: Color?
    private let haptic: DSHapticStyle

    @Namespace private var namespace
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameter accent: Underline fill / selected label color (underline style). Defaults to the theme accent.
    public init(
        selection: Binding<Value>,
        segments: [DSSegment<Value>],
        style: DSSegmentedControlStyle = .pill,
        accent: Color? = nil,
        haptic: DSHapticStyle = .selection
    ) {
        self._selection = selection
        // Duplicate values would give ForEach duplicate IDs; the first one wins.
        self.segments = DSSegmentedControlLogic.uniqueIndices(of: segments.map(\.value)).map { segments[$0] }
        self.style = style
        self.accent = accent
        self.haptic = haptic
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxs) {
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                segmentButton(segment, index: index)
            }
        }
        .padding(style == .pill ? DSSpacing.xxs : 0)
        .background(track)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Segments

    private func segmentButton(_ segment: DSSegment<Value>, index: Int) -> some View {
        let isSelected = segment.value == selection
        return Button {
            guard DSSegmentedControlLogic.shouldSelect(segment.value, current: selection) else { return }
            DSHapticEngine.shared.fire(haptic)
            withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy) {
                selection = segment.value
            }
        } label: {
            HStack(spacing: DSSpacing.xs) {
                if let icon = segment.icon {
                    Image(systemName: icon)
                        .dsFont(.buttonSmall)
                        .accessibilityHidden(!segment.title.isEmpty)
                }
                if !segment.title.isEmpty {
                    Text(segment.title)
                        .dsFont(.buttonSmall)
                        .lineLimit(1)
                }
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
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityValue(DSSegmentedControlLogic.accessibilityValue(index: index, count: segments.count))
    }

    // MARK: - Selection Indicator

    @ViewBuilder
    private func indicator(isSelected: Bool) -> some View {
        if isSelected {
            switch style {
            case .pill:
                Capsule(style: .continuous)
                    .fill(theme.palette.backgroundElevated)
                    .modifier(slidingIndicator)
                    .dsShadow(.sm)
            case .underline:
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Capsule(style: .continuous)
                        .fill(accent ?? theme.accent)
                        .frame(height: 2)
                        .modifier(slidingIndicator)
                }
            }
        }
    }

    /// Shared geometry slides the indicator between segments. Under Reduce
    /// Motion it doesn't travel: the old one fades out and the new one fades in.
    private var slidingIndicator: DSSegmentIndicatorGeometry {
        DSSegmentIndicatorGeometry(
            namespace: namespace,
            slides: DSSegmentedControlLogic.slidesIndicator(reduceMotion: reduceMotion)
        )
    }

    // MARK: - Track

    @ViewBuilder
    private var track: some View {
        switch style {
        case .pill:
            Capsule(style: .continuous)
                .fill(theme.palette.backgroundSecondary)
        case .underline:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Rectangle()
                    .fill(theme.palette.divider)
                    .frame(height: 1)
            }
        }
    }

    // MARK: - Colors

    private func labelColor(isSelected: Bool) -> Color {
        switch style {
        case .pill:
            return isSelected ? theme.palette.textPrimary : theme.palette.textSecondary
        case .underline:
            return isSelected ? (accent ?? theme.ink) : theme.palette.textSecondary
        }
    }
}

// MARK: - Indicator Geometry

private struct DSSegmentIndicatorGeometry: ViewModifier {
    let namespace: Namespace.ID
    let slides: Bool

    func body(content: Content) -> some View {
        if slides {
            content.matchedGeometryEffect(id: "indicator", in: namespace)
        } else {
            content
        }
    }
}

// MARK: - Logic

/// The control's rules, kept pure so `DSSegmentedControlTests` can pin them
/// without rendering.
enum DSSegmentedControlLogic {
    /// Indices of the first segment for each value, in order. Later segments
    /// that repeat a value are dropped so every `ForEach` ID is unique.
    static func uniqueIndices<V: Hashable>(of values: [V]) -> [Int] {
        var seen = Set<V>()
        return values.indices.filter { seen.insert(values[$0]).inserted }
    }

    /// A tap commits (and fires the haptic) only when it picks a different value.
    static func shouldSelect<V: Hashable>(_ tapped: V, current: V) -> Bool {
        tapped != current
    }

    /// The segment's position, read after its label and traits: "2 of 3",
    /// like the system segmented control.
    static func accessibilityValue(index: Int, count: Int) -> String {
        "\(index + 1) of \(count)"
    }

    /// The indicator slides between segments unless Reduce Motion is on.
    static func slidesIndicator(reduceMotion: Bool) -> Bool {
        !reduceMotion
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Build a segmented control directly from an array of string options.
    init(
        selection: Binding<String>,
        options: [String],
        style: DSSegmentedControlStyle = .pill,
        accent: Color? = nil,
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
                    accent: DSColors.secondary
                )
            }
            .padding(DSSpacing.xl)
        }
    }

    return PreviewWrapper()
        .background(DSColors.backgroundPrimary)
}
