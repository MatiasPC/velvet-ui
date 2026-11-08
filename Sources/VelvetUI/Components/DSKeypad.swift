import SwiftUI

// MARK: - Design System Keypad
// An on-screen numeric keypad for the screens where the system keyboard is the
// wrong tool: entering an amount (send money, tip, top up), a passcode or PIN,
// a quantity at a kiosk. Twelve keys on a 3 × 4 grid: 1–9, then the decimal
// separator (only when the value takes decimals), 0 and delete.
//
// The keypad edits a `String`, not a number, because what people type is text
// until they're done: "12." and "0.50" are valid states of an amount that no
// `Double` can hold. The rules that keep that text well-formed (one separator,
// at most `decimalPlaces` after it, no "007" in an amount, a `maxLength` on the
// digits) live in `DSKeypadLogic`, a pure type the tests pin.
//
// Feel: every key dips with `DSPress.scale` and its fill deepens while held. An
// accepted key fires a light tap (a keyboard click, not a confirmation). A key
// the rules refuse (a second separator, a third decimal, past `maxLength`,
// delete on empty) leaves the text alone, fires `.warning` and wiggles that key
// once with `dsJiggle` — the same refusal vocabulary as `DSStepper`.
//
// Like `DSSlider`, the keypad draws no value: show your own read-out above it,
// so the app decides the currency, the masking of a PIN and the layout.

/// One key on the pad.
enum DSKeypadKey: Hashable, Sendable {
    case digit(Int)
    case decimal
    case delete
}

/// The editing rules, kept out of the view so they can be tested.
enum DSKeypadLogic {
    /// What pressing a key does to the text.
    enum Outcome: Equatable {
        /// The key applied; the new text.
        case accepted(String)
        /// The key would make the text invalid; leave it as it is.
        case refused
    }

    /// The keys, row by row. `nil` is an empty slot (bottom-left when the value takes no decimals).
    static func rows(decimalPlaces: Int) -> [[DSKeypadKey?]] {
        [
            [.digit(1), .digit(2), .digit(3)],
            [.digit(4), .digit(5), .digit(6)],
            [.digit(7), .digit(8), .digit(9)],
            [decimalPlaces > 0 ? .decimal : nil, .digit(0), .delete],
        ]
    }

    /// The number of digits in `text`; the separator doesn't count toward `maxLength`.
    static func digitCount(_ text: String) -> Int {
        text.reduce(0) { $0 + ($1.isASCII && $1.isNumber ? 1 : 0) }
    }

    /// Applies `key` to `text`.
    ///
    /// - `maxLength`: the most digits the text may hold; `nil` (or less than 1) means no limit.
    /// - `decimalPlaces`: digits allowed after the separator. `0` makes the pad integer-only:
    ///   no separator key, and leading zeros are kept, so a PIN can start with 0. Above `0`
    ///   the text is an amount: a lone leading "0" is replaced by the next digit ("0" → "5"),
    ///   "00" is refused, and a separator typed first becomes "0.".
    /// - `separator`: the locale's decimal separator.
    static func apply(
        _ key: DSKeypadKey,
        to text: String,
        maxLength: Int?,
        decimalPlaces: Int,
        separator: String
    ) -> Outcome {
        let limit = maxLength.flatMap { $0 > 0 ? $0 : nil }
        let isAmount = decimalPlaces > 0
        let hasSeparator = isAmount && !separator.isEmpty && text.contains(separator)

        switch key {
        case .digit(let raw):
            guard (0...9).contains(raw) else { return .refused }
            let digit = String(raw)
            if hasSeparator {
                let fraction = text.components(separatedBy: separator).last ?? ""
                guard digitCount(fraction) < decimalPlaces else { return .refused }
            } else if isAmount && text == "0" {
                // An amount never reads "05" or "00": the next digit replaces the zero.
                return raw == 0 ? .refused : .accepted(digit)
            }
            if let limit, digitCount(text) >= limit { return .refused }
            return .accepted(text + digit)

        case .decimal:
            guard isAmount, !separator.isEmpty, !hasSeparator else { return .refused }
            if text.isEmpty { return .accepted("0" + separator) }
            return .accepted(text + separator)

        case .delete:
            guard !text.isEmpty else { return .refused }
            if !separator.isEmpty, text.hasSuffix(separator) {
                return .accepted(String(text.dropLast(separator.count)))
            }
            return .accepted(String(text.dropLast()))
        }
    }

    /// What VoiceOver reads for a key.
    static func accessibilityLabel(for key: DSKeypadKey) -> String {
        switch key {
        case .digit(let digit): return String(digit)
        case .decimal:          return "Decimal point"
        case .delete:           return "Delete"
        }
    }
}

private enum Metrics {
    /// Key height: DSSpacing.massive (64). Comfortably above the 44 pt minimum, and
    /// four rows plus gaps fit under a read-out on the smallest iPhone.
    static let keyHeight: CGFloat = DSSpacing.massive
    /// Opacity of the ink wash laid over a key while it is held.
    static let pressedWash: Double = 0.10
    /// Opacity of a disabled pad, the same as `DSToggle`.
    static let disabledOpacity: Double = 0.5
}

/// A numeric keypad for amounts, passcodes and quantities.
///
/// Bind it to a `String`. Each key edits the text by the rules in the parameters
/// below; a key that would break them is refused with a warning haptic and a
/// wiggle, and the text is left as it was. The keypad draws no value: show your
/// own read-out (an amount, PIN dots) above it.
///
/// The decimal separator follows the `\.locale` environment ("," in many
/// locales). Parse the result with the same locale, e.g.
/// `Decimal(string: text, locale: locale)`.
public struct DSKeypad: View {
    @Binding private var text: String
    private let maxLength: Int?
    private let decimalPlaces: Int
    private let haptic: DSHapticStyle

