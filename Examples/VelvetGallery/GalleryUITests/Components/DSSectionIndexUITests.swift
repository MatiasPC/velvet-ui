import XCTest

/// DSSectionIndex on its stage: twenty letters (A…W, no I, Q, U, X, Y or Z) in a
/// 44 × 320 pt column on the trailing edge of a contact list, every letter a
/// 16 pt row at the default text size. The index is one adjustable element,
/// "Section index", whose value is the last letter jumped to ("A" before any
/// jump); "Jumped to" reads the letter the stage's list scrolled to ("Nothing"
/// before any jump).
final class DSSectionIndexUITests: XCTestCase {
    private let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "J", "K",
                           "L", "M", "N", "O", "P", "R", "S", "T", "V", "W"]

    /// Vertical centre of `letter`'s row as a fraction of the column's height.
    private func centre(of letter: String) -> CGFloat {
        let index = letters.firstIndex(of: letter) ?? 0
        return (CGFloat(index) + 0.5) / CGFloat(letters.count)
    }

    @MainActor
    func testTapSlideAndHoldAtTheEnd() {
        let app = StageLauncher.launch("DSSectionIndex")
        let index = app.element("Section index")
        let jumped = app.element("Jumped to")
        XCTAssertTrue(index.waitForExistence(timeout: 5))
        XCTAssertEqual(index.stringValue, "A")
        XCTAssertEqual(jumped.stringValue, "Nothing")

        func letter(_ l: String) -> XCUICoordinate {
            index.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: centre(of: l)))
        }

        // A tap jumps to the letter under it.
        letter("M").tap()
        XCTAssertTrue(index.waitForValue("M"), "Got \(index.stringValue ?? "nil")")
        XCTAssertTrue(jumped.waitForValue("M"), "The list wasn't told. Got \(jumped.stringValue ?? "nil")")

        // A slide keeps jumping and ends on the letter the finger lifts on.
        letter("C").press(forDuration: 0.1, thenDragTo: letter("S"))
        XCTAssertTrue(index.waitForValue("S"), "Got \(index.stringValue ?? "nil")")
        XCTAssertTrue(jumped.waitForValue("S"), "Got \(jumped.stringValue ?? "nil")")

        StageLauncher.attachScreenshot(app, named: "DSSectionIndex · S", to: self)

        // Sliding past the bottom of the column holds the last letter.
        let belowColumn = index.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.5))
        letter("E").press(forDuration: 0.1, thenDragTo: belowColumn)
        XCTAssertTrue(index.waitForValue("W"), "Got \(index.stringValue ?? "nil")")
        XCTAssertTrue(jumped.waitForValue("W"), "Got \(jumped.stringValue ?? "nil")")
    }
}
