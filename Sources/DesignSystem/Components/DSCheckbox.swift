import SwiftUI

// MARK: - Design System Checkbox
// A tactile multi-select control with a checkmark that *draws itself in*.
// When toggled on, the box fills with the accent color and the check strokes
// on with a smooth spring — the tiny, satisfying micro-interaction that makes
// forms, to-do lists, and consent rows feel alive. Distinct from `DSToggle`:
// a switch answers "on or off", a checkbox answers "selected or not" and reads
// naturally in vertical lists and multi-select groups.

public struct DSCheckbox: View {

    // MARK: - Configuration

    private let label: String?
    @Binding private var isOn: Bool
    private let size: CGFloat
    private let tint: Color
    private let checkColor: Color
    private let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Init

    /// Creates a checkbox bound to a boolean.
    /// - Parameters:
    ///   - label: Optional trailing label. Tapping it also toggles the box.
    ///   - isOn: The selection state.
    ///   - size: Edge length of the box in points. Defaults to `24`.
    ///   - tint: Fill + border color when selected. Defaults to the primary accent.
    ///   - checkColor: Color of the checkmark stroke. Defaults to the on-primary color.
    ///   - haptic: Tactile feedback fired on each toggle. Defaults to `.rigid`.
    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        size: CGFloat = 24,
        tint: Color = DSColors.defaultPalette.primary,
        checkColor: Color = DSColors.defaultPalette.textOnPrimary,
        haptic: DSHapticStyle = .rigid
    ) {
        self.label = label
        self._isOn = isOn
        self.size = size
        self.tint = tint
        self.checkColor = checkColor
        self.haptic = haptic
    }

    // MARK: - Body

    public var body: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.sm) {
                box
                if let label {
                    Text(label)
                        .ds(.body)
                        .multilineTextAlignment(.leading)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(label ?? "Checkbox")
        .accessibilityValue(isOn ? Text("Checked") : Text("Unchecked"))
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    // MARK: - Box + Checkmark

    private var box: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DSRadius.xs, style: .continuous)
                .fill(isOn ? tint : Color.clear)

            RoundedRectangle(cornerRadius: DSRadius.xs, style: .continuous)
                .strokeBorder(
                    isOn ? tint : DSColors.defaultPalette.border,
                    lineWidth: strokeWidth
                )

            DSCheckmarkShape()
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(
                    checkColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                )
        }
        .frame(width: size, height: size)
        .scaleEffect(isOn ? 1 : 0.96)
        .animation(DSAnimation.springSnappy, value: isOn)
    }

    /// Stroke weight scales with the box so small and large checkboxes stay balanced.
    private var strokeWidth: CGFloat {
        max(1.5, size * 0.09)
    }

    // MARK: - Interaction

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        withAnimation(DSAnimation.springSnappy) {
            isOn.toggle()
        }
    }
}

// MARK: - Checkmark Shape

/// The classic two-segment checkmark, laid out with fractional coordinates so it
/// scales cleanly to any box size. Drawn via `.trim(from:to:)` for the reveal.
private struct DSCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to:    CGPoint(x: rect.minX + w * 0.26, y: rect.minY + h * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.44, y: rect.minY + h * 0.70))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.76, y: rect.minY + h * 0.32))
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
    @State private var disabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            DSCheckbox("Accept terms & conditions", isOn: $terms)
            DSCheckbox("Subscribe to the newsletter", isOn: $newsletter,
                       tint: DSColors.defaultPalette.secondary)
            DSCheckbox("Product updates", isOn: $updates,
                       tint: DSColors.defaultPalette.success)
            DSCheckbox("Unavailable option", isOn: $disabled)
                .disabled(true)

            Divider()

            HStack(spacing: DSSpacing.lg) {
                DSCheckbox(isOn: $terms, size: 20)
                DSCheckbox(isOn: $newsletter)
                DSCheckbox(isOn: $updates, size: 32,
                           tint: DSColors.defaultPalette.tertiary)
            }
        }
    }
}
