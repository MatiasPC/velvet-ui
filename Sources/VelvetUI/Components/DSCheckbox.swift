import SwiftUI

// MARK: - Design System Checkbox
// The selection control the switch is not. `DSToggle` answers "on or off?" for a
// setting; a checkbox answers "is this one picked?" in a list, a form, a set of
// terms, a batch of todos. SwiftUI ships neither on iOS, so this is the
// themeable, tactile one: an empty square drawn as a filled ring that fills with the
// accent and draws its checkmark on, a single stroke trimmed from nothing to
// whole, while the box springs up underneath it.
//
// No borders: the empty box is a filled ring (two fills, never a stroke) with
// the specular edge every glass surface wears (`dsWashEdge`). The draw-on is a `trim`med
// `Path`, the pop is `springBouncy`. Under Reduce Motion nothing travels: the
// box only crossfades and the tick is simply there, so the state is never in doubt.
//
// Everything is derived from `isOn`, never from `onAppear`, so a checkbox that
// scrolls back into a lazy list (or whose screen is re-pushed) already checked
// shows the finished tick at rest instead of replaying the draw-on.
//
// Inspiration: the SwiftUI community's animated-checkmark pattern (a `Path`
// trimmed by an animatable `to:`). Rewritten on Velvet tokens; no upstream code
// is reproduced.

private enum Metrics {
    /// Apple's 44pt minimum tap target, built from tokens rather than hardcoded:
    /// DSSpacing.xxl (32) + DSSpacing.sm (12) = 44.
    static let hitTarget: CGFloat = DSSpacing.xxl + DSSpacing.sm
    /// The accent layer starts here when it pops in, and shrinks back to it on uncheck.
    static let restScale: CGFloat = 0.55
    /// Checkmark stroke as a fraction of the box side, so the tick stays proportional.
    static let markWidthRatio: CGFloat = 0.1
    /// The tick starts drawing this long (seconds) after the box starts to fill.
    static let markDelay: Double = 0.06
    /// Width of the unchecked box's ring, drawn as a fill: DSSpacing.xxxs (2).
    static let offRing: CGFloat = DSSpacing.xxxs
    /// Dim while disabled; the same as `DSToggle`.
    static let disabledOpacity: Double = 0.5
}

// MARK: - Size

public enum DSCheckboxSize: Sendable {
    /// 20pt box: dense lists, multi-select rows
    case small
    /// 24pt box: the default, comfortable in forms
    case medium
    /// 28pt box: a single prominent opt-in (terms, consent)
    case large

    /// Side length of the square box, from the spacing scale.
    var side: CGFloat {
        switch self {
        case .small:  return DSSpacing.lg
        case .medium: return DSSpacing.xl
        case .large:  return DSSpacing.xl + DSSpacing.xxs
        }
    }

    /// Stroke width of the checkmark. Scales with the box so the tick stays proportional.
    var markWidth: CGFloat { side * Metrics.markWidthRatio }

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
/// rect so it scales with the box. Trimming the `to:` end from 0 to 1 draws it on.
struct DSCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
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

/// A checkbox for lists, forms and consent rows. Tapping the box or its label
/// toggles `isOn`.
///
///     @State private var acceptsTerms = false
///
///     DSCheckbox("I accept the terms", isOn: $acceptsTerms)
///
/// The control always lays out at least 44×44 pt (Apple's minimum tap target),
/// so `.small` shrinks the box, not the row. Without a label it is just the box:
/// give it one for VoiceOver with `.accessibilityLabel("…")`.
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
    ///   - label: Optional text beside the box. The whole row (box and label) is the hit target.
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
                    Text(label)
                        .ds(size.labelStyle)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(
                minWidth: Self.minimumHitTarget,
                minHeight: Self.minimumHitTarget,
                alignment: label == nil ? .center : .leading
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(DSCheckboxButtonStyle(
            scale: label == nil ? DSPress.iconScale : DSPress.scale,
            anchor: label == nil ? .center : .leading
        ))
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
        .accessibilityValue(Text(Self.accessibilityValue(isOn: isOn)))
        .accessibilityAddTraits(isOn ? [.isToggle, .isSelected] : .isToggle)
    }

    // MARK: - Box

    /// Fill of the checked box.
    private var fill: Color { onColor ?? theme.accent }

    /// The tick sits on the accent, so it takes `onAccent`; on a custom fill it
    /// takes `textOnPrimary`, the role for text on status colors.
    private var markColor: Color { onColor == nil ? theme.onAccent : theme.palette.textOnPrimary }

