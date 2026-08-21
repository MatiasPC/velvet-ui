import SwiftUI

// MARK: - Design System Stepper
// A tactile numeric stepper for quantities — cart counters, form fields,
// settings. Tap a control to change the value by `step`; press and hold to
// auto-repeat with a gentle acceleration, so reaching a large number never
// means dozens of taps. The value rolls between digits with iOS 17's
// `numericText` content transition, each change springs, and every step fires
// a selection tick. The `+` / `−` controls disable and dim at the bounds.
//
// This fills the controls-family gap alongside DSToggle, DSSegmentedControl,
// and DSRating: the stock `Stepper` can't be styled, has no hold acceleration,
// and carries no DS motion or haptics.

public struct DSStepper: View {

    // MARK: - Configuration

    @Binding private var value: Int
    private let range: ClosedRange<Int>
    private let step: Int
    private let tint: Color
    private let format: ((Int) -> String)?

    // MARK: - State

    @Environment(\.isEnabled) private var isEnabled
    /// Drives the press-and-hold auto-repeat; cancelled on release.
    @State private var holdTask: Task<Void, Never>?

    // MARK: - Init

    /// A numeric stepper bound to an integer value.
    /// - Parameters:
    ///   - value: The current value. Clamped into `range` as it changes.
    ///   - range: The permitted closed range. Defaults to `0...99`.
    ///   - step: Amount added or removed per step. Defaults to `1`.
    ///   - tint: Accent color for the active controls. Defaults to the primary.
    ///   - format: Optional formatter for the displayed value (e.g. `"\($0) kg"`).
    ///     Defaults to the plain number.
    public init(
        value: Binding<Int>,
        in range: ClosedRange<Int> = 0...99,
        step: Int = 1,
        tint: Color = DSColors.defaultPalette.primary,
        format: ((Int) -> String)? = nil
    ) {
        self._value = value
        self.range = range
        self.step = max(1, step)
        self.tint = tint
        self.format = format
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 0) {
            control(direction: -1, icon: "minus")
            divider
            valueLabel
            divider
            control(direction: 1, icon: "plus")
        }
        .background(DSColors.defaultPalette.backgroundSecondary)
        .dsCornerRadius(DSRadius.md, strokeColor: DSColors.defaultPalette.border)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stepper")
        .accessibilityValue(displayString)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if canStep(1) { applyStep(1) }
            case .decrement: if canStep(-1) { applyStep(-1) }
            @unknown default: break
            }
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private func control(direction: Int, icon: String) -> some View {
        let enabled = isEnabled && canStep(direction)

        Image(systemName: icon)
            .font(DSTextStyle.title3.font)
            .foregroundStyle(enabled ? tint : DSColors.defaultPalette.textTertiary)
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.sm)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            // Large `minimumDuration` so the press never "succeeds" into `perform`;
            // press-down / release are driven entirely by the `pressing` closure.
            .onLongPressGesture(minimumDuration: 100, maximumDistance: 40) {
                // no-op: single taps and holds are handled in `pressing`
            } onPressingChanged: { pressing in
                if pressing { beginHold(direction) } else { endHold() }
            }
            .disabled(!enabled)
            .accessibilityHidden(true)
    }

    private var valueLabel: some View {
        Text(displayString)
            .dsTextStyle(.title3)
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(value)))
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .frame(maxHeight: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(DSColors.defaultPalette.divider)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }

    // MARK: - Stepping

    private var displayString: String {
        format?(value) ?? "\(value)"
    }

    /// Whether a step in `direction` (+1 / −1) would move within the range.
    private func canStep(_ direction: Int) -> Bool {
        direction > 0 ? value < range.upperBound : value > range.lowerBound
    }

    /// Apply one clamped step, animating the roll and firing a tick.
    private func applyStep(_ direction: Int) {
        let target = value + direction * step
        let clamped = min(max(target, range.lowerBound), range.upperBound)
        guard clamped != value else { return }
        withAnimation(DSAnimation.springSnappy) {
            value = clamped
        }
        DSHapticEngine.shared.fire(.selection)
    }

    // MARK: - Press-and-hold

    private func beginHold(_ direction: Int) {
        holdTask?.cancel()
        holdTask = Task { @MainActor in
            guard canStep(direction) else { return }
            applyStep(direction)                                  // immediate first step
            try? await Task.sleep(nanoseconds: 450_000_000)       // pause before auto-repeat
            var interval: UInt64 = 120_000_000                    // 0.12s, accelerating
            while !Task.isCancelled, canStep(direction) {
                applyStep(direction)
                try? await Task.sleep(nanoseconds: interval)
                interval = max(45_000_000, interval - 8_000_000)  // down to ~0.045s
            }
        }
    }

    private func endHold() {
        holdTask?.cancel()
        holdTask = nil
    }
}

// MARK: - Preview

#Preview("Light") {
    StepperPreview()
        .padding(DSSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    StepperPreview()
        .padding(DSSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct StepperPreview: View {
    @State private var quantity = 1
    @State private var guests = 2
    @State private var temperature = 20
    @State private var maxed = 10

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            row("Quantity") {
                DSStepper(value: $quantity, in: 1...20)
            }
            row("Guests") {
                DSStepper(value: $guests, in: 1...8,
                          tint: DSColors.defaultPalette.secondary)
            }
            row("Temperature") {
                DSStepper(value: $temperature, in: 16...30) { "\($0)°" }
            }
            row("At maximum") {
                DSStepper(value: $maxed, in: 0...10)
            }
            row("Disabled") {
                DSStepper(value: $guests, in: 1...8)
                    .disabled(true)
            }
        }
    }

    @ViewBuilder
    private func row(_ title: String, @ViewBuilder control: () -> some View) -> some View {
        HStack {
            Text(title).ds(.body)
            Spacer(minLength: DSSpacing.md)
            control()
        }
    }
}
