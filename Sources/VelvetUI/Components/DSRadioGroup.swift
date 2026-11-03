import SwiftUI

// MARK: - Design System Radio Group
// Single-select from a vertical list of options, the control the catalog was
// missing. `DSSegmentedControl` picks one of a few side-by-side modes; a
// checkbox toggles many independent flags; neither fits "choose exactly one of
// several" (a plan, a payment method, a shipping speed, a survey answer). This
// does, and it carries the Velvet signature: the indicator morphs rather than
// snaps, and a frosted highlight glides from the old row to the new one.
//
// It is built as the sibling of `DSCheckbox`: the same 24pt indicator (a wash
// fill with the specular `dsWashEdge`, never an outline), the same accent
// layer that pops in with `springBouncy`, the same `onAccent` mark, the same
// `.rigid` haptic. Where the checkbox draws a tick, the radio grows a dot.
//
// Two motions run together on select:
//   • the indicator's accent layer pops up and fades in while its inner dot
//     grows from nothing a beat later (and the old row's indicator shrinks back);
//   • a `theme.subtleFill` highlight slides between rows with
//     `matchedGeometryEffect` + `springSmooth`, the selection-indicator trick
//     `DSSegmentedControl` uses, here running vertically.
//
// All of it follows `selection`, so a change made from outside (a "reset"
// button) animates the same way a tap does. Under Reduce Motion nothing slides,
// pops or grows: indicators and highlight crossfade in place.

/// Sizes and pure logic. Internal, so the unit tests can reach them; none of it is API.
enum DSRadioGroupMetrics {
    /// The indicator is this wide and tall: a `DSCheckboxSize.medium` box, so a
    /// radio row and a checkbox row line up and read as one family.
    static let indicatorSide: CGFloat = DSSpacing.xl
    /// The inner dot as a fraction of the indicator.
    static let dotRatio: CGFloat = 0.42
    /// Apple's 44pt minimum tap target, built from tokens: DSSpacing.xxl (32) + DSSpacing.sm (12).
    static let hitTarget: CGFloat = DSSpacing.xxl + DSSpacing.sm
    /// Every row is at least this tall (and as wide as the group).
    static let minimumRowHeight: CGFloat = hitTarget
    /// The accent layer starts here when it pops in, and shrinks back to it.
    static let restScale: CGFloat = 0.55
    /// The dot starts growing this long (seconds) after the layer starts to fill.
    static let dotDelay: Double = 0.06
    /// Dim while disabled; the same as `DSToggle` and `DSCheckbox`.
    static let disabledOpacity: Double = 0.5

    static var dotSide: CGFloat { indicatorSide * dotRatio }

    /// Scale of the accent layer. It only pops when motion is allowed; under
    /// Reduce Motion it rests at full size and just fades.
    static func layerScale(isSelected: Bool, reduceMotion: Bool) -> CGFloat {
        isSelected || reduceMotion ? 1 : restScale
    }

    /// Scale of the inner dot. Under Reduce Motion it stays full size, so the
    /// layer's fade carries the whole change and the dot never vanishes first.
    static func dotScale(isSelected: Bool, reduceMotion: Bool) -> CGFloat {
        isSelected || reduceMotion ? 1 : 0
    }

    /// VoiceOver label: the title, then the subtitle when there is one.
    static func accessibilityLabel(title: String, subtitle: String?) -> String {
        guard let subtitle, !subtitle.isEmpty else { return title }
        return "\(title), \(subtitle)"
    }

    /// VoiceOver value: the 1-based position in the group, "2 of 3".
    static func accessibilityValue(position: Int, count: Int) -> String {
        "\(position) of \(count)"
    }

    /// What VoiceOver says when the user picks a row.
    static func announcement(title: String) -> String {
        "\(title), selected"
    }

    /// Whether choosing `value` is a change: reselecting the current value does nothing.
    static func isChange<Value: Equatable>(to value: Value, from current: Value) -> Bool {
        value != current
    }
}

// MARK: - Option Model

/// One choice in a `DSRadioGroup`. `value` is what the binding is set to and
/// what identifies the row, so values must be unique within a group; `title` is
/// the row's label, with an optional `subtitle` for a one-line description and
/// an optional leading `icon` (SF Symbol name).
public struct DSRadioOption<Value: Hashable>: Identifiable {
    public var id: Value { value }
    public let value: Value
    public let title: String
    public let subtitle: String?
    public let icon: String?

