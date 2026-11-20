import SwiftUI

// MARK: - Design System Circular Slider
// A value on a dial: a thermostat, a sleep timer, a volume knob, a daily goal.
// DSSlider covers a straight track; a dial is what people expect when the value
// is the hero of the screen and its read-out sits in the middle. The stock
// controls have no dial at all.
//
// The arc is 270°, open at the bottom like a thermostat: it starts at the
// lower left (135°, measured clockwise from 3 o'clock) and runs clockwise over
// the top to the lower right. A touch on the ring moves the knob to the touch's
// angle; the centre is left to the content (a read-out, a unit, a button).
// Dragging into the open gap holds the knob at the end it came from, and it
// never jumps across the gap to the other end: to go from the maximum back to
// the minimum you sweep back over the top, as on a real dial.
//
// Track, fill and knob are DSSlider's, bent into a ring: a slim wash track, an
// accent fill trailing the knob, a white knob that lifts and lights up under the
// finger. Haptics are DSSlider's too: a `.selection` tick per notch on a stepped
// dial, one `.rigid` detent on arriving at either end, silence in between.
//
// Technique: the classic angle-from-`atan2` circular slider (SwiftUI Lab,
// Kavsoft "Circular slider"), with the arc drawn as `Circle().trim` +
// `rotationEffect` so the fill and the knob animate along the arc together.

// MARK: - Metrics

/// Sizes derived from the spacing scale — no raw CGFloat literals in the body.
private enum Metrics {
    /// Track thickness: a touch heavier than DSSlider's 8 pt, since a dial is
    /// usually the largest thing on its screen. DSSpacing.sm (12).
    static let trackWidth: CGFloat = DSSpacing.sm
    /// Knob diameter, the same 28 pt as DSSlider: DSSpacing.xl (24) + xxs (4).
    static let knobDiameter: CGFloat = DSSpacing.xl + DSSpacing.xxs
    /// The arc is inset by the knob's radius so the knob never leaves the frame.
    static let knobRadius: CGFloat = knobDiameter / 2
    /// How far in from the frame the centre content starts: clear of the knob
    /// and the track, plus breathing room.
    static let contentInset: CGFloat = knobDiameter + DSSpacing.sm
    /// How far the halo extends past the knob while grabbed.
    static let haloScale: CGFloat = 1.3
    /// Knob lift while the finger owns it.
    static let grabScale: CGFloat = 1.12
    /// Same dim `DSSlider` and `DSToggle` use when disabled.
    static let disabledOpacity: Double = 0.5
}

// MARK: - Logic

/// The geometry behind `DSCircularSlider`: where on the arc a value sits and
/// which value a touch means. Angles are degrees, clockwise from 3 o'clock, as
/// on screen (y grows downward). Pure and free of view state, so it is unit-tested
/// without rendering; the value mapping itself is `DSSliderScale`'s.
struct DSCircularSliderLogic: Equatable {
    /// Where the arc starts: the lower left.
    static let startAngle: Double = 135
    /// How far the arc runs clockwise. The remaining 90° is the gap at the bottom.
    static let sweep: Double = 270
    /// A drag must *start* at least this far out (× radius), so a touch on the
    /// content in the middle never moves the value.
    static let grabRadius: Double = 0.5
    /// Once a drag owns the knob, closer to the centre than this (× radius) the
    /// angle is too twitchy to follow, so the value holds.
    static let deadRadius: Double = 0.2

    let scale: DSSliderScale

    init(bounds: ClosedRange<Double>, step: Double? = nil) {
        scale = DSSliderScale(bounds: bounds, step: step)
    }

    /// The share of the circle the arc covers, for `Circle().trim(from:to:)`.
    static var arcTrim: Double { sweep / 360 }

    /// The on-screen angle of `fraction` (0 = start, 1 = end) along the arc.
    static func angle(ofFraction fraction: Double) -> Double {
        let fraction = fraction.isNaN ? 0 : min(max(fraction, 0), 1)
        return startAngle + fraction * sweep
    }

    /// The angle of `point` seen from `center`, in `0..<360`.
    static func angle(of point: CGPoint, center: CGPoint) -> Double {
        let degrees = atan2(Double(point.y - center.y), Double(point.x - center.x)) * 180 / .pi
        return normalized(degrees)
    }

