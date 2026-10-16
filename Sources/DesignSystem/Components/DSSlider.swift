import SwiftUI

// MARK: - Design System Slider
// A continuous value control — the one input Velvet was missing. DSStepper,
// DSRating and DSToggle all cover *discrete* values; nothing drove a free
// 0...1 (volume, brightness, price, opacity). The stock `Slider` can't wear the
// glass/no-border look, so this is custom-drawn to match: a slim wash track, an
// accent fill that trails the knob, and a white knob that lifts and lights up
// under the finger.
//
// The knob tracks the finger 1:1 and a tap anywhere on the track jumps to that
// spot (`minimumDistance: 0`). Haptics are tasteful rather than constant: a
// `.selection` ratchet tick each time a *stepped* slider lands on a new notch,
// and a single firm `.rigid` detent the moment travel reaches either end — a
// continuous slider stays silent in between so dragging never spams the Taptic
// Engine. The grab lift is decorative and settles to rest under Reduce Motion;
// the knob still follows the finger, because that *is* the interaction.
//
// Technique inspired by the standard pure-SwiftUI custom-slider pattern
// (GeometryReader width + DragGesture + self-fired selection haptics), e.g.
// priva28 "Making a custom slider in SwiftUI" and the position→value math in
// the SwiftUI community (kieranb662/sliders-swiftui).

// MARK: - Metrics

/// Sizes derived from the spacing scale — no raw CGFloat literals in the body.
private enum Metrics {
    /// Slim track, matching the toggle/segmented visual weight. DSSpacing.xs (8).
    static let trackHeight: CGFloat = DSSpacing.xs
    /// Knob diameter: DSSpacing.xl (24) + DSSpacing.xxs (4) = 28 — a comfortable
    /// thumb that overhangs the 8pt track symmetrically.
    static let knobDiameter: CGFloat = DSSpacing.xl + DSSpacing.xxs
    /// Apple's 44pt minimum tap target, from tokens: DSSpacing.xxl (32) + sm (12).
    /// The slim track lives centred inside this taller, invisible hit area.
    static let hitTarget: CGFloat = DSSpacing.xxl + DSSpacing.sm
    /// How far the halo extends past the knob while grabbed.
    static let haloScale: CGFloat = 1.3
    /// Knob lift while the finger owns it.
    static let grabScale: CGFloat = 1.12
    /// Slack for the floating-point bound comparison that arms the end detent.
    static let boundEpsilon: Double = 0.0001
}

// MARK: - DSSlider

/// A continuous slider bound to a `Double`.
///
///     DSSlider(value: $volume)                       // 0...1 continuous
///     DSSlider(value: $price, in: 0...500, step: 25) // snaps in 25s, ticks each
///     DSSlider(value: $opacity, in: 0...1, accent: DSColors.secondary)
///
/// Pass `step` for a notched slider (each notch fires a `.selection` tick) or
/// leave it `nil` for a smooth value. The control draws its own value label
/// only through VoiceOver — show a visible read-out alongside it when you need
/// one, the way `DSRating`'s call sites do.
public struct DSSlider: View {

    // MARK: Configuration

    @Binding private var value: Double
    private let bounds: ClosedRange<Double>
    private let step: Double?
    private let accent: Color?
    private let haptics: Bool

    // MARK: State

    /// Measured track width, used to map between touch position and value.
    @State private var trackWidth: CGFloat = 0
    /// Whether the finger currently owns the knob (drives the lift + halo).
    @State private var isDragging = false
    /// Whether the value is resting against a bound, so the end detent fires once.
    @State private var atBound = false
    /// Last notch index felt, so a stepped slider ticks once per notch crossed.
    @State private var lastStepIndex: Int?

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @DSThemed private var theme

    // MARK: Init

