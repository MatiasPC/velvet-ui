import SwiftUI

// MARK: - Design System Audio Bars
// The "we are listening / sound is playing" state: a short row of capsule bars
// that ripple like a graphic equaliser while `isActive`, and settle to a calm
// flat line when idle. It is the audio sibling of `DSThinkingIndicator` — one
// carries the "assistant is working" language, this one carries "a microphone
// or a track is live" — and reaches for the same ambient-motion rules as the
// rest of the system: eased, looping, colour from the theme, Reduce Motion as a
// resting state rather than a bail-out, and pure SwiftUI so both platforms build.
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

// MARK: - Metrics

/// Motion-shaping constants. These are not layout — there is no spacing or
/// radius token for "how fast does a bar swing" — so they live here, tuned by
/// eye, exactly like the shaping values in `DSParticleField`.
private enum Metrics {
    /// Trough height as a fraction of the full height. Bars never collapse to a
    /// sliver: at rest they are a readable flat line, not nothing.
    static let restFraction: CGFloat = 0.22
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

// MARK: - DSAudioBars

/// An ambient audio-level visualiser: a row of theme-tinted capsule bars that
/// dance while `isActive` and rest flat when not.
///
///     DSAudioBars(isActive: recorder.isRecording)
///
/// Decorative by design — it conveys state through motion, so it is hidden from
/// VoiceOver. Pair it with a label (`"Listening…"`) when the state must also be
/// announced, the same way `DSThinkingIndicator` is usually sat next to text.
public struct DSAudioBars: View {

    // MARK: Configuration

    private let isActive: Bool
    private let barCount: Int
    private let barWidth: CGFloat
    private let spacing: CGFloat
    private let height: CGFloat
    private let color: Color?

    // MARK: Environment

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - isActive: While true the bars ripple; while false they settle to a
    ///     flat resting line. Defaults to `true`.
    ///   - barCount: Number of bars. Defaults to `5`.
    ///   - barWidth: Width of each capsule bar. Defaults to `DSSpacing.xxs` (4).
    ///   - spacing: Gap between bars. Defaults to `DSSpacing.xxs` (4).
    ///   - height: Full height of the tallest bar. Defaults to `DSSpacing.xl` (24).
    ///   - color: Bar fill. Defaults to the theme accent.
    public init(
        isActive: Bool = true,
        barCount: Int = 5,
        barWidth: CGFloat = DSSpacing.xxs,
        spacing: CGFloat = DSSpacing.xxs,
        height: CGFloat = DSSpacing.xl,
        color: Color? = nil
    ) {
        self.isActive = isActive
        self.barCount = max(1, barCount)
        self.barWidth = max(1, barWidth)
        self.spacing = max(0, spacing)
        self.height = max(1, height)
        self.color = color
    }

    // MARK: Body

    public var body: some View {
        Group {
            if isActive && !reduceMotion {
                // Analytic heights off the timeline clock — no per-bar state,
                // nothing to desync, and the body re-evaluates per frame only
                // while actually active.
                TimelineView(.animation) { context in
                    row { index in
                        barHeight(for: liveLevel(bar: index, at: context.date.timeIntervalSinceReferenceDate))
                    }
                }
            } else {
                // Idle, or Reduce Motion: a resting state, not a skip. Idle is a
                // flat line; a Reduce-Motion-but-active indicator freezes on the
                // equaliser bell so it still reads as audio.
                row { index in
                    barHeight(for: isActive ? restingLevel(bar: index) : 0)
                }
            }
        }
        .frame(height: height, alignment: .center)
        .animation(DSAnimation.springSmooth, value: isActive)
        .accessibilityHidden(true)
    }

    // MARK: Bars

    private func row(_ heightFor: @escaping (Int) -> CGFloat) -> some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(color ?? theme.accent)
                    .frame(width: barWidth, height: heightFor(index))
            }
        }
    }

    // MARK: Levels

    /// Live level in `0...1` for bar `index` at `time`: a slow body wave plus a
    /// faster detail wave, each offset per bar so the row ripples.
    private func liveLevel(bar index: Int, at time: TimeInterval) -> CGFloat {
        let phase = Double(index) * Metrics.phaseStep
        let body = sin(time * Metrics.bodySpeed + phase)
        let detail = sin(time * Metrics.detailSpeed + phase * Metrics.detailPhaseScale)
        let combined = body * Metrics.bodyWeight + detail * Metrics.detailWeight // −1…1
        return CGFloat((combined + 1) / 2)
    }

    /// Static level in `0...1` for bar `index`: a symmetric bell, tallest in the
    /// middle, so the frozen Reduce-Motion state still looks like an equaliser.
    private func restingLevel(bar index: Int) -> CGFloat {
        guard barCount > 1 else { return 1 }
        let mid = Double(barCount - 1) / 2
        let distance = abs(Double(index) - mid) / mid // 0 centre … 1 edge
        return CGFloat(max(0, 1 - distance * Metrics.bellFalloff))
    }

    /// Map a `0...1` level to a pixel height, floored so a bar at rest stays a
    /// visible rounded cap rather than vanishing.
    private func barHeight(for level: CGFloat) -> CGFloat {
        let resolved = height * (Metrics.restFraction + (1 - Metrics.restFraction) * level)
        return max(resolved, barWidth)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSAudioBarsPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var listening = true

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
