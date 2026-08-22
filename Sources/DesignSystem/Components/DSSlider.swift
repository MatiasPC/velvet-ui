import SwiftUI

// MARK: - Design System Slider
// A themeable value slider with the tactility the stock `Slider` lacks:
// a thumb that springs up while dragging, haptic detents on every step, a
// distinct thump when you hit either end, and tap-to-seek anywhere on the
// track. Works continuously or in fixed steps, over any numeric range —
// perfect for volume, brightness, filters, and settings across any app.
//
// All pure SwiftUI, iOS 17+. Programmatic value changes spring into place;
// drags follow the finger 1:1.

public struct DSSlider: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let tint: Color

    @Environment(\.isEnabled) private var isEnabled
    @State private var isDragging = false

    // Component geometry (fixed dimensions, DS tokens drive everything themeable).
    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 28

    /// - Parameters:
    ///   - value: The bound value to read and write.
    ///   - range: The inclusive range the value is clamped to. Defaults to `0...1`.
    ///   - step: Optional snapping increment. `nil` (default) is continuous;
    ///           a positive value snaps and fires a selection haptic per detent.
    ///   - tint: The filled-track and detent color. Defaults to the primary accent.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        tint: Color = DSColors.defaultPalette.primary
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let usableWidth = max(width - thumbSize, 0)
            let thumbX = fraction(for: value) * usableWidth
            let filledWidth = thumbX + thumbSize / 2

            ZStack(alignment: .leading) {
                // Unfilled track
                Capsule(style: .continuous)
                    .fill(DSColors.defaultPalette.border)
                    .frame(height: trackHeight)

                // Filled track
                Capsule(style: .continuous)
                    .fill(tint)
                    .frame(width: filledWidth, height: trackHeight)

                // Thumb
                Circle()
                    .fill(DSColors.defaultPalette.textOnPrimary)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle().strokeBorder(DSColors.defaultPalette.border, lineWidth: 0.5)
                    )
                    .dsShadow(isDragging ? .md : .sm)
                    .scaleEffect(isDragging ? 1.12 : 1)
                    .offset(x: thumbX)
            }
            .frame(height: thumbSize)
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .animation(isDragging ? nil : DSAnimation.springSmooth, value: value)
            .animation(DSAnimation.springSnappy, value: isDragging)
            .gesture(dragGesture(usableWidth: usableWidth))
        }
        .frame(height: thumbSize)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement()
        .accessibilityValue(Text(accessibilityValueText))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: nudge(up: true)
            case .decrement: nudge(up: false)
            @unknown default: break
            }
        }
    }

    // MARK: - Gesture

    private func dragGesture(usableWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                guard isEnabled else { return }
                if !isDragging { isDragging = true }
                guard usableWidth > 0 else { return }
                let location = gesture.location.x - thumbSize / 2
                updateValue(fraction: location / usableWidth)
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    // MARK: - Value math

    private func fraction(for value: Double) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    private func snap(_ raw: Double) -> Double {
        guard let step, step > 0 else {
            return min(max(raw, range.lowerBound), range.upperBound)
        }
        let steps = ((raw - range.lowerBound) / step).rounded()
        let snapped = range.lowerBound + steps * step
        return min(max(snapped, range.lowerBound), range.upperBound)
    }

    private func updateValue(fraction: Double) {
        let clamped = min(max(fraction, 0), 1)
        let raw = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
        let newValue = snap(raw)
        guard newValue != value else { return }

        let hitEnd = newValue == range.lowerBound || newValue == range.upperBound
        if step != nil {
            DSHapticEngine.shared.fire(hitEnd ? .rigid : .selection)
        } else if hitEnd {
            DSHapticEngine.shared.fire(.rigid)
        }
        value = newValue
    }

    /// Keyboard / VoiceOver adjustment. Moves one step, or 5% of the range when continuous.
    private func nudge(up: Bool) {
        let increment = step ?? ((range.upperBound - range.lowerBound) / 20)
        let candidate = value + (up ? increment : -increment)
        let newValue = snap(candidate)
        guard newValue != value else { return }
        DSHapticEngine.shared.fire(.selection)
        value = newValue
    }

    private var accessibilityValueText: String {
        if step != nil, step == step?.rounded(), value == value.rounded() {
            return String(Int(value))
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
    @State private var rooms: Double = 2
    @State private var price: Double = 120

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            labeled("Volume") {
                DSSlider(value: $volume)
            }
            labeled("Brightness") {
                DSSlider(value: $brightness, tint: DSColors.defaultPalette.warning)
            }
            labeled("Rooms (stepped 0–5)") {
                DSSlider(value: $rooms, in: 0...5, step: 1,
                         tint: DSColors.defaultPalette.secondary)
            }
            labeled("Price ($0–$500, $25 steps)") {
                DSSlider(value: $price, in: 0...500, step: 25,
                         tint: DSColors.defaultPalette.tertiary)
            }
            labeled("Disabled") {
                DSSlider(value: $volume)
                    .disabled(true)
            }
        }
    }

    @ViewBuilder
    private func labeled(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(title).ds(.footnote, color: DSColors.defaultPalette.textSecondary)
            content()
        }
    }
}