    /// Where along the arc `angle` falls, `0...1`.
    ///
    /// - On the arc: the plain fraction, unless it is more than half the arc
    ///   away from `previous`, which only happens by crossing the gap. Then the
    ///   value holds at the end `previous` was nearer to.
    /// - In the gap: the end `previous` was nearer to, so the knob waits at the
    ///   end it came from. With no `previous` (the touch that starts a drag), the
    ///   nearer end of the arc.
    static func fraction(atAngle angle: Double, previous: Double?) -> Double {
        let past = normalized(angle - startAngle)
        if past <= sweep {
            let fraction = past / sweep
            if let previous, abs(fraction - previous) > 0.5 {
                return previous >= 0.5 ? 1 : 0
            }
            return fraction
        }
        if let previous { return previous >= 0.5 ? 1 : 0 }
        // The gap's middle sits halfway between the end of the arc and 360°.
        return past < (sweep + 360) / 2 ? 1 : 0
    }

    /// The (snapped, clamped) value at `fraction` along the arc.
    func value(atFraction fraction: Double) -> Double {
        scale.value(atFraction: fraction)
    }

    /// `degrees` folded into `0..<360`.
    private static func normalized(_ degrees: Double) -> Double {
        let folded = degrees.truncatingRemainder(dividingBy: 360)
        return folded < 0 ? folded + 360 : folded
    }
}

/// One drag across the dial: whether it grabbed the knob, and the fraction it
/// last showed, which is what keeps the knob from jumping across the gap.
struct DSCircularSliderTracker: Equatable {
    enum Phase: Equatable {
        /// No finger down.
        case idle
        /// The drag started on the centre content; it never moves the value.
        case ignoring
        /// The drag owns the knob; the fraction it last showed.
        case tracking(Double)
    }

    private(set) var phase: Phase = .idle

    /// Feeds one touch location. Returns the fraction along the arc to move to,
    /// or `nil` to leave the value where it is.
    mutating func move(to point: CGPoint, center: CGPoint, radius: CGFloat) -> Double? {
        let distance = Double(hypot(point.x - center.x, point.y - center.y))
        let angle = DSCircularSliderLogic.angle(of: point, center: center)
        switch phase {
        case .ignoring:
            return nil
        case .idle:
            guard radius > 0, distance >= DSCircularSliderLogic.grabRadius * Double(radius) else {
                phase = .ignoring
                return nil
            }
            let fraction = DSCircularSliderLogic.fraction(atAngle: angle, previous: nil)
            phase = .tracking(fraction)
            return fraction
        case .tracking(let previous):
            guard distance >= DSCircularSliderLogic.deadRadius * Double(radius) else { return nil }
            let fraction = DSCircularSliderLogic.fraction(atAngle: angle, previous: previous)
            phase = .tracking(fraction)
            return fraction
        }
    }

    /// The finger lifted (or the system cancelled the touch).
    mutating func end() {
        phase = .idle
    }
}

/// The haptic beat, as in `DSSlider`: one `.rigid` detent on arriving at either
/// end, a `.selection` tick per new notch on a stepped dial, never both at once.
struct DSCircularSliderFeedback: Equatable {
    private(set) var atBound = false
    private(set) var lastValue: Double?

    /// Seeds the state from where the knob rests at touch-down, so grabbing it
    /// where it already is stays silent.
    mutating func begin(value: Double, atBound: Bool) {
        self.atBound = atBound
        lastValue = value
    }

    /// The haptic a move to `value` earned, if any.
    mutating func haptic(for value: Double, atBound nowAtBound: Bool, stepped: Bool) -> DSHapticStyle? {
        let arrived = nowAtBound && !atBound
        atBound = nowAtBound
        let newNotch = stepped && lastValue != value
        lastValue = value
        if arrived { return .rigid }
        return newNotch ? .selection : nil
    }

    mutating func reset() {
        atBound = false
        lastValue = nil
    }
}

// MARK: - DSCircularSlider

