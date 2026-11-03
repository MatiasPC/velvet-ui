import SwiftUI

// MARK: - Design System Audio Bars
// The "we are listening / sound is playing" state: a short row of capsule bars
// that ripple like a graphic equaliser while `isActive`, and settle to a calm
// flat line when idle. It is the audio sibling of `DSThinkingIndicator` — one
// carries the "assistant is working" language, this one carries "a microphone
// or a track is live" — and follows the same ambient-motion rules as the rest
// of the system: eased curves rather than springs (nothing was touched), colour
// from the theme accent, Reduce Motion as a resting state rather than a
// bail-out, and pure SwiftUI so both platforms build.
//
// Reusable wherever audio is live: voice assistants and dictation, call and
// recording UIs, now-playing rows, Shazam-style "listening" states, AI voice.
//
// Motion technique: the bar heights are *computed analytically* from the
// timeline clock inside a single `TimelineView(.animation)` — the same approach
// `DSParticleField` uses — not N independent `repeatForever` springs. Two summed
// sines per bar (a slow body plus a faster detail) with a per-bar phase offset
// give an organic travelling ripple instead of a mechanical pulse, and because
// every height is derived from wall-clock time there is no accumulated state to
// desync when the view is re-created. Inspired by the common SwiftUI
// audio-visualiser tutorials (e.g. Kavsoft); no upstream code is reproduced.
//
// Two things change the shape of the row without touching the clock, so both
// are animated *values* of an `Animatable` row rather than branches in the view
// tree: `isActive` (flat line ↔ rippling, `intensity` 0 ↔ 1) and the optional
// live `level` (the amplitude of the ripple). Being animatable is what lets the
// row ease between idle and live instead of popping, and what lets the timeline
// stop ticking the moment nothing is moving.

// MARK: - Metrics

/// Motion-shaping constants. These are not layout — there is no spacing or
/// radius token for "how fast does a bar swing" — so they live here, tuned by
/// eye, exactly like the shaping values in `DSParticleField`.
private enum Metrics {
    /// Trough height as a fraction of the full height. Bars never collapse to a
    /// sliver: at rest they are a readable flat line, not nothing.
    static let restFraction: Double = 0.22
    /// How much shorter the edge bars rest than the centre in the static
    /// (Reduce Motion) state, so even frozen it reads as an equaliser.
    static let bellFalloff: Double = 0.55
    /// Phase offset between adjacent bars — turns a synchronised pulse into a
    /// travelling ripple across the row.
    static let phaseStep: Double = 0.85
    /// Angular speed of the slow body wave and the faster detail wave.
    static let bodySpeed: Double = 3.1
    static let detailSpeed: Double = 5.7
    /// The detail wave advances its phase faster across bars, so body and detail
    /// never line up into one flat beat.
    static let detailPhaseScale: Double = 1.6
    /// Blend of the two waves. They sum to 1 so the combined value stays in −1…1.
    static let bodyWeight: Double = 0.62
    static let detailWeight: Double = 0.38
}

// MARK: - Pure logic

/// The parts of `DSAudioBars` that don't need a view: the wave, the resting bell,
/// level handling and the "should the clock tick" decision. Internal and unit-tested.
enum DSAudioBarsMath {

    /// The ripple for bar `index` at `time` seconds: a slow body wave plus a faster
    /// detail wave, each offset per bar. Always in `0...1`.
    static func wave(bar index: Int, at time: TimeInterval) -> Double {
        let phase = Double(index) * Metrics.phaseStep
        let body = sin(time * Metrics.bodySpeed + phase)
        let detail = sin(time * Metrics.detailSpeed + phase * Metrics.detailPhaseScale)
        let combined = body * Metrics.bodyWeight + detail * Metrics.detailWeight // −1…1
        return min(max((combined + 1) / 2, 0), 1)
    }

    /// The frozen Reduce Motion shape for bar `index` of `count`: a symmetric bell,
    /// tallest in the middle, in `0...1`.
    static func bell(bar index: Int, of count: Int) -> Double {
        guard count > 1 else { return 1 }
        let mid = Double(count - 1) / 2
        let distance = abs(Double(index) - mid) / mid // 0 centre … 1 edge
        return max(0, 1 - distance * Metrics.bellFalloff)
    }

