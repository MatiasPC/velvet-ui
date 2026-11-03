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
    /// Same dim `DSToggle` uses when disabled.
    static let disabledOpacity: Double = 0.5
}

// MARK: - Scale

/// The value mapping behind `DSSlider`: a range, an optional step, and the
/// conversions between a value, its position along the track and a touch.
/// Pure and free of view state, so the clamping, snapping and travel maths can
/// be unit-tested without rendering anything.
struct DSSliderScale: Equatable {
    let bounds: ClosedRange<Double>
    /// Notch spacing, or `nil` for a continuous slider. Normalised at init: a
    /// non-positive or non-finite step means "continuous".
    let step: Double?

    init(bounds: ClosedRange<Double>, step: Double? = nil) {
        self.bounds = bounds
        if let step, step.isFinite, step > 0 {
            self.step = step
        } else {
            self.step = nil
        }
    }

    var lower: Double { bounds.lowerBound }
    var upper: Double { bounds.upperBound }

    /// Width of the range. 0 for a single-value range (and for an unbounded one,
    /// which the slider can't draw).
    var span: Double {
        let width = upper - lower
        return width.isFinite && width > 0 ? width : 0
    }

    /// Slack for float comparisons, relative to the range so tiny ranges work.
    private var tolerance: Double { (span > 0 ? span : 1) * 1e-9 }

    // MARK: Value

    /// `value` limited to `bounds`. NaN falls back to the lower bound.
    func clamped(_ value: Double) -> Double {
        guard !value.isNaN else { return lower }
        return min(max(value, lower), upper)
    }

    /// The nearest notch to `value`, clamped into `bounds`. Notches sit at
    /// `lower + k × step`, and the upper bound is always one more, even when
    /// `step` doesn't divide the span (`0...10` by `3`: 0 3 6 9 10) — so the far
    /// end of the track is always reachable, as with `DSStepper`.
    /// Continuous scales only clamp.
    func snapped(_ value: Double) -> Double {
        let value = clamped(value)
        guard let step else { return value }
        let notch = lower + ((value - lower) / step).rounded() * step
        guard notch < upper - tolerance else { return upper }
        return abs(upper - value) < abs(notch - value) ? upper : notch
    }

    /// The next value after `value` in `direction` (+1 up, −1 down): the next
    /// notch for a stepped scale, a tenth of the span for a continuous one.
    /// Always lands in `bounds`; at a bound it stays put.
    func adjusted(_ value: Double, direction: Int) -> Double {
        let value = clamped(value)
        let sign: Double = direction >= 0 ? 1 : -1
        guard let step else { return clamped(value + sign * span / 10) }
        let position = (value - lower) / step
        // `±tolerance` so a value already on a notch moves to the *next* one.
        let index = sign > 0 ? (position + 1e-9).rounded(.down) + 1 : (position - 1e-9).rounded(.up) - 1
        return snapped(lower + index * step)
    }

    func isAtBound(_ value: Double) -> Bool {
        value <= lower + tolerance || value >= upper - tolerance
    }