    public init(_ title: String, value: Value, subtitle: String? = nil, icon: String? = nil) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

// MARK: - Radio Group

/// A vertical single-select control. Generic over any `Hashable` value, so it
/// drives an enum, an id or a plain string with no wrapper type.
///
///     enum Plan { case free, pro, team }
///     @State private var plan: Plan = .pro
///
///     DSRadioGroup(selection: $plan, options: [
///         DSRadioOption("Free", value: .free, subtitle: "For trying things out"),
///         DSRadioOption("Pro", value: .pro, subtitle: "Everything, for one person"),
///         DSRadioOption("Team", value: .team, subtitle: "Shared workspaces")
///     ])
///
/// For a quick list of strings whose value is the label itself, use the
/// `[String]` convenience initializer. Wrap the group in a `DSCard` for the
/// glass container look, the same way list cells are grouped. Every row is at
/// least 44pt tall and as wide as the group, and the whole row is the tap target.
/// Label the group for VoiceOver with `.accessibilityLabel("Plan")`.
public struct DSRadioGroup<Value: Hashable>: View {
    @Binding private var selection: Value
    private let options: [DSRadioOption<Value>]
    private let accent: Color?
    private let haptic: DSHapticStyle

    @Namespace private var namespace
    @DSThemed private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - selection: The currently chosen value.
    ///   - options: The choices, top to bottom. Their values must be unique.
    ///   - accent: Fill of the selected indicator. Defaults to the theme accent.
    ///   - haptic: Fired on a change of selection (never on reselecting the
    ///     current value). Defaults to `.rigid`, the same snap as `DSCheckbox`.
    public init(
        selection: Binding<Value>,
        options: [DSRadioOption<Value>],
        accent: Color? = nil,
        haptic: DSHapticStyle = .rigid
    ) {
        self._selection = selection
        self.options = options
        self.accent = accent
        self.haptic = haptic
    }

    public var body: some View {
        VStack(spacing: DSSpacing.xxs) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                row(option, position: index + 1)
            }
        }
        .animation(selectionAnimation, value: selection)
        .opacity(isEnabled ? 1 : DSRadioGroupMetrics.disabledOpacity)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Row

    private func row(_ option: DSRadioOption<Value>, position: Int) -> some View {
        let isSelected = option.value == selection

        return Button {
            select(option)
        } label: {
            HStack(spacing: DSSpacing.sm) {
                indicator(isSelected: isSelected)

                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(DSTextStyle.title3.font)
                        .foregroundStyle(isSelected ? theme.ink : theme.palette.textSecondary)
                        .frame(width: DSRadioGroupMetrics.indicatorSide)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                    Text(option.title)
                        .ds(.body)
                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .ds(.footnote, color: theme.palette.textSecondary)
                    }
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: DSSpacing.sm)
            }
            .padding(DSSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: DSRadioGroupMetrics.minimumRowHeight, alignment: .leading)
            .background(highlight(isSelected: isSelected))
            .contentShape(Rectangle())
        }
        .buttonStyle(DSRadioRowButtonStyle())
        .accessibilityLabel(DSRadioGroupMetrics.accessibilityLabel(title: option.title, subtitle: option.subtitle))
        .accessibilityValue(DSRadioGroupMetrics.accessibilityValue(position: position, count: options.count))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Indicator

    /// Fill of the selected indicator.
    private var fill: Color { accent ?? theme.accent }

    /// The dot sits on the accent, so it takes `onAccent`; on a custom fill it
    /// takes `textOnPrimary`, the role for text on status colors.
    private var markColor: Color { accent == nil ? theme.onAccent : theme.palette.textOnPrimary }

    /// An empty wash circle with an accent layer on top: the layer pops up and
    /// fades in while the dot grows inside it. Each property carries its own
    /// curve (the animation modifier nearest the leaf wins), and the bouncy
    /// spring never drives opacity, which it would make flicker on the way out.
    private func indicator(isSelected: Bool) -> some View {
        let side = DSRadioGroupMetrics.indicatorSide

        return ZStack {
            Circle()
                .fill(theme.subtleFill)

            Circle()
                .fill(fill)
                .overlay {
                    Circle()
                        .fill(markColor)
                        .frame(width: DSRadioGroupMetrics.dotSide, height: DSRadioGroupMetrics.dotSide)
                        .scaleEffect(DSRadioGroupMetrics.dotScale(isSelected: isSelected, reduceMotion: reduceMotion))
                        .animation(dotAnimation(isSelected: isSelected), value: isSelected)
                }
                .opacity(isSelected ? 1 : 0)
                .animation(fadeAnimation, value: isSelected)
                .scaleEffect(DSRadioGroupMetrics.layerScale(isSelected: isSelected, reduceMotion: reduceMotion))
                .animation(popAnimation(isSelected: isSelected), value: isSelected)
        }
        .frame(width: side, height: side)
        .dsWashEdge(radius: DSRadius.pill)
    }

    // MARK: - Selection Highlight

    /// The frosted highlight behind the selected row. Only the selected row
    /// renders it; `matchedGeometryEffect` carries it from the old row to the
    /// new one, resizing to fit rows with and without a subtitle. Under Reduce
    /// Motion the two rows are not matched, so it crossfades in place instead of sliding.
    @ViewBuilder
    private func highlight(isSelected: Bool) -> some View {
        if isSelected {
            let shape = RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                .fill(theme.subtleFill)
                .dsWashEdge(radius: DSRadius.control)
            if reduceMotion {
                shape
            } else {
                shape.matchedGeometryEffect(id: "radioSelection", in: namespace)
            }
        }
    }

    // MARK: - Motion

    /// Drives the highlight and everything else that follows `selection`.
    private var selectionAnimation: Animation {
        reduceMotion ? DSAnimation.micro : DSAnimation.springSmooth
    }

    /// The pop: bouncy on the way in, a quick snap on the way out. None under Reduce Motion.
    private func popAnimation(isSelected: Bool) -> Animation? {
        reduceMotion ? nil : (isSelected ? DSAnimation.springBouncy : DSAnimation.springSnappy)
    }

    /// The layer's fade. Under Reduce Motion this is the only thing that moves.
    private var fadeAnimation: Animation {
        reduceMotion ? DSAnimation.micro : DSAnimation.fast
    }

    /// The dot grows a beat after the layer starts to fill, and is gone at once on deselect.
    private func dotAnimation(isSelected: Bool) -> Animation? {
        guard !reduceMotion else { return nil }
        return isSelected ? DSAnimation.springSmooth.delay(DSRadioGroupMetrics.dotDelay) : DSAnimation.micro
    }

    // MARK: - Selection

    private func select(_ option: DSRadioOption<Value>) {
        guard isEnabled, DSRadioGroupMetrics.isChange(to: option.value, from: selection) else { return }
        DSHapticEngine.shared.fire(haptic)
        selection = option.value
        AccessibilityNotification.Announcement(DSRadioGroupMetrics.announcement(title: option.title)).post()
    }
}

