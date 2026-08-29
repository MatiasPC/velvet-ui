import SwiftUI

// MARK: - Design System Checkbox
// A tactile checkbox with a checkmark that *draws itself on* — the classic
// path-trim micro-interaction — while the box pops and fills with the accent
// color. Where `DSToggle` expresses a single on/off setting, `DSCheckbox` is
// built for multi-select lists, form confirmations and "accept terms" flows.
// Pure SwiftUI, tokens-only, with a haptic tick on every change.

public enum DSCheckboxSize {
    /// 20pt box — dense lists and compact rows
    case small
    /// 24pt box — default
    case medium
    /// 28pt box — prominent confirmations
    case large

    /// Side length of the square box
    var box: CGFloat {
        switch self {
        case .small:  return 20
        case .medium: return 24
        case .large:  return 28
        }
    }

    /// Corner radius of the box (token-based, soft square)
    var cornerRadius: CGFloat {
        switch self {
        case .small:  return DSRadius.xs
        case .medium: return DSRadius.sm
        case .large:  return DSRadius.sm
        }
    }

    // Line weights & insets are derived from the box size so the mark scales
    // proportionally instead of relying on magic pixel values.

    /// Border thickness when unchecked
    var borderWidth: CGFloat { box * 0.09 }
    /// Checkmark stroke thickness
    var checkWidth: CGFloat { box * 0.12 }
    /// Padding around the checkmark inside the box
    var checkInset: CGFloat { box * 0.26 }
}

public struct DSCheckbox: View {
    let label: String?
    @Binding var isOn: Bool
    let size: DSCheckboxSize
    let tint: Color
    let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled
    @State private var isPressed = false

    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        size: DSCheckboxSize = .medium,
        tint: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .rigid
    ) {
        self.label = label
        self._isOn = isOn
        self.size = size
        self.tint = tint
        self.haptic = haptic
    }

    public var body: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.sm) {
                box
                if let label {
                    Text(label)
                        .ds(.body)
                    Spacer(minLength: DSSpacing.sm)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? Text("Checked") : Text("Unchecked"))
    }

    // MARK: - Box + Checkmark

    private var box: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                .fill(isOn ? tint : Color.clear)

            RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                .strokeBorder(
                    isOn ? tint : DSColors.defaultPalette.border,
                    lineWidth: size.borderWidth
                )

            DSCheckmarkShape()
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(
                    DSColors.defaultPalette.textOnPrimary,
                    style: StrokeStyle(lineWidth: size.checkWidth, lineCap: .round, lineJoin: .round)
                )
                .padding(size.checkInset)
        }
        .frame(width: size.box, height: size.box)
        .scaleEffect(isPressed ? 0.88 : 1)
        .animation(DSAnimation.springSnappy, value: isPressed)
        .animation(DSAnimation.springBouncy, value: isOn)
    }

    private func toggle() {
        guard isEnabled else { return }
        // Rising edge feels like a firm "commit"; clearing is a light tick.
        DSHapticEngine.shared.fire(isOn ? .light : haptic)
        isOn.toggle()
    }
}

// MARK: - Checkmark Shape

/// A single continuous checkmark path so `.trim` draws it on in one stroke.
private struct DSCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.02, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.92))
        path.addLine(to: CGPoint(x: w * 0.98, y: h * 0.10))
        return path
    }
}

// MARK: - Preview

#Preview("Light") {
    CheckboxPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    CheckboxPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct CheckboxPreview: View {
    @State private var terms = true
    @State private var newsletter = false
    @State private var updates = false
    @State private var a = true
    @State private var b = false
    @State private var c = true

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            DSCheckbox("I accept the Terms & Conditions", isOn: $terms)
            DSCheckbox("Send me the newsletter", isOn: $newsletter, tint: DSColors.defaultPalette.secondary)
            DSCheckbox("Product updates", isOn: $updates, tint: DSColors.defaultPalette.success)
            DSCheckbox("Disabled option", isOn: $a)
                .disabled(true)

            Divider()

            HStack(spacing: DSSpacing.xl) {
                DSCheckbox(isOn: $a, size: .small)
                DSCheckbox(isOn: $b, size: .medium)
                DSCheckbox(isOn: $c, size: .large, tint: DSColors.defaultPalette.tertiary)
            }
        }
    }
}
