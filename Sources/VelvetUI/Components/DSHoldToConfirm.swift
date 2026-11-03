import SwiftUI

// MARK: - Design System Hold To Confirm
// The companion to DSSlideToConfirm: where a slide gates an action behind a
// deliberate *gesture*, a hold gates it behind deliberate *time*. The user
// presses and keeps a finger down; a ring charges around the pill over
// `duration`; a detent texture tightens under the finger as it fills; and when
// the ring closes the pill fills with the accent and the action runs. Lifting
// early springs the ring back and the action never runs — the commitment has to
// be sustained, not just started.
//
// It speaks the same language as DSSlideToConfirm: `onConfirm` is
// `async throws`, the control spins while it awaits (for at least half a
// second, so a fast closure doesn't flash), a thrown error is a refusal that
// re-opens the control for another try, `confirmedLabel` is what the settled
// state says, and there is no reset API — re-mount with `.id(attempt)`.
//
// It reaches for a different reflex than the slide. A slide is right when the
// risk is "did you mean to touch this at all" (a payment, a destructive button a
// thumb could brush). A hold is right when the risk is "stay with this for a
// moment" — power off, hold-to-record, confirm-and-wait — and when one hand is
// all the user has.
//
// The ring is a progress indicator, not a border: at rest it is `trim` zero, so
// nothing is drawn (Velvet draws no borders). It only exists while the hold is
// charging, the same way `DSCircularProgress` strokes a ring that isn't an edge.

// MARK: - Metrics

private enum Metrics {
    /// 1.2s — long enough to read as a deliberate commitment, short enough not
    /// to feel like a punishment. The default; callers tune it per stakes.
    static let defaultDuration: Double = 1.2
    /// Shortest hold we accept. Anything shorter is just a tap.
    static let minimumDuration: Double = 0.2
    /// Detents felt across the charge. Like `DSSlideToConfirm`, the control adds
    /// no physical resistance, so texture is what gives the hold a surface.
    static let hapticTicks: Int = 6
    /// Tick strength from touch-down to the brink, ramped so the ring feels like
    /// it is tightening under the finger as it closes. The same ramp the slide uses.
    static let hapticIntensity: ClosedRange<CGFloat> = 0.2...0.6
    /// Width of the charging ring. 4pt reads as progress, not as a hairline edge.
    static let ringWidth: CGFloat = DSSpacing.xxs
    /// Half the ring width, so the stroke sits inside the pill instead of
    /// straddling its edge and bleeding past the glass.
    static let ringInset: CGFloat = DSSpacing.xxxs
    /// Floor on the spinner, the same as `DSSlideToConfirm`: a fast (or
    /// synchronous) closure would otherwise flash it for one frame.
    static let minimumProcessing: Duration = .milliseconds(500)
    /// Pause on a refusal before the control re-opens, so it registers as its
    /// own event instead of looking like the hold simply bounced back.
    static let failureBeat: Duration = .milliseconds(220)
    /// Dim applied while disabled — the same as `DSToggle`.
    static let disabledOpacity: Double = 0.5
}

// MARK: - Phase

/// The control's position in the confirmation. Everything visual derives from
/// this — there is no second source of truth about what is on screen.
private enum Phase: Equatable {
    /// At rest. The gesture is live.
    case idle
    /// A finger is down and the ring is charging.
    case holding
    /// The ring closed; awaiting `onConfirm`.
    case processing
    /// The action succeeded; the pill rests filled.
    case succeeded
    /// The action threw; brief beat before the control re-opens.
    case failing
}

// MARK: - DSHoldToConfirm

/// A press-and-hold confirmation control. The user holds the pill until a ring
/// charges all the way around, at which point the action runs.
///
///     DSHoldToConfirm("Hold to delete", icon: "trash", accent: DSColors.error) {
///         try await account.delete()
///     }
///
/// The closure carries the latency and the outcome, as it does for
/// `DSSlideToConfirm`: the control spins while it runs, and a thrown error is a
/// refusal that re-opens it for another try. Telling the user *why* is the
/// parent's job.
///
/// Lifting before the ring closes cancels: the ring springs back and `onConfirm`
/// never runs. Once confirmed the control rests filled, showing a check and
/// `confirmedLabel`; there is no reset API — re-mount with `.id(attempt)` to run
/// it again.
///
/// VoiceOver users can't hold, so the control is also an ordinary button: a
/// double-tap confirms, with no timed hold.
public struct DSHoldToConfirm: View {

