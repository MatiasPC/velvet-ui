import SwiftUI
import DesignSystem

struct ReviewScreen: View {
    @Binding var theme: DSTheme
    @Binding var scheme: ColorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xxl) {
                controls

                Group {
                    sectionTitle("Primitives")
                    breatheRow
                    jiggleRow
                    popInRow
                    edgeSweepRow
                    hueDriftRow
                }

                Group {
                    sectionTitle("Components")
                    slideToConfirmRow
                    thinkingRow
                    typewriterRow
                    stepperRow
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .dsBackdrop()
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Velvet UI — Motion wave 1").ds(.title2)
            Text("Simulator: watch the animations. Device: feel the haptics on Slide to Confirm and Stepper.")
                .ds(.footnote, color: theme.palette(for: scheme).textSecondary)

            HStack(spacing: DSSpacing.sm) {
                ForEach(DSGradientTheme.all) { candidate in
                    Button {
                        theme.gradient = candidate
                    } label: {
                        RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                            .fill(candidate.linearGradient)
                            .frame(height: DSSpacing.xxl)
                            .overlay {
                                if candidate == theme.gradient {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            DSToggle("Dark mode", isOn: Binding(
                get: { scheme == .dark },
                set: { scheme = $0 ? .dark : .light }
            ))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DSSpacing.md)
        .dsSurface(.glassThin, radius: DSRadius.card)
    }

    // MARK: - Primitives

    @State private var jiggleTick = 0
    @State private var popInTick = 0
    @State private var sweeping = true
    @State private var drifting = true

    private var breatheRow: some View {
        row("dsBreathe — ambient swell, three intensities") {
            HStack(spacing: DSSpacing.xl) {
                breatheDot("subtle", .subtle)
                breatheDot("medium", .medium)
                breatheDot("strong", .strong)
            }
        }
    }

    private func breatheDot(_ name: String, _ intensity: DSBreatheIntensity) -> some View {
        VStack(spacing: DSSpacing.xs) {
            Circle()
                .fill(theme.gradient.linearGradient)
                .frame(width: DSSpacing.huge, height: DSSpacing.huge)
                .dsBreathe(intensity)
            Text(name).ds(.caption1, color: theme.palette(for: scheme).textTertiary)
        }
    }

    private var jiggleRow: some View {
        row("dsJiggle — one decaying wiggle per trigger") {
            HStack(spacing: DSSpacing.lg) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(theme.gradient.linearGradient)
                    .dsJiggle(trigger: jiggleTick)
                Spacer()
                DSButton("Shake", variant: .secondary, size: .small) { jiggleTick += 1 }
            }
        }
    }

    private var popInRow: some View {
        row("dsPopIn — springBouncy entrance, staggered") {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                HStack(spacing: DSSpacing.sm) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                            .fill(theme.gradient.horizontalGradient)
                            .frame(height: DSSpacing.huge)
                            .dsPopIn(delay: Double(index) * 0.08)
                    }
                }
                .id(popInTick)
                DSButton("Replay", variant: .secondary, size: .small) { popInTick += 1 }
            }
        }
    }

    private var edgeSweepRow: some View {
        row("dsEdgeSweep — light travelling the surface edge") {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Processing…").ds(.body)
                    Text("A highlight rides the glass edge while active.")
                        .ds(.caption1, color: theme.palette(for: scheme).textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DSSpacing.md)
                .dsSurface(.glass, radius: DSRadius.card)
                .dsEdgeSweep(radius: DSRadius.card, isActive: sweeping)

                DSToggle("Active", isOn: $sweeping)
            }
        }
    }

    private var hueDriftRow: some View {
        row("dsHueDrift — slow bounded hue rotation") {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous)
                    .fill(theme.gradient.horizontalGradient)
                    .frame(height: DSSpacing.massive)
                    .dsHueDrift(isActive: drifting)
                DSToggle("Active", isOn: $drifting)
            }
        }
    }

    // MARK: - Components

    @State private var quantity = 3
    @State private var bulk = 25
    @State private var atBound = 99

    private var slideToConfirmRow: some View {
        row("DSSlideToConfirm — drag past 75% to confirm") {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSSlideToConfirm("Slide to delete account") {}
                DSSlideToConfirm(
                    "Slide to cancel ride",
                    icon: "xmark",
                    confirmedLabel: "Cancelled",
                    accent: DSColors.error
                ) {}
            }
        }
    }

    private var thinkingRow: some View {
        row("DSThinkingIndicator — animated symbol + cycling phrase") {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSThinkingIndicator()
                DSThinkingIndicator(
                    phrases: ["Reading your notes", "Cross-checking sources", "Drafting a reply"],
                    symbol: "brain",
                    interval: 2.0
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var typewriterRow: some View {
        row("DSTypewriterText — type, hold, erase, next") {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSTypewriterText(
                    ["Design at the speed of thought.", "Glass over gradient.", "No borders. Ever."],
                    style: .title3
                )
                DSTypewriterText(["Types once, then stops."], style: .body, loops: false)
            }
        }
    }

    private var stepperRow: some View {
        row("DSStepper — selection tick per step, refusal at bounds") {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                labeled("Default (0…99)") { DSStepper(value: $quantity) }
                labeled("Step 5, range 0…100") { DSStepper(value: $bulk, in: 0...100, step: 5) }
                labeled("At upper bound — tap +") { DSStepper(value: $atBound, in: 0...99) }
            }
        }
    }

    // MARK: - Layout helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .ds(.overline, color: theme.palette(for: scheme).textSecondary)
    }

    private func row<Content: View>(_ caption: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(caption).ds(.footnote, color: theme.palette(for: scheme).textSecondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labeled<Content: View>(_ text: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(text).ds(.caption1, color: theme.palette(for: scheme).textTertiary)
            content()
        }
    }
}