    /// Whether two values are the same notch/position for feedback purposes.
    func isSame(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) <= tolerance
    }

    // MARK: Position

    /// Where `value` sits along the range, `0...1`. 0 for a single-value range.
    func fraction(of value: Double) -> Double {
        guard span > 0 else { return 0 }
        return (clamped(value) - lower) / span
    }

    /// The (snapped, clamped) value `fraction` of the way along the range.
    func value(atFraction fraction: Double) -> Double {
        let fraction = fraction.isNaN ? 0 : min(max(fraction, 0), 1)
        return snapped(lower + fraction * span)
    }

    /// The value under a touch at `x`. The knob's centre travels the track
    /// *inset* by the knob radius at both ends, so the same inset is removed
    /// here and finger and knob centre agree at 0 and at 1. `nil` while the
    /// track is too narrow (or not measured yet) to map anything.
    func value(atX x: CGFloat, trackWidth: CGFloat, knobDiameter: CGFloat) -> Double? {
        let travel = trackWidth - knobDiameter
        guard travel > 0 else { return nil }
        return value(atFraction: Double((x - knobDiameter / 2) / travel))
    }

    // MARK: VoiceOver

    /// What VoiceOver reads: a percentage for the default `0...1` continuous
    /// slider, otherwise the value itself, with just as many decimals as the
    /// step needs (two for a continuous slider).
    func accessibilityValue(_ value: Double, locale: Locale = .current) -> String {
        let value = clamped(value)
        if bounds == 0...1, step == nil {
            return "\(Int((value * 100).rounded())) percent"
        }
        return value.formatted(
            .number.precision(.fractionLength(0...fractionDigits)).locale(locale)
        )
    }

    private var fractionDigits: Int {
        guard var remainder = step else { return 2 }
        var digits = 0
        while digits < 6, abs(remainder - remainder.rounded()) > 1e-9 {
            remainder *= 10
            digits += 1
        }
        return digits
    }
}

// MARK: - DSSlider

/// A continuous slider bound to a `Double`.
///
///     DSSlider(value: $volume)                       // 0...1 continuous
///     DSSlider(value: $price, in: 0...500, step: 25) // snaps in 25s, ticks each
///     DSSlider(value: $opacity, in: 0...1, accent: DSColors.secondary)
///
/// Pass `step` for a notched slider (each notch fires a `.selection` tick) or
/// leave it `nil` for a smooth value. The control draws no value label of its
/// own — show a visible read-out alongside it when you need one, the way
/// `DSRating`'s call sites do. VoiceOver reads the value and adjusts it with
/// swipe up and down.
public struct DSSlider: View {

    // MARK: Configuration

    @Binding private var value: Double
    private let scale: DSSliderScale
    private let accent: Color?
    private let haptics: Bool

    // MARK: State

    /// Measured track width, used to map between touch position and value.
    @State private var trackWidth: CGFloat = 0
    /// Whether the finger currently owns the knob (drives the lift + halo).
    /// A `GestureState` so it also clears when the system cancels the touch.
    @GestureState private var isDragging = false
    /// Whether this drag's feedback bookkeeping has been set up.
    @State private var isTracking = false
    /// Whether the value is resting against a bound, so the end detent fires once.
    @State private var atBound = false
    /// The last notch felt, so a stepped slider ticks once per notch crossed.
    @State private var lastNotch: Double?

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @DSThemed private var theme

    // MARK: Init

