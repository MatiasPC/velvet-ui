import SwiftUI

// MARK: - Design System Segmented Control
// A generic, animated segmented control with a sliding "pill" indicator.
// The selected highlight glides between options using `matchedGeometryEffect`,
// giving the satisfying, premium feel of a hand-tuned iOS control.
// Perfect for view switchers, filters, and time-range pickers.

// MARK: - Segment Model

/// A single option in a `DSSegmentedControl`.
/// `value` is what the binding reports; `title`/`icon` are what the user sees.
public struct DSSegment<Value: Hashable>: Identifiable {
    public let value: Value
    public let title: String
    public let icon: String?

    public var id: Value { value }

    public init(_ title: String, value: Value, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
}

// MARK: - Segmented Control

public struct DSSegmentedControl<Value: Hashable>: View {
    private let segments: [DSSegment<Value>]
    @Binding private var selection: Value
    private let haptic: DSHapticStyle

    @Namespace private var namespace

    /// Stable identifier for the sliding highlight so it animates between segments.
    private let pillID = "DSSegmentedControl.pill"

    public init(
        segments: [DSSegment<Value>],
        selection: Binding<Value>,
        haptic: DSHapticStyle = .selection
    ) {
        self.segments = segments
        self._selection = selection
        self.haptic = haptic
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxs) {
            ForEach(segments) { segment in
                segmentButton(segment)
            }
        }
        .padding(DSSpacing.xxs)
        .background(DSColors.defaultPalette.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
    }

    // MARK: - Segment Button

    @ViewBuilder
    private func segmentButton(_ segment: DSSegment<Value>) -> some View {
        let isSelected = segment.value == selection

        Button {
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(haptic)
            withAnimation(DSAnimation.springSnappy) {
                selection = segment.value
            }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon = segment.icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(segment.title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(
                isSelected
                    ? DSColors.defaultPalette.textPrimary
                    : DSColors.defaultPalette.textSecondary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: pillID, in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Build a control directly from titles when each title is also its value.
    init(
        _ titles: [String],
        selection: Binding<String>,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            segments: titles.map { DSSegment($0, value: $0) },
            selection: selection,
            haptic: haptic
        )
    }
}

// MARK: - Preview

private struct DSSegmentedControlPreview: View {
    @State private var viewMode = "Grid"
    @State private var period = "Day"
    @State private var tab = 0

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Text-only, value == title
            DSSegmentedControl(["Grid", "List", "Map"], selection: $viewMode)

            // Many options
            DSSegmentedControl(
                segments: [
                    DSSegment("Day", value: "Day"),
                    DSSegment("Week", value: "Week"),
                    DSSegment("Month", value: "Month"),
                    DSSegment("Year", value: "Year")
                ],
                selection: $period
            )

            // Icons + custom value type (Int)
            DSSegmentedControl(
                segments: [
                    DSSegment("List", value: 0, icon: "list.bullet"),
                    DSSegment("Photos", value: 1, icon: "photo"),
                    DSSegment("Map", value: 2, icon: "map")
                ],
                selection: $tab
            )
        }
        .padding(DSSpacing.lg)
        .background(DSColors.defaultPalette.backgroundPrimary)
    }
}

#Preview("Light") {
    DSSegmentedControlPreview()
}

#Preview("Dark") {
    DSSegmentedControlPreview()
        .preferredColorScheme(.dark)
}
