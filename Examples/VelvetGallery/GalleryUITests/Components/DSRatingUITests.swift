import XCTest

/// DSRating on its stage (five 40 pt stars, 8 pt gaps, starting at 0): tapping a
/// star rates it, a drag across the row lands on the star under the finger, and
/// VoiceOver reads the result as "N out of 5 stars".
final class DSRatingUITests: XCTestCase {
    /// Horizontal centre of star `n` (1-based) as a fraction of the row's width.
    private func centre(ofStar n: Int) -> CGFloat {
        let size: CGFloat = 40, gap: CGFloat = 8
        let width = size * 5 + gap * 4
        return (CGFloat(n - 1) * (size + gap) + size / 2) / width
    }

    @MainActor
    func testTapAndDragRate() {
        let app = StageLauncher.launch("DSRating")
        let rating = app.element("Rating")
        XCTAssertTrue(rating.waitForExistence(timeout: 5))
        XCTAssertEqual(rating.stringValue, "0 out of 5 stars")

        // The row is one accessibility element, so tap the stars by position.
        func star(_ n: Int) -> XCUICoordinate {
            rating.coordinate(withNormalizedOffset: CGVector(dx: centre(ofStar: n), dy: 0.5))
        }

        star(4).tap()
        XCTAssertTrue(rating.waitForValue("4 out of 5 stars"), "Got \(rating.stringValue ?? "nil")")

        star(2).tap()
        XCTAssertTrue(rating.waitForValue("2 out of 5 stars"), "Got \(rating.stringValue ?? "nil")")

        // A drag commits the star the finger lifts on, not the one it started on.
        star(1).press(forDuration: 0.1, thenDragTo: star(5))
        XCTAssertTrue(rating.waitForValue("5 out of 5 stars"), "Got \(rating.stringValue ?? "nil")")

        star(5).press(forDuration: 0.1, thenDragTo: star(3))
        XCTAssertTrue(rating.waitForValue("3 out of 5 stars"), "Got \(rating.stringValue ?? "nil")")

        StageLauncher.attachScreenshot(app, named: "DSRating · 3 stars", to: self)
    }
}
