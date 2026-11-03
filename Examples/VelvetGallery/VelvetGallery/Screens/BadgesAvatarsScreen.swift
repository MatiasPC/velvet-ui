import SwiftUI
import VelvetUI

private let groupNames = [
    "Ada Lovelace", "Grace Hopper", "Alan Turing", "Katherine Johnson",
    "Linus Torvalds", "Margaret Hamilton", "Dennis Ritchie", "Barbara Liskov"
]

struct BadgesAvatarsScreen: View {
    @State private var people = 6
    @State private var maxVisible = 4
    @State private var compact = false
    @State private var tapped = 0

    var body: some View {
        GalleryScreen(title: "Badges & Avatars", caption: "Status marks & identity") {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    LabeledExample("Variants") {
                        HStack(spacing: DSSpacing.xs) {
                            DSBadge("New", variant: .filled)
                            DSBadge("Active", variant: .soft)
                            DSBadge("Beta", variant: .outline)
                        }
                    }

                    LabeledExample("Semantic colour") {
                        DSBadge("Live", color: DSColors.success, variant: .soft)
                    }

                    LabeledExample("Count") {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            HStack(spacing: DSSpacing.sm) {
                                DSCountBadge(count: 5)
                                DSCountBadge(count: 120)
                            }
                            HStack(spacing: DSSpacing.sm) {
                                DSCountBadge(count: 0)
                                Text("count: 0 renders nothing")
                                    .ds(.footnote, color: DSColors.textTertiary)
                            }
                        }
                    }
                }
            }

            DSCard {
                LabeledExample("Avatars") {
                    HStack(spacing: DSSpacing.sm) {
                        DSAvatar(name: "John Doe", size: 32)
                        DSAvatar(name: "Jane Smith", size: 40)
                        DSAvatar(name: "Bob", size: 48)
                        DSAvatar(name: "Ada Lovelace", imageURL: URL(string: "https://picsum.photos/seed/ada/96"), size: 48)
                    }
                }
            }

            LabeledExample("Avatar group") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSAvatarGroup(
                            names: Array(groupNames.prefix(people)),
                            maxVisible: maxVisible,
                            size: compact ? DSSpacing.xxl : DSSpacing.xxxl,
                            overlap: compact ? 0.45 : 0.32
                        )
                        HStack {
                            Text("People").ds(.body)
                            Spacer()
                            DSStepper(value: $people, in: 0...groupNames.count)
                                .accessibilityLabel("People in the group")
                        }
                        HStack {
                            Text("Max visible").ds(.body)
                            Spacer()
                            DSStepper(value: $maxVisible, in: 2...8)
                                .accessibilityLabel("Most avatars to show")
                        }
                        DSToggle("Compact", isOn: $compact)
                    }
                }
                DSCard {
                    HStack(spacing: DSSpacing.md) {
                        DSAvatarGroup(names: groupNames, maxVisible: 3) { tapped += 1 }
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text("Design Review").ds(.title3)
                            Text(tapped == 0 ? "Tap the group" : "Opened \(tapped) time\(tapped == 1 ? "" : "s")")
                                .ds(.callout, color: DSColors.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
                Text("The gap between avatars is a cut-out, so the group reads on a card, a page or a photo. VoiceOver says \"Ada Lovelace, Grace Hopper and 6 others\".")
                    .ds(.footnote, color: DSColors.textTertiary)
            }
        }
    }
}

struct AvatarGroupStage: View {
    let autoplay: Bool
    @State private var count = 7

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.xl) {
                DSAvatarGroup(names: Array(groupNames.prefix(count)), maxVisible: 4, size: DSSpacing.huge)
                Text(count == 1 ? "1 person going" : "\(count) people going")
                    .ds(.title3)
                    .contentTransition(.numericText())
                    .animation(DSAnimation.normal, value: count)
            }
            .frame(maxWidth: .infinity)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for n in 1...groupNames.count {
                    count = n
                    await stagePause(0.8)
                    if Task.isCancelled { return }
                }
                await stagePause(1.4)
                for n in stride(from: groupNames.count - 1, through: 1, by: -1) {
                    count = n
                    await stagePause(0.5)
                    if Task.isCancelled { return }
                }
                await stagePause(0.8)
            }
        }
    }
}
