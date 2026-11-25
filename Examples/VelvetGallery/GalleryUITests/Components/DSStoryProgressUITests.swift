import XCTest

/// DSStoryProgress on its stage: four trip stories, three seconds each. The
/// progress is one adjustable element, "Stories", whose value is the page
/// ("1 of 4" … "4 of 4"). "Stories status" reads "Playing", "Paused" or
/// "Finished" (set by `onFinish`). The stage has "Previous story", "Pause
/// stories" / "Play stories", "Next story" and "Watch again" buttons.
///
/// The stories start when the view is created, and launching the app on a slow
/// CI simulator can use up all twelve seconds before the first read. So the
/// test lets that run finish first, then pauses and restarts it, and asserts on
/// the run it started itself: a pause holds the page past its duration, the
/// buttons skip both ways, and once playing it moves on by itself and finishes.
final class DSStoryProgressUITests: XCTestCase {
    @MainActor
    func testItHoldsWhilePausedSkipsAndMovesOnByItself() {
        let app = StageLauncher.launch("DSStoryProgress")
        let progress = app.element("Stories")
        let status = app.element("Stories status")
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertTrue(status.waitForExistence(timeout: 5))

        // The run that started at launch reaches the last story and finishes.
        XCTAssertTrue(status.waitForValue("Finished", timeout: 30), "onFinish didn't run. Got \(status.stringValue ?? "nil")")
        XCTAssertEqual(progress.stringValue, "4 of 4")

        // Pause, then start again from the first story: it stays there, paused,
        // well past its three seconds.
        app.buttons["Pause stories"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Play stories"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Watch again"].firstMatch.tap()
        XCTAssertTrue(progress.waitForValue("1 of 4"), "Got \(progress.stringValue ?? "nil")")
        XCTAssertTrue(status.waitForValue("Paused"), "Got \(status.stringValue ?? "nil")")
        StageLauncher.settle(4.5)
        XCTAssertEqual(progress.stringValue, "1 of 4", "A paused story moved on by itself.")
        StageLauncher.attachScreenshot(app, named: "DSStoryProgress · paused", to: self)

        // Skipping works while paused, both ways.
        app.buttons["Next story"].firstMatch.tap()
        XCTAssertTrue(progress.waitForValue("2 of 4"), "Got \(progress.stringValue ?? "nil")")
        app.buttons["Previous story"].firstMatch.tap()
        XCTAssertTrue(progress.waitForValue("1 of 4"), "Got \(progress.stringValue ?? "nil")")

        // Playing again, it moves on by itself and finishes on the last story.
        app.buttons["Play stories"].firstMatch.tap()
        XCTAssertTrue(status.waitForValue("Playing"), "Got \(status.stringValue ?? "nil")")
        XCTAssertTrue(progress.waitForValue("2 of 4", timeout: 10), "It didn't move on by itself. Got \(progress.stringValue ?? "nil")")
        XCTAssertTrue(status.waitForValue("Finished", timeout: 20), "onFinish didn't run. Got \(status.stringValue ?? "nil")")
        XCTAssertEqual(progress.stringValue, "4 of 4")
    }
}
