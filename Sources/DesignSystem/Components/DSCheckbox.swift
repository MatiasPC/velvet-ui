import SwiftUI

// MARK: - Design System Checkbox
// A tactile checkbox with a checkmark that draws itself on with a spring and a
// subtle pop when toggled. Every form, todo list, and terms-of-service screen
// needs a boolean selection control — this is the themeable, delightful
// alternative to a plain `Toggle` styled as a box.
//
// The tick is a custom `Shape` revealed with `.trim`, so the draw-on motion is
// pure SwiftUI and works from iOS 17. The box scales through a short pop using
// iOS 17's `.phaseAnimator` on each change.

public enum DSCheckboxShape {
    /// Rounded square — classic form checkbox
    case square
    /// Circle — "mark complete" / reminder style
    case circle
}

public enum DSCheckboxSize {
    /// 20pt box — compact rows, dense forms
    case small
    /// 24pt box — default
    case medium

    var box: CGFloat {
        switch self {
        case .small:  return 20
        case .medium: return 24
        }
    }

    /// Stroke width of the checkmark tick
    var tickWidth: CGFloat {
        switch self {
        case .small:  return 2
        case .medium: return 2.5
        }
    }

    /// Border width when unchecked
    var borderWidth: CGFloat {
        switch self {
        case .small:  return 1.5
        case .medium: return 2
        }
    }
}

public struct DSCheckbox: View {
    let label: String?
    @Binding var isOn: Bool
    let shape: DSCheckboxShape
    let size: DSCheckboxSize
    let tint: Color
    let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        shape: DSCheckboxShape = .square,
        size: DSCheckboxSize = .medium,
        tint: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .rigid
    ) {
        self.label = label
        self._isOn = isOn
        self.shape = shape
        self.size = size
        self.tint = tint
        self.haptic = haptic
    }

    public var body: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.sm) {
                checkbox
                if let label {
                    Text(label)
                        .ds(.body)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityValue(isOn ? Text("Checked") : Text("Unchecked"))
    }

    // MARK: - Box + Tick

    private var checkbox: some View {
        boxBackground
            .frame(width: size.box, height: size.box)
            .overlay { tick }
            .phaseAnimator([1.0, 1.14, 1.0], trigger: isOn) { view, scale in
                view.scaleEffect(scale)
            } animation: { _ in
                DSAnimation.springBouncy
            }
    }

    @ViewBuilder
    private var boxBackground: some View {
        switch shape {
        case .square:
            fillAndBorder(RoundedRectangle(cornerRadius: DSRadius.xs, style: .continuous))
        case .circle:
            fillAndBorder(Circle())
        }
    }

    private func fillAndBorder<S: InsettableShape>(_ shape: S) -> some View {
        shape
            .fill(isOn ? tint : Color.clear)
            .overlay(
                shape.strokeBorder(
                    isOn ? Color.clear : DSColors.defaultPalette.border,
                    lineWidth: size.borderWidth
                )
            )
    }

    private var tick: some View {
        DSCheckmarkShape()
            .trim(from: 0, to: isOn ? 1 : 0)
            .stroke(
                DSColors.defaultPalette.textOnPrimary,
                style: StrokeStyle(lineWidth: size.tickWidth, lineCap: .round, lineJoin: .round)
            )
            .frame(width: size.box, height: size.box)
    }

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        withAnimation(DSAnimation.springSnappy) {
            isOn.toggle()
        }
    }
}

// MARK: - Checkmark Shape

/// The tick path, expressed as fractions of the containing box so it scales to
/// any size while staying comfortably inset from the edges.
private struct DSCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.26, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.70))
        path.addLine(to: CGPoint(x: w * 0.76, y: h * 0.32))
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
    @State private var task1 = true
    @State private var task2 = false
    @State private var offline = false

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            DSCheckbox("Accept terms & conditions", isOn: $terms)
            DSCheckbox("Subscribe to newsletter", isOn: $newsletter, tint: DSColors.defaultPalette.secondary)
            DSCheckbox("Sync when offline", isOn: $offline)
                .disabled(true)

            Divider()

            DSCheckbox("Buy groceries", isOn: $task1, shape: .circle, tint: DSColors.defaultPalette.success)
            DSCheckbox("Call the dentist", isOn: $task2, shape: .circle, tint: DSColors.defaultPalette.success)

            Divider()

            HStack(spacing: DSSpacing.xl) {
                DSCheckbox(isOn: $task1, size: .small)
                DSCheckbox(isOn: $newsletter)
                DSCheckbox(isOn: $task1, shape: .circle, tint: DSColors.defaultPalette.tertiary)
            }
        }
    }
}
