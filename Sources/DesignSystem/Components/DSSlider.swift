import SwiftUI

// MARK: - Design System Slider
// A tactile, themeable slider for continuous or stepped input — volume,
// brightness, price ranges, filters. The stock `Slider` can't wear the Velvet
// gradient, so this one draws its own track: the fill is the active gradient
// theme (or a flat `tint`), the knob springs up while you drag, and detents
// tick under your thumb. Fills the gap left by `DSRating` (discrete) and
// `DSToggle` (boolean) — this is the one continuous control.

public enum DSSliderSize {
    /// 4pt track · 20pt knob — compact rows, dense forms
    case small
    /// 6pt track · 28pt knob — default
    case medium

    var trackHeight: CGFloat {
        switch self {
        case .small:  return 4
        case .medium: return 6
        }
    }

    var knobSize: CGFloat {
        switch self {
        case .small:  return 20
        case .medium: return 28
        }
    }
}

public struct DSSlider: View {

    // MARK: - Configuration

    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let size: DSSliderSize
    private let tint: Color?
    private let haptics: Bool

    // MARK: - State

    @State private var isDragging = false
    @Environment(\.isEnabled) private var isEnabled
    @DSThemed private var theme

    // MARK: - Init

    /// A continuous or stepped slider bound to a value the user drags to set.
    /// - Parameters:
    ///   - value: The current value, kept within `range`.
    ///   - range: The lower and upper bounds. Defaults to `0...1`.
    ///   - step: Snap increment. `nil` (default) is continuous; a value like
    ///     `1` or `0.1` snaps and ticks a selection haptic at each detent.
    ///   - size: Track/knob footprint. Defaults to `.medium`.
    ///   - tint: Flat fill color for the active track. Defaults to `nil`, which
    ///     uses the active gradient theme — the Velvet signature.
    ///   - haptics: Whether to fire tactile feedback while dragging. Defaults to `true`.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        size: DSSliderSize = .medium,
        tint: Color? = nil,
        haptics: Bool = true
    ) {
        self._value = value
        self.range = range
        self.step = step.map { $0 <= 0 ? 1 : $0 }
        self.size = size
        self.tint = tint
        self.haptics = haptics
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let knob = size.knobSize
            let usable = max(trackWidth - knob, 1)
            let fraction = normalizedFraction
            let knobOffset = fraction * usable          // knob leading edge
            let fillWidth = knob / 2 + knobOffset        // fill reaches the knob center

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.palette.border)
                    .frame(height: size.trackHeight)

                Capsule()
                    .fill(fillStyle)
                    .frame(width: fillWidth, height: size.trackHeight)

                Circle()
                    .fill(theme.palette.textOnPrimary)
                    .frame(width: knob, height: knob)
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .dsShadow(.sm)
                    .offset(x: knobOffset)
                    .animation(DSAnimation.springSnappy, value: isDragging)
            }
            .frame(width: trackWidth, height: knob)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: trackWidth), including: isEnabled ? .all : .none)
        }
        .frame(height: size.knobSize)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement()
        .accessibilityLabel("Slider")
        .accessibilityValue(accessibilityValueText)
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            let delta = step ?? (range.upperBound - range.lowerBound) / 10
            switch direction {
            case .increment: commit(min(value + delta, range.upperBound))
            case .decrement: commit(max(value - delta, range.lowerBound))
            @unknown default: break
            }
        }
    }

    // MARK: - Track Fill

    /// The active-track fill: a flat `tint` if given, else the gradient theme.
    private var fillStyle: AnyShapeStyle {
        if let tint {
            return AnyShapeStyle(tint)
        }
        return AnyShapeStyle(theme.gradient.horizontalGradient)
    }

    // MARK: - Gesture

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if !isDragging {
                    isDragging = true
                    if haptics { DSHapticEngine.shared.fire(.soft) }
                }
                update(atX: g.location.x, width: width)
            }
            .onEnded { g in
                update(atX: g.location.x, width: width)
                isDragging = false
                if haptics { DSHapticEngine.shared.fire(.light) }
            }
    }

    /// Map a horizontal touch position to a (optionally snapped) value and store it.
    private func update(atX x: CGFloat, width: CGFloat) {
        let usable = max(width - size.knobSize, 1)
        let raw = Double((x - size.knobSize / 2) / usable)
        let newValue = snappedValue(forFraction: min(max(raw, 0), 1))
        guard newValue != value else { return }
        fireHaptics(from: value, to: newValue)
        if step != nil {
            withAnimation(DSAnimation.springSnappy) { value = newValue }
        } else {
            value = newValue                            // track the finger exactly
        }
    }

    private func commit(_ newValue: Double) {
        guard newValue != value else { return }
        if haptics { DSHapticEngine.shared.fire(.selection) }
        withAnimation(DSAnimation.springSnappy) { value = newValue }
    }

    // MARK: - Derived Values

    private var normalizedFraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat(min(max((value - range.lowerBound) / span, 0), 1))
    }

    private func snappedValue(forFraction f: Double) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return range.lowerBound }
        let raw = range.lowerBound + f * span
        if let step {
            let steps = ((raw - range.lowerBound) / step).rounded()
            let snapped = range.lowerBound + steps * step
            return min(max(snapped, range.lowerBound), range.upperBound)
        }
        return min(max(raw, range.lowerBound), range.upperBound)
    }

    private func fireHaptics(from old: Double, to new: Double) {
        guard haptics else { return }
        if let step {
            let oldIndex = ((old - range.lowerBound) / step).rounded()
            let newIndex = ((new - range.lowerBound) / step).rounded()
            if oldIndex != newIndex { DSHapticEngine.shared.fire(.selection) }
        } else if (new == range.lowerBound && old != range.lowerBound) ||
                  (new == range.upperBound && old != range.upperBound) {
            DSHapticEngine.shared.fire(.rigid)   // firm tick at either end
        }
    }

    private var accessibilityValueText: String {
        "\(Int((normalizedFraction * 100).rounded()))%"
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSliderPreviewHost: View {
    @State private var theme = DSTheme()

    @State private var volume: Double = 0.6
    @State private var brightness: Double = 0.35
    @State private var quality: Double = 3
    @State private var price: Double = 0.5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        sliderRow("Volume", value: $volume) {
                            DSSlider(value: $volume)
                        }
                        sliderRow("Brightness", value: $brightness) {
                            DSSlider(value: $brightness, tint: DSColors.warning)
                        }
                        sliderRow("Quality (steps of 1, 0…5)", value: $quality) {
                            DSSlider(value: $quality, in: 0...5, step: 1)
                        }
                        sliderRow("Compact", value: $price) {
                            DSSlider(value: $price, size: .small)
                        }
                        sliderRow("Disabled", value: $volume) {
                            DSSlider(value: $volume).disabled(true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    @ViewBuilder
    private func sliderRow(
        _ label: String,
        value: Binding<Double>,
        @ViewBuilder slider: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack {
                Text(label).ds(.footnote)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(0...1)))
                    .ds(.numeric, color: DSColors.textSecondary)
            }
            slider()
        }
    }
}

#Preview("Slider — Light") {
    DSSliderPreviewHost().preferredColorScheme(.light)
}

#Preview("Slider — Dark") {
    DSSliderPreviewHost().preferredColorScheme(.dark)
}
#endif
