import SwiftUI
import DesignSystem

struct ListsScreen: View {
    var body: some View {
        GalleryScreen(title: "Lists", caption: "Rows & sections") {
            Text("TODO").ds(.body)
        }
    }
}
