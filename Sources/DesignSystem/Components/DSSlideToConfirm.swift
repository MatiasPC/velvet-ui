import SwiftUI

// MARK: - Design System Slide To Confirm
// A draggable "slide to confirm" action that guards an important, one-shot
// operation behind a deliberate gesture — think Apple's slide-to-unlock,
// payment confirmations, or destructive actions you don't want fired by a
// stray tap. The knob tracks the finger 1:1, an accent track fills in behind
// it, a threshold tick tells you when you can let go, and completing the slide
// morphs the chevron into a checkmark with a success haptic.
//
// Fully token-driven, spring-animated, and haptic — a premium alternative to a
// plain confirmation button, reusable across any app.
//
// Inspiration: Apple's classic slide-to-unlock and the "slide to pay" pattern
// popularised across fintech apps; SwiftUI DragGesture + matched fill treatment.

public struct DSSlideToConfirm: View {

    // MARK: - Configuration

    private let title: String
    private let confirmedTitle: String
    private let icon: String
    private let confirmedIcon: String
    private let accent: Color
    private let height: CGFloat
    private let onConfirm: (() -> Void)?

    // MARK: - State

    /// Optional external source of truth so the parent can observe / reset the
    /// control. When absent, the control manages its own internal state.
    private let externalConfirmed: Binding<Bool>?
    @State private var internalConfirmed = false

    @State private var dragOffset: CGFloat = 0
    @State private var passedThreshold = false

    @Environment(\.isEnabled) private var isEnabled

    /// Fraction of travel that must be reached before a release confirms.
    private let threshold: CGFloat = 0.9
    /// Gap between the knob and the track edge.
    private let inset: CGFloat = DSSpacing.xxs

    // MARK: - Init

    /// Slide-to-confirm bound to external state you can observe and reset.
    /// - Parameters:
    ///   - title: Prompt shown before confirmation (e.g. "Slide to Pay").
    ///   - confirmedTitle: Label shown once confirmed.
    ///   - icon: SF Symbol on the knob before confirmation.
    ///   - confirmedIcon: SF Symbol the knob morphs into on confirm.
    ///   - accent: Track fill / knob glyph tint.
    ///   - height: Control height (knob diameter derives from it).
    ///   - isConfirmed: Binding driving the confirmed state — set it back to
    ///     `false` to reset the control.
    ///   - onConfirm: Called once when the slide completes.
    public init(
        _ title: String,
        confirmedTitle: String = "Confirmed",
        icon: String = "chevron.right",
        confirmedIcon: String = "checkmark",
        accent: Color = DSColors.defaultPalette.primary,
        height: CGFloat = 56,
        isConfirmed: Binding<Bool>,
        onConfirm: (() -> Void)? = nil
    ) {
        self.title = title
        self.confirmedTitle = confirmedTitle
        self.icon = icon
        self.confirmedIcon = confirmedIcon
        self.accent = accent
        self.height = height
        self.externalConfirmed = isConfirmed
        self.onConfirm = onConfirm
    }

    /// Fire-once slide-to-confirm that manages its own state.
    public init(
        _ title: String,
        confirmedTitle: String = "Confirmed",
        icon: String = "chevron.right",
        confirmedIcon: String = "checkmark",
        accent: Color = DSColors.defaultPalette.primary,
        height: CGFloat = 56,
        onConfirm: @escaping () -> Void
    ) {
        self.title = title
        self.confirmedTitle = confirmedTitle
        self.icon = icon
        self.confirmedIcon = confirmedIcon
        self.accent = accent
        self.height = height
        self.externalConfirmed = nil
        self.onConfirm = onConfirm
    }

    // MARK: - Derived State

    private var isConfirmed: Binding<Bool> {
        externalConfirmed ?? $internalConfirmed
    }

    private var isConfirmedValue: Bool { isConfirmed.wrappedValue }

    private var knobSize: CGFloat { height - inset * 2 }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let maxTravel = max(geo.size.width - height, 0)
            let offset = isConfirmedValue ? maxTravel : dragOffset
            let progress = maxTravel > 0 ? offset / maxTravel : 0

