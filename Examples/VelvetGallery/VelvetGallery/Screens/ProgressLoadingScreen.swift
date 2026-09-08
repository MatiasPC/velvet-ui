import SwiftUI
import DesignSystem

struct ProgressLoadingScreen: View {
    var body: some View {
        GalleryScreen(title: "Progress & Loading", caption: "Determinate & skeletons") {
            Text("TODO").ds(.body)
        }
    }
}
