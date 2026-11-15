import SwiftUI

// MARK: - Design System Countdown
// A live countdown to a date, shown as a row of tiles (days, hours, minutes,
// seconds) whose digits roll down as time passes: the flash sale that ends
// tonight, the "Resend code in 0:42" under a one-time-code field, the event
// that starts in two days, the auction's last minute.
//
// Why not `Text(timerInterval:)`: the system timer text is one run of glyphs
// with no unit captions, no per-unit tiles and no way to know when it reaches
// zero. Apps end up rebuilding the same thing with a `Timer` that drifts off
// the second boundary and never tells them it finished.
//
// The rules (whole seconds left, rounded up so "0" only shows at the end; the
// split into units; which tiles show; how long to sleep until the next second
// boundary; the final-ten-seconds phase; the spoken value; firing the finish
// exactly once) live in `DSCountdownLogic`, a pure type the tests pin.
//
// Feel: digits roll with `.numericText(countsDown: true)` on
// `DSAnimation.springSnappy`. In the last ten seconds the seconds tile fills
// with the accent. Reaching zero fires `haptic` (a `.success` by default) once
// and calls `onFinish`. Under Reduce Motion digits change in place and the
// accent fades in. No borders: tiles are flat `theme.subtleFill` rounded
// rectangles, so the countdown sits on a `DSCard` or the backdrop.

/// The countdown rules, kept out of the view so they can be tested.
enum DSCountdownLogic {
    /// A unit the countdown can show as a tile.
    enum Unit: CaseIterable, Equatable {
        case days, hours, minutes, seconds

        /// The caption under the tile ("days", "hrs", "min", "sec").
        var caption: String {
            switch self {
            case .days:    return "days"
            case .hours:   return "hrs"
            case .minutes: return "min"
            case .seconds: return "sec"
            }
        }

        /// The spoken unit, singular or plural.
        func spoken(_ value: Int) -> String {
            let one: String
            switch self {
            case .days:    one = "day"
            case .hours:   one = "hour"
            case .minutes: one = "minute"
            case .seconds: one = "second"
            }
            return "\(value) \(value == 1 ? one : one + "s")"
        }
    }

    /// The seconds left split into units.
    struct Parts: Equatable {
        var days: Int
        var hours: Int
        var minutes: Int
        var seconds: Int

        func value(of unit: Unit) -> Int {
            switch unit {
            case .days:    return days
            case .hours:   return hours
            case .minutes: return minutes
            case .seconds: return seconds
            }
        }
    }

    /// The most seconds a countdown counts (about 100 years), so
    /// `.distantFuture` can't overflow.
    static let maxSeconds = 3_155_760_000

    /// The final stretch, in seconds, when the seconds tile turns accent.
    static let urgentSeconds = 10

    /// Whole seconds from `now` to `target`, rounded **up**: 59.3 s left reads
    /// as 60, so the countdown shows 0 only once the target has passed.
    /// Never negative, capped at `maxSeconds`.
    static func remainingSeconds(from now: Date, to target: Date) -> Int {
        let interval = target.timeIntervalSince(now)
        guard interval.isFinite, interval > 0 else { return 0 }
        return Int(min(interval.rounded(.up), Double(maxSeconds)))
    }

    /// `seconds` split into days, hours, minutes and seconds.
    static func parts(_ seconds: Int) -> Parts {
        let total = max(0, seconds)
        return Parts(
            days: total / 86_400,
            hours: total % 86_400 / 3_600,
            minutes: total % 3_600 / 60,
            seconds: total % 60
        )
    }

    /// The tiles to show: minutes and seconds always, hours from one hour
    /// left, days from one day left. A larger tile drops away as it runs out.
    static func units(for seconds: Int) -> [Unit] {
        if seconds >= 86_400 { return [.days, .hours, .minutes, .seconds] }
        if seconds >= 3_600 { return [.hours, .minutes, .seconds] }
        return [.minutes, .seconds]
    }

    /// A tile's digits: at least two ("05"), more for 100+ days.
    static func digits(_ value: Int) -> String {
        let text = String(max(0, value))
        return text.count < 2 ? "0" + text : text
    }

    /// How long to sleep before the displayed second changes: until the next
    /// whole-second boundary before `target`, plus a hair so the wake-up lands
    /// past it rather than just short. `nil` once the target has passed.
    static func delayToNextTick(from now: Date, to target: Date) -> TimeInterval? {
        let interval = target.timeIntervalSince(now)
        guard interval.isFinite, interval > 0 else { return nil }
        let fraction = interval - interval.rounded(.down)
        return (fraction > 0 ? fraction : 1) + tickSlack
    }

    /// Added to every sleep so a wake-up never lands a hair before the boundary.
    static let tickSlack: TimeInterval = 0.01

    /// The final ten seconds, while the countdown shows minutes and seconds only.
    static func isUrgent(_ seconds: Int) -> Bool {
        seconds > 0 && seconds <= urgentSeconds
    }

    /// What VoiceOver reads: "1 day, 2 hours, 5 seconds". Zero units are
    /// skipped; at the end it reads "0 seconds".
    static func accessibilityValue(_ seconds: Int) -> String {
        let parts = parts(seconds)
        let spoken = Unit.allCases
            .filter { parts.value(of: $0) > 0 }
            .map { $0.spoken(parts.value(of: $0)) }
        return spoken.isEmpty ? Unit.seconds.spoken(0) : spoken.joined(separator: ", ")
    }

    /// What happens on a tick.
    enum Event: Equatable {
        /// Nothing beyond showing the new value.
        case tick
        /// The countdown is over. `crossedZero` is true when this run watched
        /// it reach zero (fire the haptic); false when it was already over the
        /// first time it was checked (call `onFinish` quietly).
        case finished(crossedZero: Bool)
    }

