import SwiftUI
import XCTest
@testable import VelvetUI

// The README's snippets, verbatim, so `swift build` fails when they drift from
// the API. `MyApp` drops `@main` (a test target can't have an entry point).
enum DocSnippetsReadme {
    struct MyApp: App {
        @State private var theme = DSTheme(gradient: .sunset)
        var body: some Scene { WindowGroup { ContentView().dsTheme(theme) } }
    }

    struct ContentView: View {
        var body: some View {
            DSScreen(backdrop: true) {                  // the theme's gradient behind everything
                DSCard {
                    DSSlideToConfirm("Slide to pay") {
                        try await checkout()             // throw to refuse; the control re-opens
                    }
                }
                .dsScreenPadding()
            }
        }

        func checkout() async throws { /* charge the card */ }
    }

    struct PriceTag: View {
        @DSThemed private var theme

        var body: some View {
            Text("$120").ds(.numeric, color: theme.ink)
                .padding(.horizontal, DSSpacing.sm)
                .background(theme.subtleFill)
                .clipShape(Capsule())
        }
    }

    @MainActor
    static func switchTheme(_ theme: DSTheme) {
        withAnimation(DSAnimation.normal) { theme.gradient = .lagoon }
    }
}

@MainActor
final class DocSnippetsReadmeTests: XCTestCase {
    func testReadmeSnippetsInstantiate() {
        _ = DocSnippetsReadme.ContentView()
        _ = DocSnippetsReadme.PriceTag()
        let theme = DSTheme()
        DocSnippetsReadme.switchTheme(theme)
        XCTAssertEqual(theme.gradient.id, DSGradientTheme.lagoon.id)
    }
}
