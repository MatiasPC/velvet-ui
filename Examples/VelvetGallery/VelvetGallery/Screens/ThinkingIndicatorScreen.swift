import SwiftUI
import DesignSystem

struct ThinkingIndicatorScreen: View {
    var body: some View {
        GalleryScreen(title: "Thinking Indicator", caption: "Ambient processing state") {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    LabeledExample("Default") {
                        DSThinkingIndicator()
                    }
                    LabeledExample("Custom phrases, symbol and interval") {
                        DSThinkingIndicator(
                            phrases: ["Reading your notes", "Cross-checking sources", "Drafting a reply"],
                            symbol: "brain",
                            interval: 2.0
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
