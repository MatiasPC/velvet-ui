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
// phrase list (or Reduce Motion) changes — no `Timer` anywhere.
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
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
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
        let characters = Array(currentPhrase)
        let count = min(typedCharacterCount, characters.count)
        return String(characters.prefix(count))
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
        phraseIndex = 0
        typedCharacterCount = 0
        guard !phrases.isEmpty else { return }

        steppingTask = Task { @MainActor in
            if reduceMotion {
                await runReducedMotionCycle()
            } else {
                await runTypingCycle()
            }
        }
    }

    /// Full cycle: type in → hold → erase → next phrase. Stops after typing
    /// the last phrase when `loops` is `false`.
    @MainActor
    private func runTypingCycle() async {
        while !Task.isCancelled {
            guard phrases.indices.contains(phraseIndex) else { return }
            let characters = Array(phrases[phraseIndex])
            typedCharacterCount = 0

            guard await typeIn(characters) else { return }
            guard !Task.isCancelled else { return }

            await pause(holdDuration)
            guard !Task.isCancelled else { return }

            let isLastPhrase = phraseIndex == phrases.count - 1
            if isLastPhrase && !loops {
                return
            }

            guard await eraseOut(characters) else { return }
            guard !Task.isCancelled else { return }

            phraseIndex = isLastPhrase ? 0 : phraseIndex + 1
        }
    }

    /// Reduce Motion cycle: no typing/erasing animation, just the full phrase
    /// held for a duration equivalent to `typingSpeed * count + holdDuration`
    /// so the pacing stays readable and the content is always complete.
    @MainActor
    private func runReducedMotionCycle() async {
        while !Task.isCancelled {
            guard phrases.indices.contains(phraseIndex) else { return }
            let characterCount = phrases[phraseIndex].count
            typedCharacterCount = characterCount

            let isLastPhrase = phraseIndex == phrases.count - 1
            await pause(typingSpeed * Double(characterCount) + holdDuration)
            guard !Task.isCancelled else { return }

            if isLastPhrase && !loops {
                return
            }

            phraseIndex = isLastPhrase ? 0 : phraseIndex + 1
        }
    }

    /// Reveals `characters` one at a time. Returns `false` if cancelled mid-way.
    @MainActor
    private func typeIn(_ characters: [Character]) async -> Bool {
        for count in 0...characters.count {
            if Task.isCancelled { return false }
            typedCharacterCount = count
            if count < characters.count {
                await pause(typingSpeed)
                if Task.isCancelled { return false }
            }
        }
        return true
    }

    /// Removes `characters` one at a time, faster than `typeIn`. Returns `false` if cancelled mid-way.
    @MainActor
    private func eraseOut(_ characters: [Character]) async -> Bool {
        var count = characters.count
        while count > 0 {
            if Task.isCancelled { return false }
            await pause(erasingSpeed)
            if Task.isCancelled { return false }
            count -= 1
            typedCharacterCount = count
        }
        return true
    }

    /// `Task.sleep` wrapped so a cancellation error never has to be handled at each call site.
    private func pause(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(max(seconds, 0) * 1_000_000_000))
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
                        ["Design at the speed of thought.", "Glass over gradient.", "No borders. Ever."],
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
