import XCTest

/// DSHeatmap on its stage (twelve weeks of workouts ending today, nothing
/// selected). The heatmap is one accessibility element, "Workouts", whose value
/// is a summary ("12 weeks, 61 active days") until a day is picked, then that
/// day ("Friday, November 13, 45"). The read-out under it, "Selected day", holds
/// the selected day's offset from today, or "none". The test taps cells the way
/// a person would and reads both back.
final class DSHeatmapUITests: XCTestCase {
    private let weeks = 12

    @MainActor
    func testTappingACellSelectsThatDayAndTappingAgainClearsIt() {
        let app = StageLauncher.launch("DSHeatmap")
        let heatmap = app.element("Workouts")
        let selected = app.element("Selected day")
        XCTAssertTrue(heatmap.waitForExistence(timeout: 5))
        XCTAssertTrue(selected.waitForExistence(timeout: 5))
        StageLauncher.settle()

        // Nothing selected: the heatmap reads its summary.
        XCTAssertEqual(selected.stringValue, "none")
        XCTAssertTrue(heatmap.stringValue?.hasPrefix("\(weeks) weeks, ") == true, "Got \(heatmap.stringValue ?? "nil")")
        XCTAssertTrue(heatmap.stringValue?.hasSuffix("active days") == true, "Got \(heatmap.stringValue ?? "nil")")

        // The columns span the element's width, a week each, oldest first. The
        // second-to-last column is last week: 1 to 13 days ago, whatever today is.
        // Low in the element is inside the grid (the month names are a thin top row).
        let lastWeek = cell(heatmap, column: weeks - 2)
        lastWeek.tap()
        let first = waitForOffset(selected, where: { (-13)...(-1) ~= $0 })
        XCTAssertNotNil(first, "Tapping last week's column didn't select a day in it. Got \(selected.stringValue ?? "nil")")
        XCTAssertFalse(heatmap.stringValue?.hasSuffix("active days") ?? true,
                       "A selected heatmap should read the day, got \(heatmap.stringValue ?? "nil")")

        // Tapping the selected day again clears the selection.
        StageLauncher.settle(0.5)
        lastWeek.tap()
        XCTAssertTrue(selected.waitForValue("none"), "A second tap should clear the selection. Got \(selected.stringValue ?? "nil")")
        XCTAssertTrue(heatmap.stringValue?.hasSuffix("active days") == true, "Got \(heatmap.stringValue ?? "nil")")

        // The first column is the oldest week: 11 weeks back, give or take its weekday.
        StageLauncher.settle(0.5)
        cell(heatmap, column: 0).tap()
        let oldest = -7 * (weeks - 1)
        let picked = waitForOffset(selected, where: { (oldest - 6)...(oldest + 6) ~= $0 })
        XCTAssertNotNil(picked, "Tapping the first column didn't select a day eleven weeks back. Got \(selected.stringValue ?? "nil")")

        StageLauncher.attachScreenshot(app, named: "DSHeatmap · a day selected", to: self)
    }

    /// A point in `column`, two-thirds of the way down the heatmap.
    @MainActor
    private func cell(_ heatmap: XCUIElement, column: Int) -> XCUICoordinate {
        let x = (CGFloat(column) + 0.5) / CGFloat(weeks)
        return heatmap.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.66))
    }

    /// Waits until the read-out's value is an integer that passes `condition`.
    @MainActor
    private func waitForOffset(_ element: XCUIElement, where condition: @escaping (Int) -> Bool, timeout: TimeInterval = 15) -> Int? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let value = element.stringValue.flatMap(Int.init), condition(value) { return value }
            StageLauncher.settle(0.2)
        }
        return nil
    }
}
