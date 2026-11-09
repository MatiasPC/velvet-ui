import SwiftUI

// MARK: - Design System Range Slider
// Two knobs on one track, for picking a span rather than a point: a price
// filter, an age range, a time window. DSSlider picks one value; filters need a
// lower *and* an upper bound, and two sliders stacked on top of each other
// don't stop the minimum from passing the maximum.
//
// It is DSSlider's sibling and shares its mapping (`DSSliderScale`) and its
// look: the slim wash track, an accent fill that now runs *between* the knobs,
// and white knobs that lift and glow under the finger. A touch picks the
// nearest knob and keeps it for the whole drag, so the knobs never swap
// identities mid-gesture; a tap on the track moves the nearer knob there.
// `minimumDistance` keeps a gap between them (a price window of at least $50).
//
// Haptics follow DSSlider: a `.selection` tick per notch on a stepped slider,
// and one firm `.rigid` detent the moment the moving knob arrives at its
// limit — either end of the track, or the gap to the other knob. Under Reduce
// Motion the grab lift rests and the knobs follow the finger without a spring.
//
// Technique: the standard two-thumb pattern (one DragGesture over the whole
// track, nearest-thumb hit testing on touch-down), as in the SwiftUI community's
// range-slider write-ups (e.g. Sarunw's custom slider posts and
// spacenation/swiftui-sliders). Original implementation.

// MARK: - Metrics

/// The same sizes as `DSSlider`, from the spacing scale.
private enum Metrics {
    /// Slim track. DSSpacing.xs (8).
    static let trackHeight: CGFloat = DSSpacing.xs
    /// Knob diameter: 24 + 4 = 28.
    static let knobDiameter: CGFloat = DSSpacing.xl + DSSpacing.xxs
    /// Apple's 44pt minimum tap target: 32 + 12.
    static let hitTarget: CGFloat = DSSpacing.xxl + DSSpacing.sm
    /// How far the halo extends past the knob while grabbed.
    static let haloScale: CGFloat = 1.3
    /// Knob lift while the finger owns it.
    static let grabScale: CGFloat = 1.12
    /// Same dim `DSSlider` and `DSToggle` use when disabled.
    static let disabledOpacity: Double = 0.5
}

// MARK: - Thumb

/// One of the two knobs of a `DSRangeSlider`.
enum DSRangeThumb: Hashable, Sendable {
    case lower, upper
}

// MARK: - Logic

/// The rules behind `DSRangeSlider`: keep the range inside the bounds, on the
/// notches and at least `minimumDistance` wide; decide which knob a touch
/// grabs; move one knob without letting it pass the other. Pure, so it is
/// unit-tested without rendering.
struct DSRangeSliderLogic: Equatable {
    let scale: DSSliderScale
    /// The smallest allowed `upper − lower`. Normalised at init: negative or
    /// non-finite is 0, and it never exceeds the span.
    let minimumDistance: Double

    init(bounds: ClosedRange<Double>, step: Double? = nil, minimumDistance: Double = 0) {
        let scale = DSSliderScale(bounds: bounds, step: step)
        self.scale = scale
        if minimumDistance.isFinite, minimumDistance > 0 {
            self.minimumDistance = min(minimumDistance, scale.span)
        } else {
            self.minimumDistance = 0
        }
    }

    private var lower: Double { scale.lower }
    private var upper: Double { scale.upper }

    /// Slack for float comparisons, relative to the span.
    private var tolerance: Double { (scale.span > 0 ? scale.span : 1) * 1e-9 }

    // MARK: Notches

    /// The smallest notch at or above `value` (clamped into the bounds).
    func notch(atOrAbove value: Double) -> Double {
        let snapped = scale.snapped(value)
        return snapped < value - tolerance ? scale.adjusted(snapped, direction: 1) : snapped
    }

    /// The largest notch at or below `value` (clamped into the bounds).
    func notch(atOrBelow value: Double) -> Double {
        let snapped = scale.snapped(value)
        return snapped > value + tolerance ? scale.adjusted(snapped, direction: -1) : snapped
    }

    // MARK: Range