    // MARK: Configuration

    private let label: String
    private let icon: String?
    private let confirmedLabel: String
    private let duration: Double
    private let accent: Color?
    private let isFullWidth: Bool
    private let onConfirm: () async throws -> Void

    // MARK: State

    /// Ring fill, `0...1`. Driven by one linear animation while charging and
    /// sprung back to 0 on cancel.
    @State private var progress: CGFloat = 0
    @State private var phase: Phase = .idle
    /// The charge clock. It, not the ring animation, is the source of truth for
    /// when the action fires — a cancelled `Task` throws out of its sleep, so a
    /// lifted finger can never let the confirmation slip through. It covers only
    /// the hold: once the ring closes the action runs in its own task, which a
    /// disappearing view must not cancel half way through a payment.
    @State private var holdTask: Task<Void, Never>?

    @DSThemed private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - label: Instruction shown before and during the hold, e.g. "Hold to delete".
    ///   - icon: SF Symbol shown before the label while idle. `nil` for label only.
    ///   - confirmedLabel: Replaces `label` once the action has succeeded.
    ///   - duration: How long the finger must stay down. Defaults to 1.2s;
    ///     values under 0.2s are raised to 0.2s.
    ///   - accent: Fill and ring color. Defaults to `theme.accent`; pass a status
    ///     color (e.g. `error`) for a destructive hold.
    ///   - isFullWidth: Stretch to the available width. Defaults to `true`.
    ///   - onConfirm: The action. The control spins while this runs and treats a
    ///     thrown error as a refusal — it re-opens for a retry. Declared
    ///     `async throws` so a synchronous closure still type-checks.
    public init(
        _ label: String,
        icon: String? = nil,
        confirmedLabel: String = "Confirmed",
        duration: Double = 1.2,
        accent: Color? = nil,
        isFullWidth: Bool = true,
        onConfirm: @escaping () async throws -> Void
    ) {
        self.label = label
        self.icon = icon
        self.confirmedLabel = confirmedLabel
        self.duration = duration
        self.accent = accent
        self.isFullWidth = isFullWidth
        self.onConfirm = onConfirm
    }

    // MARK: Body

    public var body: some View {
        let resolvedAccent = accent ?? theme.accent

        content
            .padding(.vertical, DSSpacing.md)
            .padding(.horizontal, DSSpacing.lg)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background {
                // The payoff: the whole pill fills accent the instant the ring
                // closes. Behind the content, so it never crosses the label.
                Capsule(style: .continuous)
                    .fill(resolvedAccent)
                    .opacity(isFilled ? 1 : 0)
            }
            .dsSurface(.glassThin, radius: DSRadius.chip)
            .overlay { ring(color: resolvedAccent) }
            .scaleEffect(phase == .holding ? DSPress.scale : 1)
            .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
            .contentShape(Capsule(style: .continuous))
            .gesture(holdGesture, including: isInteractive ? .all : .none)
            .onDisappear { holdTask?.cancel() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint(Self.accessibilityHint)
            .accessibilityValue(Self.accessibilityValue(
                isProcessing: phase == .processing,
                isConfirmed: phase == .succeeded,
                confirmedLabel: confirmedLabel
            ))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { confirmWithoutHolding() }
    }

    // MARK: Content

    /// Every state's content stacked in one `ZStack`, so the pill is as wide as
    /// the widest of them and never resizes as the label changes (it matters when
    /// `isFullWidth` is false).
    private var content: some View {
        ZStack {
            row(icon: icon, text: label)
                .opacity(showsInstruction ? 1 : 0)

            row(icon: "checkmark", text: confirmedLabel)
                .opacity(phase == .succeeded ? 1 : 0)

            if phase == .processing {
                ProgressView()
                    .tint(onFillColor)
                    .transition(.opacity)
            }
        }
        .animation(DSAnimation.fast, value: phase)
    }

    private func row(icon: String?, text: String) -> some View {
        let color = isFilled ? onFillColor : theme.ink
        return HStack(spacing: DSSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .dsTextStyle(.button, color: color)
            }
            Text(text)
                .ds(.button, color: color)
        }
    }

