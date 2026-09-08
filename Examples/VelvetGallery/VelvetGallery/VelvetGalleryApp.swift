import SwiftUI
import DesignSystem

@main
struct VelvetGalleryApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Text("VelvetGallery")
                    .ds(.title1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DSColors.backgroundPrimary.ignoresSafeArea())
                    .navigationTitle("Velvet UI")
            }
            .dsTheme(DSTheme())
        }
    }
}
