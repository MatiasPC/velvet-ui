import SwiftUI

// MARK: - Design System Slide To Confirm
// "Slide to unlock" turned into a gate for actions a tap is too easy to trigger
// by accident — delete an account, cancel a ride, send a payment. The knob
// tracks the finger, a gradient trail reveals behind it, the label dissolves
// letter by letter, and a cloud of light motes is born around the finger for as
// long as the drag lasts. Crossing 75 % of the travel locks the action in;
// letting go before that snaps the knob back.
//
// A payment needs two things a confirmation does not: the money takes real time
// to move, and it can be refused. So `onConfirm` is `async throws` — the
// control spins while it awaits and reports the outcome by the *colour of the
// motes*, green on success and unchanged on failure. `finish` decides what
// happens after: `.settle` rests in place (the original behaviour), while
// `.morphAndVanish` collapses the pill into a circle and dissolves it, handing
// the screen back to whatever comes next.
//
// Technique inspired by: open-swiftui-animations/SlideToCancelAnimations

// MARK: - DSSlideFinish

/// What the control does once the action resolves.
public enum DSSlideFinish: Sendable {
    /// Stays filled, showing the check and `confirmedLabel`. The default, and
    /// the right choice for a destructive confirmation: the screen does not
    /// change, so the control has to be the record that something happened.
    case settle
    /// The pill collapses to a circle, resolves there, then dissolves — leaving
    /// its layout slot behind. For flows that hand off to a success state.
    case morphAndVanish
}

// MARK: - Metrics

private enum Metrics {
    /// Track height. No token for "56pt" exists, so it's expressed as
    /// DSSpacing.huge (48) + DSSpacing.xs (8) — a comfortable one-hand target.
    static let trackHeight: CGFloat = DSSpacing.huge + DSSpacing.xs
    /// Knob diameter: a circle exactly as tall as the track. It nests into the
    /// pill's rounded ends (equal radii), so no track surface shows above or
    /// below it, and it sits flush against the leading and trailing edges.
    static let knobDiameter: CGFloat = trackHeight
    /// Breathing room so the label never sits flush against the track edge.
    static let labelHorizontalPadding: CGFloat = DSSpacing.lg
    /// Vertical lift applied to a letter as it fades — a subtle "flying away" cue.
    static let letterLiftDistance: CGFloat = DSSpacing.xxs
    /// Fraction of available travel that counts as "confirmed".
    static let confirmThreshold: Double = 0.75
    /// How much faster a letter dissolves than the raw drag progress once past
    /// its own threshold, so the label finishes fading before the drag does.
    /// Tuned by eye — there is no spacing/color token for animation shaping.
    static let letterFadeSharpness: Double = 3

    // MARK: Choreography

    /// Beat after release: the knob reaches the end and the trail fills the
    /// track edge to edge, so the whole control is one solid gradient before
    /// anything collapses.
    static let commitBeat: Duration = .milliseconds(100)
    /// Pill → circle.
    static let collapseBeat: Duration = .milliseconds(250)
    /// Floor on the spinner. Without it a fast (or synchronous) closure flashes
    /// the spinner for one frame, which reads as a glitch rather than as work.
    static let minimumProcessing: Duration = .milliseconds(500)
    /// How long the check is held before the control dissolves.
    static let successBeat: Duration = .milliseconds(500)
    /// Pause on failure before the circle re-opens, so the refusal registers as
    /// its own event instead of looking like the drag simply bounced back.
    static let failureBeat: Duration = .milliseconds(220)
    /// The dissolve itself.
    static let vanishBeat: Duration = .milliseconds(320)
    /// Bloom the circle reaches as it dissolves. It grows rather than shrinks so
    /// it reads as dispersing outward with the exhaled motes, not as retreating.
    static let vanishBloom: CGFloat = 1.15

    // MARK: Haptic texture

    /// Detents felt across the full travel. The drag is 1:1 — no resistance, no
    /// magnet — so texture is what gives the gesture a surface to cross.
    static let hapticTicks: Int = 8
    /// Tick strength from start to threshold. Ramped, so the track feels like it
    /// is tightening under the finger even though nothing physically resists.
    static let hapticIntensity: ClosedRange<CGFloat> = 0.2...0.6
}

// MARK: - Phase

/// The control's position in the confirmation choreography. Everything visual
/// derives from this — there is no second source of truth about what is on
/// screen.
private enum Phase: Equatable {
    case idle
    case dragging
    /// Released above the threshold: filling edge to edge.
    case committing
    /// Pill closing into a circle. `.morphAndVanish` only.
    case collapsing
    /// Awaiting `onConfirm`.
    case processing
    /// The action succeeded; motes have swept green.
    case succeeded
    /// The action threw. Motes stay neutral and the control re-opens.
    case failing
    /// Dissolving. `.morphAndVanish` only.
    case vanishing
    /// Invisible, but still occupying its layout slot.
    case gone
}

