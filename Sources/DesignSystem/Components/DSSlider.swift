import SwiftUI

// MARK: - Design System Slider
// A themeable, tactile alternative to the stock `Slider`. The knob "pops"
// while you drag, the fill tracks it with a responsive spring, and every
// snap of a stepped slider fires a selection tick — so adjusting a value
// feels physical. An optional value bubble floats above the knob during a
// drag, and stepped sliders can show tick marks. Like `DSToggle`, this is
// the on-brand control every settings screen, filter panel, or media view
// eventually needs.

public struct DSSlider: View {

    // MARK: - Configuration

    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let tint: Color
    private let trackColor: Color
    private let height: CGFloat
    private let knobSize: CGFloat
    private let showsValue: Bool
    private let showsTicks: Bool
    private let valueFormat: String
    private let haptics: Bool

    // MARK: - State

    @Environment(\.isEnabled) private var isEnabled
    @State private var isDragging = false
    @State private var lastStepIndex: Int? = nil

    // MARK: - Initializer

    /// A draggable slider bound to a value within a range.
    /// - Parameters:
    ///   - value: The current value, kept within `range`.
    ///   - range: The inclusive value range. Defaults to `0...1`.
    ///   - step: Optional snap increment. When set, the value snaps to
    ///     multiples of `step` and each snap fires a selection tick.
    ///     `nil` (default) makes the slider continuous.
    ///   - tint: Fill and knob-accent color. Defaults to the primary color.
    ///   - trackColor: The unfilled track color. Defaults to the border color.
    ///   - height: Track thickness. Defaults to `6`.
    ///   - knobSize: Diameter of the draggable knob. Defaults to `28`.
    ///   - showsValue: Whether to float a value bubble above the knob while
    ///     dragging. Defaults to `false`.
    ///   - showsTicks: Whether to draw tick marks at each step (stepped
    ///     sliders only, capped for legibility). Defaults to `false`.
    ///   - valueFormat: `String(format:)` specifier for the value bubble and
    ///     accessibility value. Defaults to `"%.0f"`.
    ///   - haptics: Whether to fire tactile feedback while dragging.
    ///     Defaults to `true`.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        tint: Color = DSColors.defaultPalette.primary,
        trackColor: Color = DSColors.defaultPalette.border,
        height: CGFloat = 6,
        knobSize: CGFloat = 28,
        showsValue: Bool = false,
        showsTicks: Bool = false,
        valueFormat: String = "%.0f",
        haptics: Bool = true
    ) {
        self._value = value
        self.range = range.lowerBound < range.upperBound ? range : range.lowerBound...(range.lowerBound + 1)
        self.step = (step ?? 0) > 0 ? step : nil
        self.tint = tint
        self.trackColor = trackColor
        self.height = height
        self.knobSize = knobSize
        self.showsValue = showsValue
        self.showsTicks = showsTicks
        self.valueFormat = valueFormat
        self.haptics = haptics
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let usable = max(width - knobSize, 1)
            let knobX = knobSize / 2 + fraction * usable

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(trackColor)
                    .frame(height: height)

                // Tick marks (stepped sliders only)
                if showsTicks, let marks = tickCount {
                    ForEach(0...marks, id: \.self) { i in
                        Circle()
                            .fill(DSColors.defaultPalette.divider)
                            .frame(width: DSSpacing.xxs, height: DSSpacing.xxs)
                            .position(
                                x: knobSize / 2 + CGFloat(i) / CGFloat(marks) * usable,
                                y: rowHeight / 2
                            )
                    }
                }

                // Fill
                Capsule()
                    .fill(tint)
                    .frame(width: knobX, height: height)

                // Knob
                knob
                    .position(x: knobX, y: rowHeight / 2)

                // Value bubble
                if showsValue && isDragging {
                    valueBubble
                        .position(x: knobX, y: -DSSpacing.md)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .frame(width: width, height: rowHeight)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width), including: isEnabled ? .all : .none)
            .animation(DSAnimation.interactive, value: value)
            .animation(DSAnimation.springSnappy, value: isDragging)
        }
        .frame(height: rowHeight)
        .padding(.top, showsValue ? DSSpacing.xxl : 0)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slider")
        .accessibilityValue(Text(String(format: valueFormat, clampedValue)))
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            let delta = step ?? ((range.upperBound - range.lowerBound) / 10)
            switch direction {
            case .increment: commit(clampedValue + delta)
            case .decrement: commit(clampedValue - delta)
            @unknown default: break
            }
        }
    }

    // MARK: - Knob + Bubble

    private var knob: some View {
        Circle()
            .fill(DSColors.defaultPalette.textOnPrimary)
            .frame(width: knobSize, height: knobSize)
            .overlay(
                Circle().stroke(tint.opacity(0.15), lineWidth: 1)
            )
            .dsShadow(isDragging ? .md : .sm)
            .scaleEffect(isDragging ? 1.12 : 1.0)
    }

    private var valueBubble: some View {
        Text(String(format: valueFormat, clampedValue))
            .ds(.buttonSmall, color: DSColors.defaultPalette.textOnPrimary)
            .padding(.horizontal, DSSpacing.xs)
            .padding(.vertical, DSSpacing.xxs)
            .background(Capsule().fill(tint))
            .dsShadow(.md)
            .fixedSize()
    }

    // MARK: - Derived Values

    private var rowHeight: CGFloat { max(knobSize, height) }

    private var clampedValue: Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat((clampedValue - range.lowerBound) / span)
    }

    /// Number of tick intervals to draw, or `nil` when ticks don't apply
    /// (continuous slider) or would be too dense to read.
    private var tickCount: Int? {
        guard let step else { return nil }
        let count = Int(((range.upperBound - range.lowerBound) / step).rounded())
        return (count >= 1 && count <= 40) ? count : nil
    }

    // MARK: - Gesture

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if !isDragging {
                    isDragging = true
                    if haptics { DSHapticEngine.shared.fire(.light) }
                }
                update(atX: g.location.x, width: width)
            }
            .onEnded { g in
                update(atX: g.location.x, width: width)
                isDragging = false
                lastStepIndex = nil
                if haptics { DSHapticEngine.shared.fire(.light) }
            }
    }

    /// Map a horizontal touch position to a (possibly snapped) value.
    private func update(atX x: CGFloat, width: CGFloat) {
        let usable = max(width - knobSize, 1)
        let frac = min(max((x - knobSize / 2) / usable, 0), 1)
        let span = range.upperBound - range.lowerBound
        let newValue = snapped(range.lowerBound + Double(frac) * span)

        if haptics, let step, step > 0 {
            let idx = Int(((newValue - range.lowerBound) / step).rounded())
            if idx != lastStepIndex {
                if lastStepIndex != nil { DSHapticEngine.shared.fire(.selection) }
                lastStepIndex = idx
            }
        }

        if newValue != value { value = newValue }
    }

    /// Snap a raw value to the step grid and clamp it to the range.
    private func snapped(_ raw: Double) -> Double {
        let clamped = min(max(raw, range.lowerBound), range.upperBound)
        guard let step, step > 0 else { return clamped }
        let steps = ((clamped - range.lowerBound) / step).rounded()
        return min(range.lowerBound + steps * step, range.upperBound)
    }

    /// Programmatic value change (accessibility) with animation + haptic.
    private func commit(_ raw: Double) {
        let newValue = snapped(raw)
        guard newValue != value else { return }
        if haptics { DSHapticEngine.shared.fire(.selection) }
        withAnimation(DSAnimation.springSnappy) {
            value = newValue
        }
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
    @State private var price: Double = 40

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Volume").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                HStack(spacing: DSSpacing.md) {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(DSColors.defaultPalette.textSecondary)
                    DSSlider(value: $volume)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(DSColors.defaultPalette.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Brightness").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $brightness, tint: DSColors.defaultPalette.warning)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Quantity — stepped + ticks").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(
                    value: $quantity,
                    in: 0...8,
                    step: 1,
                    tint: DSColors.defaultPalette.secondary,
                    showsValue: true,
                    showsTicks: true
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Budget — value bubble").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(
                    value: $price,
                    in: 0...100,
                    step: 5,
                    tint: DSColors.defaultPalette.tertiary,
                    showsValue: true
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Disabled").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $volume)
                    .disabled(true)
            }
        }
    }
}
