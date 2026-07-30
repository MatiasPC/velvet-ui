import SwiftUI

// MARK: - Design System Slider
// A tactile, themeable value slider built from scratch (not a wrapper around
// the stock `Slider`). The thumb glues to your finger while dragging and
// "grows" with a bouncy spring on grab; stepped sliders snap between detents
// and fire a selection tick each time you cross one, so adjusting a value
// feels physical. Works for any bounded quantity — volume, brightness,
// price ranges, filters — in both light and dark.

public struct DSSlider: View {

    // MARK: - Configuration

    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let tint: Color
    private let trackColor: Color
    private let haptics: Bool

    // MARK: - State

    @State private var isDragging = false

    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Layout Constants

    /// Height of the track / fill capsule.
    private let trackHeight: CGFloat = 6
    /// Diameter of the draggable thumb.
    private let thumbSize: CGFloat = 28

    // MARK: - Initializer

    /// A slider bound to a value the user can drag or tap to set.
    /// - Parameters:
    ///   - value: The current value, kept within `range`.
    ///   - range: The closed range of allowed values. Defaults to `0...1`.
    ///   - step: Optional snap increment. Pass `nil` for a continuous slider,
    ///     or a value (e.g. `5`) to snap to detents and tick on each crossing.
    ///     Defaults to `nil`.
    ///   - tint: Fill color for the completed portion of the track. Defaults
    ///     to the primary accent.
    ///   - trackColor: Color of the remaining track. Defaults to the border color.
    ///   - haptics: Whether to fire tactile feedback while sliding. Defaults to `true`.
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        tint: Color = DSColors.defaultPalette.primary,
        trackColor: Color = DSColors.defaultPalette.border,
        haptics: Bool = true
    ) {
        self._value = value
        self.range = range
        if let step, step > 0 {
            self.step = step
        } else {
            self.step = nil
        }
        self.tint = tint
        self.trackColor = trackColor
        self.haptics = haptics
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let usable = max(width - thumbSize, 1)
            let fraction = self.fraction
            let thumbX = fraction * usable

            ZStack(alignment: .leading) {
                // Remaining track
                Capsule()
                    .fill(trackColor)
                    .frame(width: width, height: trackHeight)

                // Completed fill
                Capsule()
                    .fill(tint)
                    .frame(width: thumbX + thumbSize / 2, height: trackHeight)

                // Thumb
                Circle()
                    .fill(DSColors.defaultPalette.backgroundElevated)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle().stroke(DSColors.defaultPalette.border, lineWidth: 0.5)
                    )
                    .dsShadow(.md)
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .offset(x: thumbX)
                    .animation(DSAnimation.springBouncy, value: isDragging)
            }
            .frame(width: width, height: thumbSize)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width), including: isEnabled ? .all : .none)
            .animation(DSAnimation.interactive, value: fraction)
        }
        .frame(height: thumbSize)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement()
        .accessibilityLabel("Slider")
        .accessibilityValue(Text(formatted(value)))
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            let delta = step ?? (range.upperBound - range.lowerBound) / 10
            switch direction {
            case .increment: commit(value + delta)
            case .decrement: commit(value - delta)
            @unknown default: break
            }
        }
    }

    // MARK: - Derived Values

    /// Position of the current value within the range, in `0...1`.
    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    // MARK: - Gesture

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if !isDragging { isDragging = true }
                let usable = max(width - thumbSize, 1)
                let f = min(max((g.location.x - thumbSize / 2) / usable, 0), 1)
                let span = range.upperBound - range.lowerBound
                let snapped = snap(range.lowerBound + f * span)
                guard snapped != value else { return }
                if haptics, step != nil {
                    DSHapticEngine.shared.fire(.selection)
                }
                value = snapped
            }
            .onEnded { _ in
                isDragging = false
                if haptics { DSHapticEngine.shared.fire(.light) }
            }
    }

    /// Snap a raw value to the nearest step (if any) and clamp to the range.
    private func snap(_ raw: Double) -> Double {
        guard let step else {
            return min(max(raw, range.lowerBound), range.upperBound)
        }
        let steps = ((raw - range.lowerBound) / step).rounded()
        let snapped = range.lowerBound + steps * step
        return min(max(snapped, range.lowerBound), range.upperBound)
    }

    private func commit(_ newValue: Double) {
        let snapped = snap(newValue)
        guard snapped != value else { return }
        if haptics { DSHapticEngine.shared.fire(.selection) }
        withAnimation(DSAnimation.springSnappy) {
            value = snapped
        }
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

// MARK: - Preview

#Preview {
    struct SliderPreview: View {
        @State private var volume: Double = 0.5
        @State private var brightness: Double = 0.8
        @State private var quantity: Double = 40
        @State private var locked: Double = 0.35

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Volume").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSlider(value: $volume)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Brightness").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSlider(value: $brightness, tint: DSColors.defaultPalette.warning)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Quantity — \(quantity, specifier: "%.0f")")
                        .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSlider(value: $quantity, in: 0...100, step: 5,
                             tint: DSColors.defaultPalette.secondary)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Disabled").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSSlider(value: $locked)
                        .disabled(true)
                }
            }
            .padding(DSSpacing.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return Group {
        SliderPreview()
            .preferredColorScheme(.light)
        SliderPreview()
            .preferredColorScheme(.dark)
    }
}