    // MARK: Ring

    /// The charging progress ring. A `trim` of the pill's own capsule, so at rest
    /// (`progress == 0`) it draws nothing — no border. Hidden once the fill takes
    /// over, so it never sits on top of the solid accent.
    private func ring(color: Color) -> some View {
        Capsule(style: .continuous)
            .trim(from: 0, to: progress)
            .stroke(color, style: StrokeStyle(lineWidth: Metrics.ringWidth, lineCap: .round))
            .padding(Metrics.ringInset)
            .opacity(isFilled ? 0 : 1)
            .allowsHitTesting(false)
    }

    // MARK: Gesture

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                // Fires on touch-down and on every micro-move. Guard so the
                // charge begins exactly once per press.
                guard phase == .idle, isEnabled else { return }
                begin()
            }
            .onEnded { _ in
                if phase == .holding { cancel() }
            }
    }

    // MARK: Choreography

    private func begin() {
        // Two transactions on purpose: the press dip is snappy, while the ring
        // charges on its own linear clock over `duration`.
        withAnimation(DSPress.animation) { phase = .holding }
        withAnimation(.linear(duration: effectiveDuration)) { progress = 1 }
        DSHapticEngine.shared.fire(.soft, intensity: Self.touchDownIntensity)
        holdTask = Task { @MainActor in await runHold() }
    }

    /// Sleeps the charge in `hapticTicks` steps, firing a ramped `.soft` detent
    /// at each one; a cancelled `Task` throws out of the sleep and returns before
    /// it can confirm. Completing every step means the finger stayed down the
    /// whole way, so the action runs.
    @MainActor
    private func runHold() async {
        for tick in Self.chargeSchedule(duration: effectiveDuration) {
            do {
                try await Task.sleep(for: .seconds(tick.delay))
            } catch {
                return // cancelled by an early release
            }
            if let intensity = tick.intensity {
                DSHapticEngine.shared.fire(.soft, intensity: intensity)
            }
        }
        holdTask = nil
        startConfirmation()
    }

    private func cancel() {
        holdTask?.cancel()
        holdTask = nil
        DSHapticEngine.shared.fire(.light)
        withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springSmooth) {
            progress = 0
            phase = .idle
        }
    }

    /// VoiceOver path: a single activation confirms without a timed hold, since a
    /// press-and-hold gesture can't be performed under the assistive cursor.
    private func confirmWithoutHolding() {
        guard isEnabled, phase == .idle || phase == .holding else { return }
        holdTask?.cancel()
        holdTask = nil
        startConfirmation()
    }

    private func startConfirmation() {
        Task { @MainActor in await runConfirmation() }
    }

    @MainActor
    private func runConfirmation() async {
        withAnimation(DSAnimation.fast) {
            progress = 1
            phase = .processing
        }

        // Run the action first and hold the spinner afterwards, so the floor is
        // a floor and not an added delay: a slow action is never padded.
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
            DSHapticEngine.shared.fire(.success)
            withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springBouncy) {
                phase = .succeeded
            }
        } else {
            DSHapticEngine.shared.fire(.error)
            withAnimation(DSAnimation.fast) { phase = .failing }
            try? await Task.sleep(for: Metrics.failureBeat)
            withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springSmooth) {
                progress = 0
                phase = .idle
            }
        }
    }

    // MARK: Pure helpers

    static let accessibilityHint = "Double-tap to confirm"

    /// Empty while idle/holding/failing, "Processing" while awaiting the action,
    /// the confirmed label once it succeeded. Same words as `DSSlideToConfirm`.
    static func accessibilityValue(isProcessing: Bool, isConfirmed: Bool, confirmedLabel: String) -> String {
        if isConfirmed { return confirmedLabel }
        return isProcessing ? "Processing" : ""
    }

    /// One step of the charge: wait `delay`, then fire a `.soft` detent at
    /// `intensity`. The last step has no intensity: it hands off to the success
    /// beat instead of ticking.
    struct ChargeStep: Equatable {
        let delay: Double
        let intensity: CGFloat?
    }

    /// The charge split into `hapticTicks` equal steps whose delays sum to the
    /// (clamped) `duration`, with a detent ramping from 0.2 to 0.6 across them.
    static func chargeSchedule(duration: Double) -> [ChargeStep] {
        let total = clampedDuration(duration)
        let ticks = Metrics.hapticTicks
        let range = Metrics.hapticIntensity
        let span = range.upperBound - range.lowerBound
        return (1...ticks).map { tick in
            let fraction = CGFloat(tick) / CGFloat(ticks)
            let intensity: CGFloat? = tick < ticks ? range.lowerBound + span * fraction : nil
            return ChargeStep(delay: total / Double(ticks), intensity: intensity)
        }
    }

    /// The touch-down detent, the weakest of the ramp.
    static var touchDownIntensity: CGFloat { Metrics.hapticIntensity.lowerBound }

    /// `duration`, raised to the minimum; non-finite values fall back to the default.
    static func clampedDuration(_ duration: Double) -> Double {
        guard duration.isFinite else { return Metrics.defaultDuration }
        return max(duration, Metrics.minimumDuration)
    }

    // MARK: Derived State

    private var effectiveDuration: Double { Self.clampedDuration(duration) }

    private var isInteractive: Bool { phase == .idle || phase == .holding }

    /// The pill is solid accent from the moment the ring closes until it re-opens.
    private var isFilled: Bool { phase == .processing || phase == .succeeded }

    private var showsInstruction: Bool { phase == .idle || phase == .holding || phase == .failing }

    /// Text/icon color on the filled pill. Per the accent-role rules: the theme's
    /// `onAccent` when the fill is the theme accent, and `textOnPrimary` (white)
    /// when the caller overrode the accent with a status/destructive color.
    private var onFillColor: Color {
        accent == nil ? theme.onAccent : theme.palette.textOnPrimary
    }
}