/// A value on a 270° dial, with your own content in the middle.
///
///     DSCircularSlider(value: $volume)                                    // 0...1
///     DSCircularSlider(value: $temperature, in: 10...30, step: 0.5,
///                      accessibilityLabel: "Temperature") {
///         Text("\(temperature, specifier: "%.1f")°").ds(.displayMedium)
///     }
///
/// Drag anywhere on the ring to move the knob there. The arc is open at the
/// bottom; dragging into the gap holds the knob at the end it came from, and it
/// never jumps across to the other end. The dial is square and fills the width
/// it is offered, so give it a `frame` when it shouldn't. VoiceOver reads the
/// value and adjusts it with swipe up and down.
public struct DSCircularSlider<Content: View>: View {

    // MARK: Configuration

    @Binding private var value: Double
    private let logic: DSCircularSliderLogic
    private let accent: Color?
    private let label: String
    private let content: Content

    // MARK: State

    /// Whether the finger currently owns the dial. A `GestureState` so it also
    /// clears when the system cancels the touch.
    @GestureState private var isDragging = false
    /// Whether this drag grabbed the knob, and where it last was.
    @State private var tracker = DSCircularSliderTracker()
    @State private var feedback = DSCircularSliderFeedback()

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @DSThemed private var theme

    // MARK: Init

    /// - Parameters:
    ///   - value: The bound value. It is kept inside `bounds`: an out-of-range
    ///     value is clamped (and written back) as soon as the dial sees it.
    ///   - bounds: The allowed range. Defaults to `0...1`.
    ///   - step: Snap increment, measured from the lower bound. `nil` (default)
    ///     is continuous; a non-positive value is treated as continuous.
    ///   - accent: Colour of the filled arc. Defaults to the theme accent.
    ///   - accessibilityLabel: What VoiceOver calls the dial. Defaults to "Dial".
    ///   - content: Drawn in the middle of the dial, usually the value's read-out.
    ///     It is not read separately by VoiceOver, which reads the value instead.
    public init(
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        accent: Color? = nil,
        accessibilityLabel: String = "Dial",
        @ViewBuilder content: () -> Content
    ) {
        self._value = value
        self.logic = DSCircularSliderLogic(bounds: bounds, step: step)
        self.accent = accent
        self.label = accessibilityLabel
        self.content = content()
    }

    // MARK: Body

    public var body: some View {
        let resolvedAccent = accent ?? theme.accent
        let fraction = logic.scale.fraction(of: value)

        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let radius = max(side / 2 - Metrics.knobRadius, 0)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                ring(fraction: fraction, radius: radius, accent: resolvedAccent)
                    // A dial turns clockwise in every language.
                    .environment(\.layoutDirection, .leftToRight)

                content
                    .padding(Metrics.contentInset)
                    .frame(width: side, height: side)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(dragGesture(center: center, radius: radius), including: isEnabled ? .all : .none)
        }
        .aspectRatio(1, contentMode: .fit)
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
        .onAppear { normalize() }
        .onChange(of: value) { normalize() }
        .onChange(of: logic) { normalize() }
        .onChange(of: isDragging) { _, dragging in
            if !dragging { endTracking() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(logic.scale.accessibilityValue(value))
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            switch direction {
            case .increment: commit(logic.scale.adjusted(value, direction: 1))
            case .decrement: commit(logic.scale.adjusted(value, direction: -1))
            @unknown default: break
            }
        }
    }

    // MARK: Ring

    @ViewBuilder
    private func ring(fraction: Double, radius: CGFloat, accent: Color) -> some View {
        let diameter = radius * 2
        let start = Angle.degrees(DSCircularSliderLogic.startAngle)
        let stroke = StrokeStyle(lineWidth: Metrics.trackWidth, lineCap: .round)

        ZStack {
            Circle()
                .trim(from: 0, to: DSCircularSliderLogic.arcTrim)
                .stroke(trackFill, style: stroke)
                .rotationEffect(start)
                .frame(width: diameter, height: diameter)

            // A progress arc, not a border: zero-length at the minimum.
            Circle()
                .trim(from: 0, to: DSCircularSliderLogic.arcTrim * fraction)
                .stroke(accent, style: stroke)
                .rotationEffect(start)
                .frame(width: diameter, height: diameter)

            // Laid out at 3 o'clock, then turned to its angle: a rotation
            // animates along the arc, where an x/y offset would cut the chord.
            knob(accent)
                .offset(x: radius)
                .rotationEffect(.degrees(DSCircularSliderLogic.angle(ofFraction: fraction)))
        }
        .animation(motion(DSAnimation.springSnappy), value: isDragging)
    }

