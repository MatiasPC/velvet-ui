import SwiftUI
import VelvetUI

struct SuccessCheckScreen: View {
    @State private var paid = false
    @State private var replay = 0

    var body: some View {
        GalleryScreen(title: "Success Check", caption: "Ring, disc and check, with a pop on the beat") {
            LabeledExample("Payment success") {
                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        DSSuccessCheck(isComplete: paid, size: 96, accessibilityLabel: "Payment sent")
                            .padding(DSSpacing.md)
                        Text(paid ? "Payment sent" : "Ready to pay").ds(.title3)
                        DSButton(paid ? "Replay" : "Pay $24.00", isFullWidth: true) {
                            if paid {
                                paid = false
                                Task {
                                    try? await Task.sleep(for: .seconds(0.5))
                                    paid = true
                                }
                            } else {
                                paid = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            LabeledExample("Sizes") {
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSSuccessCheck(isComplete: paid, size: 24, haptic: nil)
                        DSSuccessCheck(isComplete: paid, size: 40, haptic: nil)
                        DSSuccessCheck(isComplete: paid, size: 64, haptic: nil)
                        DSSuccessCheck(isComplete: paid, size: 88, haptic: nil)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            LabeledExample("Custom color") {
                DSCard {
                    HStack {
                        DSSuccessCheck(isComplete: paid, size: 48, color: DSColors.info, haptic: nil)
                        Text("Synced").ds(.body)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct SuccessCheckStage: View {
    let autoplay: Bool
    @State private var done = false

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.lg) {
                DSSuccessCheck(isComplete: done, size: 112, accessibilityLabel: "Payment sent")
                    .padding(DSSpacing.lg)
                Text("Payment sent").ds(.title2)
                    .opacity(done ? 1 : 0.35)
                    .animation(DSAnimation.normal, value: done)
            }
            .frame(maxWidth: .infinity)
        }
        .task(id: autoplay) {
            if !autoplay { done = true; return }
            await stageLoop {
                done = false
                await stagePause(0.6)
                if Task.isCancelled { return }
                done = true
                await stagePause(2.5)
            }
        }
    }
}
