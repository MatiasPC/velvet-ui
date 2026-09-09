import SwiftUI
import DesignSystem

/// Standalone harness for the Velvet UI motion wave-1 review.
///
/// Simulator: see every animation. Physical device: feel the haptics
/// (`DSSlideToConfirm` and `DSStepper` are the ones that fire them).
@main
struct MotionReviewApp: App {
    @State private var theme = DSTheme(gradient: .sunset)
    @State private var scheme: ColorScheme = .dark

    var body: some Scene {
        WindowGroup {
            ReviewScreen(theme: $theme, scheme: $scheme)
                .dsTheme(theme)
                .preferredColorScheme(scheme)
        }
    }
}