    /// One counter per key, bumped on each refusal to retrigger that key's wiggle.
    @State private var refusals: [DSKeypadKey: Int] = [:]
    @DSThemed private var theme
    @Environment(\.locale) private var locale
    @Environment(\.isEnabled) private var isEnabled

    /// - Parameters:
    ///   - text: The entered text. Keys append to it and delete from its end.
    ///   - maxLength: The most digits it may hold (the separator doesn't count). `nil`, the default, means no limit. Use 4 or 6 for a PIN.
    ///   - decimalPlaces: Digits allowed after the decimal separator. `0`, the default, hides the separator key and keeps leading zeros (a PIN or a code). Use `2` for money.
    ///   - haptic: Fired on every accepted key. Defaults to `.light`; a refused key always fires `.warning`.
    public init(
        text: Binding<String>,
        maxLength: Int? = nil,
        decimalPlaces: Int = 0,
        haptic: DSHapticStyle = .light
    ) {
        self._text = text
        self.maxLength = maxLength
        self.decimalPlaces = max(0, decimalPlaces)
        self.haptic = haptic
    }

    private var separator: String { locale.decimalSeparator ?? "." }

    public var body: some View {
        Grid(horizontalSpacing: DSSpacing.sm, verticalSpacing: DSSpacing.sm) {
            ForEach(Array(DSKeypadLogic.rows(decimalPlaces: decimalPlaces).enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, key in
                        if let key {
                            keyButton(key)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: Metrics.keyHeight)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Keypad")
    }

    // MARK: Keys

    private func keyButton(_ key: DSKeypadKey) -> some View {
        Button {
            press(key)
        } label: {
            keyLabel(key)
                .frame(maxWidth: .infinity, minHeight: Metrics.keyHeight)
                .contentShape(RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
        }
        .buttonStyle(DSKeypadKeyStyle(isDigit: isDigit(key), fill: theme.subtleFill, wash: theme.ink))
        .dsJiggle(trigger: refusals[key, default: 0])
        .accessibilityLabel(DSKeypadLogic.accessibilityLabel(for: key))
        .accessibilityAddTraits(.isKeyboardKey)
    }

    @ViewBuilder
    private func keyLabel(_ key: DSKeypadKey) -> some View {
        switch key {
        case .digit(let digit):
            Text(String(digit))
                .ds(.title1, color: theme.palette.textPrimary)
                .monospacedDigit()
        case .decimal:
            Text(separator)
                .ds(.title1, color: theme.palette.textPrimary)
        case .delete:
            Image(systemName: "delete.backward")
                .dsFont(.title2)
                .foregroundStyle(theme.palette.textPrimary)
        }
    }

    private func isDigit(_ key: DSKeypadKey) -> Bool {
        if case .digit = key { return true }
        return false
    }

    // MARK: Behavior

    private func press(_ key: DSKeypadKey) {
        let outcome = DSKeypadLogic.apply(
            key, to: text, maxLength: maxLength, decimalPlaces: decimalPlaces, separator: separator
        )
        switch outcome {
        case .accepted(let next):
            text = next
            DSHapticEngine.shared.fire(haptic)
        case .refused:
            DSHapticEngine.shared.fire(.warning)
            refusals[key, default: 0] += 1
        }
    }
}

// MARK: - Key Style

/// Digit keys sit on a flat nested fill (glass on glass turns muddy, and a pad
/// usually lives on a card or the backdrop); the separator and delete keys are
/// bare glyphs, so the digits read as the keyboard. Every key dips while held,
/// and a faint ink wash deepens it, which is what makes the bare keys visible
/// when pressed.
private struct DSKeypadKeyStyle: ButtonStyle {
    let isDigit: Bool
    let fill: Color
    let wash: Color

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
        configuration.label
            .background {
                ZStack {
                    if isDigit { shape.fill(fill) }
                    shape.fill(wash.opacity(configuration.isPressed ? Metrics.pressedWash : 0))
                }
            }
            .scaleEffect(configuration.isPressed ? DSPress.scale : 1.0)
            .animation(DSPress.animation, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSKeypadPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var amount = ""
    @State private var pin = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(spacing: DSSpacing.lg) {
                        Text(amount.isEmpty ? "$0" : "$" + amount)
                            .ds(.displayMedium)
                            .contentTransition(.numericText())
                            .animation(DSAnimation.springSnappy, value: amount)
                        DSKeypad(text: $amount, maxLength: 7, decimalPlaces: 2)
                    }
                }

                DSCard {
                    VStack(spacing: DSSpacing.lg) {
                        HStack(spacing: DSSpacing.md) {
                            ForEach(0..<4, id: \.self) { i in
                                Circle()
                                    .fill(i < pin.count ? DSColors.primary : DSColors.backgroundSecondary)
                                    .frame(width: DSSpacing.sm, height: DSSpacing.sm)
                            }
                        }
                        DSKeypad(text: $pin, maxLength: 4)
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

#Preview("Keypad — Light") {
    DSKeypadPreviewHost().preferredColorScheme(.light)
}

#Preview("Keypad — Dark") {
    DSKeypadPreviewHost().preferredColorScheme(.dark)
}
#endif
