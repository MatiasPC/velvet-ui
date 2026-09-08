import SwiftUI
import DesignSystem

@main
struct VelvetGalleryApp: App {
    @AppStorage("gallery.appearance") private var appearanceRaw = Appearance.system.rawValue
    private let theme = DSTheme(gradient: .neutral)

    private var appearance: Binding<Appearance> {
        Binding(
            get: { Appearance(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack { ComponentListView() }
                .dsTheme(theme)
                .tint(DSColors.textPrimary)
                .environment(\.galleryAppearance, appearance)
                .preferredColorScheme(appearance.wrappedValue.colorScheme)
        }
    }
}
