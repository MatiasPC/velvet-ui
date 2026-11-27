import SwiftUI

// MARK: - Design System Typewriter Text
// Types a phrase out character by character, holds it, erases it, then moves
// on to the next phrase — a blinking caret runs the whole time. For hero
// headlines and empty states that need a little life without stealing focus.
//
// Data-driven: any `[String]` works. Character stepping walks the string's
// `Character` collection (grapheme clusters), never raw UTF-8 bytes, so emoji
// and accented characters are never split mid-glyph. A Swift Concurrency
// `Task` drives the stepping loop (type → hold → erase → next), stored in
// `@State` so it can be cancelled in `.onDisappear` and restarted whenever the
// phrase list (or Reduce Motion) changes — no `Timer` anywhere. The task only
// sleeps and applies steps; what each step is lives in the pure
// `DSTypewriterTextLogic.Script`, pinned by `DSTypewriterTextTests`.
//
// Technique inspired by: open-swiftui-animations/Gists_To_Try/TypingErasing.swift
// That gist hardcodes ~26 phase enum cases to spell one fixed word with a
// `Timer`. This rewrite is fully data-driven and Task-based instead.

// MARK: - Layout Support

private enum Metrics {
    /// Caret width — the "hairline" spacing token doubled as a thin filled bar
    /// instead of a stroke (Velvet UI draws no borders).
    static let caretWidth: CGFloat = DSSpacing.xxxs
    /// Caret corner radius. `.xs` on a hairline-width bar exceeds half the
    /// bar's own width, so SwiftUI clamps it — the caret renders as a soft
    /// capsule tip rather than a sharp rectangle.
    static let caretCornerRadius: CGFloat = DSRadius.xs
    /// Gap between the last typed character and the caret.
    static let caretGap: CGFloat = DSSpacing.xxxs
    /// Caret blink half-cycle. Not a `Color`/`Font`/`CGFloat` token — it's a
    /// `TimeInterval` duration, so the "tokens only" rule doesn't cover it —
    /// but it's centralized here rather than inlined. Matches the ~0.5s
    /// classic terminal caret cadence called for in the component spec.
    static let caretBlinkDuration: TimeInterval = 0.5
}

/// Reports the rendered height of the longest phrase so the caret can be
/// sized to the text style without a hardcoded point value.
private struct DSTypewriterLineHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Logic

/// The typewriter's rules as plain values, so they can be tested without
/// rendering: which characters are visible, and the script the stepping task
/// plays (type in → hold → erase → next phrase, or the Reduce Motion cycle).
enum DSTypewriterTextLogic {
    /// The longest single wait, in seconds (about 31 years). A longer finite
    /// value is clamped so converting it to nanoseconds for `Task.sleep` can't
    /// overflow.
    static let maximumDelay: TimeInterval = 1_000_000_000

    /// The first `count` characters of `phrase`, counted in grapheme clusters
    /// (`Character`s), never bytes, so emoji and accents are never split.
    /// A negative count gives an empty string; a count past the end, the whole phrase.
    static func visibleText(of phrase: String, count: Int) -> String {
        String(phrase.prefix(max(count, 0)))
    }

    /// A duration as something `Task.sleep` can take: NaN and negative values
    /// become 0, huge values are clamped to `maximumDelay`, and `+infinity`
    /// returns `nil`, meaning "never" (the script stops where it is).
    static func delay(_ seconds: TimeInterval) -> TimeInterval? {
        if seconds.isNaN { return 0 }
        if seconds == .infinity { return nil }
        return min(max(seconds, 0), maximumDelay)
    }

    enum Phase: Equatable, Sendable {
        /// Revealing characters one at a time.
        case typing
        /// The phrase is complete (holding) or losing characters (erasing).
        case erasing
        /// Reduce Motion: the whole phrase is shown at once.
        case showing
    }

    struct State: Equatable, Sendable {
        var phraseIndex: Int
        var characterCount: Int
        var phase: Phase
    }

    /// Wait `delay` seconds, then show `state`.
    struct Step: Equatable, Sendable {
        var delay: TimeInterval
        var state: State
    }

    struct Script: Sendable {
        let phrases: [String]
        let typingSpeed: TimeInterval
        let erasingSpeed: TimeInterval
        let holdDuration: TimeInterval
        let loops: Bool
        let reduceMotion: Bool

        /// Nothing to animate: no phrases, or every phrase is empty.
        var isStatic: Bool { phrases.allSatisfy(\.isEmpty) }