    /// `range` clamped into the bounds, snapped to the notches and widened to
    /// at least `minimumDistance`: the upper end moves up when there is room,
    /// otherwise the range is pinned to the top of the track.
    func normalized(_ range: ClosedRange<Double>) -> ClosedRange<Double> {
        var low = scale.snapped(range.lowerBound)
        var high = scale.snapped(range.upperBound)
        if high < low { swap(&low, &high) }
        if high - low < minimumDistance - tolerance {
            let wanted = low + minimumDistance
            if wanted <= upper + tolerance {
                high = notch(atOrAbove: wanted)
            } else {
                high = upper
                low = notch(atOrBelow: upper - minimumDistance)
            }
        }
        return low...max(low, high)
    }

    /// Where `thumb` may travel while the other knob stays put.
    func limits(for thumb: DSRangeThumb, in range: ClosedRange<Double>) -> ClosedRange<Double> {
        let range = normalized(range)
        switch thumb {
        case .lower:
            return lower...max(lower, notch(atOrBelow: range.upperBound - minimumDistance))
        case .upper:
            return min(upper, notch(atOrAbove: range.lowerBound + minimumDistance))...upper
        }
    }

    func value(of thumb: DSRangeThumb, in range: ClosedRange<Double>) -> Double {
        thumb == .lower ? range.lowerBound : range.upperBound
    }

    /// The range after moving `thumb` toward `target`: snapped, then stopped at
    /// the bounds and at the gap to the other knob. The other end never moves.
    func moving(_ thumb: DSRangeThumb, to target: Double, in range: ClosedRange<Double>) -> ClosedRange<Double> {
        let range = normalized(range)
        let travel = limits(for: thumb, in: range)
        let stopped = min(max(scale.snapped(target), travel.lowerBound), travel.upperBound)
        switch thumb {
        case .lower: return stopped...range.upperBound
        case .upper: return range.lowerBound...stopped
        }
    }

    /// The VoiceOver adjustable action: one notch (or a tenth of the span for a
    /// continuous slider) in `direction`, stopped like a drag.
    func adjusted(_ thumb: DSRangeThumb, direction: Int, in range: ClosedRange<Double>) -> ClosedRange<Double> {
        let range = normalized(range)
        return moving(thumb, to: scale.adjusted(value(of: thumb, in: range), direction: direction), in: range)
    }

    /// Whether `thumb` rests against either end of its travel, so a drag fires
    /// its detent once on arrival.
    func isAtLimit(_ thumb: DSRangeThumb, in range: ClosedRange<Double>) -> Bool {
        let range = normalized(range)
        let travel = limits(for: thumb, in: range)
        let current = value(of: thumb, in: range)
        return current <= travel.lowerBound + tolerance || current >= travel.upperBound - tolerance
    }

    // MARK: Touch

    /// The unsnapped value under a touch at `x`, with the same knob-radius inset
    /// `DSSlider` uses. `nil` until the track is wide enough to map anything.
    func value(atX x: CGFloat, trackWidth: CGFloat, knobDiameter: CGFloat) -> Double? {
        let travel = trackWidth - knobDiameter
        guard travel > 0 else { return nil }
        let fraction = min(max(Double((x - knobDiameter / 2) / travel), 0), 1)
        return lower + fraction * scale.span
    }

    /// The knob a touch at `value` grabs: the nearer one. When the knobs sit on
    /// top of each other, the side of the touch decides, and at the top of the
    /// track the lower knob is the one that can still move.
    func thumb(nearest value: Double, in range: ClosedRange<Double>) -> DSRangeThumb {
        let range = normalized(range)
        let toLower = abs(value - range.lowerBound)
        let toUpper = abs(value - range.upperBound)
        if abs(toLower - toUpper) <= tolerance {
            if value > range.upperBound + tolerance { return .upper }
            if value < range.lowerBound - tolerance { return .lower }
            return range.upperBound >= upper - tolerance ? .lower : .upper
        }
        return toLower < toUpper ? .lower : .upper
    }
}

// MARK: - Feedback

/// The haptic bookkeeping for one drag: a `.rigid` detent on arriving at a
/// limit and, for a stepped slider, a `.selection` tick per new notch. Never
/// both on the same move.
struct DSRangeSliderFeedback: Equatable {
    private(set) var atLimit = false
    private(set) var lastValue: Double?

    /// Seeds the state from where the knob is at touch-down, so grabbing a knob
    /// that already rests on a notch or a limit is silent.
    mutating func begin(value: Double, atLimit: Bool) {
        self.atLimit = atLimit
        lastValue = value
    }

