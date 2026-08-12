import SwiftUI

// MARK: - Design System Slider
// A themeable, tactile replacement for the stock `Slider`. The thumb grows
// when grabbed, the fill tracks the accent color, and a value bubble floats
// above the thumb while scrubbing. Haptics fire only on meaningful moments —
// each step for a discrete slider, or the ends of the range — so continuous
// dragging never turns into a haptic buzz.

public struct DSSlider: View {

    // MARK: - Configuration

    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    let tint: Color
    let trackColor: Color
    let showsValueLabel: Bool
    let valueFormat: (Double) -> String
    let onEditingChanged: (Bool) -> Void

    @State private var isDragging = false
    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Dimensions (component-local)

    /// Diameter of the draggable thumb
    private let thumbSize: CGFloat = 28
    /// Height of the track + fill capsules
    private let trackHeight: CGFloat = 6
    /// How much the thumb grows while being dragged
    private let grabScale: CGFloat = 1.15

    // MARK: - Init

    /// Creates a themeable slider.
    /// - Parameters:
    ///   - value: The bound value to drive.
    ///   - range: The inclusive range the value moves within. Defaults to `0...1`.
    ///   - step: Optional snap increment. When set, the thumb snaps to each step
    ///           and ticks with a selection haptic. `nil` slides continuously.
    ///   - tint: Fill + thumb accent color. Defaults to the palette primary.
    ///   - trackColor: The unfilled track color. Defaults to the palette border.
    ///   - showsValueLabel: Show a floating value bubble above the thumb while dragging.
    ///   - valueFormat: Formats the value shown in the bubble. Defaults to a whole number.
    ///   - onEditingChanged: Called with `true` when dragging begins, `false` when it ends.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        tint: Color = DSColors.defaultPalette.primary,
        trackColor: Color = DSColors.defaultPalette.border,
        showsValueLabel: Bool = false,
        valueFormat: @escaping (Double) -> String = { String(format: "%.0f", $0) },
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.tint = tint
        self.trackColor = trackColor
        self.showsValueLabel = showsValueLabel
        self.valueFormat = valueFormat
        self.onEditingChanged = onEditingChanged
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let travel = max(width - thumbSize, 1)
            let offsetX = fraction * travel

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(trackColor)
                    .frame(height: trackHeight)

                // Fill (extends to the thumb center)
                Capsule()
                    .fill(tint)
                    .frame(width: offsetX + thumbSize / 2, height: trackHeight)

                // Thumb
                thumb
                    .offset(x: offsetX)
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { handleDrag(locationX: $0.location.x, width: width) }
                    .onEnded { _ in endDrag() }
            )
            .animation(DSAnimation.interactive, value: value)
        }
        .frame(height: thumbSize)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement()
        .accessibilityValue(Text(valueFormat(value)))
        .accessibilityAdjustableAction { direction in
            adjust(direction)
        }
    }

    // MARK: - Thumb + Value Bubble

    private var thumb: some View {
        Circle()
            .fill(DSColors.defaultPalette.backgroundElevated)
            .overlay(
                Circle().stroke(trackColor, lineWidth: 1)
            )
            .frame(width: thumbSize, height: thumbSize)
            .dsShadow(.sm)
            .scaleEffect(isDragging ? grabScale : 1.0)
            .overlay(alignment: .top) {
                if showsValueLabel && isDragging {
                    valueBubble
                        .offset(y: -(thumbSize / 2 + DSSpacing.sm))
                        .transition(.dsScale)
                }
            }
            .animation(DSAnimation.springSnappy, value: isDragging)
    }

    private var valueBubble: some View {
        Text(valueFormat(value))
            .ds(.buttonSmall, color: DSColors.defaultPalette.textOnPrimary)
            .fixedSize()
            .padding(.horizontal, DSSpacing.xs)
            .padding(.vertical, DSSpacing.xxs)
            .background(tint, in: Capsule())
            .dsShadow(.md)
    }

    // MARK: - Geometry

    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    // MARK: - Interaction

    private func handleDrag(locationX: CGFloat, width: CGFloat) {
        guard isEnabled else { return }

        if !isDragging {
            isDragging = true
            onEditingChanged(true)
            DSHapticEngine.shared.fire(.light)
        }

        let travel = max(width - thumbSize, 1)
        let rawFraction = (locationX - thumbSize / 2) / travel
        let clamped = min(max(Double(rawFraction), 0), 1)

        var newValue = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
        if let step {
            newValue = (newValue / step).rounded() * step
        }
        newValue = min(max(newValue, range.lowerBound), range.upperBound)

        guard newValue != value else { return }

        // Haptics: a tick at each step, a firmer bump at either end,
        // and nothing at all mid-slide for a continuous range.
        let atBound = newValue == range.lowerBound || newValue == range.upperBound
        if atBound {
            DSHapticEngine.shared.fire(.rigid)
        } else if step != nil {
            DSHapticEngine.shared.fire(.selection)
        }

        value = newValue
    }

    private func endDrag() {
        guard isDragging else { return }
        isDragging = false
        onEditingChanged(false)
    }

    /// VoiceOver increment / decrement.
    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        let delta = step ?? (range.upperBound - range.lowerBound) / 10
        let newValue: Double
        switch direction {
        case .increment: newValue = value + delta
        case .decrement: newValue = value - delta
        @unknown default: return
        }
        value = min(max(newValue, range.lowerBound), range.upperBound)
        DSHapticEngine.shared.fire(.selection)
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
    @State private var rooms: Double = 2
    @State private var price: Double = 120

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Volume").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $volume, showsValueLabel: true) { _ in }
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Brightness").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $brightness, tint: DSColors.defaultPalette.secondary)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Bedrooms").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(
                    value: $rooms,
                    in: 0...5,
                    step: 1,
                    tint: DSColors.defaultPalette.tertiary,
                    showsValueLabel: true
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Max price").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(
                    value: $price,
                    in: 0...500,
                    step: 10,
                    showsValueLabel: true,
                    valueFormat: { "$\(Int($0))" }
                )
            }

            DSSlider(value: .constant(0.4))
                .disabled(true)
        }
    }
}