        /// What shows before the first step: nothing typed yet, or under
        /// Reduce Motion the whole first phrase.
        var start: State {
            reduceMotion
                ? State(phraseIndex: 0, characterCount: phrases.first?.count ?? 0, phase: .showing)
                : State(phraseIndex: 0, characterCount: 0, phase: .typing)
        }

        /// The step after `state`, or `nil` when the script is over: the last
        /// phrase is complete and `loops` is `false`, a wait is infinite, or
        /// there is nothing to animate.
        func step(after state: State) -> Step? {
            guard !isStatic, phrases.indices.contains(state.phraseIndex) else { return nil }
            let length = phrases[state.phraseIndex].count
            let isLast = state.phraseIndex == phrases.count - 1
            let nextIndex = isLast ? 0 : state.phraseIndex + 1

            switch state.phase {
            case .showing:
                // Reduce Motion holds each phrase as long as typing it plus the
                // hold would take, so the pacing stays readable.
                if isLast && !loops { return nil }
                guard let wait = DSTypewriterTextLogic.delay(typingSpeed * Double(length) + holdDuration) else { return nil }
                let next = State(phraseIndex: nextIndex, characterCount: phrases[nextIndex].count, phase: .showing)
                return Step(delay: wait, state: next)

            case .typing:
                let typed = min(max(state.characterCount, 0), length)
                if typed < length {
                    guard let wait = DSTypewriterTextLogic.delay(typingSpeed) else { return nil }
                    return Step(delay: wait, state: State(phraseIndex: state.phraseIndex, characterCount: typed + 1, phase: .typing))
                }
                // Fully typed: stop on the last phrase, or hold before erasing.
                if isLast && !loops { return nil }
                guard let wait = DSTypewriterTextLogic.delay(holdDuration) else { return nil }
                return Step(delay: wait, state: State(phraseIndex: state.phraseIndex, characterCount: length, phase: .erasing))

            case .erasing:
                let remaining = min(max(state.characterCount, 0), length)
                if remaining > 0 {
                    guard let wait = DSTypewriterTextLogic.delay(erasingSpeed) else { return nil }
                    return Step(delay: wait, state: State(phraseIndex: state.phraseIndex, characterCount: remaining - 1, phase: .erasing))
                }
                return Step(delay: 0, state: State(phraseIndex: nextIndex, characterCount: 0, phase: .typing))
            }
        }
    }
}

// MARK: - DSTypewriterText

public struct DSTypewriterText: View {
    let phrases: [String]
    let style: DSTextStyle
    let typingSpeed: TimeInterval
    let erasingSpeed: TimeInterval
    let holdDuration: TimeInterval
    let loops: Bool
    let caretColor: Color?

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phraseIndex = 0
    @State private var typedCharacterCount = 0
    @State private var caretVisible = true
    @State private var measuredLineHeight: CGFloat = 0
    @State private var steppingTask: Task<Void, Never>?

    /// - Parameters:
    ///   - phrases: The phrases to cycle through, in order. An empty array renders nothing.
    ///   - style: Text style for the phrases. Defaults to `.title1`.
    ///   - typingSpeed: Seconds per character while typing in.
    ///   - erasingSpeed: Seconds per character while erasing. Should be faster than `typingSpeed`.
    ///   - holdDuration: Seconds a fully-typed phrase stays on screen before erasing.
    ///   - loops: When `false`, stops on the last phrase fully typed (caret keeps blinking) instead of cycling forever.
    ///   - caretColor: Caret fill. Defaults to the theme accent.
    public init(
        _ phrases: [String],
        style: DSTextStyle = .title1,
        typingSpeed: TimeInterval = 0.06,
        erasingSpeed: TimeInterval = 0.03,
        holdDuration: TimeInterval = 1.4,
        loops: Bool = true,
        caretColor: Color? = nil
    ) {
        self.phrases = phrases
        self.style = style
        self.typingSpeed = typingSpeed
        self.erasingSpeed = erasingSpeed
        self.holdDuration = holdDuration
        self.loops = loops
        self.caretColor = caretColor
    }

    // MARK: Derived text

    /// The phrase currently animating. Empty (and safe) if `phraseIndex` is out of range.
    private var currentPhrase: String {
        phrases.indices.contains(phraseIndex) ? phrases[phraseIndex] : ""
    }

