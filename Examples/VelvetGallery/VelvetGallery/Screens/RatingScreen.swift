import SwiftUI
import DesignSystem

struct RatingScreen: View {
    @State private var rating: Double = 3
    @State private var half: Double = 3.5

    var body: some View {
        GalleryScreen(title: "Rating", caption: "Star input") {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    LabeledExample("Interactive") {
                        DSRating(rating: $rating, tint: DSColors.textPrimary)
                    }
                    LabeledExample("Half steps") {
                        DSRating(rating: $half, step: 0.5, tint: DSColors.textPrimary)
                    }
                    LabeledExample("Read-only") {
                        DSRating(value: 4.2, size: 20, tint: DSColors.textPrimary)
                    }
                    LabeledExample("Custom symbol & tint — re-symbol and re-colour it") {
                        DSRating(
                            value: 4,
                            symbol: "heart.fill",
                            emptySymbol: "heart",
                            size: 20,
                            tint: DSColors.error
                        )
                    }
                }
            }
        }
    }
}