// MARK: - DSSlideToConfirm

/// A slide-to-confirm action control — the user drags a knob across a
/// pill-shaped track instead of tapping a button.
///
///     DSSlideToConfirm("Slide to delete account") {
///         deleteAccount()
///     }
///
/// For a payment, let the closure carry the latency and the outcome, and let
/// the control hand off when it resolves:
///
///     DSSlideToConfirm("Slide to pay $42.00", finish: .morphAndVanish) {
///         try await payments.charge(cart)
///     }
///
/// The control does not word its own failure — it reports one by keeping the
/// motes neutral and re-opening so the gesture can be repeated. Telling the
/// user *why* the charge was refused is the parent's job.
public struct DSSlideToConfirm: View {

    // MARK: Configuration

    private let label: String
    private let icon: String
    private let confirmedLabel: String
    private let accent: Color?
    private let finish: DSSlideFinish
    private let onConfirm: () async throws -> Void

    // MARK: State

    /// Knob's current travel distance from the leading edge, in `0...maxOffset`.
    @State private var dragOffset: CGFloat = 0
    /// Measured width of the track. Stable through the collapse: the circle is
    /// made by masking, not by resizing, so this is measured once and stays put.
    @State private var trackWidth: CGFloat = 0
    /// Whether the "crossed the threshold" haptic already fired for this drag.
    @State private var hasFiredThresholdHaptic = false
    /// Index of the last detent felt, so each is felt exactly once per crossing.
    @State private var lastHapticTick: Int = 0
    @State private var phase: Phase = .idle
    /// 0 neutral, 1 success. Animating it sweeps every live mote at once.
    @State private var tintMix: Double = 0
    /// Bumped once to fire the dispersal burst.
    @State private var exhale: Int = 0

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - label: Instruction shown in the track before any drag, e.g. "Slide to pay".
    ///   - icon: SF Symbol shown inside the knob while idle. Defaults to a forward chevron.
    ///   - confirmedLabel: Replaces `label` once a `.settle` action has succeeded.
    ///   - accent: Knob fill color. Defaults to `theme.accent`.
    ///   - finish: What happens after the action resolves. Defaults to `.settle`.
    ///   - onConfirm: The action. The control spins while this runs and treats a
    ///     thrown error as a refusal — it stays neutral and re-opens for a retry.
    ///     Declared `async throws` so a synchronous closure still type-checks:
    ///     existing call sites need no change.
    public init(
        _ label: String,
        icon: String = "chevron.right",
        confirmedLabel: String = "Confirmed",
        accent: Color? = nil,
        finish: DSSlideFinish = .settle,
        onConfirm: @escaping () async throws -> Void
    ) {
        self.label = label
        self.icon = icon
        self.confirmedLabel = confirmedLabel
        self.accent = accent
        self.finish = finish
        self.onConfirm = onConfirm
    }

    // MARK: Body

