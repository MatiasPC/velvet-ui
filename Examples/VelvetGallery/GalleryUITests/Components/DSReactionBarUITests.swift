import XCTest

/// DSReactionBar on its stage: the default six reactions (👍 ❤️ 😂 😮 😢 🙏) in
/// 44 pt cells inside a 4 pt inset, starting with none. The bar is one adjustable
/// element, "Reaction", whose value is the picked emoji or "None". The test aims
/// at the emoji that carry no variation selector, so the values compare exactly.
final class DSReactionBarUITests: XCTestCase {
    /// Horizontal centre of emoji `n` (1-based) as a fraction of the bar's width.
    private func centre(ofEmoji n: Int, count: Int = 6) -> CGFloat {
        let cell: CGFloat = 44, inset: CGFloat = 4
        let width = cell * CGFloat(count) + inset * 2
        return (inset + (CGFloat(n) - 0.5) * cell) / width
    }

    @MainActor
    func testTapSlideTakeBackAndCancel() {
        let app = StageLauncher.launch("DSReactionBar")
        let bar = app.element("Reaction")
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
        XCTAssertEqual(bar.stringValue, "None")

        func emoji(_ n: Int) -> XCUICoordinate {
            bar.coordinate(withNormalizedOffset: CGVector(dx: centre(ofEmoji: n), dy: 0.5))
        }

        // A tap picks the emoji under it.
        emoji(1).tap()
        XCTAssertTrue(bar.waitForValue("👍"), "Got \(bar.stringValue ?? "nil")")

        // Picking it again takes the reaction back.
        emoji(1).tap()
        XCTAssertTrue(bar.waitForValue("None"), "Got \(bar.stringValue ?? "nil")")

        // A slide picks the emoji the finger lifts on, not the one it started on.
        emoji(1).press(forDuration: 0.1, thenDragTo: emoji(5))
        XCTAssertTrue(bar.waitForValue("😢"), "Got \(bar.stringValue ?? "nil")")

        StageLauncher.attachScreenshot(app, named: "DSReactionBar · 😢", to: self)

        // Lifting the finger far above the bar cancels: the reaction stays.
        let farAbove = bar.coordinate(withNormalizedOffset: CGVector(dx: centre(ofEmoji: 3), dy: -4))
        emoji(3).press(forDuration: 0.1, thenDragTo: farAbove)
        StageLauncher.settle()
        XCTAssertEqual(bar.stringValue, "😢", "Letting go far from the bar picked something.")
    }
}
