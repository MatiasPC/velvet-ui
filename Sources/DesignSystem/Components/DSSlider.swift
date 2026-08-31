import SwiftUI

// MARK: - Design System Slider
// A tactile, fully themeable value slider — the premium alternative to the
// stock `Slider`, which can't be restyled. The thumb grows under the finger,
// an optional value bubble floats above while dragging, and haptics tick on
// every step crossing with a firmer bump when a bound is reached. Works for
// continuous ranges (volume, opacity) or discrete steps (quantity, ratings).

public struct DSSlider: View {

    // MARK: - Configuration

    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let tint: Color
    private let trackColor: Color
    private let thumbColor: Color
    private let trackHeight: CGFloat
    private let thumbSize: CGFloat
    private let showsValue: Bool
    private let haptics: Bool
    private let format: (Double) -> String

    // MARK: - State

    @State private var isDragging = false
    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Init

    /// A draggable slider bound to a value within `range`.
    /// - Parameters:
    ///   - value: The current value. Clamped to `range` for display.
    ///   - range: The inclusive value range. Defaults to `0...1`.
    ///   - step: Optional snap increment. `nil` (default) is continuous;
    ///     a positive value snaps to detents and ticks a selection haptic
    ///     on each crossing.
    ///   - tint: Fill color for the completed portion. Defaults to primary.
    ///   - trackColor: Color of the unfilled track. Defaults to the border color.
    ///   - thumbColor: Fill color of the thumb. Defaults to the elevated surface.
    ///   - trackHeight: Thickness of the track. Defaults to `6`.
    ///   - thumbSize: Diameter of the thumb at rest. Defaults to `28`.
    ///   - showsValue: Whether to float a value bubble above the thumb while
    ///     dragging. Defaults to `true`.
    ///   - haptics: Whether to fire tactile feedback. Defaults to `true`.
    ///   - format: Formats the value for the bubble and accessibility.
    ///     Defaults to a whole-number-or-one-decimal formatter.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        tint: Color = DSColors.defaultPalette.primary,
        trackColor: Color = DSColors.defaultPalette.border,
        thumbColor: Color = DSColors.defaultPalette.backgroundElevated,
        trackHeight: CGFloat = 6,
        thumbSize: CGFloat = 28,
        showsValue: Bool = true,
        haptics: Bool = true,
        format: @escaping (Double) -> String = DSSlider.defaultFormat
    ) {
        self._value = value
        self.range = range
        self.step = (step ?? 0) > 0 ? step : nil
        self.tint = tint
        self.trackColor = trackColor
        self.thumbColor = thumbColor
        self.trackHeight = trackHeight
        self.thumbSize = thumbSize
        self.showsValue = showsValue
        self.haptics = haptics
        self.format = format
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let centerX = thumbSize / 2 + CGFloat(fraction) * max(width - thumbSize, 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)
                    .frame(height: trackHeight)

                Capsule()
                    .fill(tint)
                    .frame(width: centerX, height: trackHeight)

                thumb
                    .offset(x: centerX - thumbSize / 2)
            }
            .frame(height: thumbSize)
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(drag(width: width), including: isEnabled ? .all : .subviews)
            // Animate programmatic value changes, but let drags track 1:1.
            .animation(isDragging ? nil : DSAnimation.springSmooth, value: fraction)
        }
        .frame(height: thumbSize)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement()
        .accessibilityLabel("Slider")
        .accessibilityValue(format(clamped(value)))
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            let delta = step ?? (span / 10)
            switch direction {
            case .increment: commit(clamped(value + delta))
            case .decrement: commit(clamped(value - delta))
            @unknown default: break
            }
        }
    }

    // MARK: - Thumb

    private var thumb: some View {
        Circle()
            .fill(thumbColor)
            .frame(width: thumbSize, height: thumbSize)
            .overlay(Circle().stroke(DSColors.defaultPalette.border, lineWidth: 1))
            .dsShadow(.sm)
            .scaleEffect(isDragging ? 1.18 : 1.0)
            .overlay(alignment: .bottom) {
                if showsValue && isDragging {
                    valueBubble
                        .fixedSize()
                        .offset(y: -(thumbSize + DSSpacing.xs))
                        .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
                }
            }
            .animation(DSAnimation.springSnappy, value: isDragging)
    }

    private var valueBubble: some View {
        Text(format(clamped(value)))
            .ds(.buttonSmall, color: DSColors.defaultPalette.textOnPrimary)
            .padding(.horizontal, DSSpacing.xs)
            .padding(.vertical, DSSpacing.xxs)
            .background(tint, in: Capsule())
            .dsShadow(.sm)
    }

    // MARK: - Gesture

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !isDragging {
                    withAnimation(DSAnimation.springSnappy) { isDragging = true }
                    if haptics { DSHapticEngine.shared.fire(.soft) }
                }
                let newValue = valueAt(x: gesture.location.x, width: width)
                guard newValue != value else { return }
                if haptics { fireHaptic(from: value, to: newValue) }
                value = newValue
            }
            .onEnded { _ in
                if haptics { DSHapticEngine.shared.fire(.light) }
                withAnimation(DSAnimation.springSnappy) { isDragging = false }
            }
    }

    // MARK: - Value Math

    private var span: Double {
        max(range.upperBound - range.lowerBound, .ulpOfOne)
    }

    /// The completed portion of the track, in `0...1`.
    private var fraction: Double {
        min(max((clamped(value) - range.lowerBound) / span, 0), 1)
    }

    private func clamped(_ v: Double) -> Double {
        min(max(v, range.lowerBound), range.upperBound)
    }

    /// Map a horizontal touch position to a snapped value, keeping the thumb
    /// fully inside the track at both ends.
    private func valueAt(x: CGFloat, width: CGFloat) -> Double {
        let usable = max(width - thumbSize, 1)
        let clampedX = min(max(x - thumbSize / 2, 0), usable)
        let raw = range.lowerBound + Double(clampedX / usable) * span
        return snapped(raw)
    }

    private func snapped(_ raw: Double) -> Double {
        guard let step else { return clamped(raw) }
        let steps = ((raw - range.lowerBound) / step).rounded()
        return clamped(range.lowerBound + steps * step)
    }

    private func commit(_ newValue: Double) {
        guard newValue != value else { return }
        if haptics { fireHaptic(from: value, to: newValue) }
        withAnimation(DSAnimation.springSmooth) { value = newValue }
    }

    /// A firm bump when a bound is hit, otherwise a selection tick per step.
    private func fireHaptic(from old: Double, to new: Double) {
        if new == range.lowerBound && old != range.lowerBound {
            DSHapticEngine.shared.fire(.rigid); return
        }
        if new == range.upperBound && old != range.upperBound {
            DSHapticEngine.shared.fire(.rigid); return
        }
        guard let step else { return }
        let oldIndex = ((old - range.lowerBound) / step).rounded()
        let newIndex = ((new - range.lowerBound) / step).rounded()
        if oldIndex != newIndex { DSHapticEngine.shared.fire(.selection) }
    }

    // MARK: - Default Formatter

    /// Shows whole numbers without decimals, everything else to one decimal.
    public static func defaultFormat(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

// MARK: - Preview

#Preview("Light") {
    SliderPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    SliderPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct SliderPreview: View {
    @State private var volume: Double = 0.6
    @State private var brightness: Double = 0.35
    @State private var quantity: Double = 3
    @State private var temperature: Double = 21

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xxl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Continuous").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $volume, format: { "\(Int($0 * 100))%" })
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Custom tint").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $brightness, tint: DSColors.defaultPalette.secondary,
                         format: { "\(Int($0 * 100))%" })
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Stepped 1…5").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $quantity, in: 1...5, step: 1)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Range 16…30 · disabled").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $temperature, in: 16...30, step: 0.5,
                         tint: DSColors.defaultPalette.tertiary, format: { String(format: "%.1f°", $0) })
                    .disabled(true)
            }
        }
    }
}
