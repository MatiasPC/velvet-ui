import SwiftUI
import VelvetUI

struct ConfettiScreen: View {
    @State private var celebrate = 0
    @State private var paid = 0
    @State private var topBurst = 0
    @State private var cornerLeft = 0
    @State private var cornerRight = 0

    var body: some View {
        GalleryScreen(title: "Confetti", caption: "A themed burst from any point") {
            LabeledExample("Celebrate button") {
                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        Image(systemName: "party.popper.fill").dsFont(.displayMedium)
                        Text("Goal reached").ds(.title3)
                        DSButton("Celebrate", icon: "sparkles") { celebrate += 1 }
                    }
                    .frame(maxWidth: .infinity)
                }
                .dsConfetti(trigger: celebrate, origin: UnitPoint(x: 0.5, y: 0.45))
            }

            LabeledExample("From a successful slide") {
                DSCard {
                    DSSlideToConfirm("Slide to pay $42.00", confirmedLabel: "Paid") {
                        try await Task.sleep(for: .milliseconds(600))
                        paid += 1
                    }
                }
                .dsConfetti(trigger: paid, origin: UnitPoint(x: 0.5, y: 0.5), haptic: nil)
            }

            LabeledExample("Origins — top, and both bottom corners") {
                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        DSButton("From the top", variant: .secondary) { topBurst += 1 }
                        DSButton("Both corners", variant: .secondary) {
                            cornerLeft += 1
                            cornerRight += 1
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DSSpacing.lg)
                }
                .dsConfetti(trigger: topBurst, origin: .top, count: 60)
                .dsConfetti(trigger: cornerLeft, origin: .bottomLeading, count: 50)
                .dsConfetti(trigger: cornerRight, origin: .bottomTrailing, count: 50, haptic: .success)
            }

            Text("Attach it to a container that covers the area the paper should fall through. Under Reduce Motion no pieces are drawn.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Chrome-free recording stage: a success card that bursts every ~2.5 s.
struct ConfettiStage: View {
    let autoplay: Bool
    @State private var burst = 0

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.md) {
                Image(systemName: "checkmark.seal.fill").dsFont(.displayLarge)
                Text("Payment received").ds(.title2)
                Text("Your receipt is on its way").ds(.callout, color: DSColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsConfetti(trigger: burst, origin: UnitPoint(x: 0.5, y: 0.5), count: 100)
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(0.6)
                burst += 1
                await stagePause(1.9)
            }
        }
    }
}
