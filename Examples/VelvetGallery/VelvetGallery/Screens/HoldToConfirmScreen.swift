import SwiftUI
import VelvetUI

/// Stand-in for a declined action.
private struct ActionRefused: Error {}

struct HoldToConfirmScreen: View {
    @State private var confirmAttempt = 0
    @State private var deleteAttempt = 0
    @State private var quickAttempt = 0
    @State private var slowAttempt = 0
    @State private var asyncAttempt = 0
    @State private var refuseNext = false
    @State private var isEnabled = false

    var body: some View {
        GalleryScreen(title: "Hold to Confirm", caption: "Keep pressing until the ring closes") {
            LabeledExample("Default — theme accent, 1.2s") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSHoldToConfirm("Hold to confirm", icon: "hand.tap") {}
                            .id(confirmAttempt)
                        DSButton("Reset", variant: .ghost, size: .small) { confirmAttempt += 1 }
                    }
                }
            }

            LabeledExample("Destructive — status accent") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSHoldToConfirm(
                            "Hold to delete",
                            icon: "trash",
                            confirmedLabel: "Deleted",
                            accent: DSColors.error
                        ) {}
                        .id(deleteAttempt)
                        DSButton("Reset", variant: .ghost, size: .small) { deleteAttempt += 1 }
                    }
                }
            }

            LabeledExample("Duration — 0.6s compact, 2.5s deliberate") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        HStack {
                            DSHoldToConfirm(
                                "Hold to send",
                                icon: "paperplane.fill",
                                confirmedLabel: "Sent",
                                duration: 0.6,
                                isFullWidth: false
                            ) {}
                            .id(quickAttempt)
                            Spacer()
                        }
                        DSHoldToConfirm("Hold to power off", icon: "power", confirmedLabel: "Off", duration: 2.5) {}
                            .id(slowAttempt)
                        DSButton("Reset both", variant: .ghost, size: .small) {
                            quickAttempt += 1
                            slowAttempt += 1
                        }
                    }
                }
            }

            LabeledExample("Async action — spins, then succeeds or re-opens") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSToggle("Next charge fails", isOn: $refuseNext, onColor: DSColors.textSecondary)
                        DSHoldToConfirm("Hold to pay $42.00", icon: "creditcard", confirmedLabel: "Paid") {
                            try await Task.sleep(for: .milliseconds(1200))
                            if refuseNext { throw ActionRefused() }
                        }
                        .id(asyncAttempt)
                        DSButton("Reset", variant: .ghost, size: .small) { asyncAttempt += 1 }
                    }
                }
            }

            LabeledExample("Disabled") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSHoldToConfirm("Hold to confirm", icon: "hand.tap") {}
                            .disabled(!isEnabled)
                        DSToggle("Enabled", isOn: $isEnabled, onColor: DSColors.textSecondary)
                    }
                }
            }

            Text("Let go early and the ring springs back without running anything. On a device a soft detent ticks as it charges, a success tap lands when it fills, and a refusal gives an error tap. With VoiceOver on, a double-tap confirms with no hold.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

struct HoldToConfirmStage: View {
    @State private var attempt = 0

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text("Delete account").ds(.title2)
                    Text("This can't be undone.").ds(.callout, color: DSColors.textSecondary)
                }
                DSHoldToConfirm(
                    "Hold to delete",
                    icon: "trash",
                    confirmedLabel: "Deleted",
                    accent: DSColors.error
                ) {
                    // Re-arm for the next take once the settled state has been seen.
                    Task {
                        try? await Task.sleep(for: .seconds(2.5))
                        attempt += 1
                    }
                }
                .id(attempt)
            }
        }
    }
}
