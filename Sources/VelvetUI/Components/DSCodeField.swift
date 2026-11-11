import SwiftUI

// MARK: - Design System Code Field (OTP / Verification)
// A polished one-time-code input for verification and 2FA flows.
// Individual digit boxes with an animated active slot, a blinking caret,
// per-digit haptics, and a shake-on-error reaction — all pure SwiftUI.

public enum DSCodeFieldState {
    /// Default entry state
    case normal
    /// Invalid code — boxes tint red and shake
    case error
    /// Verified code — boxes tint green
    case success
}

public struct DSCodeField: View {
    let length: Int
    @Binding var code: String
    let state: DSCodeFieldState
    let boxHeight: CGFloat
    let onComplete: ((String) -> Void)?

    @FocusState private var isFocused: Bool
    @State private var accepted = ""
    @State private var shakeTrigger: CGFloat = 0
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        length: Int = 6,
        code: Binding<String>,
        state: DSCodeFieldState = .normal,
        boxHeight: CGFloat = 56,
        onComplete: ((String) -> Void)? = nil
    ) {
        self.length = DSCodeFieldLogic.boxCount(length)
        self._code = code
        self.state = state
        self.boxHeight = boxHeight
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // Invisible field that owns the keyboard + SMS autofill.
            TextField("", text: $code)
                #if os(iOS)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                #endif
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityLabel("Verification code")
                .accessibilityValue(Self.accessibilityValue(code: code, length: length, state: state))

            // Visual digit boxes.
            HStack(spacing: DSSpacing.xs) {
                ForEach(0..<length, id: \.self) { index in
                    box(index: index)
                }
            }
            .modifier(DSCodeFieldShake(shakes: shakeTrigger))
            .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear {
            // A code that arrives already filled (a restored draft) is adopted
            // silently: no haptic and no `onComplete`.
            accepted = DSCodeFieldLogic.sanitize(code, length: length)
            if accepted != code { code = accepted }
        }
        .onChange(of: code) { _, newValue in
            let filtered = DSCodeFieldLogic.sanitize(newValue, length: length)
            if filtered != newValue {
                // Write back the cleaned code; the next onChange handles it.
                code = filtered
                return
            }
            let change = DSCodeFieldLogic.change(from: accepted, to: filtered, length: length)
            accepted = filtered
            if change.haptic { DSHapticEngine.shared.fire(.light) }
            if change.completes { onComplete?(filtered) }
        }
        .onChange(of: state) { _, newState in
            switch newState {
            case .error:
                DSHapticEngine.shared.fire(.error)
                // Under Reduce Motion the red tint and the haptic carry the error.
                guard !reduceMotion else { break }
                withAnimation(DSAnimation.normal) { shakeTrigger += 1 }
            case .success:
                DSHapticEngine.shared.fire(.success)
            case .normal:
                break
            }
        }
    }

    // MARK: - Digit Box

    @ViewBuilder
    private func box(index: Int) -> some View {
        let character = character(at: index)
        let isFilled = character != nil
        let isActive = isFocused && index == code.count && code.count < length

        ZStack {
            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .fill(boxFill)

            RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                .stroke(
                    borderColor(isActive: isActive, isFilled: isFilled),
                    lineWidth: isActive || state != .normal ? 2 : (isFilled ? 1.5 : 1)
                )

            if let character {
                Text(String(character))
                    .ds(.title1, color: digitColor)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else if isActive {
                DSCodeFieldCaret()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: boxHeight)
        .scaleEffect(isActive ? 1.04 : 1.0)
        .animation(DSAnimation.springSnappy, value: isActive)
        .animation(DSAnimation.springSnappy, value: code)
        .animation(DSAnimation.micro, value: state)
    }

    // MARK: - Helpers

    /// e.g. "1 2 3, 3 of 6 digits", plus ", incorrect code" / ", verified".
    static func accessibilityValue(code: String, length: Int, state: DSCodeFieldState) -> String {
        DSCodeFieldLogic.accessibilityValue(code: code, length: length, state: state)
    }

    private func character(at index: Int) -> Character? {
        guard index < code.count else { return nil }
        return Array(code)[index]
    }

    private var boxFill: Color {
        switch state {
        case .error:   return theme.palette.error.opacity(0.08)
        case .success: return theme.palette.success.opacity(0.08)
        case .normal:  return theme.palette.backgroundSecondary
        }
    }

    private func borderColor(isActive: Bool, isFilled: Bool) -> Color {
        switch state {
        case .error:   return theme.palette.error
        case .success: return theme.palette.success
        case .normal:
            if isActive { return theme.ink }
            if isFilled { return theme.ink.opacity(0.4) }
            return theme.palette.border
        }
    }

    private var digitColor: Color {
        switch state {
        case .error:   return theme.palette.error
        case .success: return theme.palette.success
        case .normal:  return theme.palette.textPrimary
        }
    }
}

// MARK: - Logic

/// The input rules of `DSCodeField`, kept pure so tests can pin them without
/// rendering: which characters count as digits, when a keystroke ticks and when
/// the code is complete.
enum DSCodeFieldLogic {
    /// What a change to the bound code should trigger.
    struct Change: Equatable {
        /// A digit was added: fire the light haptic.
        var haptic: Bool
        /// The code just became a full `length`-digit code: call `onComplete`.
        var completes: Bool
    }

    /// At least one box, so `ForEach(0..<length)` never traps on a zero or
    /// negative `length`.
    static func boxCount(_ length: Int) -> Int {
        max(1, length)
    }

    /// Keeps decimal digits only, in ASCII, clamped to `length`.
    ///
    /// Digits from any script count ("٤٢" from an Arabic keypad becomes "42"),
    /// so the bound code always compares cleanly against a server's code.
    /// Number-like characters that aren't one digit ("½", "Ⅻ") are dropped.
    static func sanitize(_ raw: String, length: Int) -> String {
        var digits = ""
        for character in raw {
            guard digits.count < boxCount(length) else { break }
            guard let value = character.wholeNumberValue,
                  (0...9).contains(value) else { continue }
            digits.append(Character(String(value)))
        }
        return digits
    }

    /// Compares the last accepted code with a new, already sanitized one.
    ///
    /// A digit added ticks. The code completes only when it changes into a
    /// full code: an extra keystroke on a full code (sanitized back to the
    /// same digits) doesn't submit it twice; deleting a digit and typing a new
    /// one does, and so does pasting a different full code.
    static func change(from previous: String, to new: String, length: Int) -> Change {
        Change(
            haptic: new.count > previous.count,
            completes: new.count == boxCount(length) && new != previous
        )
    }

    /// e.g. "1 2 3, 3 of 6 digits", plus ", incorrect code" / ", verified".
    static func accessibilityValue(code: String, length: Int, state: DSCodeFieldState) -> String {
        let digits = code.map(String.init).joined(separator: " ")
        var value = digits.isEmpty ? "" : "\(digits), "
        let boxes = boxCount(length)
        value += "\(code.count) of \(boxes) \(boxes == 1 ? "digit" : "digits")"
        switch state {
        case .normal:  break
        case .error:   value += ", incorrect code"
        case .success: value += ", verified"
        }
        return value
    }
}

// MARK: - Blinking Caret

private struct DSCodeFieldCaret: View {
    @State private var isOn = true
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Capsule()
            .fill(theme.ink)
            .frame(width: 2, height: 24)
            .opacity(isOn ? 1 : 0)
            .onAppear {
                // Under Reduce Motion the caret rests, steady and visible. (Same
                // rule as `DSMotion.loop`, inlined: DSCodeField copies standalone
                // with only the core, which doesn't include DSMotion.)
                guard !reduceMotion else { return }
                withAnimation(DSAnimation.slow.repeatForever(autoreverses: true)) { isOn = false }
            }
    }
}

// MARK: - Shake Effect

/// Horizontal shake driven by an animatable trigger. Incrementing `shakes`
/// runs one full shake that settles back to rest.
private struct DSCodeFieldShake: GeometryEffect {
    var amount: CGFloat = 8
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(shakes * .pi * 3), y: 0)
        )
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCodeFieldPreview: View {
    @State private var normalCode = "12"
    @State private var errorCode = "1234"
    @State private var successCode = "5678"

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Verification code").ds(.footnote, color: DSColors.textSecondary)
                DSCodeField(length: 6, code: $normalCode)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Invalid code").ds(.footnote, color: DSColors.textSecondary)
                DSCodeField(length: 4, code: $errorCode, state: .error)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Verified").ds(.footnote, color: DSColors.textSecondary)
                DSCodeField(length: 4, code: $successCode, state: .success)
            }
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.backgroundPrimary)
    }
}

#Preview("Light") {
    DSCodeFieldPreview().preferredColorScheme(.light)
}

#Preview("Dark") {
    DSCodeFieldPreview().preferredColorScheme(.dark)
}
#endif
