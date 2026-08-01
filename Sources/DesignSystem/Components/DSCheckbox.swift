import SwiftUI

// MARK: - Design System Checkbox
// A tactile checkbox whose checkmark literally draws itself on — the tick is a
// `Shape` revealed with an animated `trim`, layered over a box whose fill
// springs into the accent color. Every form, settings screen, and terms-of-use
// gate needs a boolean control that reads as "selected" rather than "on"; this
// is the themeable, animated alternative to a plain `Toggle` for lists and
// multi-select. Pair it with a trailing label for a fully tappable row.
//
// Inspiration: the classic SwiftUI draw-on checkmark pattern (animating a
// stroked path with `.trim(from:to:)`).
// - SerialCoder.dev — "Implementing A Customizable And Animatable Circled Checkmark View"
//   https://serialcoder.dev/text-tutorials/swiftui/playing-with-swiftui-implementing-a-customizable-and-animatable-circled-checkmark-view/
// - Better Programming — "How to Create and Animate Checkboxes in SwiftUI"
//   https://medium.com/better-programming/how-to-create-and-animate-checkboxes-in-swiftui-e428fe7cc9c1

// MARK: - Size

public enum DSCheckboxSize {
    /// 20×20 box — dense forms, inline list rows
    case small
    /// 24×24 box — default, comfortable tap target
    case medium

    var box: CGFloat {
        switch self {
        case .small:  return 20
        case .medium: return 24
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .small:  return 1.5
        case .medium: return 2
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small:  return DSRadius.xs
        case .medium: return DSRadius.sm
        }
    }
}

// MARK: - Checkbox

public struct DSCheckbox: View {
    let label: String?
    @Binding var isOn: Bool
    let size: DSCheckboxSize
    let onColor: Color
    let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled
    @State private var isPressed = false

    /// Create a checkbox with an optional trailing label.
    /// - Parameters:
    ///   - label: Text shown beside the box. The whole row is tappable. Defaults to `nil`.
    ///   - isOn: Binding to the checked state.
    ///   - size: Box footprint. Defaults to `.medium`.
    ///   - onColor: Fill color when checked. Defaults to the accent primary.
    ///   - haptic: Feedback fired on each toggle. Defaults to `.rigid`.
    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        size: DSCheckboxSize = .medium,
        onColor: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .rigid
    ) {
        self.label = label
        self._isOn = isOn
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
        .accessibilityValue(isOn ? Text("Checked") : Text("Unchecked"))
    }

    // MARK: - Box + Checkmark

    private var box: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                .fill(onColor)
                .opacity(isOn ? 1 : 0)
                .animation(DSAnimation.springSnappy, value: isOn)

            RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                .stroke(
                    isOn ? onColor : DSColors.defaultPalette.border,
                    lineWidth: size.lineWidth
                )
                .animation(DSAnimation.springSnappy, value: isOn)

            DSCheckmarkShape()
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(
                    DSColors.defaultPalette.textOnPrimary,
                    style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round, lineJoin: .round)
                )
                .padding(size.box * 0.22)
                .animation(DSAnimation.springSmooth, value: isOn)
        }
        .frame(width: size.box, height: size.box)
        .scaleEffect(isPressed ? 0.88 : 1)
        .animation(DSAnimation.springSnappy, value: isPressed)
    }

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        isOn.toggle()
    }
}

// MARK: - Checkmark Shape

/// The tick path, drawn in a unit rect so `.trim` can reveal it stroke-first.
private struct DSCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.10, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.20))
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
    @State private var updates = true
    @State private var a = true
    @State private var b = false
    @State private var c = false

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            DSCheckbox("Accept terms & conditions", isOn: $terms)
            DSCheckbox("Subscribe to the newsletter", isOn: $newsletter,
                       onColor: DSColors.defaultPalette.secondary)
            DSCheckbox("Product updates", isOn: $updates,
                       onColor: DSColors.defaultPalette.success)
            DSCheckbox("Disabled option", isOn: $newsletter)
                .disabled(true)

            Divider()

            HStack(spacing: DSSpacing.lg) {
                DSCheckbox(isOn: $a, size: .small)
                DSCheckbox(isOn: $b)
                DSCheckbox(isOn: $c, size: .small, onColor: DSColors.defaultPalette.tertiary)
            }
        }
    }
}
