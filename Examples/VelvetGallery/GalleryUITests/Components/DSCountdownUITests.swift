import XCTest

/// DSCountdown on its stage: a twelve-second "resend the code" countdown. It is
/// one accessibility element, "Resend timer", whose value is the time left
/// ("12 seconds" … "0 seconds"). "Resend status" reads "Waiting" until the
/// countdown's `onFinish` runs, then "Ready"; the "Resend code" button starts
/// it again. The test watches it tick down, finish and restart.
///
/// The stage starts its clock when the view is created, and on a slow CI
/// simulator launching the app and settling it can use up most of the twelve
/// seconds before the test first reads the value. So the test never assumes
/// the first countdown is still running: it waits for that one to finish, then
/// presses "Resend code" and checks the restarted countdown, whose start time
/// the test controls, from the top: it restarts, ticks down, finishes and runs
/// `onFinish` again.
final class DSCountdownUITests: XCTestCase {
    @MainActor
    func testItTicksDownFinishesAndRestarts() {
        let app = StageLauncher.launch("DSCountdown")
        let timer = app.element("Resend timer")
        let status = app.element("Resend status")
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("Sale ends in").stringValue?.contains("day") == true,
                      "The sale countdown should read days. Got \(app.element("Sale ends in").stringValue ?? "nil")")

        // The countdown that started at launch reaches zero (however much of it
        // the launch used up), and onFinish runs once it does.
        XCTAssertTrue(timer.waitForValue("0 seconds", timeout: 20), "Got \(timer.stringValue ?? "nil")")
        XCTAssertTrue(status.waitForValue("Ready", timeout: 5), "onFinish didn't run. Got \(status.stringValue ?? "nil")")
        StageLauncher.attachScreenshot(app, named: "DSCountdown · finished", to: self)

        // Resend restarts it from the top, so from here the test owns the clock.
        app.buttons["Resend code"].firstMatch.tap()
        XCTAssertTrue(status.waitForValue("Waiting", timeout: 5), "Got \(status.stringValue ?? "nil")")
        let start = waitForSeconds(timer, where: { $0 > 0 }, timeout: 5)
        XCTAssertNotNil(start, "The countdown didn't restart. Got \(timer.stringValue ?? "nil")")

        // It counts down: the seconds left drop below where they restarted.
        let later = waitForSeconds(timer, where: { $0 < (start ?? 0) && $0 > 0 }, timeout: 4)
        XCTAssertNotNil(later, "The countdown didn't tick. Still \(timer.stringValue ?? "nil")")

        // It reaches zero again, and onFinish runs for the restarted countdown too.
        XCTAssertTrue(timer.waitForValue("0 seconds", timeout: 20), "Got \(timer.stringValue ?? "nil")")
        XCTAssertTrue(status.waitForValue("Ready", timeout: 5), "onFinish didn't run after Resend. Got \(status.stringValue ?? "nil")")
    }

    /// The whole seconds in a value like "4 seconds" or "1 second"; nil for anything else.
    @MainActor
    private func seconds(_ element: XCUIElement) -> Int? {
        guard let value = element.stringValue,
              let first = value.split(separator: " ").first,
              value.hasSuffix("second") || value.hasSuffix("seconds"),
              !value.contains(",") else { return nil }
        return Int(first)
    }

    /// Polls until the value is a number of seconds that passes `condition`.
    @MainActor
    private func waitForSeconds(_ element: XCUIElement, where condition: @escaping (Int) -> Bool, timeout: TimeInterval) -> Int? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let value = seconds(element), condition(value) { return value }
            StageLauncher.settle(0.2)
        }
        return nil
    }
}
