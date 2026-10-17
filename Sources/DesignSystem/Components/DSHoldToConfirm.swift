import SwiftUI

// MARK: - Design System Hold To Confirm
// The companion to DSSlideToConfirm: where a slide gates an action behind a
// deliberate *gesture*, a hold gates it behind deliberate *time*. The user
// presses and keeps a finger down; a gradient ring charges around the pill over
// `duration`; a detent texture tightens under the finger as it fills; and when
// the ring closes the action fires with a success beat. Lifting early snaps the
// ring back and the action never runs — the commitment has to be sustained, not
// just started.
//
// It reaches for a different reflex than the slide. A slide is right when the
// risk is "did you mean to touch this at all" (a payment, a destructive button a
// thumb could brush). A hold is right when the risk is "stay with this for a
// moment" — power off, hold-to-record, confirm-and-wait — and when one hand is
// all the user has. Both exist so an app can pick the reflex that matches the
// stakes.
//
// The ring is a progress indicator, not a border: at rest it is `trim` zero, so
// nothing is drawn (Velvet draws no borders). It only exists while the hold is
// charging, the same way `DSCircularProgress` strokes a ring that isn't an edge.

// MARK: - Metrics

private enum Metrics {
    /// 1.2s — long enough to read as a deliberate commitment, short enough not
    /// to feel like a punishment. The default; callers tune it per stakes.
    static let defaultDuration: Double = 1.2
    /// Detents felt across the charge. Like `DSSlideToConfirm`, the control adds
    /// no physical resistance, so texture is what gives the hold a surface.
    static let hapticTicks: Int = 6
    /// Tick strength from touch-down to the brink, ramped so the ring feels like
    /// it is tightening under the finger as it closes.
    static let hapticIntensity: ClosedRange<CGFloat> = 0.2...0.6
    /// Width of the charging ring. 4pt reads as progress, not as a hairline edge.
    static let ringWidth: CGFloat = DSSpacing.xxs
    /// Half the ring width, so the stroke sits inside the pill instead of
    /// straddling its edge and bleeding past the glass.
    static let ringInset: CGFloat = DSSpacing.xxxs
}

// MARK: - Phase

/// The control's position in the confirmation. Everything visual derives from
/// this — there is no second source of truth about what is on screen.
private enum Phase: Equatable {
    /// At rest. The gesture is live.
    case idle
    /// A finger is down and the ring is charging.
    case holding
    /// The hold completed; the pill is filled and the action has run.
    case confirmed
}

// MARK: - DSHoldToConfirm

/// A press-and-hold confirmation control. The user holds the pill until a ring
/// charges all the way around, at which point the action fires.
///
///     DSHoldToConfirm("Hold to delete", icon: "trash", accent: DSColors.error) {
///         deleteAccount()
///     }
///
/// Lifting before the ring closes cancels: the ring snaps back and `onConfirm`
/// never runs. Once confirmed the control rests filled, showing a check and
/// `confirmedLabel`; there is no reset API — re-mount with `.id(attempt)` to run
/// it again, the same contract as `DSSlideToConfirm`.
public struct DSHoldToConfirm: View {

    // MARK: Configuration

    private let label: String
    private let icon: String?
    private let confirmedLabel: String
    private let duration: Double
    private let accent: Color?
    private let isFullWidth: Bool
    private let onConfirm: () -> Void

    // MARK: State

    /// Ring fill, `0...1`. Driven by one linear animation while charging and
    /// sprung back to 0 on cancel.
    @State private var progress: CGFloat = 0
    @State private var phase: Phase = .idle
    /// The charge clock. It, not the ring animation, is the source of truth for
    /// when the action fires — a cancelled `Task` throws out of its sleep, so a
    /// lifted finger can never let the confirmation slip through.
    @State private var holdTask: Task<Void, Never>?

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - label: Instruction shown before and during the hold, e.g. "Hold to delete".
    ///   - icon: SF Symbol shown before the label while idle. `nil` for label only.
    ///   - confirmedLabel: Replaces `label` once the hold completes.
    ///   - duration: How long the finger must stay down. Defaults to 1.2s.
    ///   - accent: Fill and ring color. Defaults to `theme.accent`; pass a status
    ///     color (e.g. `error`) for a destructive hold.
    ///   - isFullWidth: Stretch to the available width. Defaults to `true`.
    ///   - onConfirm: The action. Runs once, when the ring closes.
    public init(
        _ label: String,
        icon: String? = nil,
        confirmedLabel: String = "Confirmed",
        duration: Double = Metrics.defaultDuration,
        accent: Color? = nil,
        isFullWidth: Bool = true,
        onConfirm: @escaping () -> Void
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
                    .opacity(isConfirmed ? 1 : 0)
            }
            .dsSurface(.glassThin, radius: DSRadius.chip)
            .overlay { ring(accent: resolvedAccent) }
            .scaleEffect(phase == .holding ? DSPress.scale : 1)
            .contentShape(Capsule(style: .continuous))
            .gesture(holdGesture)
            .onDisappear { holdTask?.cancel() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint("Touch and hold to confirm")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { confirmImmediately() }
    }

