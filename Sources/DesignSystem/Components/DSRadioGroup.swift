import SwiftUI

// MARK: - Design System Radio Group
// Single-select from a vertical list of options — the control the catalog was
// missing. `DSSegmentedControl` picks one of a few side-by-side modes; a
// checkbox toggles many independent flags; neither fits "choose exactly one of
// several" (a plan, a payment method, a shipping speed, a survey answer). This
// does, and it carries the Velvet signature: the indicator morphs rather than
// snaps, and a frosted highlight glides from the old row to the new one.
//
// Two motions run together on select, both from proven Velvet patterns:
//   • the indicator symbol swaps `circle` → `circle.inset.filled` through
//     `.contentTransition(.symbolEffect(.replace))` (the same symbol-morph idea
//     as `DSThinkingIndicator`), tinting to the accent as it fills;
//   • a `theme.subtleFill` highlight slides between rows with
//     `matchedGeometryEffect` + `springSmooth` — the selection-indicator trick
//     `DSSegmentedControl` already uses, here running vertically.
//
// No borders: the selected row is a frosted wash, never a stroke. The ring is a
// control glyph (an SF Symbol), not a surface edge.

// MARK: - Option Model

/// One choice in a `DSRadioGroup`. `value` is what the binding is set to;
/// `title` is the row's label, with an optional `subtitle` for a one-line
/// description and an optional leading `icon` (SF Symbol name).
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
/// glass container look, the same way list cells are grouped.
public struct DSRadioGroup<Value: Hashable>: View {
    @Binding private var selection: Value
    private let options: [DSRadioOption<Value>]
    private let accent: Color?
    private let haptic: DSHapticStyle

    @Namespace private var namespace
    @DSThemed private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Diameter of the radio indicator. A literal until a third component needs
    /// a shared `DSIconSize` token (tracked in engineering-notes), matching how
    /// `DSSegmentedControl` sizes its glyphs today.
    private let indicatorSize: CGFloat = 22

    /// - Parameters:
    ///   - selection: The currently chosen value.
    ///   - options: The choices, top to bottom.
    ///   - accent: Fill for the selected indicator and highlight tint source.
    ///     Defaults to the theme accent.
    ///   - haptic: Fired on a change of selection (never on reselecting the
    ///     current value). Defaults to `.selection`.
    public init(
        selection: Binding<Value>,
        options: [DSRadioOption<Value>],
        accent: Color? = nil,
        haptic: DSHapticStyle = .selection
    ) {
        self._selection = selection
        self.options = options
        self.accent = accent
        self.haptic = haptic
    }

    public var body: some View {
        VStack(spacing: DSSpacing.xxs) {
            ForEach(options) { option in
                row(option)
            }
        }
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Row

    private func row(_ option: DSRadioOption<Value>) -> some View {
        let isSelected = option.value == selection
        let resolvedAccent = accent ?? theme.accent

        return Button {
            select(option.value)
        } label: {
            HStack(spacing: DSSpacing.sm) {
                indicator(isSelected: isSelected, accent: resolvedAccent)

                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(DSTextStyle.title3.font)
                        .foregroundStyle(isSelected ? theme.ink : theme.palette.textSecondary)
                        .frame(width: indicatorSize)
                }

                VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                    Text(option.title)
                        .ds(.body)
                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .ds(.footnote, color: theme.palette.textSecondary)
                    }
                }

                Spacer(minLength: DSSpacing.sm)
            }
            .padding(DSSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(highlight(isSelected: isSelected))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityValue(Text(option.subtitle ?? ""))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Indicator

    /// A ring that fills into a dot. The symbol swap is a content transition,
    /// not travel, so under Reduce Motion it simply cuts rather than morphing.
    private func indicator(isSelected: Bool, accent: Color) -> some View {
        Image(systemName: isSelected ? "circle.inset.filled" : "circle")
            .font(.system(size: indicatorSize, weight: .regular))
            .foregroundStyle(isSelected ? accent : theme.palette.textTertiary)
            .contentTransition(reduceMotion ? .identity : .symbolEffect)
            .frame(width: indicatorSize, height: indicatorSize)
    }

    // MARK: - Selection Highlight

    /// The frosted highlight behind the selected row. Only the selected row
    /// renders it; `matchedGeometryEffect` carries it from the old row to the
    /// new one, resizing to fit rows with and without a subtitle.
    @ViewBuilder
    private func highlight(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                .fill(theme.subtleFill)
                .matchedGeometryEffect(id: "radioSelection", in: namespace)
        }
    }

    // MARK: - Selection

    private func select(_ value: Value) {
        guard isEnabled, value != selection else { return }
        DSHapticEngine.shared.fire(haptic)
        if reduceMotion {
            selection = value
        } else {
            withAnimation(DSAnimation.springSmooth) {
                selection = value
            }
        }
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
        haptic: DSHapticStyle = .selection
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
                        accent: DSColors.secondary
                    )
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
