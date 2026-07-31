import SwiftUI

// MARK: - Design System Slider
// A tactile, Control-Center-style slider. The whole bar swells when you grab it
// and settles back on release, the fill tracks your finger 1:1, and value
// changes tick through the haptic engine. A themeable, delightful replacement
// for the stock `Slider` — perfect for volume, brightness, filters, and prices.

public struct DSSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    let tint: Color
    let trackColor: Color
    let restHeight: CGFloat
    let expandedHeight: CGFloat
    let haptics: Bool

    @State private var isDragging = false
    @State private var lastHapticValue: Double
    @Environment(\.isEnabled) private var isEnabled

    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        tint: Color = DSColors.defaultPalette.primary,
        trackColor: Color = DSColors.defaultPalette.border,
        restHeight: CGFloat = 8,
        expandedHeight: CGFloat = 16,
        haptics: Bool = true
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.tint = tint
        self.trackColor = trackColor
        self.restHeight = restHeight
        self.expandedHeight = expandedHeight
        self.haptics = haptics
        self._lastHapticValue = State(initialValue: value.wrappedValue)
    }

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let barHeight = isDragging ? expandedHeight : restHeight

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)
                    .frame(height: barHeight)

                Capsule()
                    .fill(tint)
                    .frame(width: fillWidth(for: width), height: barHeight)
            }
            .frame(width: width, height: expandedHeight, alignment: .center)
            .contentShape(Rectangle())
            .gesture(drag(width: width))
        }
        .frame(height: expandedHeight)
        .animation(DSAnimation.springSnappy, value: isDragging)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement()
        .accessibilityValue(Text(accessibilityText))
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            adjust(direction)
        }
    }

    // MARK: - Geometry

    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    private func fillWidth(for width: CGFloat) -> CGFloat {
        max(0, width * CGFloat(fraction))
    }

    private func snap(_ raw: Double) -> Double {
        let clamped = min(max(raw, range.lowerBound), range.upperBound)
        guard let step, step > 0 else { return clamped }
        let steps = ((clamped - range.lowerBound) / step).rounded()
        let snapped = range.lowerBound + steps * step
        return min(max(snapped, range.lowerBound), range.upperBound)
    }

    // MARK: - Interaction

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                guard isEnabled, width > 0 else { return }
                if !isDragging {
                    isDragging = true
                    if haptics { DSHapticEngine.shared.fire(.soft) }
                }
                let position = min(max(gesture.location.x / width, 0), 1)
                let raw = range.lowerBound + Double(position) * (range.upperBound - range.lowerBound)
                let newValue = snap(raw)
                if newValue != value {
                    value = newValue
                    emitHaptic(for: newValue)
                }
            }
            .onEnded { _ in
                guard isEnabled else { return }
                isDragging = false
                if haptics { DSHapticEngine.shared.fire(.rigid) }
            }
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        let delta = step ?? (range.upperBound - range.lowerBound) / 10
        let target: Double
        switch direction {
        case .increment: target = value + delta
        case .decrement: target = value - delta
        @unknown default: return
        }
        let newValue = snap(target)
        guard newValue != value else { return }
        value = newValue
        emitHaptic(for: newValue)
    }

    // MARK: - Haptics

    /// Fired only when the value actually changes, so ticks map to real motion.
    private func emitHaptic(for newValue: Double) {
        guard haptics else { return }
        defer { lastHapticValue = newValue }

        if newValue <= range.lowerBound || newValue >= range.upperBound {
            DSHapticEngine.shared.fire(.rigid)
        } else if step != nil {
            DSHapticEngine.shared.fire(.selection)
        } else {
            // Continuous: quantize into evenly-spaced ticks so we don't spam.
            let ticks = 20.0
            let span = max(range.upperBound - range.lowerBound, .leastNonzeroMagnitude)
            let previous = ((lastHapticValue - range.lowerBound) / span * ticks).rounded(.down)
            let current = ((newValue - range.lowerBound) / span * ticks).rounded(.down)
            if previous != current {
                DSHapticEngine.shared.fire(.light, intensity: 0.5)
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityText: String {
        if let step, step >= 1 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}

// MARK: - Preview

#Preview("Light") {
    SliderPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    SliderPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct SliderPreview: View {
    @State private var volume: Double = 0.6
    @State private var brightness: Double = 0.35
    @State private var quantity: Double = 3
    @State private var locked: Double = 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Volume").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $volume)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Brightness").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $brightness, tint: DSColors.defaultPalette.warning)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Quantity — \(Int(quantity))")
                    .ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $quantity, in: 0...10, step: 1,
                         tint: DSColors.defaultPalette.secondary)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Disabled").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $locked)
                    .disabled(true)
            }
        }
    }
}
