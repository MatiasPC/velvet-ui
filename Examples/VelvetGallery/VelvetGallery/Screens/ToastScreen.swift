import SwiftUI
import DesignSystem

struct ToastScreen: View {
    var body: some View {
        GalleryScreen(title: "Toast", caption: "Transient feedback") {
            Text("TODO").ds(.body)
        }
    }
}
