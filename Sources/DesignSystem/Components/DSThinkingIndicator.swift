import SwiftUI

// MARK: - Design System Thinking Indicator
// The "the assistant is working" state: a symbol that carries the motion and a
// phrase that carries the meaning. Built for AI / background-processing states
// where a plain spinner reads as frozen and a progress bar would be a lie —
// there is no fraction to report, only that something is still happening.
//
// The symbol leans on the platform's own SF Symbol effects (breathing layers,
// iterating variable color) rather than a hand-rolled animation loop, so it
// stays in sync with the rest of the system's "processing" language. The
// phrase cycles on a wall-clock schedule (`TimelineView(.periodic)`) and
// assembles itself letter by letter with `DSAnimation.stagger(index:)` — the
// same cadence `dsStaggerIn` uses for list rows, here applied to characters.
//
// Technique inspired by: open-swiftui-animations/AIThinkingAnimations

// MARK: - Metrics

/// Layout constants, all expressed in terms of existing tokens — nothing raw.
private enum Metrics {
    /// Gap between the symbol and the phrase. `DSSpacing.xs` — the token used
    /// everywhere else for compact spacing between two related elements.
    static let iconGap: CGFloat = DSSpacing.xs
    /// How far a letter rises into place as it fades in. `DSSpacing.xxs` — the
    /// smallest spacing step; enough to read as motion, too small to jitter.
    static let letterRise: CGFloat = DSSpacing.xxs
}

// MARK: - DSThinkingIndicator

public struct DSThinkingIndicator: View {
    let phrases: [String]
    let symbol: String
    let interval: TimeInterval
    let tint: Color?

    @State private var startDate = Date()
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - phrases: Cycled in order, looping. A single phrase disables cycling
    ///     but still renders (and still assembles once on appear).
    ///   - symbol: SF Symbol name for the leading animated glyph.
    ///   - interval: Seconds each phrase stays on screen before the next one assembles.
    ///   - tint: Letter color. Defaults to `theme.ink`. The symbol always uses the
    ///     theme gradient regardless of this value — it is decorative, not textual.
    public init(
        phrases: [String] = ["Thinking", "Weighing options", "Almost there"],
        symbol: String = "sparkles",
        interval: TimeInterval = 2.6,
        tint: Color? = nil
    ) {
        self.phrases = phrases
        self.symbol = symbol
        self.interval = interval
        self.tint = tint
    }

    private var letterColor: Color { tint ?? theme.ink }


    public var body: some View {
        TimelineView(.periodic(from: startDate, by: max(interval, 0.1))) { context in
            let index = phraseIndex(at: context.date)
            let phrase = phrases.indices.contains(index) ? phrases[index] : ""

            HStack(spacing: Metrics.iconGap) {
                symbolView
                phraseView(phrase, index: index)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(phrase)
            .accessibilityAddTraits(.updatesFrequently)
        }
    }

    /// Which phrase should be showing at `date`, derived from wall-clock time
    /// rather than stored state — nothing to desync on view re-creation.
    private func phraseIndex(at date: Date) -> Int {
        guard phrases.count > 1, interval > 0 else { return 0 }
        let elapsed = max(0, date.timeIntervalSince(startDate))
        return Int(elapsed / interval) % phrases.count
    }

    // MARK: Symbol

    private var symbolView: some View {
        Image(systemName: symbol)
            .font(DSTextStyle.footnote.font)
            .foregroundStyle(theme.gradient.horizontalGradient)
            .symbolEffect(.breathe.byLayer, isActive: !reduceMotion)
            .symbolEffect(.variableColor.iterative, isActive: !reduceMotion)
            .accessibilityHidden(true)
    }

    // MARK: Phrase

    @ViewBuilder
    private func phraseView(_ phrase: String, index: Int) -> some View {
        ZStack(alignment: .leading) {
            // Sizer: every phrase stacked invisibly, so the row reserves the width
            // of the widest one and nothing around it shifts as they cycle.
            // Measuring all of them beats picking the longest by character count —
            // "Wow" is wider than "iiiiii", so a count-based guess under-reserves.
            ForEach(Array(phrases.enumerated()), id: \.offset) { _, candidate in
                Text(candidate)
                    .dsTextStyle(.footnote)
                    .opacity(0)
                    .accessibilityHidden(true)
            }

            Group {
                if reduceMotion {
                    // Cycling is information, not decoration: it keeps happening,
                    // just as a plain cross-fade instead of a per-letter assembly.
                    Text(phrase)
                        .dsTextStyle(.footnote, color: letterColor)
                        .id(index)
                        .transition(.opacity)
                } else {
                    HStack(spacing: 0) {
                        ForEach(Array(phrase.enumerated()), id: \.offset) { offset, character in
                            DSThinkingLetter(character: character, index: offset, color: letterColor)
                        }
                    }
                    .id(index)
                }
            }
            .animation(reduceMotion ? DSAnimation.fast : nil, value: index)
        }
    }
}

// MARK: - Letter

/// One character of a cycling phrase, fading and rising into place on its own
/// staggered delay. A fresh `DSThinkingLetter` is mounted every time the parent
/// phrase's `.id(index)` changes, so `onAppear` — and the stagger — fires again
/// for every cycle, not just the first.
private struct DSThinkingLetter: View {
    let character: Character
    let index: Int
    let color: Color

    @State private var isVisible = false

    var body: some View {
        Text(String(character))
            .dsTextStyle(.footnote, color: color)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : Metrics.letterRise)
            .onAppear {
                withAnimation(DSAnimation.stagger(index: index)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSThinkingIndicatorPreviewHost: View {
    @State private var theme = DSTheme()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    DSThinkingIndicator()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    DSThinkingIndicator(
                        phrases: ["Reading your notes", "Cross-checking sources", "Drafting a reply"],
                        symbol: "brain",
                        interval: 2.0
                    )
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

#Preview("Thinking — Light") {
    DSThinkingIndicatorPreviewHost().preferredColorScheme(.light)
}

#Preview("Thinking — Dark") {
    DSThinkingIndicatorPreviewHost().preferredColorScheme(.dark)
}
#endif
