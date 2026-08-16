import SwiftUI

// MARK: - Design System Slider
// A custom-drawn value slider with a spring-loaded thumb that grows under the
// finger, an accent-filled track, and tactile haptic "detents" as it crosses
// each step (plus a firm end-stop at the range bounds). Built entirely from a
// `GeometryReader` + `DragGesture` — never wraps the stock `Slider` — so it
// themes cleanly and feels alive. Ideal for volume, brightness, price ranges,
// filters, and any continuous or stepped value across any app.
//
// Inspiration: the common SwiftUI community pattern of computing the drag
// fraction from the view width, snapping to the nearest step, and firing a
// selection haptic on each detent crossing.
// - iOS Dev Notes — "SwiftUI Sliders: Complete Guide" (https://bluecityapps.com/posts/swiftui-sliders.html)
// - Rudrank Riyam — "Creating a Custom Slider Inspired By Camera Control" (https://rudrank.com/exploring-swiftui-creating-a-custom-slider-inspired-by-camera-control)

public struct DSSlider: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let accent: Color
    private let haptics: Bool

    @Environment(\.isEnabled) private var isEnabled
    @State private var isDragging = false

    // MARK: - Geometry (token-derived)

    /// Thickness of the track at rest.
    private let trackHeight = DSSpacing.xxs      // 4pt
    /// Diameter of the draggable thumb.
    private let thumbSize = DSSpacing.xl         // 24pt
    /// Overall touch/height region — leaves room for the thumb + focus ring.
    private let barHeight = DSSpacing.xxl        // 32pt

    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        accent: Color = DSColors.defaultPalette.primary,
        haptics: Bool = true
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.accent = accent
        self.haptics = haptics
    }

    public var body: some View {
        GeometryReader { geometry in
            track(width: geometry.size.width)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .gesture(dragGesture(width: geometry.size.width))
        }
        .frame(height: barHeight)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(DSAnimation.interactive, value: value)
        .accessibilityElement()
        .accessibilityLabel(Text("Slider"))
        .accessibilityValue(accessibilityValueText)
        .accessibilityAdjustableAction { direction in
            let delta = step ?? ((range.upperBound - range.lowerBound) / 10)
            switch direction {
            case .increment: commit(min(value + delta, range.upperBound))
            case .decrement: commit(max(value - delta, range.lowerBound))
            default: break
            }
        }
    }

    // MARK: - Track + Thumb

    private func track(width: CGFloat) -> some View {
        let usable = max(width - thumbSize, 1)
        let thumbX = usable * fraction

        return ZStack(alignment: .leading) {
            // Inactive track
            Capsule(style: .continuous)
                .fill(DSColors.defaultPalette.border)
                .frame(maxWidth: .infinity)
                .frame(height: trackHeight)

            // Active fill — reaches the thumb's center
            Capsule(style: .continuous)
                .fill(accent)
                .frame(width: thumbX + thumbSize / 2, height: trackHeight)

            thumb
                .offset(x: thumbX)
        }
        .frame(height: thumbSize)
    }

    private var thumb: some View {
        Circle()
            .fill(DSColors.defaultPalette.backgroundElevated)
            .frame(width: thumbSize, height: thumbSize)
            .overlay(
                Circle().strokeBorder(DSColors.defaultPalette.border, lineWidth: 1)
            )
            .dsShadow(.md)
            .overlay(
                // Focus ring that blooms while dragging
                Circle()
                    .strokeBorder(accent.opacity(0.25), lineWidth: DSSpacing.xxs)
                    .scaleEffect(isDragging ? 1.3 : 1.0)
                    .opacity(isDragging ? 1 : 0)
            )
            .scaleEffect(isDragging ? 1.12 : 1.0)
            .animation(DSAnimation.springSnappy, value: isDragging)
    }

    // MARK: - Gesture

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                guard isEnabled else { return }
                if !isDragging {
                    isDragging = true
                    if haptics { DSHapticEngine.shared.fire(.soft) }
                }
                updateValue(at: gesture.location.x, width: width)
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    // MARK: - Value Math

    /// Current value expressed as a clamped 0...1 fraction of the range.
    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        let f = (value - range.lowerBound) / span
        return CGFloat(min(max(f, 0), 1))
    }

    private func updateValue(at locationX: CGFloat, width: CGFloat) {
        let usable = max(width - thumbSize, 1)
        let clampedX = min(max(locationX - thumbSize / 2, 0), usable)
        let ratio = Double(clampedX / usable)
        let span = range.upperBound - range.lowerBound

        var newValue = range.lowerBound + ratio * span
        if let step, step > 0 {
            let steps = ((newValue - range.lowerBound) / step).rounded()
            newValue = range.lowerBound + steps * step
        }
        newValue = min(max(newValue, range.lowerBound), range.upperBound)
        commit(newValue)
    }

    private func commit(_ newValue: Double) {
        guard newValue != value else { return }
        if haptics {
            if newValue == range.lowerBound || newValue == range.upperBound {
                DSHapticEngine.shared.fire(.rigid)   // firm end-stop
            } else if step != nil {
                DSHapticEngine.shared.fire(.selection) // detent tick
            }
        }
        value = newValue
    }

    // MARK: - Accessibility

    private var accessibilityValueText: Text {
        if range == 0...1 && step == nil {
            return Text("\(Int((fraction * 100).rounded()))%")
        }
        return Text(value, format: .number.precision(.fractionLength(0...2)))
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
    @State private var quality: Double = 3
    @State private var price: Double = 40
    @State private var locked: Double = 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            HStack(spacing: DSSpacing.md) {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(DSColors.defaultPalette.textSecondary)
                DSSlider(value: $volume)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(DSColors.defaultPalette.textSecondary)
            }

            HStack(spacing: DSSpacing.md) {
                Image(systemName: "sun.min")
                    .foregroundStyle(DSColors.defaultPalette.textSecondary)
                DSSlider(value: $brightness, accent: DSColors.defaultPalette.warning)
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(DSColors.defaultPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Quality — step 1").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $quality, in: 0...5, step: 1, accent: DSColors.defaultPalette.secondary)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Max price — $\(Int(price))")
                    .ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $price, in: 0...100, step: 5, accent: DSColors.defaultPalette.tertiary)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Disabled").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $locked)
                    .disabled(true)
            }
        }
    }
}
