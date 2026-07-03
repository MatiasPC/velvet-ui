import SwiftUI

// MARK: - Design System Segmented Control
// A polished, animated segmented picker with a selection pill that
// smoothly slides between options using matchedGeometryEffect.
// Perfect for switching between views, filters, or modes.
// Inspired by the classic iOS segmented control, elevated with
// spring physics and a satisfying selection tick.

public enum DSSegmentedControlStyle {
    /// Elevated white pill on a subtle track, selected label picks up the tint color.
    /// Neutral, iOS-native feel — great for content filters.
    case subtle
    /// Tint-filled pill with contrasting label — bolder, more expressive.
    case filled
}

public struct DSSegmentedControl<Value: Hashable>: View {
    private let segments: [Value]
    @Binding private var selection: Value
    private let title: (Value) -> String
    private let tint: Color
    private let style: DSSegmentedControlStyle
    private let haptic: DSHapticStyle

    @Namespace private var namespace

    public init(
        segments: [Value],
        selection: Binding<Value>,
        tint: Color = DSColors.defaultPalette.primary,
        style: DSSegmentedControlStyle = .subtle,
        haptic: DSHapticStyle = .selection,
        title: @escaping (Value) -> String
    ) {
        self.segments = segments
        self._selection = selection
        self.tint = tint
        self.style = style
        self.haptic = haptic
        self.title = title
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxxs) {
            ForEach(segments, id: \.self) { segment in
                segmentLabel(for: segment)
            }
        }
        .padding(DSSpacing.xxs)
        .background(
            Capsule(style: .continuous)
                .fill(DSColors.defaultPalette.backgroundSecondary)
        )
    }

    // MARK: - Segment

    @ViewBuilder
    private func segmentLabel(for segment: Value) -> some View {
        let isSelected = segment == selection

        Text(title(segment))
            .ds(.buttonSmall, color: labelColor(isSelected: isSelected))
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background {
                if isSelected {
                    pill
                        .matchedGeometryEffect(id: Self.pillID, in: namespace)
                }
            }
            .contentShape(Capsule(style: .continuous))
            .onTapGesture { select(segment) }
    }

    private var pill: some View {
        Capsule(style: .continuous)
            .fill(pillColor)
            .dsShadow(style == .subtle ? .sm : .none)
    }

    // MARK: - Selection

    private func select(_ segment: Value) {
        guard segment != selection else { return }
        DSHapticEngine.shared.fire(haptic)
        withAnimation(DSAnimation.springSnappy) {
            selection = segment
        }
    }

    // MARK: - Colors

    private var pillColor: Color {
        switch style {
        case .subtle: return DSColors.defaultPalette.backgroundElevated
        case .filled: return tint
        }
    }

    private func labelColor(isSelected: Bool) -> Color {
        guard isSelected else { return DSColors.defaultPalette.textSecondary }
        switch style {
        case .subtle: return tint
        case .filled: return DSColors.defaultPalette.textOnPrimary
        }
    }

    private static var pillID: String { "ds.segmented.selection" }
}

// MARK: - Convenience for String Segments

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for plain string segments, where each
    /// segment's title is the string itself.
    init(
        segments: [String],
        selection: Binding<String>,
        tint: Color = DSColors.defaultPalette.primary,
        style: DSSegmentedControlStyle = .subtle,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            segments: segments,
            selection: selection,
            tint: tint,
            style: style,
            haptic: haptic,
            title: { $0 }
        )
    }
}

// MARK: - Preview

#Preview("Segmented Control") {
    struct PreviewHost: View {
        @State private var view = "List"
        @State private var range = "Week"
        @State private var mode = "Focus"

        var body: some View {
            VStack(spacing: DSSpacing.xxl) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("SUBTLE").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSegmentedControl(
                        segments: ["List", "Grid", "Map"],
                        selection: $view
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("FILLED").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSegmentedControl(
                        segments: ["Day", "Week", "Month"],
                        selection: $range,
                        style: .filled
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("CUSTOM TINT").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSegmentedControl(
                        segments: ["Focus", "Relax", "Sleep"],
                        selection: $mode,
                        tint: DSColors.defaultPalette.tertiary,
                        style: .filled
                    )
                }
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return PreviewHost()
}

#Preview("Segmented Control — Dark") {
    struct PreviewHost: View {
        @State private var range = "Week"

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                DSSegmentedControl(
                    segments: ["Day", "Week", "Month"],
                    selection: $range
                )
                DSSegmentedControl(
                    segments: ["Day", "Week", "Month"],
                    selection: $range,
                    style: .filled
                )
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return PreviewHost().preferredColorScheme(.dark)
}
