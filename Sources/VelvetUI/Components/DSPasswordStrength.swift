import SwiftUI

// MARK: - Design System Password Strength
// A strength meter for a new-password field: four segments that fill and
// change colour as the password gets stronger, a one-word level ("Weak",
// "Fair", "Good", "Strong") and the one change that would help most ("Add a
// number", "Avoid common passwords"). Sign-up, change password, set a PIN
// phrase, create a vault.
//
// Why a component: every app rebuilds this with ad-hoc rules that reward
// "Password1!" and punish a long passphrase. Velvet's rules follow current
// guidance (NIST SP 800-63B): length counts most, a common password is weak
// however it is decorated, and a mix of character kinds only lifts a password
// that is already long enough. The meter is advisory; enforce your real rules
// on the server.
//
// The rules (the analysis, the level, the hint, the spoken value, when the
// haptic fires) live in `DSPasswordStrengthLogic`, a pure type the tests pin.
//
// Feel: filled segments grow from the leading edge on
// `DSAnimation.springSnappy` and cross-fade to the level's colour. Reaching
// "Strong" fires `haptic` once (a `.light` tap by default), not on every
// keystroke. Under Reduce Motion segments fade instead of growing. No borders:
// empty segments are flat `theme.subtleFill` capsules.

/// How strong a password is, from nothing typed to strong. Ordered, so
/// `DSPasswordStrength.level(of: password) >= .good` reads naturally.
public enum DSPasswordStrengthLevel: Int, CaseIterable, Comparable, Sendable {
    case empty, weak, fair, good, strong

    /// The word the meter shows: "Weak", "Fair", "Good", "Strong" ("Empty" when nothing is typed).
    public var title: String {
        switch self {
        case .empty:  return "Empty"
        case .weak:   return "Weak"
        case .fair:   return "Fair"
        case .good:   return "Good"
        case .strong: return "Strong"
        }
    }

