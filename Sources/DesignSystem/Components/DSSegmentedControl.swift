import SwiftUI

// MARK: - Design System Segmented Control
// A polished, generic segmented picker with a sliding selection pill.
// The pill glides between segments with a spring, backed by matchedGeometryEffect —
// the hallmark of a premium, tactile switch. Great for view toggles, filters,
// and small mode selections where a full Picker feels heavy.

// MARK: - Segment Model

/// A single option in a ``DSSegmentedControl``.
public struct DSSegment<Value: Hashable>: Identifiable {
    public var id: Value { value }
    public let value: Value
    public let title: String
    public let icon: String?

    public init(_ title: String, value: Value, icon: String? = nil) {
        self.value = value
        self.title = title
        self.icon = icon
    }
}

// MARK: - Segmented Control

public struct DSSegmentedControl<Value: Hashable>: View {
    @Binding private var selection: Value
    private let segments: [DSSegment<Value>]
    private let haptic: DSHapticStyle

    @Namespace private var pillNamespace

    public init(
        selection: Binding<Value>,
        segments: [DSSegment<Value>],
        haptic: DSHapticStyle = .selection
    ) {
        self._selection = selection
        self.segments = segments
        self.haptic = haptic
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xxxs) {
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
            guard segment.value != selection else { return }
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
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .padding(.horizontal, DSSpacing.xxs)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.defaultPalette.backgroundElevated)
                        .dsShadow(.sm)
                        .matchedGeometryEffect(id: "dsSegmentedPill", in: pillNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Convenience

public extension DSSegmentedControl where Value == String {
    /// Convenience initializer for the common case of plain string options.
    /// Each option string is used as both its label and its selection value.
    init(
        selection: Binding<String>,
        options: [String],
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            segments: options.map { DSSegment($0, value: $0) },
            haptic: haptic
        )
    }
}

// MARK: - Preview

#Preview("DSSegmentedControl") {
    struct PreviewHost: View {
        @State private var mode = "Overview"
        @State private var range = "Week"
        @State private var view = "list"

        var body: some View {
            VStack(spacing: DSSpacing.xxl) {
                // Plain string options
                DSSegmentedControl(
                    selection: $mode,
                    options: ["Overview", "Activity", "Settings"]
                )

                // Compact two-way toggle
                DSSegmentedControl(
                    selection: $range,
                    options: ["Day", "Week", "Month", "Year"]
                )

                // Icon + title segments
                DSSegmentedControl(
                    selection: $view,
                    segments: [
                        DSSegment("List", value: "list", icon: "list.bullet"),
                        DSSegment("Grid", value: "grid", icon: "square.grid.2x2"),
                        DSSegment("Map", value: "map", icon: "map")
                    ]
                )
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return PreviewHost()
}
