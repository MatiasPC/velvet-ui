import SwiftUI
import VelvetUI

@main
struct VelvetGalleryApp: App {
    @AppStorage("gallery.appearance") private var appearanceRaw = Appearance.system.rawValue
    @AppStorage(StageDefaults.storedBackground) private var stageBackgroundRaw = StageBackground.neutral.rawValue
    @AppStorage(StageDefaults.storedAutoplay) private var stageAutoplay = false
    @State private var launchStage: Stage?
    private let theme = DSTheme(gradient: .neutral)

    init() {
        // Launch arguments (-VelvetStage, -VelvetStageBackground, ...) are copied
        // into the stored settings before any view reads them.
        StageDefaults.applyLaunchArguments()
        _launchStage = State(initialValue: StageDefaults.launchStage())
    }

    private var appearance: Binding<Appearance> {
        Binding(
            get: { Appearance(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let stage = launchStage {
                    StageContainer(
                        stage: stage,
                        background: StageBackground(rawValue: stageBackgroundRaw) ?? .neutral,
                        autoplay: stageAutoplay
                    ) { launchStage = nil }
                } else {
                    NavigationStack { ComponentListView() }
                        .dsTheme(theme)
                }
            }
                .tint(DSColors.textPrimary)
                .environment(\.galleryAppearance, appearance)
                .preferredColorScheme(appearance.wrappedValue.colorScheme)
        }
    }
}
