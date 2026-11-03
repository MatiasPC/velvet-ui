import SwiftUI
import VelvetUI

struct LikeButtonScreen: View {
    @State private var liked = false
    @State private var likes = 128
    @State private var starred = false
    @State private var saved = true
    @State private var thumbed = false
    @State private var small = false
    @State private var medium = false
    @State private var large = false
    @State private var rowLiked = false
    @State private var rowLikes = 42
    @State private var fromCode = false
    @State private var tinted = false
    @State private var disabled = true

    var body: some View {
        GalleryScreen(title: "Like Button", caption: "A pop and a halo on the way in, a haptic on the beat") {
            LabeledExample("Heart with a count") {
                DSCard {
                    HStack {
                        DSLikeButton(isLiked: $liked, count: likes, size: DSSpacing.xxl, accessibilityLabel: "Like post")
                            .onChange(of: liked) { _, isOn in likes += isOn ? 1 : -1 }
                        Spacer()
                        Text("Tap to like, tap again to take it back. The undo is quiet.")
                            .ds(.footnote, color: DSColors.textSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            LabeledExample("Any filled and outline symbol pair") {
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSLikeButton(isLiked: $starred, symbol: "star.fill", emptySymbol: "star",
                                     tint: DSColors.warning, accessibilityLabel: "Favorite")
                        DSLikeButton(isLiked: $saved, symbol: "bookmark.fill", emptySymbol: "bookmark",
                                     accessibilityLabel: "Save")
                        DSLikeButton(isLiked: $thumbed, symbol: "hand.thumbsup.fill", emptySymbol: "hand.thumbsup",
                                     tint: DSColors.info, accessibilityLabel: "Helpful")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LabeledExample("Sizes (the tap target stays 44 pt)") {
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSLikeButton(isLiked: $small, size: 20)
                        DSLikeButton(isLiked: $medium)
                        DSLikeButton(isLiked: $large, size: 40)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LabeledExample("In a list row") {
                DSCard(padding: 0) {
                    DSListCell(title: "Weekend in Lisbon", subtitle: "\(rowLikes) people like this") {
                        Image(systemName: "mappin.circle")
                    } trailing: {
                        DSLikeButton(isLiked: $rowLiked, accessibilityLabel: "Like Weekend in Lisbon")
                            .onChange(of: rowLiked) { _, isOn in rowLikes += isOn ? 1 : -1 }
                    }
                }
            }

            LabeledExample("Custom tint and haptic") {
                DSCard {
                    HStack {
                        DSLikeButton(isLiked: $tinted, tint: DSColors.success, haptic: .rigid,
                                     accessibilityLabel: "Approve")
                        Text("Success tint, rigid tap").ds(.callout, color: DSColors.textSecondary)
                        Spacer()
                    }
                }
            }

            LabeledExample("Set from code swaps quietly") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        HStack {
                            DSLikeButton(isLiked: $fromCode, accessibilityLabel: "Like")
                            Spacer()
                            Text(fromCode ? "Liked" : "Not liked").ds(.callout, color: DSColors.textSecondary)
                        }
                        DSButton(fromCode ? "Reset from code" : "Like from code", variant: .secondary) {
                            fromCode.toggle()
                        }
                        Text("The beat belongs to the tap: a saved state restored on load never pops or buzzes.")
                            .ds(.footnote, color: DSColors.textSecondary)
                    }
                }
            }

            LabeledExample("Disabled") {
                DSCard {
                    HStack {
                        DSLikeButton(isLiked: $disabled, count: 7).disabled(true)
                        Spacer()
                    }
                }
            }
        }
    }
}

/// Recording stage. Manual: the beat belongs to the tap, so tap the three buttons.
struct LikeButtonStage: View {
    @State private var liked = false
    @State private var likes = 128
    @State private var starred = false
    @State private var saved = false

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text("Weekend in Lisbon").ds(.title3)
                    Text("3 nights, 2 guests").ds(.callout, color: DSColors.textSecondary)
                }
                HStack(spacing: DSSpacing.lg) {
                    DSLikeButton(isLiked: $liked, count: likes, size: DSSpacing.xxl, accessibilityLabel: "Like")
                        .onChange(of: liked) { _, isOn in likes += isOn ? 1 : -1 }
                    DSLikeButton(isLiked: $starred, size: DSSpacing.xxl, symbol: "star.fill", emptySymbol: "star",
                                 tint: DSColors.warning, accessibilityLabel: "Favorite")
                    DSLikeButton(isLiked: $saved, size: DSSpacing.xxl, symbol: "bookmark.fill", emptySymbol: "bookmark",
                                 accessibilityLabel: "Save")
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
