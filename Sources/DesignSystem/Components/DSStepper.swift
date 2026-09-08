import SwiftUI

// MARK: - Design System Stepper
// A compact −/＋ counter for quantities: cart items, portions, guest counts,
// any small integer a form needs. The value rolls between numbers with the
// iOS 17 numeric content transition, each step ticks with a selection haptic,
// and the control gives a firm nudge — without changing the value — when you
// push against a bound, so the limit is felt, not just seen.
//
// Doc + inspiration for the rolling number:
//   Sarunw — "Animating number changes in SwiftUI"
//   https://sarunw.com/posts/animating-number-changes-in-swiftui/

public struct DSStepper: View {
    let label: String?
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let haptics: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - label: Optional leading label; when present the control trails a `Spacer`.
    ///   - value: The current value. The control keeps it inside `range`.
    ///   - range: Allowed closed range. Defaults to `0...99`.
    ///   - step: Amount added or removed per tap. Defaults to `1`.
    ///   - haptics: Fire tactile feedback on each step and at the bounds. Defaults to `true`.
    public init(
        _ label: String? = nil,
        value: Binding<Int>,
        in range: ClosedRange<Int> = 0...99,
        step: Int = 1,
        haptics: Bool = true
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = max(1, step)
        self.haptics = haptics
    }

    public var body: some View {
        HStack(spacing: DSSpacing.md) {
            if let label {
                Text(label).ds(.body)
                Spacer(minLength: DSSpacing.sm)
            }
            control
        }
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Stepper")
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            switch direction {
            case .increment: change(by: step)
            case .decrement: change(by: -step)
            @unknown default: break
            }
        }
    }

    // MARK: - Control

    private var control: some View {
        HStack(spacing: DSSpacing.xs) {
            DSStepperButton(icon: "minus", enabled: canDecrement) {
                change(by: -step)
            }

            Text("\(value)")
                .ds(.numeric)
                .contentTransition(.numericText(value: Double(value)))
                .frame(minWidth: DSSpacing.xl)

            DSStepperButton(icon: "plus", enabled: canIncrement) {
                change(by: step)
            }
        }
        .dsSurface(.glassThin, radius: DSRadius.chip)
    }

    // MARK: - Stepping

    private func change(by delta: Int) {
        let target = clamp(value + delta)
        guard target != value else {
            // Pushing against a bound: a firm nudge, no change in value.
            if haptics { DSHapticEngine.shared.fire(.rigid) }
            return
        }
        if haptics { DSHapticEngine.shared.fire(.selection) }
        if reduceMotion {
            value = target
        } else {
            withAnimation(DSAnimation.springSnappy) {
                value = target
            }
        }
    }

    private func clamp(_ v: Int) -> Int {
        min(max(v, range.lowerBound), range.upperBound)
    }

    private var canDecrement: Bool { value > range.lowerBound }
    private var canIncrement: Bool { value < range.upperBound }
}

// MARK: - Stepper Button

/// One −/＋ target. Stays tappable at a bound (dimmed) so the parent can fire
/// the "at the limit" nudge; the glass pill and press feel match the catalog.
private struct DSStepperButton: View {
    let icon: String
    let enabled: Bool
    let action: () -> Void

    @State private var isPressed = false
    @DSThemed private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(DSTextStyle.title3.font)
                .foregroundStyle(theme.ink)
                .frame(minWidth: DSSpacing.md)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.sm)
                .contentShape(Rectangle())
                .opacity(enabled ? 1 : 0.35)
                .scaleEffect(isPressed ? DSPress.iconScale : 1.0)
                .animation(DSPress.animation, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#if DEBUG
private struct DSStepperPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var quantity = 2
    @State private var guests = 1
    @State private var portions = 4
    @State private var locked = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        DSStepper("Quantity", value: $quantity, in: 0...10)
                        DSStepper("Guests", value: $guests, in: 1...8)
                        DSStepper("Portions", value: $portions, in: 1...12, step: 2)
                        DSStepper("Disabled", value: $locked)
                            .disabled(true)
                    }
                }

                DSCard {
                    HStack {
                        Text("Standalone").ds(.body)
                        Spacer()
                        DSStepper(value: $quantity, in: 0...10)
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Stepper — Light") {
    DSStepperPreviewHost().preferredColorScheme(.light)
}

#Preview("Stepper — Dark") {
    DSStepperPreviewHost().preferredColorScheme(.dark)
}
#endif
