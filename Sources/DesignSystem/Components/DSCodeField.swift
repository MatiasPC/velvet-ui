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
    @State private var previousCount: Int = 0
    @State private var shakeTrigger: CGFloat = 0

    public init(
        length: Int = 6,
        code: Binding<String>,
        state: DSCodeFieldState = .normal,
        boxHeight: CGFloat = 56,
        onComplete: ((String) -> Void)? = nil
    ) {
        self.length = length
        self._code = code
        self.state = state
        self.boxHeight = boxHeight
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // Invisible field that owns the keyboard + SMS autofill.
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityHidden(true)

            // Visual digit boxes.
            HStack(spacing: DSSpacing.xs) {
                ForEach(0..<length, id: \.self) { index in
                    box(index: index)
                }
            }
            .modifier(DSCodeFieldShake(shakes: shakeTrigger))
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear { previousCount = code.count }
        .onChange(of: code) { _, newValue in
            // Keep only digits, clamped to `length`.
            var filtered = newValue.filter(\.isNumber)
            if filtered.count > length { filtered = String(filtered.prefix(length)) }
            if filtered != newValue {
                code = filtered
                return
            }
            if filtered.count > previousCount {
                DSHapticEngine.shared.fire(.light)
            }
            previousCount = filtered.count
            if filtered.count == length {
                onComplete?(filtered)
            }
        }
        .onChange(of: state) { _, newState in
            switch newState {
            case .error:
                DSHapticEngine.shared.fire(.error)
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

    private func character(at index: Int) -> Character? {
        guard index < code.count else { return nil }
        return Array(code)[index]
    }

    private var boxFill: Color {
        let palette = DSColors.defaultPalette
        switch state {
        case .error:   return palette.error.opacity(0.08)
        case .success: return palette.success.opacity(0.08)
        case .normal:  return palette.backgroundSecondary
        }
    }

    private func borderColor(isActive: Bool, isFilled: Bool) -> Color {
        let palette = DSColors.defaultPalette
        switch state {
        case .error:   return palette.error
        case .success: return palette.success
        case .normal:
            if isActive { return palette.borderFocused }
            if isFilled { return palette.primary.opacity(0.4) }
            return palette.border
        }
    }

    private var digitColor: Color {
        let palette = DSColors.defaultPalette
        switch state {
        case .error:   return palette.error
        case .success: return palette.success
        case .normal:  return palette.textPrimary
        }
    }
}

// MARK: - Blinking Caret

private struct DSCodeFieldCaret: View {
    @State private var isOn = true

    var body: some View {
        Capsule()
            .fill(DSColors.defaultPalette.primary)
            .frame(width: 2, height: 24)
            .opacity(isOn ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isOn = false
                }
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
                Text("Verification code").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSCodeField(length: 6, code: $normalCode)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Invalid code").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSCodeField(length: 4, code: $errorCode, state: .error)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Verified").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSCodeField(length: 4, code: $successCode, state: .success)
            }
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
    }
}

#Preview("Light") {
    DSCodeFieldPreview().preferredColorScheme(.light)
}

#Preview("Dark") {
    DSCodeFieldPreview().preferredColorScheme(.dark)
}
#endif
