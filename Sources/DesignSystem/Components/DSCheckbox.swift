import SwiftUI

// MARK: - Design System Checkbox
// The selection control the switch is not. `DSToggle` answers "on or off?" for a
// setting; a checkbox answers "is this one picked?" in a list, a form, a set of
// terms, a batch of todos. SwiftUI ships neither on iOS, so this is the
// themeable, tactile one: an empty glass square that fills with the accent and
// draws its checkmark on — a single stroke trimmed from nothing to whole — while
// the box springs up underneath it.
//
// No borders: the empty box is a wash fill with the specular edge every glass
// surface wears (`dsWashEdge`), never an outline. The draw-on is a `trim`ed
// `Path`, the pop is `springBouncy`, and both settle instantly under Reduce
// Motion so the state is never in doubt.
//
// Inspiration: the SwiftUI community's animated-checkmark pattern — a `Path`
// trimmed by an animatable `to:` (Sarah, "How to Create and Animate Checkboxes
// in SwiftUI"; Rohit Saini, "Checkmark Animation in SwiftUI"). Rewritten on
// Velvet tokens; no upstream code is reproduced.

// MARK: - Size

public enum DSCheckboxSize: Sendable {
    /// 20pt box — dense lists, multi-select rows
    case small
    /// 24pt box — the default, comfortable in forms
    case medium
    /// 28pt box — a single prominent opt-in (terms, consent)
    case large

    /// Side length of the square box.
    var side: CGFloat {
        switch self {
        case .small:  return 20
        case .medium: return 24
        case .large:  return 28
        }
    }

    /// Stroke width of the checkmark. Scales with the box so the tick stays proportional.
    var checkWidth: CGFloat {
        switch self {
        case .small:  return 2
        case .medium: return 2.5
        case .large:  return 3
        }
    }

    /// Text style for the label beside the box.
    var labelStyle: DSTextStyle {
        switch self {
        case .small:  return .callout
        case .medium: return .body
        case .large:  return .body
        }
    }
}

// MARK: - Checkmark Shape

/// A checkmark drawn as one continuous stroke, laid out proportionally in its
/// rect so it scales with the box. Trimming the `to:` end from 0 → 1 draws it on.
public struct DSCheckmarkShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Proportional points leave ~24% margin on every side so round caps
        // never clip against the box edge.
        path.move(to: CGPoint(x: rect.minX + w * 0.24, y: rect.minY + h * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.70))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.76, y: rect.minY + h * 0.30))
        return path
    }
}

// MARK: - Checkbox

public struct DSCheckbox: View {
    private let label: String?
    @Binding private var isOn: Bool
    private let size: DSCheckboxSize
    private let onColor: Color?
    private let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @DSThemed private var theme

    /// - Parameters:
    ///   - label: Optional text beside the box. The whole row is the hit target.
    ///   - isOn: Binding to the checked state.
    ///   - size: Box size. Defaults to `.medium` (24pt).
    ///   - onColor: Fill while checked. Defaults to the theme accent.
    ///   - haptic: Feedback on toggle. Defaults to `.rigid` (a precise snap).
    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        size: DSCheckboxSize = .medium,
        onColor: Color? = nil,
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
                    Text(label).ds(size.labelStyle)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityValue(isOn ? Text("Checked") : Text("Unchecked"))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: - Box

    private var fill: Color { onColor ?? theme.accent }

    private var box: some View {
        ZStack {
            // Empty container — a wash fill, never an outline. Always underneath.
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .fill(theme.subtleFill)

            // Filled + checkmark layer. Springs up from 0.55 with a bouncy
            // overshoot so checking reads as a pop; fades/shrinks out on uncheck.
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .fill(fill)
                .overlay {
                    DSCheckmarkShape()
                        .trim(from: 0, to: isOn ? 1 : 0)
                        .stroke(
                            theme.onAccent,
                            style: StrokeStyle(lineWidth: size.checkWidth, lineCap: .round, lineJoin: .round)
                        )
                        // The tick draws on a beat after the box has filled.
                        .animation(anim(DSAnimation.springSmooth.delay(0.06)), value: isOn)
                }
                .dsShadow(isOn ? .glow(fill) : .none)
                .opacity(isOn ? 1 : 0)
                .scaleEffect(isOn ? 1 : 0.55)
                .animation(anim(DSAnimation.springBouncy), value: isOn)
        }
        .frame(width: size.side, height: size.side)
        .dsWashEdge(radius: DSRadius.sm)
    }

    // MARK: - Behavior

    /// Wrap an animation, or return `nil` under Reduce Motion so the state snaps.
    private func anim(_ base: Animation) -> Animation? {
        reduceMotion ? nil : base
    }

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
    @State private var terms = true
    @State private var newsletter = false
    @State private var offers = true
    @State private var disabled = false
    @State private var tasks = [true, false, false]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSCheckbox("Accept terms & conditions", isOn: $terms)
                        DSCheckbox("Subscribe to the newsletter", isOn: $newsletter)
                        DSCheckbox("Send me offers", isOn: $offers, onColor: DSColors.secondary)
                        DSCheckbox("Unavailable option", isOn: $disabled)
                            .disabled(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Today").ds(.footnote, color: DSColors.textSecondary)
                        DSCheckbox("Water the plants", isOn: $tasks[0], size: .small)
                        DSCheckbox("Reply to Ana", isOn: $tasks[1], size: .small)
                        DSCheckbox("Book the flight", isOn: $tasks[2], size: .small)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: DSSpacing.xl) {
                    DSCheckbox(isOn: $terms, size: .small)
                    DSCheckbox(isOn: $newsletter, size: .medium)
                    DSCheckbox(isOn: $offers, size: .large, onColor: DSColors.success)
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
