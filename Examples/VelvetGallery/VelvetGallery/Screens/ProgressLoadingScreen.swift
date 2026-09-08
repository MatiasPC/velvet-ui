import SwiftUI
import DesignSystem

struct ProgressLoadingScreen: View {
    @State private var progress: Double = 0.65
    @State private var number: Double = 1248

    var body: some View {
        GalleryScreen(title: "Progress & Loading", caption: "Determinate & skeletons") {
            LabeledExample("Driver") {
                Slider(value: $progress, in: 0...1)
                    .tint(DSColors.textPrimary)
            }

            LabeledExample("Determinate") {
                DSCard {
                    VStack(spacing: DSSpacing.lg) {
                        DSCircularProgress(progress: progress, size: 80)
                        DSLinearProgress(progress: progress)
                        DSGradientProgress(
                            progress: progress,
                            colors: [DSColors.textTertiary, DSColors.textPrimary]
                        )
                        DSStepProgress(
                            currentStep: max(1, Int(progress * 5) + (progress >= 1 ? 0 : 1)),
                            totalSteps: 5
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            LabeledExample("Animated number") {
                HStack {
                    DSAnimatedNumber(value: number, style: .displayMedium)
                    Spacer()
                    DSButton("Randomize", size: .small) {
                        number = Double(Int.random(in: 100...9999))
                    }
                }
            }

            LabeledExample("Skeletons") {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.backgroundSecondary)
                        .frame(height: DSSpacing.lg)
                        .dsShimmer()
                    RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                        .fill(DSColors.backgroundSecondary)
                        .frame(width: 180, height: DSSpacing.md)
                        .dsShimmer()
                }
            }

            LabeledExample("Pulse") {
                DSBadge("Syncing", variant: .soft).dsPulse()
            }
        }
    }
}