    public var body: some View {
        let resolvedAccent = accent ?? theme.accent

        ZStack(alignment: .leading) {
            theme.gradient.horizontalGradient
                .mask(alignment: .leading) {
                    // Ends at the knob's centre: the opaque knob caps the trail,
                    // so its leading edge reads as the knob's own circle rather
                    // than a shape trying (and failing) to match it.
                    Rectangle().frame(width: trailWidth)
                }

            labelArea
                .padding(.horizontal, Metrics.labelHorizontalPadding)
                .frame(maxWidth: .infinity)
        }
        .frame(height: Metrics.trackHeight)
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
        .dsSurface(.glassThin, radius: DSRadius.chip)
        .overlay(alignment: .leading) {
            // Sits on top of the pill clip so the knob spans the full track
            // height and its shadow isn't cropped by the surface's rounded edge.
            knob(fill: resolvedAccent)
                .offset(x: dragOffset)
        }
        // The collapse is a mask, not a resize. Nothing underneath reflows —
        // which matters because at this point the control is one solid gradient
        // and any reflow would be visible as the glyphs jumping. A capsule
        // inset from both sides until only `trackHeight` remains *is* a circle,
        // since the pill already carries the capsule radius.
        .mask {
            Capsule().padding(.horizontal, collapseInset)
        }
        .overlay {
            resolution
        }
        .scaleEffect(isDissolving ? Metrics.vanishBloom : 1)
        .opacity(isDissolving ? 0 : 1)
        // Outside the scale and opacity above: the motes disperse into the space
        // the control is vacating, so they must not fade or grow with it.
        .overlay {
            DSParticleField(
                emitter: emitterCentre,
                emitterRadius: Metrics.knobDiameter / 2,
                isEmitting: isEmitting,
                neutralTint: theme.palette.textTertiary,
                successTint: theme.palette.success,
                tintMix: tintMix,
                exhale: exhale
            )
            .padding(-DSParticleField.margin)
        }
        .contentShape(Rectangle())
        .gesture(dragGesture, including: isInteractive ? .all : .none)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityHint("Swipe right to confirm")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            startConfirmation()
        }
    }

    // MARK: Label

    @ViewBuilder
    private var labelArea: some View {
        if phase == .succeeded && finish == .settle {
            Text(confirmedLabel)
                .ds(.button, color: theme.palette.textSecondary)
                .transition(.opacity)
        } else {
            instructionLabel
                // The per-letter dissolve below is paced by the *drag*: each
                // letter waits its turn (`DSAnimation.stagger`, up to `count *
                // 0.05s`) and `letterOpacity` only reaches 0 for a drag taken
                // slowly to the very end. A quick flick past the 75% threshold
                // commits with letters still lit, and the stagger outlasts the
                // ~350ms it takes the pill to mask down to a circle — so the
                // text shows through the morph. Gate it on `phase`, the way
                // `showsKnobGlyph` and `resolution` already are: the moment the
                // choreography starts, the label clears on a fast fade.
                .opacity(showsInstructionLabel ? 1 : 0)
                .animation(DSAnimation.fast, value: showsInstructionLabel)
        }
    }

    @ViewBuilder
    private var instructionLabel: some View {
        if reduceMotion {
            // Reduce Motion: the drag itself still moves the knob and trail —
            // that's the interaction, not decoration — but the per-letter
            // stagger collapses into a single fade of the whole label.
            Text(label)
                .ds(.button, color: theme.palette.textSecondary)
                .opacity(1 - progress)
        } else {
            HStack(spacing: 0) {
                ForEach(Array(label.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .ds(.button, color: theme.palette.textSecondary)
                        .opacity(letterOpacity(at: index))
                        .offset(y: letterLift(at: index))
                        .animation(DSAnimation.stagger(index: index), value: progress)
                }
            }
        }
    }

    // MARK: Knob

    @ViewBuilder
    private func knob(fill: Color) -> some View {
        Circle()
            .fill(fill)
            .frame(width: Metrics.knobDiameter, height: Metrics.knobDiameter)
            .overlay {
                // The glyph is dropped the moment the outcome takes over the
                // centre, so the collapse closes on clean gradient instead of
                // clipping a chevron in half.
                Image(systemName: icon)
                    .dsTextStyle(.title3, color: theme.onAccent)
                    .opacity(showsKnobGlyph ? 1 : 0)
            }
            .dsShadow(.sm)
    }

    // MARK: Resolution

    /// The spinner and the check. Drawn over the mask rather than inside the
    /// knob so it can sit at the centre of the collapsed circle; for `.settle`
    /// there is no collapse, so it is offset back onto the resting knob.
    @ViewBuilder
    private var resolution: some View {
        Group {
            switch phase {
            case .processing:
                ProgressView()
                    .tint(theme.onAccent)
                    .transition(.opacity)
            case .succeeded, .vanishing, .gone:
                Image(systemName: "checkmark")
                    .dsTextStyle(.title3, color: theme.onAccent)
                    .dsPopIn()
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .offset(x: resolutionOffset)
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isInteractive else { return }
                if phase != .dragging { phase = .dragging }
                let clamped = min(max(0, value.translation.width), maxOffset)
                withAnimation(DSAnimation.interactive) {
                    dragOffset = clamped
                }
                fireDragHaptics()
            }
            .onEnded { _ in
                guard isInteractive else { return }
                if progress >= Metrics.confirmThreshold {
                    startConfirmation()
                } else {
                    // Only a real drag earns the snap-back feedback: a plain tap on
                    // the track ends here at offset 0 and must stay silent.
                    if dragOffset > 0 {
                        withAnimation(DSAnimation.springBouncy) {
                            dragOffset = 0
                        }
                        DSHapticEngine.shared.fire(.light)
                    }
                    resetDragHaptics()
                    phase = .idle
                }
            }
    }

    /// A detent strip: one `.soft` tap per tick crossed, ramping in strength
    /// toward the threshold, then the `.rigid` commit tap on top of it.
    private func fireDragHaptics() {
        let crossedThreshold = progress >= Metrics.confirmThreshold
        if crossedThreshold, !hasFiredThresholdHaptic {
            hasFiredThresholdHaptic = true
            lastHapticTick = Metrics.hapticTicks
            DSHapticEngine.shared.fire(.rigid)
            return
        }
        if !crossedThreshold {
            hasFiredThresholdHaptic = false
        }

        let tick = Int(progress * Double(Metrics.hapticTicks))
        guard tick != lastHapticTick else { return }
        lastHapticTick = tick
        guard tick > 0 else { return }

        let span = Metrics.hapticIntensity.upperBound - Metrics.hapticIntensity.lowerBound
        let strength = Metrics.hapticIntensity.lowerBound + span * CGFloat(min(progress, 1))
        DSHapticEngine.shared.fire(.soft, intensity: strength)
    }

    private func resetDragHaptics() {
        hasFiredThresholdHaptic = false
        lastHapticTick = 0
    }

    // MARK: Choreography

    private func startConfirmation() {
        guard isInteractive else { return }
        Task { @MainActor in await runConfirmation() }
    }

    @MainActor
    private func runConfirmation() async {
        withAnimation(DSAnimation.springSmooth) {
            dragOffset = maxOffset
            phase = .committing
        }
        try? await Task.sleep(for: Metrics.commitBeat)

        if finish == .morphAndVanish {
            withAnimation(DSAnimation.springSmooth) { phase = .collapsing }
            try? await Task.sleep(for: Metrics.collapseBeat)
        }

        withAnimation(DSAnimation.fast) { phase = .processing }

        // Run the action first and hold the spinner afterwards, so the floor is
        // a floor and not an added delay: a slow charge is never padded.
        let clock = ContinuousClock()
        let start = clock.now
        var refusal: Error?
        do {
            try await onConfirm()
        } catch {
            refusal = error
        }
        let elapsed = clock.now - start
        if elapsed < Metrics.minimumProcessing {
            try? await Task.sleep(for: Metrics.minimumProcessing - elapsed)
        }

        if refusal == nil {
            await succeed()
        } else {
            await refuse()
        }
    }

    @MainActor
    private func succeed() async {
        DSHapticEngine.shared.fire(.success)
        withAnimation(DSAnimation.springBouncy) {
            phase = .succeeded
            tintMix = 1
        }
        guard finish == .morphAndVanish else { return }

        try? await Task.sleep(for: Metrics.successBeat)
        exhale += 1
        withAnimation(DSAnimation.normal) { phase = .vanishing }
        try? await Task.sleep(for: Metrics.vanishBeat)
        phase = .gone
    }

    /// The refusal. The motes are never tinted, so they thin out in the neutral
    /// they have carried the whole way — the absence of green *is* the message.
    @MainActor
    private func refuse() async {
        DSHapticEngine.shared.fire(.error)
        withAnimation(DSAnimation.fast) { phase = .failing }
        try? await Task.sleep(for: Metrics.failureBeat)
        withAnimation(DSAnimation.springSmooth) {
            phase = .idle
            dragOffset = 0
        }
        resetDragHaptics()
    }

    // MARK: Derived State

    /// The gesture is live only before the choreography takes over.
    private var isInteractive: Bool {
        phase == .idle || phase == .dragging
    }

    /// Motes are born from the first touch until the outcome lands. They have to
    /// outlive the spinner: a mote lives under a second, so a cloud that stopped
    /// at the end of the drag would already be dead by the time there is
    /// anything to turn green.
    private var isEmitting: Bool {
        switch phase {
        case .idle, .failing, .gone: return false
        case .dragging, .committing, .collapsing, .processing, .succeeded, .vanishing: return true
        }
    }

    private var isDissolving: Bool {
        phase == .vanishing || phase == .gone
    }

    /// True from the moment the pill closes until the control is gone.
    private var isCollapsed: Bool {
        guard finish == .morphAndVanish else { return false }
        switch phase {
        case .collapsing, .processing, .succeeded, .vanishing, .gone: return true
        case .idle, .dragging, .committing, .failing: return false
        }
    }

    /// Inset applied to both ends of the mask. At `(trackWidth - trackHeight)/2`
    /// exactly `trackHeight` remains — a capsule as wide as it is tall.
    private var collapseInset: CGFloat {
        guard isCollapsed, trackWidth > Metrics.trackHeight else { return 0 }
        return (trackWidth - Metrics.trackHeight) / 2
    }

    /// The instruction label lives in the pre-commit phases only. Its per-letter
    /// dissolve is paced by the drag and only converges on an unhurried one, so
    /// without this gate a fast commit leaves lit text over the collapsing pill.
    /// Mirrors `showsKnobGlyph`.
    private var showsInstructionLabel: Bool {
        phase == .idle || phase == .dragging
    }

    /// The knob keeps its chevron until the outcome owns the centre.
    private var showsKnobGlyph: Bool {
        switch phase {
        // `.failing` gets it back: the chevron fades in as the circle re-opens,
        // so the control is visibly ready for another try before the knob has
        // even finished travelling home.
        case .idle, .dragging, .committing, .failing: return true
        case .collapsing, .processing, .succeeded, .vanishing, .gone: return false
        }
    }

    /// `.morphAndVanish` resolves at the centre of the collapsed circle;
    /// `.settle` resolves inside the knob, which is resting at the trailing end.
    private var resolutionOffset: CGFloat {
        finish == .morphAndVanish ? 0 : maxOffset / 2
    }

    /// Where motes are born, in this view's coordinate space: the knob while the
    /// finger owns it, the circle's centre once the collapse has moved it.
    private var emitterCentre: CGPoint {
        let x = isCollapsed
            ? trackWidth / 2
            : dragOffset + Metrics.knobDiameter / 2
        return CGPoint(x: x, y: Metrics.trackHeight / 2)
    }

    // MARK: Derived Geometry

    /// Maximum horizontal distance the knob can travel: from flush-leading to
    /// flush-trailing.
    private var maxOffset: CGFloat {
        max(trackWidth - Metrics.knobDiameter, 0)
    }

    /// Drag progress in `0...1`.
    private var progress: Double {
        maxOffset > 0 ? Double(dragOffset / maxOffset) : 0
    }

    /// Width of the revealed gradient trail. While dragging it stops at the knob's
    /// centre — the opaque knob covers the straight edge and caps the trail with
    /// its own circle. Once committed it fills the whole track: the knob rests
    /// flush against the trailing end, so stopping at its centre would leave the
    /// trailing half of the track unfilled.
    private var trailWidth: CGFloat {
        guard trackWidth > 0 else { return 0 }
        if phase != .idle && phase != .dragging && phase != .failing { return trackWidth }
        return min(trackWidth, dragOffset + Metrics.knobDiameter / 2)
    }

    /// Opacity for the letter at `index`: letters closer to the knob's start
    /// (lower index) cross their fade threshold first as progress increases.
    private func letterOpacity(at index: Int) -> Double {
        let total = Double(max(label.count, 1))
        let threshold = Double(index) / total
        let fade = (progress - threshold) * Metrics.letterFadeSharpness
        return 1 - min(max(fade, 0), 1)
    }

    /// Small upward lift that grows as a letter fades out.
    private func letterLift(at index: Int) -> CGFloat {
        CGFloat(1 - letterOpacity(at: index)) * -Metrics.letterLiftDistance
    }
}

// MARK: - Preview

#if DEBUG
/// One of each: the destructive gate that rests in place, a payment that clears,
/// and a payment that is refused. The two payment rows share a counter so the
/// control can be re-mounted after it vanishes — the documented reset.
private struct DSSlideToConfirmPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var paidAttempt = 0
    @State private var refusedAttempt = 0

    private struct Refused: Error {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Destructive — settles in place").ds(.title3)
                    DSSlideToConfirm(
                        "Slide to cancel ride",
                        icon: "xmark",
                        confirmedLabel: "Cancelled",
                        accent: DSColors.error
                    ) {}
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Payment — clears, then vanishes").ds(.title3)
                    DSSlideToConfirm(
                        "Slide to pay $42.00",
                        confirmedLabel: "Paid",
                        finish: .morphAndVanish
                    ) {
                        try? await Task.sleep(for: .milliseconds(1200))
                    }
                    .id(paidAttempt)

                    DSButton("Reset", variant: .ghost, size: .small) {
                        paidAttempt += 1
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Payment — refused").ds(.title3)
                    DSSlideToConfirm(
                        "Slide to pay $42.00",
                        finish: .morphAndVanish
                    ) {
                        try await Task.sleep(for: .milliseconds(900))
                        throw Refused()
                    }
                    .id(refusedAttempt)

                    Text("Motes stay neutral, the circle re-opens, drag again.")
                        .ds(.caption1, color: DSColors.textSecondary)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Slide to Confirm — Light") {
    DSSlideToConfirmPreviewHost().preferredColorScheme(.light)
}

#Preview("Slide to Confirm — Dark") {
    DSSlideToConfirmPreviewHost().preferredColorScheme(.dark)
}
#endif