    /// The amplitude a `level` input asks for, in `0...1`. `nil` means no level
    /// input: the ripple runs at full amplitude. NaN reads as silence.
    static func amplitude(for level: Double?) -> Double {
        guard let level else { return 1 }
        if level.isNaN { return 0 }
        return min(max(level, 0), 1)
    }

    /// How far above its resting line bar `index` stands, in `0...1`.
    /// - Parameters:
    ///   - intensity: `0` idle … `1` fully active (animated, so it eases between).
    ///   - amplitude: The `level` amplitude, `0...1`.
    ///   - frozen: Reduce Motion: use the bell, and ignore `amplitude` (the level is motion too).
    static func fraction(
        bar index: Int, of count: Int, at time: TimeInterval,
        intensity: Double, amplitude: Double, frozen: Bool
    ) -> Double {
        let shape = frozen ? bell(bar: index, of: count) : wave(bar: index, at: time)
        let level = frozen ? 1 : amplitude
        return min(max(intensity * level * shape, 0), 1)
    }

    /// Pixel height for a `0...1` fraction: the resting line plus the swing above it,
    /// never thinner than the bar is wide (so a resting bar stays a rounded cap).
    static func height(fraction: Double, full: CGFloat, barWidth: CGFloat) -> CGFloat {
        let resolved = full * CGFloat(Metrics.restFraction + (1 - Metrics.restFraction) * fraction)
        return max(resolved, barWidth)
    }

    /// Whether the timeline clock should be running. It stops whenever nothing can
    /// be moving or nobody can see it, so a listening indicator that was left behind
    /// (a pushed screen, a backgrounded app, a stopped recording) costs no CPU.
    static func isTicking(isActive: Bool, reduceMotion: Bool, isVisible: Bool, isSceneActive: Bool) -> Bool {
        isActive && !reduceMotion && isVisible && isSceneActive
    }
}

// MARK: - DSAudioBars

/// An ambient audio-level visualiser: a row of theme-accent capsule bars that
/// dance while `isActive` and rest flat when not.
///
///     DSAudioBars(isActive: recorder.isRecording)
///     DSAudioBars(level: recorder.level)   // follows the microphone
///
/// With no `level` the bars ripple at full amplitude, a canned "audio is live".
/// With a `level` (`0...1`) the ripple's amplitude follows it, so the bars swell
/// with the voice and settle when it goes quiet. Level changes are smoothed with
/// a short eased curve, so you can pass raw meter readings.
///
/// The bars are filled with the theme accent (pass `color` to override). Between idle and active, and between levels, they ease rather than
/// spring: nothing was touched. The clock behind the ripple stops whenever the bars
/// aren't moving or aren't on screen.
///
/// Decorative by design — it conveys state through motion, so it is hidden from
/// VoiceOver. Pair it with a label (`"Listening…"`) when the state must also be
/// announced, the same way `DSThinkingIndicator` is usually sat next to text.
/// Reduce Motion: the ripple stops and active bars rest on a symmetric bell; the
/// `level` is ignored.
public struct DSAudioBars: View {

    // MARK: Configuration

    private let isActive: Bool
    private let level: Double?
    private let barCount: Int
    private let barWidth: CGFloat
    private let spacing: CGFloat
    private let height: CGFloat
    private let color: Color?

    // MARK: State & environment

    /// True between appearing and disappearing, so the clock stops when the view
    /// is navigated away from or scrolled out of a lazy container.
    @State private var isVisible = false
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    // MARK: Init

    /// - Parameters:
    ///   - isActive: While true the bars ripple; while false they ease down to a
    ///     flat resting line. Defaults to `true`.
    ///   - level: Live audio level, `0...1`, as the amplitude of the ripple. `nil`
    ///     (the default) ripples at full amplitude. Values outside the range are clamped.
    ///   - barCount: Number of bars. Defaults to `5`.
    ///   - barWidth: Width of each capsule bar. Defaults to `DSSpacing.xxs` (4).
    ///   - spacing: Gap between bars. Defaults to `DSSpacing.xxs` (4).
    ///   - height: Full height of the tallest bar. Defaults to `DSSpacing.xl` (24).
    ///   - color: Bar fill. Defaults to the theme accent.
    public init(
        isActive: Bool = true,
        level: Double? = nil,
        barCount: Int = 5,
        barWidth: CGFloat = DSSpacing.xxs,
        spacing: CGFloat = DSSpacing.xxs,
        height: CGFloat = DSSpacing.xl,
        color: Color? = nil
    ) {
        self.isActive = isActive
        self.level = level
        self.barCount = max(1, barCount)
        self.barWidth = max(1, barWidth)
        self.spacing = max(0, spacing)
        self.height = max(1, height)
        self.color = color
    }