            ZStack(alignment: .leading) {
                // Track
                Capsule(style: .continuous)
                    .fill(accent.opacity(0.12))

                // Accent fill that grows behind the knob
                Capsule(style: .continuous)
                    .fill(accent)
                    .frame(width: offset + height)

                // Prompt / confirmation label
                Text(isConfirmedValue ? confirmedTitle : title)
                    .dsTextStyle(.button, color: labelColor)
                    .frame(maxWidth: .infinity)
                    .opacity(isConfirmedValue ? 1 : 1 - progress)

                // Knob
                knob
                    .offset(x: offset + inset)
                    .gesture(dragGesture(maxTravel: maxTravel))
            }
            .frame(width: geo.size.width, height: height)
            .clipShape(Capsule(style: .continuous))
            .animation(DSAnimation.springSmooth, value: isConfirmedValue)
        }
        .frame(height: height)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(isConfirmedValue ? confirmedTitle : title))
        .accessibilityHint(Text("Swipe right to confirm"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            if isEnabled, !isConfirmedValue { confirm() }
        }
    }

    // MARK: - Knob

    private var knob: some View {
        Circle()
            .fill(DSColors.defaultPalette.backgroundElevated)
            .frame(width: knobSize, height: knobSize)
            .overlay(
                Image(systemName: isConfirmedValue ? confirmedIcon : icon)
                    .font(.system(size: knobSize * 0.4, weight: .semibold))
                    .foregroundStyle(accent)
                    .contentTransition(.symbolEffect(.replace))
            )
            .dsShadow(.sm)
    }

    // MARK: - Gesture

    private func dragGesture(maxTravel: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isEnabled, !isConfirmedValue else { return }
                let clamped = min(max(value.translation.width, 0), maxTravel)
                dragOffset = clamped

                let progress = maxTravel > 0 ? clamped / maxTravel : 0
                if progress >= threshold, !passedThreshold {
                    passedThreshold = true
                    DSHapticEngine.shared.fire(.rigid)
                } else if progress < threshold, passedThreshold {
                    passedThreshold = false
                }
            }
            .onEnded { _ in
                guard isEnabled, !isConfirmedValue else { return }
                if passedThreshold {
                    confirm()
                } else {
                    withAnimation(DSAnimation.springSmooth) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Actions

    private func confirm() {
        guard !isConfirmedValue else { return }
        DSHapticEngine.shared.fire(.success)
        passedThreshold = false
        // Reset the underlying drag offset so an external reset springs from 0.
        dragOffset = 0
        isConfirmed.wrappedValue = true
        onConfirm?()
    }

    // MARK: - Colors

    private var labelColor: Color {
        isConfirmedValue
            ? DSColors.defaultPalette.textOnPrimary
            : DSColors.defaultPalette.textSecondary
    }
}

// MARK: - Preview

#Preview("Light") {
    SlideToConfirmPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    SlideToConfirmPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct SlideToConfirmPreview: View {
    @State private var paid = false
    @State private var deleted = false

    var body: some View {
        VStack(spacing: DSSpacing.xxl) {
            DSSlideToConfirm(
                "Slide to Pay",
                confirmedTitle: "Payment Sent",
                icon: "creditcard",
                isConfirmed: $paid
            )

            DSSlideToConfirm(
                "Slide to Delete",
                confirmedTitle: "Deleted",
                icon: "trash",
                confirmedIcon: "checkmark",
                accent: DSColors.defaultPalette.error,
                isConfirmed: $deleted
            )

            DSSlideToConfirm(
                "Slide to Unlock",
                confirmedTitle: "Unlocked",
                icon: "lock.open",
                accent: DSColors.defaultPalette.secondary
            ) { }

            DSButton("Reset", variant: .ghost) {
                withAnimation(DSAnimation.springSmooth) {
                    paid = false
                    deleted = false
                }
            }
        }
    }
}
