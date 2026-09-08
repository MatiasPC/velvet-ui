import SwiftUI
import DesignSystem

struct EmptyStateScreen: View {
    @State private var hasResults = false

    var body: some View {
        GalleryScreen(title: "Empty State", caption: "Nothing here yet") {
            LabeledExample("Search results") {
                if hasResults {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("3 results").ds(.title3)
                            Text("Showing sample data.").ds(.callout, color: DSColors.textSecondary)
                            DSButton("Clear", variant: .ghost) { hasResults = false }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    DSCard {
                        DSEmptyState(
                            icon: "magnifyingglass",
                            title: "No results",
                            message: "Try adjusting your search or filters to find what you're looking for.",
                            actionTitle: "Show sample"
                        ) { hasResults = true }
                    }
                }
            }
        }
    }
}
