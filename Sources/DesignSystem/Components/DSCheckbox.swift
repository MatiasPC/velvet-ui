import SwiftUI

// MARK: - Design System Checkbox
// A tactile checkbox whose checkmark is *drawn on* — the tick strokes in with a
// bouncy spring via `Path` + `.trim`, while the box springs its fill and a light
// press scales the control. Unlike `DSToggle` (a boolean on/off switch), a
// checkbox reads as "selected / not selected" — the right control for terms
// acceptance, multi-select lists, filters, and to-do items. Square or circle.

// MARK: - Shape

public enum DSCheckboxShape {
    /// Rounded square — classic checkbox for forms and terms.
    case square
    /// Full circle — reads as a to-do / selection dot.
    case circle
}

// MARK: - Checkbox

public struct DSCheckbox: View {

    // MARK: - Configuration

    @Binding private var isOn: Bool
    private let label: String?
    private let size: CGFloat
    private let shape: DSCheckboxShape
    private let tint: Color
    private let checkColor: Color
    private let haptic: DSHapticStyle

    // MARK: - State

    @State private var isPressed = false
    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Init

    /// Create an animated checkbox.
    /// - Parameters:
    ///   - label: Optional trailing text. Tapping anywhere on the row toggles.
    ///   - isOn: Binding to the checked state.
    ///   - size: Edge length of the box. Defaults to `24`.
    ///   - shape: `.square` (default) or `.circle`.
    ///   - tint: Fill color when checked. Defaults to the primary accent.
    ///   - checkColor: Checkmark stroke color. Defaults to `textOnPrimary`.
    ///   - haptic: Feedback fired on toggle. Defaults to `.rigid`.
    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        size: CGFloat = 24,
        shape: DSCheckboxShape = .square,
        tint: Color = DSColors.defaultPalette.primary,
        checkColor: Color = DSColors.defaultPalette.textOnPrimary,
        haptic: DSHapticStyle = .rigid
    ) {
        self._isOn = isOn
        self.label = label
        self.size = size
        self.shape = shape
        self.tint = tint
        self.checkColor = checkColor
        self.haptic = haptic
    }

    // MARK: - Body

    public var body: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.md) {
                box
                if let label {
                    Text(label).ds(.body)
                    Spacer(minLength: DSSpacing.sm)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
        .accessibilityValue(isOn ? Text("Checked") : Text("Unchecked"))
    }

    // MARK: - Box

    private var box: some View {
        ZStack {
            container
                .fill(isOn ? tint : DSColors.defaultPalette.backgroundElevated)

            container
                .strokeBorder(
                    isOn ? tint : DSColors.defaultPalette.border,
                    lineWidth: borderWidth
                )

            DSCheckmarkShape()
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(
                    checkColor,
                    style: StrokeStyle(lineWidth: checkWidth, lineCap: .round, lineJoin: .round)
                )
                .padding(size * 0.28)
        }
        .frame(width: size, height: size)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(DSAnimation.springBouncy, value: isOn)
        .animation(DSAnimation.springSnappy, value: isPressed)
    }

    /// The box outline — a rounded square, or a circle when `cornerRadius == size / 2`.
    private var container: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    // MARK: - Derived Metrics

    private var cornerRadius: CGFloat {
        switch shape {
        case .square: return DSRadius.sm
        case .circle: return size / 2
        }
    }

    /// Outline weight, scaled to the box so small and large checkboxes stay balanced.
    private var borderWidth: CGFloat { size * 0.08 }

    /// Checkmark stroke weight, scaled to the box.
    private var checkWidth: CGFloat { size * 0.14 }

    // MARK: - Action

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        withAnimation(DSAnimation.springBouncy) {
            isOn.toggle()
        }
    }
}

// MARK: - Checkmark Shape

/// A checkmark path in unit space, drawn with two line segments so `.trim`
/// animates it as a single continuous stroke.
private struct DSCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.04, y: h * 0.54))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.88))
        path.addLine(to: CGPoint(x: w * 0.96, y: h * 0.16))
        return path
    }
}

// MARK: - Preview

#Preview("Light") {
    CheckboxPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    CheckboxPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct CheckboxPreview: View {
    @State private var terms = true
    @State private var newsletter = false
    @State private var pushed = false
    @State private var task1 = true
    @State private var task2 = false

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            Text("Square").ds(.overline, color: DSColors.defaultPalette.textSecondary)
            DSCheckbox("Accept terms & conditions", isOn: $terms)
            DSCheckbox("Subscribe to newsletter", isOn: $newsletter)
            DSCheckbox("Enable analytics", isOn: $pushed, tint: DSColors.defaultPalette.secondary)
            DSCheckbox("Disabled option", isOn: $newsletter)
                .disabled(true)

            Divider()

            Text("Circle · to-do").ds(.overline, color: DSColors.defaultPalette.textSecondary)
            DSCheckbox("Buy groceries", isOn: $task1, shape: .circle,
                       tint: DSColors.defaultPalette.success)
            DSCheckbox("Walk the dog", isOn: $task2, shape: .circle,
                       tint: DSColors.defaultPalette.success)

            Divider()

            Text("Standalone").ds(.overline, color: DSColors.defaultPalette.textSecondary)
            HStack(spacing: DSSpacing.lg) {
                DSCheckbox(isOn: $task1, size: 20)
                DSCheckbox(isOn: $task2)
                DSCheckbox(isOn: $terms, size: 32, shape: .circle,
                           tint: DSColors.defaultPalette.tertiary)
            }
        }
    }
}
