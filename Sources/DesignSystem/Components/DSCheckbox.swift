import SwiftUI

// MARK: - Design System Checkbox
// A satisfying, tactile checkbox where the box springs into the accent color
// and the checkmark *draws itself* on with a trim animation — the kind of
// micro-interaction that makes to-do lists and forms feel alive (think
// Things 3 / Todoist). `DSToggle` is a switch for settings; this is the
// multi-select / task-complete / "I agree" control every app also needs.

public enum DSCheckboxStyle: Sendable {
    /// Rounded square — classic checkbox for forms and multi-select
    case square
    /// Circle — task-complete / to-do item look
    case circle
}

public enum DSCheckboxSize: Sendable {
    /// 20pt box — dense lists, inline agreements
    case small
    /// 24pt box — default, comfortable tap target
    case medium

    var dimension: CGFloat {
        switch self {
        case .small:  return 20
        case .medium: return 24
        }
    }

    /// Corner radius for the `.square` style (the `.circle` style always pills)
    var squareRadius: CGFloat {
        switch self {
        case .small:  return DSRadius.xs
        case .medium: return DSRadius.sm
        }
    }
}

public struct DSCheckbox: View {
    let label: String?
    @Binding var isOn: Bool
    let style: DSCheckboxStyle
    let size: DSCheckboxSize
    let tint: Color
    let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        style: DSCheckboxStyle = .square,
        size: DSCheckboxSize = .medium,
        tint: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .rigid
    ) {
        self.label = label
        self._isOn = isOn
        self.style = style
        self.size = size
        self.tint = tint
        self.haptic = haptic
    }

    public var body: some View {
        Button(action: toggle) {
            if let label {
                HStack(spacing: DSSpacing.sm) {
                    box
                    Text(label)
                        .ds(.body)
                    Spacer(minLength: DSSpacing.sm)
                }
                .contentShape(Rectangle())
            } else {
                box.contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityValue(isOn ? Text("Checked") : Text("Unchecked"))
    }

    // MARK: - Box + Checkmark

    private var box: some View {
        let dimension = size.dimension
        let cornerRadius = style == .circle ? dimension / 2 : size.squareRadius
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return ZStack {
            // Resting border — softens into the accent as it fills
            shape
                .strokeBorder(isOn ? tint : DSColors.defaultPalette.border, lineWidth: 2)
                .animation(DSAnimation.springSnappy, value: isOn)

            // Accent fill that pops up from the center
            shape
                .fill(tint)
                .scaleEffect(isOn ? 1 : 0.4)
                .opacity(isOn ? 1 : 0)
                .animation(DSAnimation.springBouncy, value: isOn)

            // Checkmark that draws itself on
            DSCheckmarkShape()
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(
                    DSColors.defaultPalette.textOnPrimary,
                    style: StrokeStyle(
                        lineWidth: max(2, dimension * 0.13),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .padding(dimension * 0.28)
                .animation(DSAnimation.springSnappy, value: isOn)
        }
        .frame(width: dimension, height: dimension)
    }

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        isOn.toggle()
    }
}

// MARK: - Checkmark Shape

/// A two-segment tick drawn with proportional points so it scales to any box size.
private struct DSCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
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
    @State private var buyMilk = true
    @State private var callMom = false

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            DSCheckbox("I agree to the Terms & Conditions", isOn: $terms)
            DSCheckbox("Send me product updates", isOn: $newsletter,
                       tint: DSColors.defaultPalette.secondary)
            DSCheckbox("Sync over cellular", isOn: $newsletter)
                .disabled(true)

            Divider()

            // To-do list, circle style
            DSCheckbox("Buy milk", isOn: $buyMilk, style: .circle,
                       tint: DSColors.defaultPalette.success)
            DSCheckbox("Call mom", isOn: $callMom, style: .circle,
                       tint: DSColors.defaultPalette.success)

            Divider()

            // Standalone, no label — different sizes
            HStack(spacing: DSSpacing.lg) {
                DSCheckbox(isOn: $buyMilk, size: .small)
                DSCheckbox(isOn: $callMom)
                DSCheckbox(isOn: $buyMilk, style: .circle,
                           tint: DSColors.defaultPalette.tertiary)
            }
        }
    }
}
