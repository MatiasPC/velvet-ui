import XCTest

/// DSSegmentedControl on its stage (a pill and an underline control sharing one
/// "Day / Week / Month" selection, starting on "Day"): a tap moves the selected
/// trait to the tapped segment, and each segment reads its position ("2 of 3").
final class DSSegmentedControlUITests: XCTestCase {
    @MainActor
    func testTapMovesTheSelection() {
        let app = StageLauncher.launch("DSSegmentedControl")
        // firstMatch is the pill control, the first on the stage.
        let day = app.element("Day")
        let week = app.element("Week")
        let month = app.element("Month")
        XCTAssertTrue(week.waitForExistence(timeout: 5))

        XCTAssertEqual(day.stringValue, "1 of 3")
        XCTAssertEqual(week.stringValue, "2 of 3")
        XCTAssertEqual(month.stringValue, "3 of 3")
        XCTAssertTrue(day.isSelected)
        XCTAssertFalse(week.isSelected)

        week.tap()
        XCTAssertTrue(waitForSelected(week), "Week never became selected")
        XCTAssertFalse(day.isSelected)

        month.tap()
        XCTAssertTrue(waitForSelected(month), "Month never became selected")
        XCTAssertFalse(week.isSelected)

        // Tapping the selected segment keeps it selected.
        month.tap()
        StageLauncher.settle(0.5)
        XCTAssertTrue(month.isSelected)

        StageLauncher.attachScreenshot(app, named: "DSSegmentedControl · Month", to: self)
    }

    private func waitForSelected(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isSelected == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
