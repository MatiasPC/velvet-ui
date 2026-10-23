import SwiftUI
import VelvetUI

/// A real content card that goes through `.dsSkeleton` — same view for both states.
private struct ProfileCard: View {
    let isLoading: Bool

    @DSThemed private var theme

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                HStack(spacing: DSSpacing.sm) {
                    DSAvatar(name: "Ada Lovelace", size: DSSpacing.huge)
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text("Ada Lovelace").ds(.title3)
                        Text("Posted 2 hours ago").ds(.callout, color: DSColors.textSecondary)
                    }
                }
                Text("The Analytical Engine weaves algebraic patterns just as the loom weaves flowers and leaves.")
                    .ds(.body)
                RoundedRectangle(cornerRadius: DSRadius.surface, style: .continuous)
                    .fill(isLoading ? AnyShapeStyle(theme.subtleFill) : AnyShapeStyle(theme.gradient.linearGradient))
                    .frame(height: 140)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsSkeleton(isLoading)
        }
    }
}

struct SkeletonScreen: View {
    @State private var isLoading = false

    var body: some View {
        GalleryScreen(title: "Skeleton", caption: "Placeholders that match the layout") {
            LabeledExample("Hand-built feed card") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        HStack(spacing: DSSpacing.sm) {
                            DSSkeleton.circle(DSSpacing.huge)
                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                DSSkeleton(width: 140)
                                DSSkeleton(width: 90)
                            }
                        }
                        DSSkeleton(height: 140, cornerRadius: DSRadius.surface)
                    }
                }
            }

            LabeledExample("Real content, .dsSkeleton(isLoading)") {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    ProfileCard(isLoading: isLoading)
                    DSButton("Reload", variant: .secondary, icon: "arrow.clockwise") {
                        guard !isLoading else { return }
                        isLoading = true
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            isLoading = false
                        }
                    }
                }
            }

            LabeledExample("List rows") {
                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack(spacing: DSSpacing.sm) {
                                DSSkeleton.circle(DSSpacing.xxl)
                                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                    DSSkeleton(height: DSSpacing.sm)
                                    DSSkeleton(width: 100)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SkeletonStage: View {
    let autoplay: Bool
    @State private var isLoading = true

    var body: some View {
        ProfileCard(isLoading: isLoading)
            .task(id: autoplay) {
                guard autoplay else { return }
                await stageLoop {
                    isLoading = true
                    await stagePause(2.0)
                    isLoading = false
                    await stagePause(2.4)
                }
            }
    }
}
