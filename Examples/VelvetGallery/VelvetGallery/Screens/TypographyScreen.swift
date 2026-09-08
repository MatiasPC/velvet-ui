import SwiftUI
import DesignSystem

struct TypographyScreen: View {
    var body: some View {
        GalleryScreen(title: "Typography", caption: "Every text style") {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Hero").ds(.hero)
                    Text("Large Title").ds(.largeTitle)
                    Text("Title 1").ds(.title1)
                    Text("Title 2").ds(.title2)
                    Text("Title 3").ds(.title3)
                    Text("Body — the quick brown fox jumps over the lazy dog").ds(.body)
                    Text("Callout").ds(.callout)
                    Text("Footnote").ds(.footnote)
                    Text("Caption 1").ds(.caption1)
                    Text("Caption 2").ds(.caption2)
                    Text("BUTTON").ds(.button)
                    Text("OVERLINE").ds(.overline)
                    Text("$1,248.00").ds(.numeric)
                    Text("42").ds(.displayLarge)
                    Text("128").ds(.displayMedium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
