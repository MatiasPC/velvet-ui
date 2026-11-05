import XCTest

/// Every recording stage launches, renders and keeps running, in light and dark.
///
/// The list comes from `Stage.allCases` (the app's own `Stage.swift` is compiled
/// into this target), so a new component is covered the moment it gets a stage.
/// Each launch attaches a screenshot; CI uploads them as the
/// `gallery-screenshots` artifact for a visual check of the PR.
final class StageSmokeTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true   // report every broken stage, not just the first
    }

    @MainActor
    func testEveryStageLaunchesInLightAndDark() {
        for stage in Stage.allCases {
            for scheme in StageLauncher.Scheme.allCases {
                XCTContext.runActivity(named: "\(stage.rawValue) · \(scheme.rawValue)") { _ in
                    let app = StageLauncher.launch(stage.rawValue, scheme: scheme)
                    StageLauncher.settle()
                    XCTAssertEqual(
                        app.state, .runningForeground,
                        "\(stage.rawValue) (\(scheme.rawValue)) crashed or left the foreground."
                    )
                    StageLauncher.attachScreenshot(app, named: "\(stage.rawValue)-\(scheme.rawValue)", to: self)
                    app.terminate()
                }
            }
        }
    }
}
