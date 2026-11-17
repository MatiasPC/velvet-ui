import XCTest

/// DSPageControl on its stage (a paged TabView of four cards over a default
/// control: 8 pt dots, a 24 pt active capsule, 8 pt gaps, 72 pt wide, starting
/// on page 1): tapping a dot jumps to it, the touch row reaches above and below
/// the 8 pt dots, and a swipe on the cards moves the dots too.
final class DSPageControlUITests: XCTestCase {
    /// A point `dx` across and `dy` down from the control's centre, so the taps
    /// don't depend on how tall the accessibility frame is.
    private func point(_ control: XCUIElement, dx: CGFloat, dy: CGFloat = 0) -> XCUICoordinate {
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .withOffset(CGVector(dx: dx, dy: dy))
    }

    @MainActor
    func testTapAndSwipeMoveThePage() {
        let app = StageLauncher.launch("DSPageControl")
        let control = app.element("Page")
        XCTAssertTrue(control.waitForExistence(timeout: 10))
        XCTAssertEqual(control.stringValue, "1 of 4")

        // Page 1 active: dots centred at 12, 36, 52, 68 of 72; the centre is 36.
        point(control, dx: 16).tap()
        XCTAssertTrue(control.waitForValue("3 of 4", timeout: 10), "Got \(control.stringValue ?? "nil")")

        // Page 3 active: dots centred at 4, 20, 44, 68. Tap 14 pt above the
        // centre (10 pt above the dots), inside the 44 pt touch row.
        point(control, dx: -32, dy: -14).tap()
        XCTAssertTrue(control.waitForValue("1 of 4", timeout: 10), "Got \(control.stringValue ?? "nil")")

        // And 14 pt below, on the last dot.
        point(control, dx: 32, dy: 14).tap()
        XCTAssertTrue(control.waitForValue("4 of 4", timeout: 10), "Got \(control.stringValue ?? "nil")")

        // Swiping the cards back one page moves the dots with them.
        let card = app.element("Get started")
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        card.swipeRight()
        XCTAssertTrue(control.waitForValue("3 of 4", timeout: 10), "Got \(control.stringValue ?? "nil")")

        StageLauncher.attachScreenshot(app, named: "DSPageControl · page 3", to: self)
    }
}