    /// - Parameters:
    ///   - value: The bound value. It is kept inside `bounds`: an out-of-range
    ///     value is clamped (and written back) as soon as the slider sees it.
    ///   - bounds: The allowed range. Defaults to `0...1`.
    ///   - step: Snap increment, measured from the lower bound. `nil` (default)
    ///     is continuous; a non-positive value is treated as continuous. The upper
    ///     bound is always reachable, even when `step` doesn't divide the range.
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
        self.scale = DSSliderScale(bounds: bounds, step: step)
        self.accent = accent
        self.haptics = haptics
    }

    // MARK: Body

    public var body: some View {
        let resolvedAccent = accent ?? theme.accent

        ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(trackFill)
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
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
        .onAppear { normalize() }
        .onChange(of: value) { normalize() }
        .onChange(of: scale) { normalize() }
        .onChange(of: isDragging) { _, dragging in
            if !dragging { endTracking() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slider")
        .accessibilityValue(scale.accessibilityValue(value))
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            switch direction {
            case .increment: commit(scale.adjusted(value, direction: 1))
            case .decrement: commit(scale.adjusted(value, direction: -1))
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
            .animation(motion(DSAnimation.springSnappy), value: isDragging)
    }

    /// The unfilled track. On a backdrop it is the glass wash, which reads as a
    /// frosted channel. On a plain screen `subtleFill` is `backgroundSecondary`,
    /// close to white and almost invisible as an 8pt line, so it takes the same
    /// neutral `DSToggle`'s off track and `DSLinearProgress` use.
    private var trackFill: Color {
        theme.onBackdrop ? theme.subtleFill : theme.palette.border
    }

    /// The grab lift is decorative — pinned at rest under Reduce Motion.
    private var knobScale: CGFloat {
        isDragging && !reduceMotion ? Metrics.grabScale : 1
    }

    /// `animation`, or none under Reduce Motion: the value still moves, it just
    /// moves exactly with the finger instead of springing after it.
    private func motion(_ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { gesture in
                guard isEnabled else { return }
                if !isTracking { beginTracking() }
                update(toX: gesture.location.x)
            }
            .onEnded { _ in endTracking() }
    }

    /// Seeds the feedback state from where the knob is *now*, so touching down
    /// on the notch (or the end) it already rests on doesn't tick.
    private func beginTracking() {
        isTracking = true
        let current = scale.clamped(value)
        atBound = scale.isAtBound(current)
        lastNotch = scale.snapped(current)
    }

    private func endTracking() {
        isTracking = false
        atBound = false
        lastNotch = nil
    }

    /// Map a touch position to a (snapped, clamped) value, move there, and fire
    /// whatever tactile feedback the move earned.
    private func update(toX x: CGFloat) {
        guard let newValue = scale.value(atX: x, trackWidth: trackWidth, knobDiameter: Metrics.knobDiameter) else {
            return
        }
        if newValue != value {
            withAnimation(motion(DSAnimation.interactive)) { value = newValue }
        }
        fireHaptics(for: newValue)
    }

    /// One `.rigid` detent on arriving at either bound, and — for a stepped
    /// slider only — a `.selection` tick each time a new notch is reached.
    /// Continuous sliders stay silent between the two ends.
    private func fireHaptics(for newValue: Double) {
        guard haptics else { return }

        let nowAtBound = scale.isAtBound(newValue)
        if nowAtBound, !atBound {
            DSHapticEngine.shared.fire(.rigid)
        }
        atBound = nowAtBound

        guard scale.step != nil else { return }
        if let lastNotch, scale.isSame(lastNotch, newValue) { return }
        lastNotch = newValue
        // The bound already fired its firmer detent this frame; don't stack a
        // selection tick on top of it.
        if !nowAtBound {
            DSHapticEngine.shared.fire(.selection)
        }
    }

    /// The VoiceOver adjustable action: already snapped and clamped by the scale.
    private func commit(_ newValue: Double) {
        guard newValue != value else { return }
        withAnimation(motion(DSAnimation.springSnappy)) { value = newValue }
        if haptics { DSHapticEngine.shared.fire(.selection) }
    }

    /// Keeps the bound value inside `bounds`, whoever changed it.
    private func normalize() {
        let clamped = scale.clamped(value)
        if clamped != value { value = clamped }
    }

    // MARK: Derived Geometry

    /// Knob travel from the leading edge: from flush-leading to flush-trailing.
    private var knobOffset: CGFloat {
        guard trackWidth > Metrics.knobDiameter else { return 0 }
        return CGFloat(scale.fraction(of: value)) * (trackWidth - Metrics.knobDiameter)
    }

    /// Accent fill ends at the knob's centre, so the opaque knob caps it.
    private var fillWidth: CGFloat {
        guard trackWidth > 0 else { return 0 }
        return min(trackWidth, knobOffset + Metrics.knobDiameter / 2)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSliderPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var volume: Double = 0.6
    @State private var brightness: Double = 0.35
    @State private var price: Double = 150
    @State private var temperature: Double = -2
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
                        row("Temperature — -10...10 by 0.5", value: String(format: "%.1f°", temperature)) {
                            DSSlider(value: $temperature, in: -10...10, step: 0.5)
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