    private var box: some View {
        ZStack {
            // Empty container, always underneath: a filled ring (an outer shape in
            // `textSecondary`, an inner one in the surface tone), never a stroke.
            // The outer tone is what reads against the card, at 3:1 or better.
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .fill(theme.palette.textSecondary)
            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                .inset(by: Metrics.offRing)
                .fill(theme.palette.backgroundElevated)

            checkedLayer
        }
        .frame(width: size.side, height: size.side)
        .dsWashEdge(radius: DSRadius.sm)
    }

    /// Accent fill plus the tick. It pops up from `restScale` with a bouncy
    /// spring, fades on its own non-oscillating curve (a bouncy spring on opacity
    /// would flicker a ghost of the fill on uncheck), and the tick draws a beat
    /// later. Animation modifiers nearest the leaf win, so each property keeps
    /// its own curve.
    private var checkedLayer: some View {
        RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
            .fill(fill)
            .overlay {
                DSCheckmarkShape()
                    .trim(from: 0, to: Self.markProgress(isOn: isOn, reduceMotion: reduceMotion))
                    .stroke(
                        markColor,
                        style: StrokeStyle(lineWidth: size.markWidth, lineCap: .round, lineJoin: .round)
                    )
                    .animation(markAnimation, value: isOn)
            }
            .opacity(isOn ? 1 : 0)
            .animation(fadeAnimation, value: isOn)
            .scaleEffect(Self.layerScale(isOn: isOn, reduceMotion: reduceMotion))
            .animation(popAnimation, value: isOn)
    }

    // MARK: - Motion

    /// The pop: bouncy on the way in, a quick snap on the way out. None under Reduce Motion.
    private var popAnimation: Animation? {
        reduceMotion ? nil : (isOn ? DSAnimation.springBouncy : DSAnimation.springSnappy)
    }

    /// The fill's fade. Under Reduce Motion this is the only thing that moves.
    private var fadeAnimation: Animation {
        reduceMotion ? DSAnimation.micro : DSAnimation.fast
    }

    /// The tick draws on a beat after the box starts to fill, and undraws at once on uncheck.
    private var markAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return isOn ? DSAnimation.springSmooth.delay(Metrics.markDelay) : DSAnimation.micro
    }

    /// Scale of the accent layer. It only pops when motion is allowed; under
    /// Reduce Motion it rests at full size and just fades.
    static func layerScale(isOn: Bool, reduceMotion: Bool) -> CGFloat {
        isOn || reduceMotion ? 1 : Metrics.restScale
    }

    /// How much of the tick is drawn: all of it while checked, none otherwise.
    /// Under Reduce Motion it is always whole, so the layer's fade carries the
    /// change and the tick never vanishes before the fill does.
    static func markProgress(isOn: Bool, reduceMotion: Bool) -> CGFloat { isOn || reduceMotion ? 1 : 0 }

    // MARK: - Layout & accessibility

    /// The smallest the control lays out in either direction (44pt).
    static let minimumHitTarget = Metrics.hitTarget

    /// VoiceOver value: "Checked" or "Unchecked".
    static func accessibilityValue(isOn: Bool) -> String { isOn ? "Checked" : "Unchecked" }

    // MARK: - Behavior

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        isOn.toggle()
    }
}

// MARK: - Button Style

/// Press feedback from `DSPress`: the whole row dips toward its leading edge
/// (so the box stays put under the thumb), or the lone box dips in place.
private struct DSCheckboxButtonStyle: ButtonStyle {
    let scale: CGFloat
    let anchor: UnitPoint

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0, anchor: anchor)
            .animation(DSPress.animation, value: configuration.isPressed)
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
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        DSCheckbox("Accept terms & conditions", isOn: $terms)
                        DSCheckbox("Subscribe to the newsletter", isOn: $newsletter)
                        DSCheckbox("Send me offers", isOn: $offers, onColor: DSColors.success)
                        DSCheckbox("Unavailable option", isOn: $disabled)
                            .disabled(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Today").ds(.footnote, color: DSColors.textSecondary)
                        DSCheckbox("Water the plants", isOn: $tasks[0], size: .small)
                        DSCheckbox("Reply to Ana", isOn: $tasks[1], size: .small)
                        DSCheckbox("Book the flight", isOn: $tasks[2], size: .small)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: DSSpacing.md) {
                    DSCheckbox(isOn: $terms, size: .small).accessibilityLabel("Small")
                    DSCheckbox(isOn: $newsletter, size: .medium).accessibilityLabel("Medium")
                    DSCheckbox(isOn: $offers, size: .large, onColor: DSColors.success).accessibilityLabel("Large")
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
