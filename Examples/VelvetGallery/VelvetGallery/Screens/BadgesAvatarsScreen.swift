import SwiftUI
import DesignSystem

struct BadgesAvatarsScreen: View {
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
        }
    }
}