    /// - Parameters:
    ///   - value: The bound value, kept clamped into `bounds`.
    ///   - bounds: The allowed range. Defaults to `0...1`.
    ///   - step: Snap increment. `nil` (default) is continuous; a non-positive
    ///     value is treated as continuous.
    ///   - accent: Fill colour of the trailed track. Defaults to the theme accent.
    ///   - haptics: Whether to fire tactile feedback while sliding. Defaults to `true`.
    public init(
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        accent: Color? = nil,
        haptics: Bool = true
    ) {
        self._value = value
        self.bounds = bounds
        if let step, step > 0 {
            self.step = step
        } else {
            self.step = nil
        }
        self.accent = accent
        self.haptics = haptics
    }

    // MARK: Body

    public var body: some View {
        let resolvedAccent = accent ?? theme.accent

        ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(theme.subtleFill)
                .frame(height: Metrics.trackHeight)

            Capsule(style: .continuous)
                .fill(resolvedAccent)
                .frame(width: fillWidth, height: Metrics.trackHeight)

            knob(resolvedAccent)
                .offset(x: knobOffset)
        }
        .frame(height: Metrics.hitTarget)
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { trackWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newValue in
                        trackWidth = newValue
                    }
            }
        }
        .contentShape(Rectangle())
        .gesture(dragGesture, including: isEnabled ? .all : .none)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(DSAnimation.interactive, value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slider")
        .accessibilityValue(Text(accessibilityValueText))
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            let delta = step ?? max(span / 10, 0)
            switch direction {
            case .increment: commit(value + delta)
            case .decrement: commit(value - delta)
            @unknown default: break
            }
        }
    }

    // MARK: Knob

    @ViewBuilder
    private func knob(_ accent: Color) -> some View {
        Circle()
            .fill(theme.palette.textOnPrimary)
            .frame(width: Metrics.knobDiameter, height: Metrics.knobDiameter)
            .overlay {
                // A diffuse accent halo on grab — the same focus-glow recipe the
                // text field uses, shaped to the circular knob. Opacity, not
                // motion, so it stays under Reduce Motion.
                Circle()
                    .stroke(
                        accent.opacity(isDragging ? DSWash.focusOpacity : 0),
                        lineWidth: DSWash.focusWidth
                    )
                    .blur(radius: DSWash.focusBlur)
                    .scaleEffect(Metrics.haloScale)
                    .allowsHitTesting(false)
                    .animation(DSAnimation.micro, value: isDragging)
            }
            .scaleEffect(knobScale)
            .dsShadow(.sm)
            .animation(DSAnimation.springSnappy, value: isDragging)
    }

    /// The grab lift is decorative — pinned at rest under Reduce Motion.
    private var knobScale: CGFloat {
        isDragging && !reduceMotion ? Metrics.grabScale : 1
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                guard isEnabled else { return }
                if !isDragging {
                    withAnimation(DSAnimation.springSnappy) { isDragging = true }
                }
                update(toX: gesture.location.x)
            }
            .onEnded { _ in
                guard isEnabled else { return }
                withAnimation(DSAnimation.springSnappy) { isDragging = false }
                atBound = false
                lastStepIndex = nil
            }
    }

    /// Map a touch position to a (snapped, clamped) value, move there, and fire
    /// whatever tactile feedback the move earned.
    private func update(toX x: CGFloat) {
        let newValue = clamp(snapped(rawValue(atX: x)))
        if newValue != value {
            withAnimation(DSAnimation.interactive) { value = newValue }
        }
        fireHaptics(for: newValue)
    }

    /// One `.rigid` detent on first contact with either bound, and — for a
    /// stepped slider only — a `.selection` tick each time a new notch is
    /// reached. Continuous sliders stay silent between the two ends.
    private func fireHaptics(for newValue: Double) {
        guard haptics else { return }

        let nowAtBound = newValue <= lower + Metrics.boundEpsilon
            || newValue >= upper - Metrics.boundEpsilon
        if nowAtBound, !atBound {
            DSHapticEngine.shared.fire(.rigid)
        }
        atBound = nowAtBound

        if let step {
            let index = Int(((newValue - lower) / step).rounded())
            if index != lastStepIndex {
                lastStepIndex = index
                // The bound already fired its firmer detent this frame; don't
                // stack a selection tick on top of it.
                if !nowAtBound {
                    DSHapticEngine.shared.fire(.selection)
                }
            }
        }
    }

    /// Used by the VoiceOver adjustable action — snaps, clamps and ticks.
    private func commit(_ raw: Double) {
        let newValue = clamp(snapped(raw))
        guard newValue != value else { return }
        withAnimation(DSAnimation.springSnappy) { value = newValue }
        if haptics { DSHapticEngine.shared.fire(.selection) }
    }

    // MARK: Derived Geometry

    private var lower: Double { bounds.lowerBound }
    private var upper: Double { bounds.upperBound }
    private var span: Double { max(upper - lower, 0) }

    /// Value position in `0...1`, clamped — the single source for both the fill
    /// width and the knob offset, so they can never disagree.
    private var fraction: Double {
        span > 0 ? min(max((value - lower) / span, 0), 1) : 0
    }

    /// Knob travel from the leading edge: from flush-leading to flush-trailing.
    private var knobOffset: CGFloat {
        guard trackWidth > Metrics.knobDiameter else { return 0 }
        return CGFloat(fraction) * (trackWidth - Metrics.knobDiameter)
    }

    /// Accent fill ends at the knob's centre, so the opaque knob caps it.
    private var fillWidth: CGFloat {
        guard trackWidth > 0 else { return 0 }
        return min(trackWidth, knobOffset + Metrics.knobDiameter / 2)
    }

    /// Touch x → raw (unsnapped) value, clamped into bounds. The usable travel is
    /// inset by the knob radius at each end so the finger and the knob centre agree.
    private func rawValue(atX x: CGFloat) -> Double {
        let usable = trackWidth - Metrics.knobDiameter
        guard usable > 0, span > 0 else { return lower }
        let frac = Double((x - Metrics.knobDiameter / 2) / usable)
        return lower + min(max(frac, 0), 1) * span
    }

    private func snapped(_ raw: Double) -> Double {
        guard let step else { return raw }
        return lower + (((raw - lower) / step).rounded() * step)
    }

    private func clamp(_ newValue: Double) -> Double {
        min(max(newValue, lower), upper)
    }

    // MARK: Accessibility

    /// A percentage reads naturally for the default continuous `0...1`; any other
    /// configuration reads the raw value.
    private var accessibilityValueText: String {
        if bounds == 0...1, step == nil {
            return "\(Int((value * 100).rounded())) percent"
        }
        return formatted(value)
    }

    private func formatted(_ newValue: Double) -> String {
        newValue == newValue.rounded() ? String(Int(newValue)) : String(format: "%.2f", newValue)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSliderPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var volume: Double = 0.6
    @State private var brightness: Double = 0.35
    @State private var price: Double = 150
    @State private var opacity: Double = 0.8
    @State private var locked: Double = 0.5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        row("Volume", value: "\(Int(volume * 100))%") {
                            DSSlider(value: $volume)
                        }
                        row("Brightness", value: "\(Int(brightness * 100))%") {
                            HStack(spacing: DSSpacing.sm) {
                                Image(systemName: "sun.min")
                                    .foregroundStyle(DSColors.textSecondary)
                                DSSlider(value: $brightness)
                                Image(systemName: "sun.max.fill")
                                    .foregroundStyle(DSColors.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        row("Max price — snaps in 25s", value: "$\(Int(price))") {
                            DSSlider(value: $price, in: 0...500, step: 25)
                        }
                        row("Opacity — custom accent", value: String(format: "%.2f", opacity)) {
                            DSSlider(value: $opacity, accent: DSColors.secondary)
                        }
                        row("Disabled", value: "50%") {
                            DSSlider(value: $locked)
                                .disabled(true)
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

    private func row(
        _ title: String,
        value: String,
        @ViewBuilder control: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack {
                Text(title).ds(.footnote, color: DSColors.textSecondary)
                Spacer()
                Text(value).ds(.numeric, color: DSColors.textPrimary)
            }
            control()
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
