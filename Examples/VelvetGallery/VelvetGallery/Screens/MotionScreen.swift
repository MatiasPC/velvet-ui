import SwiftUI
import DesignSystem

/// The five `DSMotion` ambient primitives. Neutral fills — the gallery draws no
/// gradient — so the motion itself is the subject, not the colour.
struct MotionScreen: View {
    @State private var jiggleTick = 0
    @State private var popInTick = 0
    @State private var sweeping = true
    @State private var drifting = true

    var body: some View {
        GalleryScreen(title: "Motion", caption: "Ambient primitives") {
            LabeledExample("dsBreathe — ambient swell, three intensities") {
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        breatheDot("subtle", .subtle)
                        breatheDot("medium", .medium)
                        breatheDot("strong", .strong)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            LabeledExample("dsJiggle — one decaying wiggle per trigger") {
                DSCard {
                    HStack(spacing: DSSpacing.lg) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(DSColors.textPrimary)
                            .dsJiggle(trigger: jiggleTick)
                        Spacer()
                        DSButton("Shake", variant: .secondary, size: .small) { jiggleTick += 1 }
                    }
                }
            }

            LabeledExample("dsPopIn — springBouncy entrance, staggered") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        HStack(spacing: DSSpacing.sm) {
                            ForEach(0..<4, id: \.self) { index in
                                RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                                    .fill(DSColors.backgroundSecondary)
                                    .frame(height: DSSpacing.huge)
                                    .dsPopIn(delay: Double(index) * 0.08)
                            }
                        }
                        .id(popInTick)
                        DSButton("Replay", variant: .secondary, size: .small) { popInTick += 1 }
                    }
                }
            }

            LabeledExample("dsEdgeSweep — light travelling the surface edge") {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Processing…").ds(.body)
                        Text("A highlight rides the glass edge while active.")
                            .ds(.caption1, color: DSColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DSSpacing.md)
                    .dsSurface(.glass, radius: DSRadius.card)
                    .dsEdgeSweep(radius: DSRadius.card, isActive: sweeping)

                    DSToggle("Active", isOn: $sweeping, onColor: DSColors.textSecondary)
                }
            }

            LabeledExample("dsHueDrift — slow bounded hue rotation") {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous)
                        .fill(DSColors.textPrimary)
                        .frame(height: DSSpacing.massive)
                        .dsHueDrift(isActive: drifting)
                    DSToggle("Active", isOn: $drifting, onColor: DSColors.textSecondary)
                }
            }
        }
    }

    private func breatheDot(_ name: String, _ intensity: DSBreatheIntensity) -> some View {
        VStack(spacing: DSSpacing.xs) {
            Circle()
                .fill(DSColors.textPrimary)
                .frame(width: DSSpacing.huge, height: DSSpacing.huge)
                .dsBreathe(intensity)
            Text(name).ds(.caption1, color: DSColors.textTertiary)
        }
    }
}