    /// The haptic a move to `value` earned, if any.
    mutating func haptic(for value: Double, atLimit nowAtLimit: Bool, stepped: Bool) -> DSHapticStyle? {
        let arrived = nowAtLimit && !atLimit
        atLimit = nowAtLimit
        let newNotch = stepped && lastValue != value
        lastValue = value
        if arrived { return .rigid }
        return newNotch ? .selection : nil
    }
}

// MARK: - DSRangeSlider

/// A two-knob slider bound to a `ClosedRange<Double>`.
///
///     DSRangeSlider(range: $price, in: 0...500, step: 25)
///     DSRangeSlider(range: $hours, in: 0...24, step: 1, minimumDistance: 2)
///
/// The knobs never cross, and with `minimumDistance` they keep a gap. Pass
/// `step` for notches (each fires a `.selection` tick) or leave it `nil` for a
/// smooth range. The control draws no values: show a read-out beside it.
/// VoiceOver finds two adjustable knobs, "Minimum" and "Maximum".
public struct DSRangeSlider: View {

    // MARK: Configuration

    @Binding private var range: ClosedRange<Double>
    private let logic: DSRangeSliderLogic
    private let accent: Color?

    // MARK: State

    @State private var trackWidth: CGFloat = 0
    /// The knob this drag owns; picked once, on touch-down.
    @State private var activeThumb: DSRangeThumb?
    @State private var feedback = DSRangeSliderFeedback()
    /// Clears when the system cancels the touch, too.
    @GestureState private var isDragging = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @DSThemed private var theme

    // MARK: Init