// MARK: - Button Style

/// Press feedback from `DSPress`: the row dips under the finger.
private struct DSRadioRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DSPress.scale : 1.0)
            .animation(DSPress.animation, value: configuration.isPressed)
    }
}

// MARK: - String Convenience

public extension DSRadioGroup where Value == String {
    /// Build a radio group directly from an array of string options, where each
    /// string is both the label and the bound value.
    init(
        selection: Binding<String>,
        options: [String],
        accent: Color? = nil,
        haptic: DSHapticStyle = .rigid
    ) {
        self.init(
            selection: selection,
            options: options.map { DSRadioOption($0, value: $0) },
            accent: accent,
            haptic: haptic
        )
    }
}

// MARK: - Preview

#if DEBUG
private struct DSRadioGroupPreviewHost: View {
    @State private var theme = DSTheme()

    enum Plan: String, CaseIterable { case free, pro, team }
    @State private var plan: Plan = .pro
    @State private var payment = "Apple Pay"
    @State private var speed = "Standard"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                Text("Plans — subtitles").ds(.overline, color: DSColors.textSecondary)
                DSCard {
                    DSRadioGroup(selection: $plan, options: [
                        DSRadioOption("Free", value: .free, subtitle: "For trying things out"),
                        DSRadioOption("Pro", value: .pro, subtitle: "Everything, for one person"),
                        DSRadioOption("Team", value: .team, subtitle: "Shared workspaces")
                    ])
                    .accessibilityLabel("Plan")
                }

                Text("Payment — leading icons, custom accent")
                    .ds(.overline, color: DSColors.textSecondary)
                DSCard {
                    DSRadioGroup(
                        selection: $payment,
                        options: [
                            DSRadioOption("Apple Pay", value: "Apple Pay", icon: "apple.logo"),
                            DSRadioOption("Credit Card", value: "Credit Card", icon: "creditcard"),
                            DSRadioOption("PayPal", value: "PayPal", icon: "p.circle")
                        ],
                        accent: DSColors.success
                    )
                    .accessibilityLabel("Payment method")
                }

                Text("Shipping — plain strings, disabled").ds(.overline, color: DSColors.textSecondary)
                DSCard {
                    DSRadioGroup(
                        selection: $speed,
                        options: ["Standard", "Express", "Overnight"]
                    )
                    .disabled(true)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Radio Group — Light") {
    DSRadioGroupPreviewHost().preferredColorScheme(.light)
}

#Preview("Radio Group — Dark") {
    DSRadioGroupPreviewHost().preferredColorScheme(.dark)
}
#endif
