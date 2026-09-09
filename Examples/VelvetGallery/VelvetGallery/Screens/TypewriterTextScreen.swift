import SwiftUI
import DesignSystem

struct TypewriterTextScreen: View {
    var body: some View {
        GalleryScreen(title: "Typewriter Text", caption: "Type, hold, erase, next") {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    LabeledExample("Looping phrases") {
                        DSTypewriterText(
                            ["Design at the speed of thought.", "Glass over gradient.", "No borders. Ever."],
                            style: .title3
                        )
                    }
                    LabeledExample("Types once, then stops") {
                        DSTypewriterText(["Types once, then stops."], style: .body, loops: false)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