    public static func < (lhs: DSPasswordStrengthLevel, rhs: DSPasswordStrengthLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// The password-strength rules, kept out of the view so they can be tested.
enum DSPasswordStrengthLogic {
    /// The kinds of character a password can mix.
    enum Kind: CaseIterable, Hashable {
        case lowercase, uppercase, digit, symbol

        static func of(_ character: Character) -> Kind {
            if character.isNumber { return .digit }
            if character.isUppercase { return .uppercase }
            if character.isLetter { return .lowercase }
            return .symbol
        }
    }

    /// What the rules know about a password.
    struct Analysis: Equatable {
        var length: Int
        var kinds: Set<Kind>
        var distinct: Int
        /// The password, without the digits and symbols around it, is a well-known one.
        var isCommon: Bool
        /// Four or more characters in a straight run: "1234", "dcba", "aaaa".
        var hasRun: Bool
    }

    /// The most-used passwords and keyboard walks, lowercased. A password is
    /// common when it is one of these, or one of these with digits and symbols
    /// around it ("Password1!", "qwerty123").
    static let common: Set<String> = [
        "password", "passw0rd", "p@ssword", "p@ssw0rd", "qwerty", "qwertyuiop", "asdfgh", "asdfghjkl",
        "zxcvbn", "letmein", "iloveyou", "welcome", "admin", "administrator", "monkey", "dragon",
        "football", "baseball", "sunshine", "princess", "trustno", "master", "login", "secret",
        "abc", "abcdef", "abcdefgh", "qwe", "starwars", "superman", "batman", "shadow", "hello",
        "freedom", "whatever", "changeme", "default", "guest", "test", "user",
        "123456", "1234567", "12345678", "123456789", "1234567890", "111111", "000000", "123123", "654321",
    ]

    /// The shortest straight run that counts against a password.
    static let runLength = 4

    /// Characters needed before a password can be more than weak, at least 1.
    static func clampedMinimum(_ minLength: Int) -> Int { max(1, minLength) }

    static func analyze(_ password: String) -> Analysis {
        let characters = Array(password)
        let lowered = password.lowercased()
        let core = lowered.trimmingCharacters(in: CharacterSet.letters.inverted)
        return Analysis(
            length: characters.count,
            kinds: Set(characters.map(Kind.of)),
            distinct: Set(characters).count,
            isCommon: common.contains(lowered) || common.contains(core),
            hasRun: hasRun(lowered)
        )
    }

    /// Whether `text` has `runLength` characters in a row that step by the same
    /// amount: +1 ("abcd", "1234"), -1 ("4321") or 0 ("aaaa").
    static func hasRun(_ text: String) -> Bool {
        let scalars = text.unicodeScalars.map { Int($0.value) }
        guard scalars.count >= runLength else { return false }
        var length = 1
        var step: Int?
        for index in scalars.indices.dropFirst() {
            let delta = scalars[index] - scalars[index - 1]
            if abs(delta) <= 1, delta == step {
                length += 1
            } else {
                step = abs(delta) <= 1 ? delta : nil
                length = step == nil ? 1 : 2
            }
            if length >= runLength { return true }
        }
        return false
    }

    /// The level for a password.
    ///
    /// - Empty: nothing typed.
    /// - Weak: shorter than `minLength`, a common password, or three distinct
    ///   characters or fewer.
    /// - Otherwise a score: one point per kind of character, one more at
    ///   `minLength + 4` characters, at twice and at three times `minLength`,
    ///   minus one for a straight run. 2 or less is Fair, 3–4 Good, 5+ Strong.
    static func level(_ password: String, minLength: Int) -> DSPasswordStrengthLevel {
        guard !password.isEmpty else { return .empty }
        let analysis = analyze(password)
        let minimum = clampedMinimum(minLength)
        if analysis.isCommon || analysis.length < minimum || analysis.distinct <= 3 { return .weak }
        let score = analysis.kinds.count
            + (analysis.length >= minimum + 4 ? 1 : 0)
            + (analysis.length >= minimum * 2 ? 1 : 0)
            + (analysis.length >= minimum * 3 ? 1 : 0)
            - (analysis.hasRun ? 1 : 0)
        switch score {
        case ...2: return .fair
        case 3...4: return .good
        default: return .strong
        }
    }

    /// The one change that would help most, or nil once the password is strong.
    static func hint(_ password: String, minLength: Int) -> String? {
        let minimum = clampedMinimum(minLength)
        let tooShort = "Use at least \(minimum) character\(minimum == 1 ? "" : "s")"
        guard !password.isEmpty else { return tooShort }
        let analysis = analyze(password)
        if analysis.isCommon { return "Avoid common passwords" }
        if analysis.length < minimum { return tooShort }
        if analysis.distinct <= 3 { return "Avoid repeating characters" }
        if level(password, minLength: minLength) == .strong { return nil }
        if analysis.hasRun { return "Avoid sequences like 1234 or abcd" }
        if !analysis.kinds.contains(.digit) { return "Add a number" }
        if !analysis.kinds.contains(.symbol) { return "Add a symbol" }
        if !analysis.kinds.contains(.uppercase) { return "Add a capital letter" }
        return "Make it longer"
    }

    /// Segments filled for a level, out of `segmentCount`.
    static let segmentCount = 4

    static func filledSegments(_ level: DSPasswordStrengthLevel) -> Int {
        min(level.rawValue, segmentCount)
    }

    /// What VoiceOver reads: the level, then the hint ("Fair. Add a number").
    static func accessibilityValue(level: DSPasswordStrengthLevel, hint: String?) -> String {
        guard let hint else { return level.title }
        return "\(level.title). \(hint)"
    }

    /// The haptic fires once, when the password becomes strong.
    static func firesHaptic(from old: DSPasswordStrengthLevel, to new: DSPasswordStrengthLevel) -> Bool {
        new == .strong && old < .strong
    }

    /// Announced to VoiceOver when the level changes; nil when it empties.
    static func announcement(from old: DSPasswordStrengthLevel, to new: DSPasswordStrengthLevel) -> String? {
        guard old != new, new != .empty else { return nil }
        return "Password strength: \(new.title)"
    }
}

private enum Metrics {
    /// Segment thickness: DSSpacing.xxs (4).
    static let barHeight: CGFloat = DSSpacing.xxs
    /// Gap between segments: DSSpacing.xxs (4).
    static let barGap: CGFloat = DSSpacing.xxs
    /// An empty segment's fill, collapsed at the leading edge. Not 0, which
    /// makes the transform singular.
    static let collapsedScale: CGFloat = 0.001
}

/// A strength meter for a new password: four segments that fill and change
/// colour, the level ("Weak" … "Strong") and the one change that would help
/// most. Put it under the password field and pass the same text.
public struct DSPasswordStrength: View {
    /// How strong a password is: `.empty`, `.weak`, `.fair`, `.good`, `.strong`.
    public typealias Level = DSPasswordStrengthLevel

    /// The level the meter shows for `password`, for gating a submit button on
    /// the same rules ("Create account" from `.good`).
    nonisolated public static func level(of password: String, minLength: Int = 8) -> Level {
        DSPasswordStrengthLogic.level(password, minLength: minLength)
    }

    private let password: String
    private let minLength: Int
    private let haptic: DSHapticStyle
    private let label: String

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - password: The password being typed. Pass the field's text.
    ///   - minLength: Characters needed before it can be more than weak. Defaults to 8.
    ///   - haptic: Fired once when the password becomes strong. Defaults to `.light`.
    ///   - accessibilityLabel: What VoiceOver reads before the level. Defaults to "Password strength".
    public init(
        password: String,
        minLength: Int = 8,
        haptic: DSHapticStyle = .light,
        accessibilityLabel: String = "Password strength"
    ) {
        self.password = password
        self.minLength = minLength
        self.haptic = haptic
        self.label = accessibilityLabel
    }

    public var body: some View {
        let level = DSPasswordStrengthLogic.level(password, minLength: minLength)
        let hint = DSPasswordStrengthLogic.hint(password, minLength: minLength)

        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            bar(level)
            HStack(alignment: .firstTextBaseline, spacing: DSSpacing.xs) {
                if level != .empty {
                    Text(level.title)
                        .ds(.footnote, color: theme.palette.textPrimary)
                        .contentTransition(.opacity)
                }
                if let hint {
                    Text(hint)
                        .ds(.caption1, color: theme.palette.textSecondary)
                        .contentTransition(.opacity)
                }
                Spacer(minLength: 0)
            }
            .animation(DSAnimation.fast, value: level)
            .animation(DSAnimation.fast, value: hint)
        }
        .onChange(of: level) { old, new in
            if DSPasswordStrengthLogic.firesHaptic(from: old, to: new) {
                DSHapticEngine.shared.fire(haptic)
            }
            if let message = DSPasswordStrengthLogic.announcement(from: old, to: new) {
                AccessibilityNotification.Announcement(message).post()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(DSPasswordStrengthLogic.accessibilityValue(level: level, hint: hint))
    }

    // MARK: Segments

    private func bar(_ level: Level) -> some View {
        let filled = DSPasswordStrengthLogic.filledSegments(level)
        let color = fill(for: level)

        return HStack(spacing: Metrics.barGap) {
            ForEach(0..<DSPasswordStrengthLogic.segmentCount, id: \.self) { index in
                let isOn = index < filled
                Capsule()
                    .fill(theme.subtleFill)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(color)
                            .scaleEffect(x: isOn || reduceMotion ? 1 : Metrics.collapsedScale, anchor: .leading)
                            .opacity(isOn ? 1 : 0)
                    }
                    .frame(height: Metrics.barHeight)
                    .animation(reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy, value: isOn)
            }
        }
        .animation(DSAnimation.normal, value: level)
    }

    private func fill(for level: Level) -> Color {
        switch level {
        case .empty, .weak: return theme.palette.error
        case .fair:         return theme.palette.warning
        case .good, .strong: return theme.palette.success
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSPasswordStrengthPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var password = "sunflower"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        DSTextField(label: "New password", placeholder: "At least 8 characters", text: $password, isSecure: true)
                        DSPasswordStrength(password: password)
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    ForEach(["", "password1", "sunflower", "Sunflower7", "correct horse battery staple"], id: \.self) { sample in
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text(sample.isEmpty ? "(empty)" : sample).ds(.caption1, color: DSColors.textTertiary)
                            DSPasswordStrength(password: sample)
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

#Preview("Password Strength — Light") {
    DSPasswordStrengthPreviewHost().preferredColorScheme(.light)
}

#Preview("Password Strength — Dark") {
    DSPasswordStrengthPreviewHost().preferredColorScheme(.dark)
}
#endif