    /// Fires the finish exactly once per run, and the haptic only when the
    /// countdown was seen above zero first.
    struct Tracker: Equatable {
        private var last: Int?
        private(set) var isFinished = false

        mutating func advance(to remaining: Int) -> Event {
            defer { last = remaining }
            guard !isFinished else { return .tick }
            guard remaining <= 0 else { return .tick }
            isFinished = true
            return .finished(crossedZero: (last ?? 0) > 0)
        }
    }
}

private enum Metrics {
    /// A tile is at least this wide: DSSpacing.massive (64), room for "00" at title1.
    static let tileWidth: CGFloat = DSSpacing.massive
    /// Space between the digits and their caption: DSSpacing.xxxs (2).
    static let captionGap: CGFloat = DSSpacing.xxxs
}

/// A live countdown to a date: a row of tiles (days, hours, minutes, seconds)
/// whose digits roll down each second.
///
/// Hours show from one hour left and days from one day left; minutes and
/// seconds always. In the last ten seconds the seconds tile fills with the
/// accent. At zero it fires `haptic` once and calls `onFinish`.
public struct DSCountdown: View {
    private let target: Date
    private let accent: Color?
    private let haptic: DSHapticStyle
    private let label: String
    private let onFinish: (() -> Void)?

    @State private var remaining: Int

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - target: The moment the countdown reaches zero.
    ///   - accent: The fill of the seconds tile in the last ten seconds. Defaults to the theme accent.
    ///   - haptic: Fired once when the countdown reaches zero on screen. Defaults to `.success`.
    ///   - accessibilityLabel: What VoiceOver reads before the time left. Defaults to "Time remaining".
    ///   - onFinish: Called once when the countdown reaches zero, or as soon as it
    ///     appears if `target` has already passed. Called again for a new `target`.
    public init(
        to target: Date,
        accent: Color? = nil,
        haptic: DSHapticStyle = .success,
        accessibilityLabel: String = "Time remaining",
        onFinish: (() -> Void)? = nil
    ) {
        self.target = target
        self.accent = accent
        self.haptic = haptic
        self.label = accessibilityLabel
        self.onFinish = onFinish
        self._remaining = State(initialValue: DSCountdownLogic.remainingSeconds(from: .now, to: target))
    }

    public var body: some View {
        let parts = DSCountdownLogic.parts(remaining)
        let units = DSCountdownLogic.units(for: remaining)

        HStack(spacing: DSSpacing.xs) {
            ForEach(units, id: \.self) { unit in
                tile(unit, value: parts.value(of: unit))
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition.scale.combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? DSAnimation.fast : DSAnimation.springSmooth, value: units)
        .task(id: target) { await run() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(DSCountdownLogic.accessibilityValue(remaining))
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: Tiles

    private func tile(_ unit: DSCountdownLogic.Unit, value: Int) -> some View {
        let isUrgent = unit == .seconds && DSCountdownLogic.isUrgent(remaining)
        let fill = accent ?? theme.accent
        // A custom accent falls back to the palette's text-on-primary, as DSChip does.
        let onFill = accent == nil ? theme.onAccent : theme.palette.textOnPrimary

        return VStack(spacing: Metrics.captionGap) {
            Text(DSCountdownLogic.digits(value))
                .ds(.title1, color: isUrgent ? onFill : theme.palette.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
                .animation(reduceMotion ? nil : DSAnimation.springSnappy, value: value)
            Text(unit.caption)
                .ds(.overline, color: isUrgent ? onFill : theme.palette.textSecondary)
                .lineLimit(1)
        }
        .padding(.vertical, DSSpacing.sm)
        .padding(.horizontal, DSSpacing.xs)
        .frame(minWidth: Metrics.tileWidth)
        .background {
            RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                .fill(isUrgent ? fill : theme.subtleFill)
        }
        .animation(reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy, value: isUrgent)
    }

    // MARK: Behavior

    /// Ticks on each whole-second boundary before `target` until it passes.
    /// Restarts (with a fresh finish) whenever `target` changes.
    private func run() async {
        var tracker = DSCountdownLogic.Tracker()
        while !Task.isCancelled {
            let now = Date.now
            let left = DSCountdownLogic.remainingSeconds(from: now, to: target)
            if left != remaining { remaining = left }

            if case .finished(let crossedZero) = tracker.advance(to: left) {
                if crossedZero { DSHapticEngine.shared.fire(haptic) }
                onFinish?()
                return
            }
            guard let delay = DSCountdownLogic.delayToNextTick(from: now, to: target) else { return }
            try? await Task.sleep(for: .seconds(delay))
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCountdownPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var resendAt = Date.now.addingTimeInterval(15)
    @State private var canResend = false

    private let saleEnds = Date.now.addingTimeInterval(2 * 86_400 + 5 * 3_600 + 42 * 60)
    private let eventStarts = Date.now.addingTimeInterval(3 * 3_600 + 12)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Sale ends in").ds(.title3)
                        DSCountdown(to: saleEnds, accessibilityLabel: "Sale ends in")
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Live in").ds(.overline, color: DSColors.textSecondary)
                    DSCountdown(to: eventStarts, accent: DSColors.secondary)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Resend code in").ds(.callout, color: DSColors.textSecondary)
                        DSCountdown(to: resendAt, accessibilityLabel: "Resend code in") {
                            canResend = true
                        }
                        DSButton("Resend code", variant: .secondary, size: .small) {
                            canResend = false
                            resendAt = .now.addingTimeInterval(15)
                        }
                        .disabled(!canResend)
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Countdown — Light") {
    DSCountdownPreviewHost().preferredColorScheme(.light)
}

#Preview("Countdown — Dark") {
    DSCountdownPreviewHost().preferredColorScheme(.dark)
}
#endif
