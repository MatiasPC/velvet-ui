import SwiftUI

// MARK: - Design System Stepper
// A −/value/+ numeric stepper on a glass track. Tapping either glyph steps the
// bound value, clamped into range; the number rolls with `.numericText` rather
// than swapping. Hitting a bound doesn't move the value — the whole track fires
// a single decaying `dsJiggle` wiggle and a `.warning` haptic to say "no further",
// while a normal step fires a light `.selection` tick.
//
// The two glyph buttons stay hit-testable at a bound (never `.disabled`) so the
// refusal feedback can still fire — they just dim and stop looking tappable.
//
// Technique inspired by: open-swiftui-animations/HumanInitiatedAnimations/IncreaseDecrease.swift

/// Sizes derived from the spacing scale — no raw CGFloat literals in the view body below.
private enum Metrics {
    /// Apple's 44pt minimum tap target, built from tokens rather than hardcoded:
    /// DSSpacing.xxl (32) + DSSpacing.sm (12) = 44.
    static let hitTarget: CGFloat = DSSpacing.xxl + DSSpacing.sm
    /// Icon point size as a fraction of the hit target — the same 0.4 ratio
    /// `DSIconButton` uses, so the −/+ glyphs read at a consistent weight.
    static let iconSize: CGFloat = hitTarget * 0.4
    /// Breathing room around the value label inside the glass track.
    static let valuePadding: CGFloat = DSSpacing.xs
}

public struct DSStepper: View {
    @Binding private var value: Int
    private let range: ClosedRange<Int>
    private let step: Int
    private let accent: Color?

    /// Bumped once per refusal to retrigger `dsJiggle`.
    @State private var jiggleTrigger = 0
    @DSThemed private var theme

    /// - Parameters:
    ///   - value: The current value, clamped into `range`.
    ///   - range: The allowed bounds. Defaults to `0...99`.
    ///   - step: The increment per tap or VoiceOver adjustment. Non-positive
    ///     values are treated as `1`. Defaults to `1`.
    ///   - accent: Glyph tint. Defaults to `theme.ink`.
    public init(
        value: Binding<Int>,
        in range: ClosedRange<Int> = 0...99,
        step: Int = 1,
        accent: Color? = nil
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.accent = accent
    }

    public var body: some View {
        HStack(spacing: 0) {
            DSStepperGlyphButton(
                systemName: "minus",
                color: accent ?? theme.ink,
                isAtBound: isAtLowerBound,
                action: { applyStep(-effectiveStep) }
            )

            valueLabel

            DSStepperGlyphButton(
                systemName: "plus",
                color: accent ?? theme.ink,
                isAtBound: isAtUpperBound,
                action: { applyStep(effectiveStep) }
            )
        }
        .frame(height: Metrics.hitTarget)
        .dsSurface(.glassThin, radius: DSRadius.chip)
        .dsJiggle(trigger: jiggleTrigger)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stepper")
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: applyStep(effectiveStep)
            case .decrement: applyStep(-effectiveStep)
            @unknown default: break
            }
        }
    }

    // MARK: - Value Label

    /// The animated number, its width reserved for the widest string `range` can
    /// produce: a same-styled copy of that string sits underneath at zero opacity,
    /// so the `ZStack` sizes to it and the track never resizes as digits change.
    private var valueLabel: some View {
        ZStack {
            Text(widestValueString)
                .ds(.numeric)
                .opacity(0)

            Text("\(value)")
                .ds(.numeric, color: theme.palette.textPrimary)
                .contentTransition(.numericText(value: Double(value)))
        }
        .padding(.horizontal, Metrics.valuePadding)
    }

    /// The longest formatted value `range` can hold. Digit count only grows with
    /// magnitude, so the widest string is always one of the two bounds.
    private var widestValueString: String {
        let lower = String(range.lowerBound)
        let upper = String(range.upperBound)
        return lower.count >= upper.count ? lower : upper
    }

    // MARK: - Stepping

    /// `step`, guarded against zero/negative input.
    private var effectiveStep: Int { step > 0 ? step : 1 }

    private var isAtLowerBound: Bool { value <= range.lowerBound }
    private var isAtUpperBound: Bool { value >= range.upperBound }

    /// Applies `delta`, clamped into `range` — correct even when `step` doesn't
    /// evenly divide the range (e.g. `step: 5` over `0...12` lands on 12, not 15).
    /// A move that actually changes the value ticks `.selection`; a move that
    /// can't (already at the bound) fires `.warning` and the refusal wiggle.
    private func applyStep(_ delta: Int) {
        let proposed = value + delta
        let clamped = min(max(proposed, range.lowerBound), range.upperBound)

        if clamped != value {
            withAnimation(DSAnimation.springSnappy) {
                value = clamped
            }
            DSHapticEngine.shared.fire(.selection)
        } else {
            DSHapticEngine.shared.fire(.warning)
            jiggleTrigger += 1
        }
    }
}

// MARK: - Glyph Button

/// A minus/plus glyph matching `DSIconButton`'s press feel exactly, but never
/// `.disabled` — at a bound it just dims, so the tap (and its refusal haptic
/// and jiggle, driven by the parent) still lands.
private struct DSStepperGlyphButton: View {
    let systemName: String
    let color: Color
    let isAtBound: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: Metrics.iconSize, weight: .semibold))
                .foregroundStyle(color)
                .opacity(isAtBound ? 0.4 : 1)
                .frame(width: Metrics.hitTarget, height: Metrics.hitTarget)
                .contentShape(Rectangle())
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
    @State private var quantity = 3
    @State private var bulk = 25
    @State private var atUpperBound = 99

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Default").ds(.overline, color: DSColors.textSecondary)
                    DSStepper(value: $quantity)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Step 5, range 0...100").ds(.overline, color: DSColors.textSecondary)
                    DSStepper(value: $bulk, in: 0...100, step: 5)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("At upper bound — tap + to feel the refusal").ds(.overline, color: DSColors.textSecondary)
                    DSStepper(value: $atUpperBound, in: 0...99)
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
