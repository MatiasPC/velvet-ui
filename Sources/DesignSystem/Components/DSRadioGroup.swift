import SwiftUI

// MARK: - Design System Radio Group
// A single-select control for choosing exactly one option from a short list.
// The natural complement to `DSToggle` (boolean) and `DSSegmentedControl`
// (compact picker): where those don't fit, a radio group is the standard
// pattern for plan pickers, payment methods, shipping options and surveys.
//
// Each option is a tappable, bordered row. Selecting one springs a filled dot
// into its ring, animates the row's border and tint into the accent color, and
// fires a selection tick. Rows support an optional secondary description line,
// press feedback, and the disabled state — all driven by DS tokens only.

// MARK: - Option Model

public struct DSRadioOption<Value: Hashable>: Identifiable {
    public let value: Value
    public let title: String
    public let subtitle: String?

    public var id: Value { value }

    /// - Parameters:
    ///   - value: The value this row represents when selected.
    ///   - title: The primary label shown for the row.
    ///   - subtitle: An optional secondary description line.
    public init(_ value: Value, title: String, subtitle: String? = nil) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - Radio Group

public struct DSRadioGroup<Value: Hashable>: View {

    // MARK: - Configuration

    @Binding private var selection: Value
    private let options: [DSRadioOption<Value>]
    private let tint: Color
    private let spacing: CGFloat
    private let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Init

    /// Create a radio group from explicit option models.
    /// - Parameters:
    ///   - selection: The currently selected value.
    ///   - options: The selectable rows, in display order.
    ///   - tint: Accent color for the selected ring, dot and row. Defaults to the primary.
    ///   - spacing: Vertical gap between rows. Defaults to `DSSpacing.sm`.
    ///   - haptic: Feedback fired when the selection changes. Defaults to `.selection`.
    public init(
        selection: Binding<Value>,
        options: [DSRadioOption<Value>],
        tint: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.sm,
        haptic: DSHapticStyle = .selection
    ) {
        self._selection = selection
        self.options = options
        self.tint = tint
        self.spacing = spacing
        self.haptic = haptic
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: spacing) {
            ForEach(options) { option in
                row(for: option)
            }
        }
        .opacity(isEnabled ? 1 : 0.5)
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for option: DSRadioOption<Value>) -> some View {
        let isSelected = option.value == selection

        Button {
            select(option.value)
        } label: {
            HStack(alignment: .center, spacing: DSSpacing.md) {
                indicator(isSelected: isSelected)

                VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                    Text(option.title)
                        .ds(.body, color: DSColors.defaultPalette.textPrimary)
                        .multilineTextAlignment(.leading)

                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: DSSpacing.sm)
            }
            .padding(DSSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.08) : DSColors.defaultPalette.backgroundElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .stroke(
                        isSelected ? tint : DSColors.defaultPalette.border,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        }
        .buttonStyle(RadioRowStyle())
        .animation(DSAnimation.springSnappy, value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Indicator

    private func indicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(
                    isSelected ? tint : DSColors.defaultPalette.border,
                    lineWidth: 2
                )

            Circle()
                .fill(tint)
                .padding(5)
                .scaleEffect(isSelected ? 1 : 0.01)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: 22, height: 22)
        .animation(DSAnimation.springBouncy, value: isSelected)
    }

    // MARK: - Selection

    private func select(_ value: Value) {
        guard isEnabled, value != selection else { return }
        DSHapticEngine.shared.fire(haptic)
        withAnimation(DSAnimation.springSnappy) {
            selection = value
        }
    }
}

// MARK: - String Convenience

public extension DSRadioGroup where Value == String {
    /// Create a radio group from a list of plain string titles, using each
    /// title as its own selection value.
    init(
        selection: Binding<String>,
        options: [String],
        tint: Color = DSColors.defaultPalette.primary,
        spacing: CGFloat = DSSpacing.sm,
        haptic: DSHapticStyle = .selection
    ) {
        self.init(
            selection: selection,
            options: options.map { DSRadioOption($0, title: $0) },
            tint: tint,
            spacing: spacing,
            haptic: haptic
        )
    }
}

// MARK: - Row Button Style

private struct RadioRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DSAnimation.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Light") {
    RadioGroupPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    RadioGroupPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct RadioGroupPreview: View {
    @State private var plan = "pro"
    @State private var shipping = "Standard"

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Choose a plan")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSRadioGroup(
                    selection: $plan,
                    options: [
                        DSRadioOption("free", title: "Free", subtitle: "For getting started"),
                        DSRadioOption("pro", title: "Pro", subtitle: "$9/mo — everything you need"),
                        DSRadioOption("team", title: "Team", subtitle: "$29/mo — collaborate together")
                    ]
                )
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Shipping")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSRadioGroup(
                    selection: $shipping,
                    options: ["Standard", "Express", "Overnight"],
                    tint: DSColors.defaultPalette.secondary
                )
            }
        }
    }
}
