import SwiftUI

// MARK: - Design System Checkbox
// A tactile checkbox with a checkmark that draws itself on and a box that
// springs into the accent color. `DSToggle` covers on/off switches — this is
// the control for multi-select lists, task items, and "I agree to the terms"
// rows, where several independent selections live side by side.

// MARK: - Shape

public enum DSCheckboxShape: Sendable {
    /// Rounded square — the classic checkbox, at home in forms and lists
    case square
    /// Circle — softer, great for task lists and selectable rows
    case circle
}

// MARK: - Size

public enum DSCheckboxSize: Sendable {
    /// 20pt box — compact rows, dense multi-select lists
    case small
    /// 24pt box — default, comfortable tap target companion
    case medium

    var dimension: CGFloat {
        switch self {
        case .small:  return 20
        case .medium: return 24
        }
    }

    /// Corner radius for the `.square` shape (ignored by `.circle`)
    var cornerRadius: CGFloat {
        switch self {
        case .small:  return DSRadius.xs
        case .medium: return DSRadius.sm
        }
    }

    /// Border stroke width of the empty box
    var borderWidth: CGFloat {
        switch self {
        case .small:  return 1.5
        case .medium: return 2
        }
    }

    /// Stroke width of the checkmark itself
    var checkWidth: CGFloat {
        switch self {
        case .small:  return 2
        case .medium: return 2.5
        }
    }

    /// Checkmark glyph size as a fraction of the box
    var checkScale: CGFloat { 0.6 }
}

// MARK: - Checkbox

public struct DSCheckbox: View {
    let label: String?
    @Binding var isOn: Bool
    let shape: DSCheckboxShape
    let size: DSCheckboxSize
    let onColor: Color
    let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        shape: DSCheckboxShape = .square,
        size: DSCheckboxSize = .medium,
        onColor: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .rigid
    ) {
        self.label = label
        self._isOn = isOn
        self.shape = shape
        self.size = size
        self.onColor = onColor
        self.haptic = haptic
    }

    public var body: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.sm) {
                box
                if let label {
                    Text(label)
                        .ds(.body)
                    Spacer(minLength: 0)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityValue(isOn ? Text("Checked") : Text("Unchecked"))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: - Box + Checkmark

    private var box: some View {
        ZStack {
            // Empty-state base + border
            container
                .fill(DSColors.defaultPalette.backgroundElevated)
            container
                .strokeBorder(
                    isOn ? onColor : DSColors.defaultPalette.border,
                    lineWidth: size.borderWidth
                )

            // Filled accent that pops in when checked
            container
                .fill(onColor)
                .opacity(isOn ? 1 : 0)
                .scaleEffect(isOn ? 1 : 0.5)
                .animation(DSAnimation.springSnappy, value: isOn)

            // The checkmark, drawn on with a trim animation
            DSCheckmarkShape()
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(
                    DSColors.defaultPalette.textOnPrimary,
                    style: StrokeStyle(lineWidth: size.checkWidth, lineCap: .round, lineJoin: .round)
                )
                .frame(
                    width: size.dimension * size.checkScale,
                    height: size.dimension * size.checkScale
                )
                .animation(DSAnimation.springSmooth, value: isOn)
        }
        .frame(width: size.dimension, height: size.dimension)
    }

    private var container: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: shape == .circle ? size.dimension / 2 : size.cornerRadius,
            style: .continuous
        )
    }

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        isOn.toggle()
    }
}

// MARK: - Checkmark Shape

/// A hand-tuned checkmark path drawn in relative coordinates so it scales
/// cleanly to any box size. Stroke it with round caps for a soft finish.
public struct DSCheckmarkShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.28))
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
    @State private var terms = false
    @State private var newsletter = true
    @State private var locked = true
    @State private var tasks = [true, false, false]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            DSCheckbox("I agree to the Terms & Conditions", isOn: $terms)
            DSCheckbox("Send me the newsletter", isOn: $newsletter, onColor: DSColors.defaultPalette.secondary)
            DSCheckbox("Locked option", isOn: $locked)
                .disabled(true)

            Divider()

            // Circle variant as a task list
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                DSCheckbox("Buy groceries", isOn: $tasks[0], shape: .circle, onColor: DSColors.defaultPalette.success)
                DSCheckbox("Walk the dog", isOn: $tasks[1], shape: .circle, onColor: DSColors.defaultPalette.success)
                DSCheckbox("Finish the report", isOn: $tasks[2], shape: .circle, onColor: DSColors.defaultPalette.success)
            }

            Divider()

            // Standalone sizes
            HStack(spacing: DSSpacing.xl) {
                DSCheckbox(isOn: $newsletter, size: .small)
                DSCheckbox(isOn: $terms)
                DSCheckbox(isOn: $newsletter, shape: .circle)
            }
        }
    }
}