    /// A grapheme-safe prefix of `currentPhrase` — built from `Character`s, never bytes.
    private var typedText: String {
        DSTypewriterTextLogic.visibleText(of: currentPhrase, count: typedCharacterCount)
    }

    /// What the visible row actually shows: the half-typed fragment normally,
    /// the full phrase under Reduce Motion.
    private var displayedText: String {
        reduceMotion ? currentPhrase : typedText
    }

    private var resolvedCaretColor: Color { caretColor ?? theme.accent }

    /// Static and fully opaque under Reduce Motion (still "intentional", never hidden);
    /// otherwise driven by the blinking `caretVisible` toggle.
    private var caretOpacity: Double {
        reduceMotion ? 1 : (caretVisible ? 1 : 0)
    }

    // MARK: Body

    public var body: some View {
        if phrases.isEmpty {
            EmptyView()
        } else {
            ZStack(alignment: .leading) {
                // Sizer: every phrase stacked invisibly, so the block reserves the
                // width and height of the widest one and nothing reflows as
                // characters appear. Measuring all of them beats picking the
                // longest by character count — "WWW" is wider than "iiiiii".
                ZStack(alignment: .leading) {
                    ForEach(Array(phrases.enumerated()), id: \.offset) { _, candidate in
                        phraseRow(text: candidate, caretOpacity: 0)
                    }
                }
                .opacity(0)
                .accessibilityHidden(true)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: DSTypewriterLineHeightKey.self,
                            value: proxy.size.height
                        )
                    }
                )

                phraseRow(text: displayedText, caretOpacity: caretOpacity)
            }
            .onPreferenceChange(DSTypewriterLineHeightKey.self) { measuredLineHeight = $0 }
            .animation(
                DSMotion.loop(.easeInOut(duration: Metrics.caretBlinkDuration), unless: reduceMotion),
                value: caretVisible
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(currentPhrase)
            .accessibilityAddTraits(.updatesFrequently)
            .onAppear {
                caretVisible = false
                restart()
            }
            .onDisappear {
                steppingTask?.cancel()
                steppingTask = nil
            }
            .onChange(of: phrases) { _, _ in restart() }
            .onChange(of: reduceMotion) { _, _ in restart() }
        }
    }

    @ViewBuilder
    private func phraseRow(text: String, caretOpacity: Double) -> some View {
        HStack(spacing: Metrics.caretGap) {
            Text(text)
                .ds(style)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)

            RoundedRectangle(cornerRadius: Metrics.caretCornerRadius, style: .continuous)
                .fill(resolvedCaretColor)
                .frame(width: Metrics.caretWidth, height: measuredLineHeight)
                .opacity(caretOpacity)
        }
    }

    // MARK: Stepping task

    private func restart() {
        steppingTask?.cancel()
        steppingTask = nil

        let script = DSTypewriterTextLogic.Script(
            phrases: phrases,
            typingSpeed: typingSpeed,
            erasingSpeed: erasingSpeed,
            holdDuration: holdDuration,
            loops: loops,
            reduceMotion: reduceMotion
        )
        show(script.start)
        guard !script.isStatic else { return }

        steppingTask = Task { @MainActor in
            var state = script.start
            while let step = script.step(after: state) {
                if step.delay > 0 {
                    // Throws only on cancellation, which the check below handles.
                    try? await Task.sleep(nanoseconds: UInt64(step.delay * 1_000_000_000))
                } else {
                    await Task.yield()
                }
                guard !Task.isCancelled else { return }
                state = step.state
                show(state)
            }
        }
    }

    private func show(_ state: DSTypewriterTextLogic.State) {
        phraseIndex = state.phraseIndex
        typedCharacterCount = state.characterCount
    }
}

// MARK: - Preview

#if DEBUG
private struct DSTypewriterTextPreviewHost: View {
    @State private var theme = DSTheme()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Looping, multi-phrase").ds(.overline, color: DSColors.textSecondary)
                    DSTypewriterText(
                        ["Design at the speed of thought.", "Glass over paper.", "No borders. Ever."],
                        style: .title1
                    )
                }

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Non-looping, single phrase").ds(.overline, color: DSColors.textSecondary)
                    DSTypewriterText(
                        ["Types once, then stops."],
                        style: .title2,
                        loops: false
                    )
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Typewriter — Light") {
    DSTypewriterTextPreviewHost().preferredColorScheme(.light)
}

#Preview("Typewriter — Dark") {
    DSTypewriterTextPreviewHost().preferredColorScheme(.dark)
}
#endif
