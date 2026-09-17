import SwiftUI

// MARK: - Design System Checkbox
// A multi-select control with a checkmark that draws itself on. DSToggle is a
// switch — one setting, on or off; a checkbox is the other boolean: a row in a
// checklist, a term to accept, an option in a multi-select. The delight is the
// tick: an accent fill crossfades in and the check strokes on with an animatable
// `trim`, the way it's drawn by hand. Off, the box is a wash surface with the
// specular edge — no border, like every Velvet surface.
//
// Box leading, optional label trailing (the checklist convention). The whole row
// is the hit target. Colors are overridable and resolve to theme roles in `body`.

public enum DSCheckboxSize {
    /// 20pt box — dense checklists, compact rows
    case small
    /// 24pt box — default, comfortable tap target with a label
    case medium

    /// Side length of the box.
    var side: CGFloat {
        switch self {
        case .small:  return 20
        case .medium: return 24
        }
    }

    /// Stroke width of the checkmark, scaled to the box.
    var checkWidth: CGFloat {
        switch self {
        case .small:  return 2
        case .medium: return 2.5
        }
    }
}

// MARK: - Checkmark Shape

/// The tick itself: a two-segment polyline in the unit box, stroked with round
/// caps and joins. Kept as a `Shape` so `trim` can animate it drawing on.
public struct DSCheckmarkShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.26, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.70))
        path.addLine(to: CGPoint(x: w * 0.76, y: h * 0.30))
        return path
    }
}

// MARK: - Checkbox

public struct DSCheckbox: View {
    let label: String?
    @Binding var isOn: Bool
    let size: DSCheckboxSize
    let onColor: Color?
    let checkColor: Color?
    let haptic: DSHapticStyle

    @State private var isPressed = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @DSThemed private var theme

    /// - Parameters:
    ///   - label: Optional text shown after the box. The whole row toggles.
    ///   - isOn: The checked state.
    ///   - size: Box size. Defaults to `.medium`.
    ///   - onColor: Fill of the checked box. Defaults to the theme accent.
    ///   - checkColor: Color of the checkmark. Defaults to `onAccent`.
    ///   - haptic: Tactile feedback on toggle. Defaults to `.light`.
    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        size: DSCheckboxSize = .medium,
        onColor: Color? = nil,
        checkColor: Color? = nil,
        haptic: DSHapticStyle = .light
    ) {
        self.label = label
        self._isOn = isOn
        self.size = size
        self.onColor = onColor
        self.checkColor = checkColor
        self.haptic = haptic
    }

    public var body: some View {
        let fill = onColor ?? theme.accent
        let check = checkColor ?? theme.onAccent

        Button(action: toggle) {
            HStack(spacing: DSSpacing.sm) {
                box(fill: fill, check: check)
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
        .accessibilityValue(isOn ? Text("Checked") : Text("Not checked"))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Box

    private func box(fill: Color, check: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)

        return ZStack {
            shape.fill(theme.subtleFill)
            shape.fill(fill).opacity(isOn ? 1 : 0)

            DSCheckmarkShape()
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(check, style: StrokeStyle(lineWidth: size.checkWidth, lineCap: .round, lineJoin: .round))
                .padding(size.side * 0.2)
        }
        .frame(width: size.side, height: size.side)
        .dsWashEdge(radius: DSRadius.sm)
        .scaleEffect(isPressed ? DSPress.scale : 1)
        .animation(DSPress.animation, value: isPressed)
        .animation(reduceMotion ? nil : DSAnimation.springBouncy, value: isOn)
    }

    // MARK: - Action

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        isOn.toggle()
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCheckboxPreviewHost: View {
    @State private var theme = DSTheme()

    @State private var terms = false
    @State private var newsletter = true
    @State private var tasks = [true, false, false]
    @State private var compact = true

    private let taskTitles = ["Design the tokens", "Build the components", "Write the docs"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        Text("Checklist").ds(.title3)
                        ForEach(taskTitles.indices, id: \.self) { index in
                            DSCheckbox(taskTitles[index], isOn: $tasks[index])
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSCheckbox("Accept terms & conditions", isOn: $terms)
                        DSCheckbox("Send me the newsletter", isOn: $newsletter, onColor: DSColors.secondary)
                        DSCheckbox("Disabled option", isOn: .constant(true))
                            .disabled(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: DSSpacing.xl) {
                    DSCheckbox(isOn: $compact, size: .small)
                    DSCheckbox(isOn: $newsletter)
                    DSCheckbox(isOn: $terms, onColor: DSColors.success)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Checkbox — Light") {
    DSCheckboxPreviewHost().preferredColorScheme(.light)
}

#Preview("Checkbox — Dark") {
    DSCheckboxPreviewHost().preferredColorScheme(.dark)
}
#endif
