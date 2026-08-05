import SwiftUI

// MARK: - Design System Slider
// A themeable value slider with a springy, tactile feel. Drag the knob — or
// tap anywhere on the track — to set a value. The knob "pops" while dragging,
// stepped sliders fire a selection tick as they cross each detent, and an
// optional value bubble floats above the knob so the exact value is always
// legible. A polished, haptic-aware replacement for the stock `Slider` that
// works for any continuous or stepped range across any app.

public struct DSSlider: View {

    // MARK: - Configuration

    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let tint: Color
    private let trackColor: Color
    private let showsValue: Bool
    private let haptics: Bool

    // MARK: - State

    @State private var isDragging = false

    // MARK: - Dimensions

    private let knobSize: CGFloat = 28
    private let trackHeight: CGFloat = 6

    // MARK: - Init

    /// A slider bound to a value the user can drag or tap to set.
    /// - Parameters:
    ///   - value: The current value, kept within `range`.
    ///   - range: The inclusive value range. Defaults to `0...1`.
    ///   - step: Snap increment. Pass `nil` for a continuous slider (the
    ///     default) or a positive value (e.g. `5`) to snap to detents.
    ///   - tint: Fill color for the active track and knob accents. Defaults to
    ///     the primary accent.
    ///   - trackColor: Color of the inactive track. Defaults to the border color.
    ///   - showsValue: Whether to float a value bubble above the knob while
    ///     dragging. Defaults to `false`.
    ///   - haptics: Whether to fire tactile feedback while sliding. Defaults to `true`.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        tint: Color = DSColors.defaultPalette.primary,
        trackColor: Color = DSColors.defaultPalette.border,
        showsValue: Bool = false,
        haptics: Bool = true
    ) {
        self._value = value
        self.range = range
        self.step = (step ?? 0) > 0 ? step : nil
        self.tint = tint
        self.trackColor = trackColor
        self.showsValue = showsValue
        self.haptics = haptics
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let travel = max(width - knobSize, 1)
            let x = knobSize / 2 + CGFloat(fraction) * travel

            ZStack(alignment: .leading) {
                // Inactive track
                Capsule()
                    .fill(trackColor)
                    .frame(height: trackHeight)

                // Active fill (leading edge → knob center)
                Capsule()
                    .fill(tint)
                    .frame(width: x, height: trackHeight)

                // Knob
                knob(at: x)
            }
            .frame(maxWidth: .infinity)
            .frame(height: knobSize)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width))
            .animation(isDragging ? nil : DSAnimation.springSmooth, value: value)
        }
        .frame(height: knobSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slider")
        .accessibilityValue(formatted(value))
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { direction in
            let delta = step ?? (range.upperBound - range.lowerBound) / 10
            switch direction {
            case .increment: setValue(value + delta)
            case .decrement: setValue(value - delta)
            @unknown default: break
            }
        }
    }

    // MARK: - Knob

    @ViewBuilder
    private func knob(at x: CGFloat) -> some View {
        Circle()
            .fill(DSColors.defaultPalette.backgroundElevated)
            .overlay(
                Circle().strokeBorder(DSColors.defaultPalette.border, lineWidth: 1)
            )
            .frame(width: knobSize, height: knobSize)
            .dsShadow(.sm)
            .scaleEffect(isDragging ? 1.12 : 1.0)
            .overlay(alignment: .center) {
                if showsValue && isDragging {
                    valueBubble
                        .offset(y: -(knobSize / 2 + DSSpacing.lg))
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .offset(x: x - knobSize / 2)
            .animation(DSAnimation.springSnappy, value: isDragging)
    }

    private var valueBubble: some View {
        Text(formatted(value))
            .ds(.footnote, color: DSColors.defaultPalette.textOnPrimary)
            .padding(.horizontal, DSSpacing.xs)
            .padding(.vertical, DSSpacing.xxs)
            .background(tint, in: Capsule())
            .fixedSize()
            .dsShadow(.sm)
    }

    // MARK: - Derived Values

    /// Position of `value` within the range, in `0...1`.
    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    // MARK: - Gesture

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !isDragging {
                    withAnimation(DSAnimation.springSnappy) { isDragging = true }
                }
                update(toX: gesture.location.x, width: width)
            }
            .onEnded { gesture in
                update(toX: gesture.location.x, width: width)
                if haptics { DSHapticEngine.shared.fire(.light) }
                withAnimation(DSAnimation.springSnappy) { isDragging = false }
            }
    }

    /// Map a horizontal touch position to a snapped, clamped value.
    private func update(toX x: CGFloat, width: CGFloat) {
        let travel = max(width - knobSize, 1)
        let clampedX = min(max(x - knobSize / 2, 0), travel)
        let frac = Double(clampedX / travel)
        let raw = range.lowerBound + frac * (range.upperBound - range.lowerBound)
        let new = snapped(raw)

        if haptics { fireDetent(from: value, to: new) }
        value = new
    }

    /// Snap a raw value to the step grid (if any) and clamp to the range.
    private func snapped(_ raw: Double) -> Double {
        var result = raw
        if let step {
            let steps = ((raw - range.lowerBound) / step).rounded()
            result = range.lowerBound + steps * step
        }
        return min(max(result, range.lowerBound), range.upperBound)
    }

    /// Selection tick when crossing a detent; a soft tap at the extremes.
    private func fireDetent(from old: Double, to new: Double) {
        if step != nil {
            if new != old { DSHapticEngine.shared.fire(.selection) }
        } else {
            let hitMin = new <= range.lowerBound && old > range.lowerBound
            let hitMax = new >= range.upperBound && old < range.upperBound
            if hitMin || hitMax { DSHapticEngine.shared.fire(.soft) }
        }
    }

    /// Set the value from a non-drag source (e.g. accessibility), animated.
    private func setValue(_ raw: Double) {
        let new = snapped(raw)
        guard new != value else { return }
        if haptics { DSHapticEngine.shared.fire(.selection) }
        withAnimation(DSAnimation.springSmooth) { value = new }
    }

    private func formatted(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v.rounded())) : String(format: "%.1f", v)
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
    @State private var rating: Double = 6
    @State private var price: Double = 40

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Volume").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $volume)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Brightness").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $brightness, tint: DSColors.defaultPalette.secondary)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Steps of 1 (0–10)").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $rating, in: 0...10, step: 1, showsValue: true)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Price · $\(Int(price))").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $price, in: 0...100, step: 5,
                         tint: DSColors.defaultPalette.success, showsValue: true)
            }
        }
    }
}
