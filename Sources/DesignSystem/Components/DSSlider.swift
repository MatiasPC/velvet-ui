import SwiftUI

// MARK: - Design System Slider
// A custom-drawn value slider: a themed accent fill under a white knob that
// "pops" and emits an accent glow the moment you touch it — the same light-on-
// touch language as the primary CTA and the toggle. Drag to set a value; with a
// `step` it snaps and ticks. Every app needs a value input (volume, brightness,
// price, opacity) — this is the tactile, themeable alternative to the stock
// `Slider`, driven by the Velvet drag + haptic + glow patterns (see DSRating).
//
// Inspiration: custom-slider patterns from the SwiftUI community —
// Hacking with Swift (DragGesture + offset), kieranb662/Sliders-SwiftUI
// (tick marks + haptics). Rebuilt on DS tokens, springs and haptics.

public struct DSSlider: View {

    // MARK: - Configuration

    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let knobSize: CGFloat
    private let tint: Color?
    private let trackColor: Color?
    private let showsTicks: Bool
    private let haptics: Bool

    // MARK: - State

    @State private var isDragging = false
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Init

    /// A draggable slider bound to a value.
    /// - Parameters:
    ///   - value: The current value, clamped to `range`.
    ///   - range: The closed range the value moves through. Defaults to `0...1`.
    ///   - step: Snap increment. `nil` (default) is continuous; a positive value
    ///     snaps to that increment and fires a selection tick on each step.
    ///   - knobSize: Diameter of the draggable knob (also the control height). Defaults to `28`.
    ///   - tint: Fill for the active track and the knob glow. Defaults to the theme accent.
    ///   - trackColor: Fill for the inactive track. Defaults to the palette border.
    ///   - showsTicks: Draw tick marks at each step (requires a `step`). Defaults to `false`.
    ///   - haptics: Whether to fire tactile feedback while sliding. Defaults to `true`.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        knobSize: CGFloat = 28,
        tint: Color? = nil,
        trackColor: Color? = nil,
        showsTicks: Bool = false,
        haptics: Bool = true
    ) {
        self._value = value
        self.range = range
        self.step = (step ?? 0) > 0 ? step : nil
        self.knobSize = knobSize
        self.tint = tint
        self.trackColor = trackColor
        self.showsTicks = showsTicks
        self.haptics = haptics
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let center = knobCenter(in: width)

            ZStack(alignment: .leading) {
                // Inactive track
                Capsule(style: .continuous)
                    .fill(trackColor ?? theme.palette.border)
                    .frame(height: trackHeight)

                // Active fill
                Capsule(style: .continuous)
                    .fill(tint ?? theme.accent)
                    .frame(width: max(center, trackHeight), height: trackHeight)

                // Step ticks (above the fill so passed marks stay visible)
                ForEach(tickCenters(width: width), id: \.self) { x in
                    Capsule(style: .continuous)
                        .fill(theme.palette.textTertiary.opacity(0.6))
                        .frame(width: tickWidth, height: trackHeight)
                        .offset(x: x - tickWidth / 2)
                }

                // Knob
                knob
                    .offset(x: center - knobSize / 2)
            }
            .frame(width: width, height: knobSize)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width))
            .animation(reduceMotion ? nil : DSAnimation.interactive, value: value)
            .animation(reduceMotion ? nil : DSPress.animation, value: isDragging)
        }
        .frame(height: knobSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slider")
        .accessibilityValue(accessibilityValueText)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: adjust(by: stepMagnitude)
            case .decrement: adjust(by: -stepMagnitude)
            @unknown default: break
            }
        }
    }

    // MARK: - Knob

    private var knob: some View {
        Circle()
            .fill(theme.palette.textOnPrimary)
            .frame(width: knobSize, height: knobSize)
            .dsShadow(isDragging ? .glow(tint ?? theme.accent) : .sm)
            .scaleEffect(isDragging && !reduceMotion ? 1.12 : 1.0)
    }

    // MARK: - Geometry

    private let trackHeight: CGFloat = DSSpacing.xs
    private let tickWidth: CGFloat = DSSpacing.xxxs

    /// Fraction of the range the current value represents, in `0...1`.
    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    /// Horizontal center of the knob for a given track width.
    private func knobCenter(in width: CGFloat) -> CGFloat {
        knobSize / 2 + CGFloat(fraction) * max(width - knobSize, 0)
    }

    /// Tick-mark centers, or empty when ticks are off / unbounded.
    private func tickCenters(width: CGFloat) -> [CGFloat] {
        guard showsTicks, let step else { return [] }
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return [] }
        let count = Int((span / step).rounded())
        guard count >= 1, count <= 40 else { return [] }
        let travel = max(width - knobSize, 1)
        return (0...count).map { i in
            knobSize / 2 + CGFloat(Double(i) / Double(count)) * travel
        }
    }

    // MARK: - Gesture

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if !isDragging {
                    isDragging = true
                    if haptics { DSHapticEngine.shared.fire(.soft) }
                }
                updateValue(atX: drag.location.x, width: width)
            }
            .onEnded { drag in
                updateValue(atX: drag.location.x, width: width)
                isDragging = false
                if haptics { DSHapticEngine.shared.fire(.light) }
            }
    }

    /// Map a horizontal touch position to a snapped, clamped value.
    private func updateValue(atX x: CGFloat, width: CGFloat) {
        let travel = max(width - knobSize, 1)
        let clampedX = min(max(x - knobSize / 2, 0), travel)
        let f = Double(clampedX / travel)
        let raw = range.lowerBound + f * (range.upperBound - range.lowerBound)
        let snapped = snap(raw)
        guard snapped != value else { return }
        // Continuous drags would tick on every pixel — only stepped sliders tick.
        if haptics, step != nil { DSHapticEngine.shared.fire(.selection) }
        value = snapped
    }

    /// Snap to the nearest step (anchored to `lowerBound`) and clamp to `range`.
    private func snap(_ raw: Double) -> Double {
        var v = raw
        if let step {
            let steps = ((v - range.lowerBound) / step).rounded()
            v = range.lowerBound + steps * step
        }
        return min(max(v, range.lowerBound), range.upperBound)
    }

    /// Nudge from an accessibility adjustable action.
    private func adjust(by delta: Double) {
        let v = snap(value + delta)
        guard v != value else { return }
        if haptics { DSHapticEngine.shared.fire(.selection) }
        withAnimation(reduceMotion ? nil : DSAnimation.springSnappy) {
            value = v
        }
    }

    /// Step used by the accessibility rotor: the explicit step, else 1/10 of the range.
    private var stepMagnitude: Double {
        step ?? (range.upperBound - range.lowerBound) / 10
    }

    // MARK: - Accessibility text

    private var accessibilityValueText: String {
        if range == 0...1 {
            return "\(Int((fraction * 100).rounded())) percent"
        }
        return value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSliderPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var volume: Double = 0.7
    @State private var brightness: Double = 0.4
    @State private var quality: Double = 3
    @State private var temperature: Double = 21

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        labeled("Volume", value: "\(Int((volume * 100).rounded()))%") {
                            HStack(spacing: DSSpacing.sm) {
                                Image(systemName: "speaker.fill")
                                    .foregroundStyle(theme.palette.textTertiary)
                                DSSlider(value: $volume)
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundStyle(theme.palette.textTertiary)
                            }
                        }

                        labeled("Brightness", value: "\(Int((brightness * 100).rounded()))%") {
                            DSSlider(value: $brightness, tint: theme.palette.secondary)
                        }

                        labeled("Quality", value: "\(Int(quality)) / 5") {
                            DSSlider(value: $quality, in: 0...5, step: 1, showsTicks: true)
                        }

                        labeled("Temperature", value: String(format: "%.0f°C", temperature)) {
                            DSSlider(
                                value: $temperature,
                                in: 16...30,
                                step: 0.5,
                                tint: theme.palette.info
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    @ViewBuilder
    private func labeled(_ title: String, value: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Text(title).ds(.footnote, color: theme.palette.textSecondary)
                Spacer()
                Text(value).ds(.numeric)
            }
            content()
        }
    }
}

#Preview("Slider — Light") {
    DSSliderPreviewHost().preferredColorScheme(.light)
}

#Preview("Slider — Dark") {
    DSSliderPreviewHost().preferredColorScheme(.dark)
}
#endif
