import SwiftUI
import DesignSystem

struct EmptyStateScreen: View {
    var body: some View {
        GalleryScreen(title: "Empty State", caption: "Nothing here yet") {
            Text("TODO").ds(.body)
        }
    }
}