    /// - Parameters:
    ///   - range: The selected span. It is kept inside `bounds`, on the notches
    ///     and at least `minimumDistance` wide; a value that breaks those rules
    ///     is corrected and written back as soon as the slider sees it.
    ///   - bounds: The allowed values. Defaults to `0...1`.
    ///   - step: Snap increment, measured from the lower bound. `nil` (default)
    ///     is continuous. The upper bound is always reachable.
    ///   - minimumDistance: The smallest allowed width of the range. Defaults to
    ///     0, which lets the knobs meet. Capped at the width of `bounds`.
    ///   - accent: Fill between the knobs. Defaults to the theme accent.
    public init(
        range: Binding<ClosedRange<Double>>,
        in bounds: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        minimumDistance: Double = 0,
        accent: Color? = nil
    ) {
        self._range = range
        self.logic = DSRangeSliderLogic(bounds: bounds, step: step, minimumDistance: minimumDistance)
        self.accent = accent
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
                .frame(width: max(0, offset(of: .upper) - offset(of: .lower)), height: Metrics.trackHeight)
                .padding(.leading, offset(of: .lower) + Metrics.knobDiameter / 2)

            knob(.lower, accent: resolvedAccent)
                .zIndex(activeThumb == .lower ? 2 : 0)
            knob(.upper, accent: resolvedAccent)
                .zIndex(1)
        }
        .frame(height: Metrics.hitTarget)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { trackWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newValue in trackWidth = newValue }
            }
        }
        .contentShape(Rectangle())
        .gesture(dragGesture, including: isEnabled ? .all : .none)
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
        .onAppear { normalize() }
        .onChange(of: range) { normalize() }
        .onChange(of: logic) { normalize() }
        .onChange(of: isDragging) { _, dragging in
            if !dragging { activeThumb = nil }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Knob

    /// A knob, placed by leading padding (not `offset`) so its accessibility
    /// frame sits where it is drawn.
    private func knob(_ thumb: DSRangeThumb, accent: Color) -> some View {
        let isActive = isDragging && activeThumb == thumb
        return Circle()
            .fill(theme.palette.textOnPrimary)
            .frame(width: Metrics.knobDiameter, height: Metrics.knobDiameter)
            .overlay {
                // DSSlider's grab halo: opacity only, so it stays under Reduce Motion.
                Circle()
                    .stroke(accent.opacity(isActive ? DSWash.focusOpacity : 0), lineWidth: DSWash.focusWidth)
                    .blur(radius: DSWash.focusBlur)
                    .scaleEffect(Metrics.haloScale)
                    .allowsHitTesting(false)
                    .animation(DSAnimation.micro, value: isActive)
            }
            .scaleEffect(isActive && !reduceMotion ? Metrics.grabScale : 1)
            .dsShadow(.sm)
            .animation(motion(DSAnimation.springSnappy), value: isActive)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(thumb == .lower ? "Minimum" : "Maximum")
            .accessibilityValue(logic.scale.accessibilityValue(logic.value(of: thumb, in: range)))
            .accessibilityAdjustableAction { direction in
                guard isEnabled else { return }
                switch direction {
                case .increment: commit(logic.adjusted(thumb, direction: 1, in: range))
                case .decrement: commit(logic.adjusted(thumb, direction: -1, in: range))
                @unknown default: break
                }
            }
            .padding(.leading, offset(of: thumb))
    }

    /// The glass wash on a backdrop, DSSlider's neutral grey on a plain screen.
    private var trackFill: Color {
        theme.onBackdrop ? theme.subtleFill : theme.palette.border
    }

    private func motion(_ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { gesture in
                guard isEnabled,
                      let target = logic.value(atX: gesture.location.x, trackWidth: trackWidth, knobDiameter: Metrics.knobDiameter)
                else { return }
                let thumb: DSRangeThumb
                if let activeThumb {
                    thumb = activeThumb
                } else {
                    thumb = logic.thumb(nearest: target, in: range)
                    activeThumb = thumb
                    feedback.begin(value: logic.value(of: thumb, in: range), atLimit: logic.isAtLimit(thumb, in: range))
                }
                move(thumb, to: target)
            }
            .onEnded { _ in activeThumb = nil }
    }

    /// Moves the dragged knob and fires whatever the move earned.
    private func move(_ thumb: DSRangeThumb, to target: Double) {
        let newRange = logic.moving(thumb, to: target, in: range)
        if newRange != range {
            withAnimation(motion(DSAnimation.interactive)) { range = newRange }
        }
        let style = feedback.haptic(
            for: logic.value(of: thumb, in: newRange),
            atLimit: logic.isAtLimit(thumb, in: newRange),
            stepped: logic.scale.step != nil
        )
        if let style { DSHapticEngine.shared.fire(style) }
    }

    /// The VoiceOver adjustable action, already stopped at the limits.
    private func commit(_ newRange: ClosedRange<Double>) {
        guard newRange != range else { return }
        withAnimation(motion(DSAnimation.springSnappy)) { range = newRange }
        DSHapticEngine.shared.fire(.selection)
    }

    /// Keeps the bound range valid, whoever changed it.
    private func normalize() {
        let normalized = logic.normalized(range)
        if normalized != range { range = normalized }
    }

    // MARK: Geometry

    /// A knob's leading edge: flush-leading at the lower bound, flush-trailing at the upper.
    private func offset(of thumb: DSRangeThumb) -> CGFloat {
        guard trackWidth > Metrics.knobDiameter else { return 0 }
        let fraction = logic.scale.fraction(of: logic.value(of: thumb, in: range))
        return CGFloat(fraction) * (trackWidth - Metrics.knobDiameter)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSRangeSliderPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var price: ClosedRange<Double> = 100...400
    @State private var hours: ClosedRange<Double> = 9...17
    @State private var level: ClosedRange<Double> = 0.2...0.7

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        row("Price", value: "$\(Int(price.lowerBound)) – $\(Int(price.upperBound))") {
                            DSRangeSlider(range: $price, in: 0...500, step: 25, minimumDistance: 50)
                        }
                        row("Open hours — at least 2", value: "\(Int(hours.lowerBound)):00 – \(Int(hours.upperBound)):00") {
                            DSRangeSlider(range: $hours, in: 0...24, step: 1, minimumDistance: 2)
                        }
                        row("Continuous, custom accent", value: String(format: "%.2f – %.2f", level.lowerBound, level.upperBound)) {
                            DSRangeSlider(range: $level, accent: DSColors.secondary)
                        }
                        row("Disabled", value: "") {
                            DSRangeSlider(range: $level).disabled(true)
                        }
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func row(_ title: String, value: String, @ViewBuilder control: () -> some View) -> some View {
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

#Preview("Range Slider — Light") {
    DSRangeSliderPreviewHost().preferredColorScheme(.light)
}

#Preview("Range Slider — Dark") {
    DSRangeSliderPreviewHost().preferredColorScheme(.dark)
}
#endif
