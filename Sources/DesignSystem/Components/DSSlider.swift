import SwiftUI

// MARK: - Design System Slider
// A fully themeable value slider with a springy thumb, an accent-filled track,
// and tactile detents. Dragging scales the thumb up with a snappy spring and
// fires a selection tick as the value crosses each detent, so continuous and
// stepped sliders both feel physical. An optional value bubble rides above the
// thumb and rolls its digits with `numericText`. The stock SwiftUI `Slider`
// can't be tinted or restyled — this is the on-brand replacement for volume,
// brightness, price ranges, filters, and any bounded numeric input.
//
// Inspiration: kieranb662 "Sliders-SwiftUI" (tick-based haptic sliders,
// https://github.com/kieranb662/Sliders-SwiftUI) and the SwiftUI community's
// drag-to-set patterns.

public struct DSSlider: View {

    // MARK: - Configuration

    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let tint: Color
    private let showsValue: Bool
    private let haptics: Bool
    private let format: ((Double) -> String)?

    // MARK: - State

    @State private var isDragging = false
    /// Detent index the last haptic tick fired on, to avoid repeat buzzes.
    @State private var lastTickIndex: Int? = nil

    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Layout Constants

    /// Diameter of the draggable knob.
    private let thumbDiameter: CGFloat = 28
    /// Height of the track and its accent fill.
    private let trackHeight: CGFloat = 6
    /// Number of implicit haptic detents across a continuous range.
    private let detentCount = 20

    // MARK: - Init