    // MARK: Body

    public var body: some View {
        let ticking = DSAudioBarsMath.isTicking(
            isActive: isActive,
            reduceMotion: reduceMotion,
            isVisible: isVisible,
            isSceneActive: scenePhase == .active
        )
        let amplitude = DSAudioBarsMath.amplitude(for: level)

        // One timeline for the lifetime of the view (so the row can ease between
        // idle and active), paused whenever nothing is moving: a paused schedule
        // costs nothing.
        return TimelineView(.animation(paused: !ticking)) { context in
            DSAudioBarsRow(
                intensity: isActive ? 1 : 0,
                amplitude: amplitude,
                time: context.date.timeIntervalSinceReferenceDate,
                frozen: reduceMotion,
                barCount: barCount,
                barWidth: barWidth,
                spacing: spacing,
                height: height,
                fill: color ?? theme.accent
            )
            // Eased, never sprung: this is ambience. Under Reduce Motion the row
            // simply takes its new shape.
            .animation(reduceMotion ? nil : DSAnimation.normal, value: isActive)
            .animation(reduceMotion ? nil : DSAnimation.fast, value: amplitude)
        }
        .frame(height: height)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .accessibilityHidden(true)
    }
}

// MARK: - Row

/// The bars themselves, as an `Animatable` view: `intensity` and `amplitude` are
/// interpolated by SwiftUI while `time` (which changes every frame) is not, so the
/// row eases between idle and live and between levels while the ripple keeps its
/// own clock.
private struct DSAudioBarsRow: View, Animatable {
    var intensity: Double
    var amplitude: Double
    let time: TimeInterval
    let frozen: Bool
    let barCount: Int
    let barWidth: CGFloat
    let spacing: CGFloat
    let height: CGFloat
    let fill: Color

    nonisolated var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(intensity, amplitude) }
        set { intensity = newValue.first; amplitude = newValue.second }
    }

    private var width: CGFloat {
        CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
    }

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(fill)
                    .frame(width: barWidth, height: barHeight(index))
            }
        }
        .frame(width: width, height: height)
    }

    private func barHeight(_ index: Int) -> CGFloat {
        DSAudioBarsMath.height(
            fraction: DSAudioBarsMath.fraction(
                bar: index, of: barCount, at: time,
                intensity: intensity, amplitude: amplitude, frozen: frozen
            ),
            full: height,
            barWidth: barWidth
        )
    }
}

// MARK: - Preview

#if DEBUG
private struct DSAudioBarsPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var listening = true
    @State private var level = 0.6

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        HStack(spacing: DSSpacing.sm) {
                            DSAudioBars(isActive: listening)
                            Text(listening ? "Listening…" : "Paused")
                                .ds(.callout, color: DSColors.textSecondary)
                            Spacer()
                        }
                        DSToggle("Active", isOn: $listening)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        HStack(spacing: DSSpacing.sm) {
                            DSAudioBars(isActive: listening, level: level, barCount: 9, height: DSSpacing.xxxl)
                            Spacer()
                            Text("\(Int(level * 100))%").ds(.numeric, color: DSColors.textSecondary)
                        }
                        Slider(value: $level, in: 0...1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        Text("Variations").ds(.footnote, color: DSColors.textSecondary)
                        HStack(spacing: DSSpacing.xl) {
                            DSAudioBars(barCount: 3)
                            DSAudioBars(barCount: 7, height: DSSpacing.xxl)
                            DSAudioBars(barCount: 5, color: DSColors.secondary)
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
}

#Preview("Audio Bars — Light") {
    DSAudioBarsPreviewHost().preferredColorScheme(.light)
}

#Preview("Audio Bars — Dark") {
    DSAudioBarsPreviewHost().preferredColorScheme(.dark)
}
#endif