// MARK: - Preview

#if DEBUG
/// A default confirm, a destructive hold, a quick one, and an async hold that is
/// refused — each re-mountable via `.id` so it can be run again after it settles.
private struct DSHoldToConfirmPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var confirmAttempt = 0
    @State private var deleteAttempt = 0
    @State private var quickAttempt = 0
    @State private var refusedAttempt = 0

    private struct Refused: Error {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Default — theme accent, 1.2s").ds(.title3)
                    DSHoldToConfirm("Hold to confirm", icon: "hand.tap") {}
                        .id(confirmAttempt)
                    DSButton("Reset", variant: .ghost, size: .small) { confirmAttempt += 1 }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Destructive — status accent").ds(.title3)
                    DSHoldToConfirm(
                        "Hold to delete",
                        icon: "trash",
                        confirmedLabel: "Deleted",
                        accent: DSColors.error
                    ) {}
                    .id(deleteAttempt)
                    DSButton("Reset", variant: .ghost, size: .small) { deleteAttempt += 1 }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Compact, quick (0.6s)").ds(.title3)
                    DSHoldToConfirm(
                        "Hold to send",
                        icon: "paperplane.fill",
                        confirmedLabel: "Sent",
                        duration: 0.6,
                        isFullWidth: false
                    ) {}
                    .id(quickAttempt)
                    DSButton("Reset", variant: .ghost, size: .small) { quickAttempt += 1 }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Async — refused, re-opens").ds(.title3)
                    DSHoldToConfirm("Hold to pay $42.00", icon: "creditcard") {
                        try await Task.sleep(for: .milliseconds(900))
                        throw Refused()
                    }
                    .id(refusedAttempt)
                    DSButton("Reset", variant: .ghost, size: .small) { refusedAttempt += 1 }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Hold to Confirm — Light") {
    DSHoldToConfirmPreviewHost().preferredColorScheme(.light)
}

#Preview("Hold to Confirm — Dark") {
    DSHoldToConfirmPreviewHost().preferredColorScheme(.dark)
}
#endif