    /// A themeable slider bound to a value within `range`.
    /// - Parameters:
    ///   - value: The current value. Clamped into `range` for display.
    ///   - range: The inclusive bounds. Defaults to `0...1`.
    ///   - step: Snap increment. `nil` (default) is continuous; the slider
    ///     still emits subtle haptic detents across the range.
    ///   - tint: Fill + thumb-accent color. Defaults to the primary accent.
    ///   - showsValue: When `true`, a value bubble rides above the thumb while
    ///     dragging. Defaults to `false`.
    ///   - haptics: Whether to fire tactile detents while dragging. Defaults to `true`.
    ///   - format: Optional custom formatter for the value bubble. Defaults to
    ///     an integer for whole values and one decimal otherwise.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        tint: Color = DSColors.defaultPalette.primary,
        showsValue: Bool = false,
        haptics: Bool = true,
        format: ((Double) -> String)? = nil
    ) {
        self._value = value
        self.range = range.lowerBound < range.upperBound
            ? range
            : range.lowerBound...(range.lowerBound + 1)
        if let step, step > 0 {
            self.step = step
        } else {
            self.step = nil
        }
        self.tint = tint
        self.showsValue = showsValue
        self.haptics = haptics
        self.format = format
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let usable = max(width - thumbDiameter, 1)
            let x = CGFloat(fraction) * usable

            ZStack(alignment: .leading) {
                // Unfilled track
                Capsule(style: .continuous)
                    .fill(DSColors.defaultPalette.border)
                    .frame(height: trackHeight)

                // Accent fill up to the thumb center
                Capsule(style: .continuous)
                    .fill(tint)
                    .frame(width: x + thumbDiameter / 2, height: trackHeight)

                // Thumb
                thumb
                    .offset(x: x)

                // Value bubble
                if showsValue {
                    bubble
                        .frame(width: thumbDiameter)
                        .offset(x: x, y: -(thumbDiameter / 2 + DSSpacing.lg))
                        .opacity(isDragging ? 1 : 0)
                        .scaleEffect(isDragging ? 1 : 0.8, anchor: .bottom)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: thumbDiameter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width), including: isEnabled ? .all : .none)
            .animation(DSAnimation.springSnappy, value: isDragging)
        }
        .frame(height: thumbDiameter)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slider")
        .accessibilityValue(formatted(value))
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            let delta = step ?? tickInterval
            switch direction {
            case .increment: commit(min(value + delta, range.upperBound))
            case .decrement: commit(max(value - delta, range.lowerBound))
            @unknown default: break
            }
        }
    }

    // MARK: - Thumb

    private var thumb: some View {
        Circle()
            .fill(DSColors.defaultPalette.backgroundElevated)
            .frame(width: thumbDiameter, height: thumbDiameter)
            .overlay(
                Circle().stroke(tint.opacity(isDragging ? 0.6 : 0), lineWidth: 2)
            )
            .dsShadow(isDragging ? .lg : .md)
            .scaleEffect(isDragging ? 1.12 : 1)
    }

    // MARK: - Value Bubble

    private var bubble: some View {
        Text(formatted(value))
            .ds(.buttonSmall, color: DSColors.defaultPalette.textOnPrimary)
            .contentTransition(.numericText())
            .padding(.horizontal, DSSpacing.xs)
            .padding(.vertical, DSSpacing.xxs)
            .background(Capsule(style: .continuous).fill(tint))
            .dsShadow(.sm)
            .fixedSize()
            .animation(DSAnimation.springSnappy, value: value)
    }

    // MARK: - Gesture

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                let raw = rawValue(atX: drag.location.x, width: width)
                let newValue = clamped(snapped(raw))
                let idx = tickIndex(for: newValue)
                if !isDragging {
                    isDragging = true
                    lastTickIndex = idx
                } else if haptics, idx != lastTickIndex {
                    DSHapticEngine.shared.fire(.selection)
                    lastTickIndex = idx
                }
                if newValue != value {
                    value = newValue
                }
            }
            .onEnded { _ in
                isDragging = false
                lastTickIndex = nil
                if haptics {
                    DSHapticEngine.shared.fire(.rigid)
                }
            }
    }

    // MARK: - Value Math

    /// The current value as a `0...1` fraction of the range.
    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    /// Map a horizontal touch position to a raw (un-snapped) value.
    private func rawValue(atX x: CGFloat, width: CGFloat) -> Double {
        let usable = max(width - thumbDiameter, 1)
        let localX = x - thumbDiameter / 2
        let f = min(max(Double(localX / usable), 0), 1)
        return range.lowerBound + f * (range.upperBound - range.lowerBound)
    }

    /// Snap a raw value to the nearest step, when stepping is enabled.
    private func snapped(_ v: Double) -> Double {
        guard let step, step > 0 else { return v }
        let steps = ((v - range.lowerBound) / step).rounded()
        return range.lowerBound + steps * step
    }

    private func clamped(_ v: Double) -> Double {
        min(max(v, range.lowerBound), range.upperBound)
    }

    /// Spacing between haptic detents — the step, or an even split of the range.
    private var tickInterval: Double {
        if let step { return step }
        let span = range.upperBound - range.lowerBound
        return span / Double(detentCount)
    }

    private func tickIndex(for v: Double) -> Int {
        guard tickInterval > 0 else { return 0 }
        return Int(((v - range.lowerBound) / tickInterval).rounded(.down))
    }

    private func commit(_ newValue: Double) {
        if haptics {
            DSHapticEngine.shared.fire(.selection)
        }
        withAnimation(DSAnimation.springSnappy) {
            value = clamped(snapped(newValue))
        }
    }

    private func formatted(_ v: Double) -> String {
        if let format { return format(v) }
        if let step, step >= 1, step == step.rounded() {
            return String(Int(v.rounded()))
        }
        return v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Preview

#Preview {
    struct SliderPreview: View {
        @State private var volume: Double = 0.6
        @State private var brightness: Double = 0.35
        @State private var quantity: Double = 3
        @State private var price: Double = 240

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                labeled("Volume (continuous)") {
                    HStack(spacing: DSSpacing.md) {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(DSColors.defaultPalette.textSecondary)
                        DSSlider(value: $volume)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(DSColors.defaultPalette.textSecondary)
                    }
                }

                labeled("Brightness (secondary tint)") {
                    DSSlider(
                        value: $brightness,
                        tint: DSColors.defaultPalette.secondary
                    )
                }

                labeled("Quantity (step 1, value bubble)") {
                    DSSlider(
                        value: $quantity,
                        in: 0...10,
                        step: 1,
                        showsValue: true
                    )
                }

                labeled("Price (custom format)") {
                    DSSlider(
                        value: $price,
                        in: 0...500,
                        step: 10,
                        tint: DSColors.defaultPalette.tertiary,
                        showsValue: true,
                        format: { "$\(Int($0))" }
                    )
                }

                labeled("Disabled") {
                    DSSlider(value: .constant(0.5))
                        .disabled(true)
                }
            }
            .padding(DSSpacing.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }

        @ViewBuilder
        func labeled(_ title: String, @ViewBuilder content: () -> some View) -> some View {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text(title).ds(.overline, color: DSColors.defaultPalette.textSecondary)
                content()
            }
        }
    }

    return Group {
        SliderPreview()
            .preferredColorScheme(.light)
        SliderPreview()
            .preferredColorScheme(.dark)
    }
}
