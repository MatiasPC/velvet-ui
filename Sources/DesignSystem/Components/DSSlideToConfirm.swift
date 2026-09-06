import SwiftUI

// MARK: - Design System Slide To Confirm
// "Slide to unlock" turned into a confirmation gate for destructive or
// irreversible actions where a tap is too easy to trigger by accident —
// delete account, cancel a ride, power off. The knob tracks the finger, a
// gradient trail reveals behind it, and the label dissolves letter by letter
// as the knob approaches. Crossing 75% of the available travel locks the
// action in; letting go before that snaps the knob back to the start.
//
// Technique inspired by: open-swiftui-animations/SlideToCancelAnimations

// MARK: - Metrics

private enum Metrics {
    /// Track height. No token for "56pt" exists, so it's expressed as
    /// DSSpacing.huge (48) + DSSpacing.xs (8) — a comfortable one-hand target.
    static let trackHeight: CGFloat = DSSpacing.huge + DSSpacing.xs
    /// Gap kept between the knob and the track edge, on every side.
    static let knobInset: CGFloat = DSSpacing.xxs
    /// Knob diameter: the track height minus its inset on both top and bottom.
    static let knobDiameter: CGFloat = trackHeight - (knobInset * 2)
    /// Breathing room so the label never sits flush against the track edge.
    static let labelHorizontalPadding: CGFloat = DSSpacing.lg
    /// Vertical lift applied to a letter as it fades — a subtle "flying away" cue.
    static let letterLiftDistance: CGFloat = DSSpacing.xxs
    /// Fraction of available travel that counts as "confirmed".
    static let confirmThreshold: Double = 0.75
    /// How much faster a letter dissolves than the raw drag progress once past
    /// its own threshold, so the label finishes fading before the drag does.
    /// Tuned by eye — there is no spacing/color token for animation shaping.
    static let letterFadeSharpness: Double = 3
}

// MARK: - DSSlideToConfirm

/// A slide-to-confirm action control for irreversible actions — the user
/// drags a knob across a pill-shaped track instead of tapping a button.
///
///     DSSlideToConfirm("Slide to delete account") {
///         deleteAccount()
///     }
public struct DSSlideToConfirm: View {

    // MARK: Configuration

    private let label: String
    private let icon: String
    private let confirmedLabel: String
    private let accent: Color?
    private let onConfirm: () -> Void

    // MARK: State

    /// Knob's current travel distance from the leading inset, in `0...maxOffset`.
    @State private var dragOffset: CGFloat = 0
    /// Measured width of the track, used to derive `maxOffset`.
    @State private var trackWidth: CGFloat = 0
    /// Whether the rigid "crossed the threshold" haptic already fired for the
    /// current drag. Resets the moment progress falls back below threshold.
    @State private var hasFiredThresholdHaptic = false
    /// Once true, the control is inert until the parent recreates it.
    @State private var isConfirmed = false

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - label: Instruction shown in the track before any drag, e.g. "Slide to delete".
    ///   - icon: SF Symbol shown inside the knob while idle. Defaults to a forward chevron.
    ///   - confirmedLabel: Replaces `label` once the action has been confirmed.
    ///   - accent: Knob fill color. Defaults to `theme.accent`.
    ///   - onConfirm: Called once, right after the release-above-threshold animation starts.
    public init(
        _ label: String,
        icon: String = "chevron.right",
        confirmedLabel: String = "Confirmed",
        accent: Color? = nil,
        onConfirm: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.confirmedLabel = confirmedLabel
        self.accent = accent
        self.onConfirm = onConfirm
    }

    // MARK: Body

