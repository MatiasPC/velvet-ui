import SwiftUI

// MARK: - Design System Slider
// A themeable, tactile replacement for the stock `Slider`. The thumb springs
// under the finger and scales up while dragging, the track fills with the accent
// color, and — when a `step` is set — a selection haptic ticks on every notch the
// thumb snaps to. Tapping anywhere on the track jumps the value to that point.
// Every app needs a value control; this is the on-brand, delightful one.

public struct DSSlider: View {

    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    let tint: Color
    let showsValueLabel: Bool
    let valueFormat: (Double) -> String

    @Environment(\.isEnabled) private var isEnabled
    @State private var isDragging = false

    // MARK: - Geometry
    // Component-intrinsic dimensions, mirroring DSToggle's fixed-footprint style.

    /// Height of the track rail
    private let trackHeight: CGFloat = 6
    /// Diameter of the draggable thumb
    private let thumbSize: CGFloat = 28

    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        tint: Color = DSColors.defaultPalette.primary,
        showsValueLabel: Bool = false,
        valueFormat: @escaping (Double) -> String = { String(format: "%.0f", $0) }
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.tint = tint
        self.showsValueLabel = showsValueLabel
        self.valueFormat = valueFormat
    }

    public var body: some View {
        VStack(spacing: DSSpacing.xs) {
            if showsValueLabel {
                Text(valueFormat(value))
                    .ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            track
        }
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(Text(valueFormat(value)))
        .accessibilityAdjustableAction { direction in
            let delta = step ?? (range.upperBound - range.lowerBound) / 10
            switch direction {
            case .increment: value = applyStep(value + delta)
            case .decrement: value = applyStep(value - delta)
            @unknown default: break
            }
        }
    }

    // MARK: - Track + Thumb

    private var track: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let usable = max(width - thumbSize, 1)
            let thumbX = thumbSize / 2 + normalized(value) * usable

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DSColors.defaultPalette.border)
                    .frame(height: trackHeight)

                Capsule()
                    .fill(tint)
                    .frame(width: thumbX, height: trackHeight)

                Circle()
                    .fill(DSColors.defaultPalette.backgroundElevated)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle().strokeBorder(tint, lineWidth: isDragging ? 2 : 1)
                    )
                    .dsShadow(isDragging ? .md : .sm)
                    .scaleEffect(isDragging ? 1.12 : 1)
                    .offset(x: thumbX - thumbSize / 2)
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width))
            .animation(DSAnimation.springSnappy, value: isDragging)
            // Track the finger instantly while dragging; spring to rest otherwise.
            .animation(isDragging ? nil : DSAnimation.springSnappy, value: value)
        }
        .frame(height: thumbSize)
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                guard isEnabled else { return }
                let starting = !isDragging
                if starting {
                    isDragging = true
                    DSHapticEngine.shared.fire(.light)
                }
                update(to: gesture.location.x, width: width, silent: starting)
            }
            .onEnded { _ in
                guard isEnabled else { return }
                isDragging = false
                DSHapticEngine.shared.fire(.rigid)
            }
    }

    // MARK: - Value Math

    private func update(to x: CGFloat, width: CGFloat, silent: Bool) {
        let usable = max(width - thumbSize, 1)
        let clampedX = min(max(x - thumbSize / 2, 0), usable)
        let fraction = Double(clampedX / usable)
        let raw = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
        let newValue = applyStep(raw)
        guard newValue != value else { return }
        // A stepped slider ticks each time it crosses into a new notch.
        if !silent, let step, step > 0 {
            DSHapticEngine.shared.fire(.selection)
        }
        value = newValue
    }

    private func normalized(_ v: Double) -> CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat(min(max((v - range.lowerBound) / span, 0), 1))
    }

    private func applyStep(_ v: Double) -> Double {
        let clamped = min(max(v, range.lowerBound), range.upperBound)
        guard let step, step > 0 else { return clamped }
        let notches = ((clamped - range.lowerBound) / step).rounded()
        let stepped = range.lowerBound + notches * step
        return min(max(stepped, range.lowerBound), range.upperBound)
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
    @State private var brightness: Double = 0.6
    @State private var volume: Double = 40
    @State private var rating: Double = 3
    @State private var disabled: Double = 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Brightness").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $brightness)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Volume").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(
                    value: $volume,
                    in: 0...100,
                    tint: DSColors.defaultPalette.secondary,
                    showsValueLabel: true
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Rating (stepped)").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(
                    value: $rating,
                    in: 0...5,
                    step: 1,
                    tint: DSColors.defaultPalette.success,
                    showsValueLabel: true
                )
            }

            DSSlider(value: $disabled)
                .disabled(true)
        }
    }
}
