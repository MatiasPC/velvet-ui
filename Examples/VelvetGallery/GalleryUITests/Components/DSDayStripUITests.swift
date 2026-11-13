import XCTest

/// DSDayStrip on its stage (a booking strip from three days ago to four weeks
/// ahead, starting on today). The strip is one adjustable accessibility element,
/// "Booking day", whose value is the spoken date ("Friday, November 13, Today");
/// the read-out under it, "Days from today", holds the selected day's offset.
/// The test taps days the way a person would and reads both back.
final class DSDayStripUITests: XCTestCase {
    @MainActor
    func testTappingADaySelectsItAndTodayIsMarked() {
        let app = StageLauncher.launch("DSDayStrip")
        let strip = app.element("Booking day")
        let offset = app.element("Days from today")
        XCTAssertTrue(strip.waitForExistence(timeout: 5))
        XCTAssertTrue(offset.waitForExistence(timeout: 5))
        StageLauncher.settle()

        // It starts on today, and says so.
        XCTAssertEqual(offset.stringValue, "0")
        XCTAssertTrue(strip.stringValue?.hasSuffix("Today") == true, "Got \(strip.stringValue ?? "nil")")

        // The strip is one element; its day cells fill it edge to edge, so tap them
        // by position. Today is centred (or near the start), so the right edge is a later day.
        strip.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        let later = waitForOffset(offset, where: { $0 > 0 })
        XCTAssertNotNil(later, "Tapping a later day didn't select it. Got \(offset.stringValue ?? "nil")")
        XCTAssertFalse(strip.stringValue?.contains("Today") ?? true, "A later day still reads as Today: \(strip.stringValue ?? "nil")")

        // The strip recentres on the new day; the left edge is now an earlier one.
        StageLauncher.settle()
        strip.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.5)).tap()
        let earlier = waitForOffset(offset, where: { $0 < (later ?? .max) })
        XCTAssertNotNil(earlier, "Tapping an earlier day didn't select it. Got \(offset.stringValue ?? "nil")")
        XCTAssertGreaterThanOrEqual(earlier ?? .min, -3, "A day before the bounds was selected.")

        StageLauncher.attachScreenshot(app, named: "DSDayStrip · after two taps", to: self)
    }

    /// Waits until the read-out's value is an integer that passes `condition`.
    @MainActor
    private func waitForOffset(_ element: XCUIElement, where condition: @escaping (Int) -> Bool, timeout: TimeInterval = 5) -> Int? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let value = element.stringValue.flatMap(Int.init), condition(value) { return value }
            StageLauncher.settle(0.2)
        }
        return nil
    }
}