    private func knob(_ accent: Color) -> some View {
        Circle()
            .fill(theme.palette.textOnPrimary)
            .frame(width: Metrics.knobDiameter, height: Metrics.knobDiameter)
            .overlay {
                // DSSlider's grab halo: opacity, not motion, so it stays under
                // Reduce Motion.
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
            .scaleEffect(isDragging && !reduceMotion ? Metrics.grabScale : 1)
            .dsShadow(.sm)
    }

    /// The unfilled arc: the frosted wash on a backdrop, DSSlider's neutral
    /// track on a plain screen, where the wash would vanish.
    private var trackFill: Color {
        theme.onBackdrop ? theme.subtleFill : theme.palette.border
    }

    /// `animation`, or none under Reduce Motion: the knob still follows the
    /// finger, it just doesn't spring after it.
    private func motion(_ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }

    // MARK: Gesture

    private func dragGesture(center: CGPoint, radius: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { gesture in
                guard isEnabled else { return }
                let starting = tracker.phase == .idle
                guard let fraction = tracker.move(to: gesture.location, center: center, radius: radius) else {
                    return
                }
                if starting {
                    let current = logic.scale.clamped(value)
                    feedback.begin(value: logic.scale.snapped(current), atBound: logic.scale.isAtBound(current))
                }
                update(to: logic.value(atFraction: fraction))
            }
            .onEnded { _ in endTracking() }
    }

    private func endTracking() {
        tracker.end()
        feedback.reset()
    }

    /// Moves to `newValue` and fires whatever the move earned.
    private func update(to newValue: Double) {
        if newValue != value {
            withAnimation(motion(DSAnimation.interactive)) { value = newValue }
        }
        if let haptic = feedback.haptic(
            for: newValue,
            atBound: logic.scale.isAtBound(newValue),
            stepped: logic.scale.step != nil
        ) {
            DSHapticEngine.shared.fire(haptic)
        }
    }

    /// The VoiceOver adjustable action: already snapped and clamped by the scale.
    private func commit(_ newValue: Double) {
        guard newValue != value else { return }
        withAnimation(motion(DSAnimation.springSnappy)) { value = newValue }
        DSHapticEngine.shared.fire(.selection)
    }

    /// Keeps the bound value inside `bounds`, whoever changed it.
    private func normalize() {
        let clamped = logic.scale.clamped(value)
        if clamped != value { value = clamped }
    }
}

extension DSCircularSlider where Content == EmptyView {
    /// A dial with nothing in the middle. Show the value elsewhere.
    public init(
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        accent: Color? = nil,
        accessibilityLabel: String = "Dial"
    ) {
        self.init(value: value, in: bounds, step: step, accent: accent, accessibilityLabel: accessibilityLabel) {
            EmptyView()
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCircularSliderPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var temperature: Double = 21
    @State private var volume: Double = 0.4
    @State private var minutes: Double = 25

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    DSCircularSlider(value: $temperature, in: 10...30, step: 0.5,
                                     accessibilityLabel: "Temperature") {
                        VStack(spacing: DSSpacing.xxs) {
                            Text(String(format: "%.1f°", temperature)).ds(.displayMedium)
                            Text("Heating to").ds(.footnote, color: DSColors.textSecondary)
                        }
                    }
                    .frame(width: 240, height: 240)
                    .frame(maxWidth: .infinity)
                }

                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSCircularSlider(value: $volume, accessibilityLabel: "Volume") {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(DSColors.textSecondary)
                        }
                        .frame(width: 120, height: 120)

                        DSCircularSlider(value: $minutes, in: 5...60, step: 5,
                                         accent: DSColors.secondary, accessibilityLabel: "Timer") {
                            Text("\(Int(minutes)) min").ds(.numeric)
                        }
                        .frame(width: 120, height: 120)
                    }
                    .frame(maxWidth: .infinity)
                }

                DSCard {
                    DSCircularSlider(value: .constant(0.6))
                        .frame(width: 96, height: 96)
                        .disabled(true)
                        .frame(maxWidth: .infinity)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Circular Slider — Light") {
    DSCircularSliderPreviewHost().preferredColorScheme(.light)
}

#Preview("Circular Slider — Dark") {
    DSCircularSliderPreviewHost().preferredColorScheme(.dark)
}
#endif
