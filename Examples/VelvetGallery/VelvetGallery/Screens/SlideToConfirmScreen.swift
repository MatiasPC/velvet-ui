import SwiftUI
import DesignSystem

/// Stand-in for a declined charge.
private struct ChargeRefused: Error {}

struct SlideToConfirmScreen: View {
    @State private var payAttempt = 0
    @State private var refuseNextCharge = false

    var body: some View {
        GalleryScreen(title: "Slide to Confirm", caption: "Drag past 75% to commit") {
            LabeledExample("Destructive gate") {
                DSCard {
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

            LabeledExample("Async charge — morphAndVanish, retries on refusal") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        DSToggle(
                            "Next charge fails",
                            isOn: $refuseNextCharge,
                            onColor: DSColors.textSecondary
                        )

                        DSSlideToConfirm(
                            "Slide to pay $42.00",
                            confirmedLabel: "Paid",
                            finish: .morphAndVanish
                        ) {
                            try await Task.sleep(for: .milliseconds(1200))
                            if refuseNextCharge { throw ChargeRefused() }
                        }
                        .id(payAttempt)

                        DSButton("Reset", variant: .ghost, size: .small) {
                            payAttempt += 1
                        }
                    }
                }
            }

            Text("On a device the drag has a soft detent texture, a rigid tick at the threshold, and success / error feedback on the outcome.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}
