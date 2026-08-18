import SwiftUI

// MARK: - Design System Checkbox
// A tactile checkbox whose tick is *drawn* on with a trimmed stroke while the
// box springs and crossfades into the accent color. Distinct from `DSToggle`:
// a switch flips a setting, a checkbox marks an item — think checklists, terms
// acceptance, and multi-select rows. The draw-on checkmark is the signature
// micro-interaction that makes selection feel deliberate and satisfying.
//
// Inspiration: the community "trim the checkmark path" pattern —
// SerialCoder.dev "Animatable Circled Checkmark View"
// (https://serialcoder.dev/text-tutorials/swiftui/playing-with-swiftui-implementing-a-customizable-and-animatable-circled-checkmark-view/)
// and "How to create and animate checkboxes in SwiftUI"
// (https://medium.com/better-programming/how-to-create-and-animate-checkboxes-in-swiftui-e428fe7cc9c1).

// MARK: - Shape

public enum DSCheckboxShape {
    /// Rounded square — the classic checklist look.
    case square
    /// Circle — softer, avatar/selection-list feel.
    case circle
}

// MARK: - Checkmark Path

/// A two-segment checkmark drawn in normalized coordinates so it scales with
/// any box size. Trimming its stroke from 0→1 animates the tick drawing on.
private struct DSCheckmarkPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.minX + w * 0.04, y: rect.minY + h * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.38, y: rect.minY + h * 0.88))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.96, y: rect.minY + h * 0.18))
        return path
    }
}

// MARK: - Checkbox

public struct DSCheckbox: View {
    private let label: String?
    @Binding private var isChecked: Bool
    private let shape: DSCheckboxShape
    private let size: CGFloat
    private let tint: Color
    private let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ label: String? = nil,
        isChecked: Binding<Bool>,
        shape: DSCheckboxShape = .square,
        size: CGFloat = 24,
        tint: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .light
    ) {
        self.label = label
        self._isChecked = isChecked
        self.shape = shape
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
                    Spacer(minLength: 0)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
        .accessibilityValue(isChecked ? Text("Checked") : Text("Unchecked"))
    }

    // MARK: - Box + Tick

    private var box: some View {
        ZStack {
            container
                .fill(isChecked ? tint : DSColors.defaultPalette.backgroundElevated)

            container
                .strokeBorder(
                    isChecked ? tint : DSColors.defaultPalette.border,
                    lineWidth: borderWidth
                )

            DSCheckmarkPath()
                .trim(from: 0, to: isChecked ? 1 : 0)
                .stroke(
                    DSColors.defaultPalette.textOnPrimary,
                    style: StrokeStyle(lineWidth: tickWidth, lineCap: .round, lineJoin: .round)
                )
                .padding(size * 0.26)
                .scaleEffect(isChecked ? 1 : 0.6)
                .opacity(isChecked ? 1 : 0)
        }
        .frame(width: size, height: size)
        .animation(DSAnimation.springSnappy, value: isChecked)
    }

    /// One insettable shape drives both fill and border for square *and* circle
    /// (a circle is just a fully-rounded square).
    private var container: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    // MARK: - Geometry (proportional to `size`)

    private var cornerRadius: CGFloat {
        switch shape {
        case .square: return size * 0.3
        case .circle: return size / 2
        }
    }

    private var borderWidth: CGFloat { max(1.5, size * 0.08) }

    private var tickWidth: CGFloat { max(2, size * 0.12) }

    // MARK: - Interaction

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        isChecked.toggle()
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
    @State private var offers = false
    @State private var a = true
    @State private var b = false
    @State private var c = true

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            DSCheckbox("Accept terms & conditions", isChecked: $terms)
            DSCheckbox("Subscribe to the newsletter", isChecked: $newsletter,
                       tint: DSColors.defaultPalette.secondary)
            DSCheckbox("Send me special offers", isChecked: $offers, shape: .circle,
                       tint: DSColors.defaultPalette.success)
            DSCheckbox("Disabled option", isChecked: $a)
                .disabled(true)

            Divider()

            HStack(spacing: DSSpacing.lg) {
                DSCheckbox(isChecked: $a, size: 20)
                DSCheckbox(isChecked: $b, shape: .circle)
                DSCheckbox(isChecked: $c, size: 32,
                           tint: DSColors.defaultPalette.tertiary)
            }
        }
    }
}
