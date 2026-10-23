import SwiftUI

// MARK: - Design System Number Ticker
// A number that rolls like an odometer: every digit is a 0-9 column that
// slides to its new value, staggered from the units digit, while separators,
// currency symbols and the decimal point stay put.
//
// How it avoids layout jitter and per-frame work:
//
// 1. **One layout, no GeometryReader.** `RollingColumnLayout` sizes itself to
//    its first child (the "0") and places the glyphs (0-9 plus a sentinel 9 before and 0 after) at `(i - position)`
//    glyph-heights. `position` is its `animatableData`, so a spring on the
//    digit interpolates the offset inside the layout pass itself.
// 2. **Identity counts from the right.** The units digit keeps its identity
//    when 99 becomes 100; only the new leading digit enters, with a short fade
//    and rise.
// 3. **Sizes come from the font.** Monospaced digits (the DS numeric and
//    display styles) mean every column is the same width, and the glyph height
//    is measured from the text itself, never hard-coded.

// MARK: - Metrics

private enum Metrics {
    /// Delay added per slot, counted from the units digit. Small on purpose: the
    /// roll should read as one wave, not as a row of separate animations.
    static let stagger: Double = 0.03
    /// How far a slot rises while entering or leaving as the digit count changes.
    static let enterOffset: CGFloat = DSSpacing.xs
    /// Digits in a rolling column.
    static let digitCount: Int = 10
}

// MARK: - Slot

/// One character cell of the formatted number.
struct DSNumberTickerSlot: Equatable, Identifiable, Sendable {
    /// Position counted from the right (0 = last character). Stable when the
    /// number grows or shrinks on the left.
    let id: Int
    let character: Character
    /// The value of an ASCII digit; `nil` for separators, symbols and signs.
    let digit: Int?
}

// MARK: - Rolling column layout

/// Stacks its children vertically (each as tall as the first) and shifts the
/// whole stack so child `position` sits in the frame. Animating `position`
/// animates the roll.
private struct RollingColumnLayout: Layout {
    var position: Double

    nonisolated var animatableData: Double {
        get { position }
        set { position = newValue }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews.first?.sizeThatFits(.unspecified) ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let cell = bounds.height
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX, y: bounds.minY + (Double(index) - position) * cell),
                anchor: .topLeading,
                proposal: .unspecified
            )
        }
    }
}

// MARK: - DSNumberTicker

/// A number whose digits roll to their new values, odometer style.
///
///     DSNumberTicker(balance, format: .currency(code: "USD"))
///     DSNumberTicker(steps)
///
/// The value is formatted with the `FormatStyle` you pass, so grouping,
/// decimals, currency and percent follow the user's locale.
public struct DSNumberTicker: View {

    // MARK: Configuration

    private let formatted: String
    private let style: DSTextStyle
    private let color: Color?

    // MARK: Environment

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - value: The number to show.
    ///   - format: Any format style that turns a `Double` into a `String`:
    ///     `.number`, `.currency(code:)`, `.percent`, `.number.precision(...)`.
    ///   - style: Text style. Use one with monospaced digits (`.displayLarge`,
    ///     `.displayMedium`, `.numeric`) so the columns never jitter.
    ///   - color: Text color. Defaults to the theme's primary text color.
    public init<F: FormatStyle>(
        _ value: Double,
        format: F,
        style: DSTextStyle = .displayMedium,
        color: Color? = nil
    ) where F.FormatInput == Double, F.FormatOutput == String {
        self.formatted = format.format(value)
        self.style = style
        self.color = color
    }

    /// Shows an integer with grouping separators and no decimals.
    public init(_ value: Int, style: DSTextStyle = .displayMedium, color: Color? = nil) {
        self.init(
            Double(value),
            format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0)),
            style: style,
            color: color
        )
    }

    // MARK: Body

    public var body: some View {
        let slots = Self.slots(for: formatted)
        let ink = color ?? theme.palette.textPrimary

        HStack(spacing: 0) {
            ForEach(slots) { slot in
                slotView(slot, ink: ink)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .offset(y: Metrics.enterOffset))
                    )
            }
        }
        // Never compress: squeezed, the static slots ("US$", separators) would clip
        // while the digit columns keep their width. Give the ticker room instead.
        .fixedSize()
        .animation(reduceMotion ? DSAnimation.fast : DSAnimation.springSmooth, value: slots.map(\.id))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityLabel(for: formatted))
        .accessibilityAddTraits(.updatesFrequently)
    }

    @ViewBuilder
    private func slotView(_ slot: DSNumberTickerSlot, ink: Color) -> some View {
        if let digit = slot.digit {
            if reduceMotion {
                // A resting state, not a skip: the new digit is shown at once
                // and the old one crossfades out.
                ZStack {
                    Text("0").ds(style, color: ink).hidden()
                    Text(String(digit)).ds(style, color: ink)
                        .id(digit)
                        .transition(.opacity)
                }
                .animation(DSAnimation.fast, value: digit)
            } else {
                // A "9" sits before the 0 and a "0" after the 9: the spring
                // overshoots a few percent, and on a 9 -> 0 wrap that would
                // otherwise reveal an empty band past the end of the column.
                RollingColumnLayout(position: Double(digit + 1)) {
                    Text(String(Metrics.digitCount - 1)).ds(style, color: ink)
                    ForEach(0..<Metrics.digitCount, id: \.self) { value in
                        Text(String(value)).ds(style, color: ink)
                    }
                    Text("0").ds(style, color: ink)
                }
                .clipped()
                .animation(
                    DSAnimation.springSmooth.delay(Double(slot.id) * Metrics.stagger),
                    value: digit
                )
            }
        } else {
            Text(String(slot.character)).ds(style, color: ink)
        }
    }

    // MARK: Pure logic

    /// Splits a formatted string into slots, identified from the right.
    static func slots(for formatted: String) -> [DSNumberTickerSlot] {
        let characters = Array(formatted)
        return characters.enumerated().map { index, character in
            DSNumberTickerSlot(
                id: characters.count - 1 - index,
                character: character,
                digit: character.isASCII ? character.wholeNumberValue : nil
            )
        }
    }

    /// VoiceOver reads the whole formatted value, not column by column.
    static func accessibilityLabel(for formatted: String) -> String {
        formatted
    }
}

// MARK: - Preview

#if DEBUG
private struct DSNumberTickerPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var balance: Double = 1_284.50
    @State private var steps = 8_432
    @State private var progress: Double = 0.42

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        Text("Balance").ds(.overline, color: DSColors.textSecondary)
                        DSNumberTicker(balance, format: .currency(code: "USD"))
                        DSButton("Random jump", size: .small) {
                            balance = Double.random(in: 0...25_000).rounded()
                        }
                    }
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        Text("Steps").ds(.overline, color: DSColors.textSecondary)
                        DSNumberTicker(steps, style: .displayLarge)
                        HStack {
                            DSButton("+1", variant: .secondary, size: .small) { steps += 1 }
                            DSButton("Jump to 99 999", variant: .secondary, size: .small) { steps = 99_999 }
                        }
                    }
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        Text("Goal").ds(.overline, color: DSColors.textSecondary)
                        DSNumberTicker(progress, format: .percent, style: .numeric)
                        DSButton("Next", variant: .ghost, size: .small) {
                            progress = Double.random(in: 0...1)
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
}

#Preview("Number Ticker — Light") {
    DSNumberTickerPreviewHost().preferredColorScheme(.light)
}

#Preview("Number Ticker — Dark") {
    DSNumberTickerPreviewHost().preferredColorScheme(.dark)
}
#endif
