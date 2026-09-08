import SwiftUI
import DesignSystem

struct TypographyScreen: View {
    var body: some View {
        GalleryScreen(title: "Typography", caption: "Every text style") {
            Text("TODO").ds(.body)
        }
    }
}