    // MARK: Content

    private var content: some View {
        HStack(spacing: DSSpacing.xs) {
            if isConfirmed {
                Image(systemName: "checkmark")
                    .font(DSTextStyle.button.font)
            } else if let icon {
                Image(systemName: icon)
                    .font(DSTextStyle.button.font)
            }

            Text(isConfirmed ? confirmedLabel : label)
                .font(DSTextStyle.button.font)
        }
        .foregroundStyle(isConfirmed ? onFillColor : theme.ink)
    }

    // MARK: Ring

    /// The charging progress ring. A `trim` of the pill's own capsule, so at rest
    /// (`progress == 0`) it draws nothing — no border. Hidden once the fill takes
    /// over, so a gradient stroke never sits on top of the solid accent.
    @ViewBuilder
    private func ring(accent: Color) -> some View {
        Group {
            if self.accent == nil {
                Capsule(style: .continuous)
                    .trim(from: 0, to: progress)
                    .stroke(theme.gradient.horizontalGradient, style: ringStyle)
            } else {
                Capsule(style: .continuous)
                    .trim(from: 0, to: progress)
                    .stroke(accent, style: ringStyle)
            }
        }
        .padding(Metrics.ringInset)
        .opacity(isConfirmed ? 0 : 1)
        .allowsHitTesting(false)
    }

    private var ringStyle: StrokeStyle {
        StrokeStyle(lineWidth: Metrics.ringWidth, lineCap: .round)
    }

    // MARK: Gesture

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                // Fires on touch-down and on every micro-move. Guard so the
                // charge begins exactly once per press.
                guard phase == .idle else { return }
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
        withAnimation(.linear(duration: duration)) { progress = 1 }
        DSHapticEngine.shared.fire(.soft, intensity: Metrics.hapticIntensity.lowerBound)
        holdTask = Task { @MainActor in await runHold() }
    }

    /// Sleeps the charge in `hapticTicks` steps, firing a ramped `.soft` detent
    /// at each one; a cancelled `Task` throws out of the sleep and returns before
    /// it can confirm. Completing every step means the finger stayed down the
    /// whole way, so the action fires.
    @MainActor
    private func runHold() async {
        let step = duration / Double(Metrics.hapticTicks)
        let span = Metrics.hapticIntensity.upperBound - Metrics.hapticIntensity.lowerBound
        for tick in 1...Metrics.hapticTicks {
            do {
                try await Task.sleep(for: .seconds(step))
            } catch {
                return // cancelled by an early release
            }
            // The last step hands off to the `.success` beat, so it skips its tick.
            if tick < Metrics.hapticTicks {
                let fraction = CGFloat(tick) / CGFloat(Metrics.hapticTicks)
                DSHapticEngine.shared.fire(.soft, intensity: Metrics.hapticIntensity.lowerBound + span * fraction)
            }
        }
        confirm()
    }

    private func confirm() {
        holdTask = nil
        DSHapticEngine.shared.fire(.success)
        withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springBouncy) {
            progress = 1
            phase = .confirmed
        }
        onConfirm()
    }

    private func cancel() {
        holdTask?.cancel()
        holdTask = nil
        DSHapticEngine.shared.fire(.light)
        withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springBouncy) {
            progress = 0
            phase = .idle
        }
    }

    /// VoiceOver path: a single activation confirms without a timed hold, since a
    /// press-and-hold gesture can't be performed under the assistive cursor.
    private func confirmImmediately() {
        guard phase != .confirmed else { return }
        holdTask?.cancel()
        holdTask = nil
        confirm()
    }

    // MARK: Derived State

    private var isConfirmed: Bool { phase == .confirmed }

    /// Text/icon color on the filled pill. Per the accent-role rules: the theme's
    /// `onAccent` when the fill is the theme accent, and `textOnPrimary` (white)
    /// when the caller overrode the accent with a status/destructive color.
    private var onFillColor: Color {
        accent == nil ? theme.onAccent : theme.palette.textOnPrimary
    }
}

// MARK: - Preview

#if DEBUG
/// A default confirm, a destructive hold, and a quick one — each re-mountable via
/// `.id` so the choreography can be run again after it settles.
private struct DSHoldToConfirmPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var confirmAttempt = 0
    @State private var deleteAttempt = 0
    @State private var quickAttempt = 0

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
