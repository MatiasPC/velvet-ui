import SwiftUI

// MARK: - Design System Slider
// A themeable value slider with a spring-loaded knob, a filled accent track,
// and optional detent snapping with tactile tick feedback. SwiftUI's stock
// `Slider` can't be restyled — this is the on-brand, haptic alternative for
// settings, filters, editors, and media scrubbing across any app.
//
// Tap anywhere on the track to jump; drag the knob to fine-tune. When a `step`
// is provided the value snaps to detents and a selection tick fires each time
// a new detent is crossed (diffed against the committed value so it never spams
// while over-dragging a bound).
//
// Inspiration: Apple's Camera Control slider feel + Rudrank Riyam —
// "Creating a Custom Slider Inspired By Camera Control"
// (https://rudrank.com/exploring-swiftui-creating-a-custom-slider-inspired-by-camera-control)

// MARK: - Size

public enum DSSliderSize {
    /// 4pt track, 22pt knob — compact rows, inline controls
    case small
    /// 6pt track, 28pt knob — default
    case medium

    var trackHeight: CGFloat {
        switch self {
        case .small:  return 4
        case .medium: return 6
        }
    }

    var knobSize: CGFloat {
        switch self {
        case .small:  return 22
        case .medium: return 28
        }
    }
}

// MARK: - Slider

public struct DSSlider: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let size: DSSliderSize
    private let tint: Color
    private let showsTicks: Bool
    private let haptics: Bool

    @State private var isDragging = false
    @Environment(\.isEnabled) private var isEnabled

    /// - Parameters:
    ///   - value: The bound value the slider reads and writes.
    ///   - range: The inclusive range of representable values. Defaults to `0...1`.
    ///   - step: Optional detent size. When set, the value snaps to multiples of
    ///     `step` (aligned to the lower bound) and each crossed detent fires a
    ///     selection haptic. `nil` (default) makes the slider continuous.
    ///   - size: Track/knob footprint. Defaults to `.medium`.
    ///   - tint: Accent color of the filled portion. Defaults to the palette primary.
    ///   - showsTicks: Draw subtle detent marks behind the track. Only applies
    ///     when `step` is set. Defaults to `false`.
    ///   - haptics: Whether to emit tactile feedback. Defaults to `true`.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        size: DSSliderSize = .medium,
        tint: Color = DSColors.defaultPalette.primary,
        showsTicks: Bool = false,
        haptics: Bool = true
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.size = size
        self.tint = tint
        self.showsTicks = showsTicks
        self.haptics = haptics
    }

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let knobX = knobCenterX(width: width)

            ZStack(alignment: .leading) {
                // Inactive track
                Capsule()
                    .fill(DSColors.defaultPalette.border)
                    .frame(height: size.trackHeight)

                // Detent marks (covered by the fill as the value passes them)
                if showsTicks, let step, step > 0 {
                    tickMarks(width: width, step: step)
                }

                // Active (filled) track
                Capsule()
                    .fill(isEnabled ? tint : DSColors.defaultPalette.textTertiary)
                    .frame(width: max(knobX, size.trackHeight), height: size.trackHeight)

                // Knob
                Circle()
                    .fill(DSColors.defaultPalette.textOnPrimary)
                    .frame(width: size.knobSize, height: size.knobSize)
                    .dsShadow(isDragging ? .md : .sm)
                    .scaleEffect(isDragging ? 1.12 : 1)
                    .position(x: knobX, y: geo.size.height / 2)
                    .animation(DSAnimation.springSnappy, value: isDragging)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(drag(width: width))
        }
        .frame(height: size.knobSize)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int((fraction * 100).rounded())) percent"))
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

    // MARK: - Geometry

    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    /// X position of the knob's center for a given track width.
    private func knobCenterX(width: CGFloat) -> CGFloat {
        let usable = width - size.knobSize
        return size.knobSize / 2 + CGFloat(fraction) * max(usable, 0)
    }

    /// Convert a touch X coordinate into a (possibly stepped) value.
    private func resolvedValue(atX x: CGFloat, width: CGFloat) -> Double {
        let usable = width - size.knobSize
        guard usable > 0 else { return range.lowerBound }
        let clampedX = min(max(x - size.knobSize / 2, 0), usable)
        let f = Double(clampedX / usable)
        var raw = range.lowerBound + f * (range.upperBound - range.lowerBound)
        if let step, step > 0 {
            let steps = ((raw - range.lowerBound) / step).rounded()
            raw = range.lowerBound + steps * step
        }
        return min(max(raw, range.lowerBound), range.upperBound)
    }

    // MARK: - Detent marks

    @ViewBuilder
    private func tickMarks(width: CGFloat, step: Double) -> some View {
        let span = range.upperBound - range.lowerBound
        let count = span > 0 ? Int((span / step).rounded()) : 0
        if count > 1 && count <= 50 {
            let usable = width - size.knobSize
            ForEach(0...count, id: \.self) { index in
                Circle()
                    .fill(DSColors.defaultPalette.divider)
                    .frame(width: DSSpacing.xxxs, height: DSSpacing.xxxs)
                    .offset(
                        x: size.knobSize / 2
                            + CGFloat(index) / CGFloat(count) * usable
                            - DSSpacing.xxxs / 2
                    )
            }
        }
    }

    // MARK: - Interaction

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !isDragging {
                    isDragging = true
                    if haptics { DSHapticEngine.shared.fire(.soft) }
                }
                commit(resolvedValue(atX: gesture.location.x, width: width))
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    /// Apply a new value and emit the appropriate haptic — but only when the
    /// committed value actually changes, so over-dragging a bound (which keeps
    /// resolving to the same clamped value) never re-fires.
    private func commit(_ newValue: Double) {
        guard newValue != value else { return }
        value = newValue

        guard haptics else { return }
        if newValue == range.lowerBound || newValue == range.upperBound {
            DSHapticEngine.shared.fire(.rigid)
        } else if step != nil {
            DSHapticEngine.shared.fire(.selection)
        }
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
    @State private var brightness: Double = 40
    @State private var balance: Double = 0
    @State private var compact: Double = 0.3

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Volume").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $volume)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Brightness — \(Int(brightness))%")
                    .ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $brightness, in: 0...100, step: 10, showsTicks: true)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Balance").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $balance, in: -1...1, tint: DSColors.defaultPalette.secondary)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Compact + disabled")
                    .ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $compact, size: .small, tint: DSColors.defaultPalette.success)
                DSSlider(value: .constant(0.5), size: .small)
                    .disabled(true)
            }
        }
    }
}