    public var body: some View {
        let resolvedAccent = accent ?? theme.accent

        ZStack(alignment: .leading) {
            theme.gradient.horizontalGradient
                .mask(alignment: .leading) {
                    // Ends at the knob's centre: the opaque knob caps the trail,
                    // so its leading edge reads as the knob's own circle rather
                    // than a shape trying (and failing) to match it.
                    Rectangle().frame(width: trailWidth)
                }

            labelArea
                .padding(.horizontal, Metrics.labelHorizontalPadding)
                .frame(maxWidth: .infinity)

            knob(fill: resolvedAccent)
                .offset(x: Metrics.knobInset + dragOffset)
        }
        .frame(height: Metrics.trackHeight)
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { trackWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newValue in
                        trackWidth = newValue
                    }
            }
        }
        .dsSurface(.glassThin, radius: DSRadius.chip)
        .contentShape(Rectangle())
        .gesture(dragGesture, including: isConfirmed ? .none : .all)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityHint("Swipe right to confirm")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            confirm()
        }
    }

    // MARK: Label

    @ViewBuilder
    private var labelArea: some View {
        if isConfirmed {
            Text(confirmedLabel)
                .ds(.button, color: theme.palette.textSecondary)
                .transition(.opacity)
        } else if reduceMotion {
            // Reduce Motion: the drag itself still moves the knob and trail —
            // that's the interaction, not decoration — but the per-letter
            // stagger collapses into a single fade of the whole label.
            Text(label)
                .ds(.button, color: theme.palette.textSecondary)
                .opacity(1 - progress)
        } else {
            HStack(spacing: 0) {
                ForEach(Array(label.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .ds(.button, color: theme.palette.textSecondary)
                        .opacity(letterOpacity(at: index))
                        .offset(y: letterLift(at: index))
                        .animation(DSAnimation.stagger(index: index), value: progress)
                }
            }
        }
    }

    // MARK: Knob

    @ViewBuilder
    private func knob(fill: Color) -> some View {
        Circle()
            .fill(fill)
            .frame(width: Metrics.knobDiameter, height: Metrics.knobDiameter)
            .overlay {
                Image(systemName: isConfirmed ? "checkmark" : icon)
                    .dsTextStyle(.title3, color: theme.onAccent)
            }
            .dsShadow(.sm)
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isConfirmed else { return }
                let clamped = min(max(0, value.translation.width), maxOffset)
                withAnimation(DSAnimation.interactive) {
                    dragOffset = clamped
                }
                if progress >= Metrics.confirmThreshold {
                    if !hasFiredThresholdHaptic {
                        hasFiredThresholdHaptic = true
                        DSHapticEngine.shared.fire(.rigid)
                    }
                } else {
                    hasFiredThresholdHaptic = false
                }
            }
            .onEnded { _ in
                guard !isConfirmed else { return }
                if progress >= Metrics.confirmThreshold {
                    confirm()
                } else {
                    // Only a real drag earns the snap-back feedback: a plain tap on
                    // the track ends here at offset 0 and must stay silent.
                    if dragOffset > 0 {
                        withAnimation(DSAnimation.springBouncy) {
                            dragOffset = 0
                        }
                        DSHapticEngine.shared.fire(.light)
                    }
                    hasFiredThresholdHaptic = false
                }
            }
    }

    private func confirm() {
        guard !isConfirmed else { return }
        DSHapticEngine.shared.fire(.success)
        withAnimation(DSAnimation.springSmooth) {
            dragOffset = maxOffset
            isConfirmed = true
        }
        onConfirm()
    }

    // MARK: Derived Geometry

    /// Maximum horizontal distance the knob can travel from its leading inset.
    private var maxOffset: CGFloat {
        max(trackWidth - Metrics.knobDiameter - Metrics.knobInset * 2, 0)
    }

    /// Drag progress in `0...1`.
    private var progress: Double {
        maxOffset > 0 ? Double(dragOffset / maxOffset) : 0
    }

    /// Width of the revealed gradient trail. While dragging it stops at the knob's
    /// centre — the opaque knob covers the straight edge and caps the trail with
    /// its own circle. Once confirmed it fills the whole track (the knob rests one
    /// `knobInset` from the end, so stopping at the knob would leave a glass sliver).
    private var trailWidth: CGFloat {
        guard trackWidth > 0 else { return 0 }
        if isConfirmed { return trackWidth }
        return min(trackWidth, Metrics.knobInset + dragOffset + Metrics.knobDiameter / 2)
    }

    /// Opacity for the letter at `index`: letters closer to the knob's start
    /// (lower index) cross their fade threshold first as progress increases.
    private func letterOpacity(at index: Int) -> Double {
        let total = Double(max(label.count, 1))
        let threshold = Double(index) / total
        let fade = (progress - threshold) * Metrics.letterFadeSharpness
        return 1 - min(max(fade, 0), 1)
    }

    /// Small upward lift that grows as a letter fades out.
    private func letterLift(at index: Int) -> CGFloat {
        CGFloat(1 - letterOpacity(at: index)) * -Metrics.letterLiftDistance
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSlideToConfirmPreviewHost: View {
    @State private var theme = DSTheme()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Default").ds(.title3)
                    DSSlideToConfirm("Slide to delete account") {}
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Custom icon, label & accent").ds(.title3)
                    DSSlideToConfirm(
                        "Slide to cancel ride",
                        icon: "xmark",
                        confirmedLabel: "Cancelled",
                        accent: DSColors.error
                    ) {}
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Slide to Confirm — Light") {
    DSSlideToConfirmPreviewHost().preferredColorScheme(.light)
}

#Preview("Slide to Confirm — Dark") {
    DSSlideToConfirmPreviewHost().preferredColorScheme(.dark)
}
#endif
