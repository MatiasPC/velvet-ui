import SwiftUI

// MARK: - Design System Slider
// A branded, tactile alternative to the stock `Slider`. The thumb springs
// larger while dragging, the track fills with the accent color, and each
// stepped value crossing fires a selection tick — the kind of feedback the
// platform slider never gives you. A floating value bubble can rise above the
// thumb while dragging so the exact value is always readable. Pure SwiftUI.

public struct DSSlider: View {

    // MARK: - Configuration

    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let tint: Color
    private let trackColor: Color
    private let showsValueLabel: Bool
    private let valueLabel: ((Double) -> String)?
    private let haptics: Bool

    // MARK: - Geometry Constants

    /// Height of the track capsule.
    private let trackHeight: CGFloat = 6
    /// Diameter of the draggable thumb.
    private let thumbSize: CGFloat = 28

    // MARK: - State

    @State private var isDragging = false
    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Init

    /// A continuous or stepped slider bound to a value.
    /// - Parameters:
    ///   - value: The current value, kept within `range`.
    ///   - range: The closed range the value can span. Defaults to `0...1`.
    ///   - step: Optional snap increment. When set, dragging snaps to multiples
    ///     of `step` and fires a selection tick on each crossing. `nil` for a
    ///     smooth, continuous slider. Defaults to `nil`.
    ///   - tint: Fill color for the completed portion and thumb accent.
    ///     Defaults to the primary color.
    ///   - trackColor: Color of the remaining track. Defaults to the border color.
    ///   - showsValueLabel: When `true`, a value bubble stays visible above the
    ///     thumb; otherwise it appears only while dragging. Defaults to `false`.
    ///   - valueLabel: Optional formatter for the bubble text. Defaults to an
    ///     integer for whole steps, otherwise one decimal place.
    ///   - haptics: Whether to fire tactile feedback. Defaults to `true`.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        tint: Color = DSColors.defaultPalette.primary,
        trackColor: Color = DSColors.defaultPalette.border,
        showsValueLabel: Bool = false,
        valueLabel: ((Double) -> String)? = nil,
        haptics: Bool = true
    ) {
        self._value = value
        self.range = range
        if let step, step > 0 { self.step = step } else { self.step = nil }
        self.tint = tint
        self.trackColor = trackColor
        self.showsValueLabel = showsValueLabel
        self.valueLabel = valueLabel
        self.haptics = haptics
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let usable = max(width - thumbSize, 1)
            let thumbX = thumbSize / 2 + usable * fraction

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(trackColor)
                    .frame(height: trackHeight)

                // Filled portion
                Capsule()
                    .fill(tint)
                    .frame(width: max(thumbX, trackHeight), height: trackHeight)

                // Thumb
                Circle()
                    .fill(DSColors.defaultPalette.backgroundElevated)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(Circle().stroke(tint.opacity(0.18), lineWidth: 1))
                    .dsShadow(isDragging ? .md : .sm)
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .offset(x: thumbX - thumbSize / 2)

                // Floating value bubble
                if showsValueLabel || isDragging {
                    bubble
                        .position(x: bubbleX(thumbX, width: width), y: -DSSpacing.lg)
                        .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
                }
            }
            .frame(height: thumbSize)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(drag(width: width))
            .animation(isDragging ? DSAnimation.interactive : DSAnimation.springSmooth, value: value)
            .animation(DSAnimation.springSnappy, value: isDragging)
        }
        .frame(height: thumbSize)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement()
        .accessibilityLabel("Slider")
        .accessibilityValue(label(for: value))
        .accessibilityAddTraits(.isButton)
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

    // MARK: - Value Bubble

    private var bubble: some View {
        Text(label(for: value))
            .ds(.buttonSmall, color: DSColors.defaultPalette.textOnPrimary)
            .padding(.horizontal, DSSpacing.xs)
            .padding(.vertical, DSSpacing.xxs)
            .background(tint, in: Capsule())
            .dsShadow(.sm)
            .fixedSize()
    }

    // MARK: - Derived Values

    /// Portion of the track that is filled, in `0...1`.
    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat(min(max((value - range.lowerBound) / span, 0), 1))
    }

    /// Clamp the bubble's center so it never spills past the track edges.
    private func bubbleX(_ thumbX: CGFloat, width: CGFloat) -> CGFloat {
        let margin = thumbSize / 2
        return min(max(thumbX, margin), max(width - margin, margin))
    }

    // MARK: - Gesture

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                guard isEnabled else { return }
                if !isDragging {
                    isDragging = true
                    if haptics { DSHapticEngine.shared.fire(.light) }
                }
                update(atX: g.location.x, width: width)
            }
            .onEnded { g in
                guard isEnabled else { return }
                update(atX: g.location.x, width: width)
                isDragging = false
                if haptics { DSHapticEngine.shared.fire(.rigid) }
            }
    }

    /// Map a horizontal touch position to a (optionally snapped) value.
    private func update(atX x: CGFloat, width: CGFloat) {
        let usable = max(width - thumbSize, 1)
        let clampedX = min(max(x - thumbSize / 2, 0), usable)
        let frac = Double(clampedX / usable)
        let span = range.upperBound - range.lowerBound
        var newValue = range.lowerBound + frac * span
        if let step {
            newValue = (newValue / step).rounded() * step
        }
        newValue = min(max(newValue, range.lowerBound), range.upperBound)

        guard newValue != value else { return }
        // Only tick on discrete crossings — continuous drags stay silent.
        if haptics, step != nil {
            DSHapticEngine.shared.fire(.selection)
        }
        value = newValue
    }

    /// Set the value with a spring (used by accessibility actions).
    private func commit(_ newValue: Double) {
        if haptics { DSHapticEngine.shared.fire(.selection) }
        withAnimation(DSAnimation.springSmooth) {
            value = newValue
        }
    }

    // MARK: - Formatting

    private func label(for v: Double) -> String {
        if let valueLabel { return valueLabel(v) }
        if let step, step == step.rounded() {
            return String(Int(v.rounded()))
        }
        return String(format: "%.1f", v)
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
    @State private var level: Double = 3
    @State private var temperature: Double = 21

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xxl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("VOLUME").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $volume)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("BRIGHTNESS").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $brightness, tint: DSColors.defaultPalette.secondary)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("LEVEL (STEPPED)").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(value: $level, in: 0...10, step: 1, showsValueLabel: true)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("TEMPERATURE").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSSlider(
                    value: $temperature,
                    in: 16...30,
                    step: 0.5,
                    tint: DSColors.defaultPalette.tertiary,
                    valueLabel: { String(format: "%.1f°", $0) }
                )
            }

            DSSlider(value: $volume)
                .disabled(true)
        }
    }
}
