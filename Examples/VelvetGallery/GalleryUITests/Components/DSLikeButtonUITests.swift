import XCTest

/// DSLikeButton on its stage: liking updates the value and the count, unliking
/// restores both, and the other buttons on the stage are independent.
final class DSLikeButtonUITests: XCTestCase {
    @MainActor
    func testLikeAndUnlike() {
        let app = StageLauncher.launch("DSLikeButton")
        let like = app.element("Like")
        XCTAssertTrue(like.waitForExistence(timeout: 5))
        XCTAssertEqual(like.stringValue, "Not liked, 128")

        like.tap()
        XCTAssertTrue(like.waitForValue("Liked, 129"), "Got \(like.stringValue ?? "nil")")
        XCTAssertEqual(app.element("Favorite").stringValue, "Not liked", "Liking one button changed another.")

        like.tap()
        XCTAssertTrue(like.waitForValue("Not liked, 128"), "Got \(like.stringValue ?? "nil")")
    }

    @MainActor
    func testRapidTapsSettleOnTheRightState() {
        let app = StageLauncher.launch("DSLikeButton")
        let save = app.element("Save")
        XCTAssertTrue(save.waitForExistence(timeout: 5))

        for _ in 0..<5 { save.tap() }   // odd number of taps: ends liked
        XCTAssertTrue(save.waitForValue("Liked"), "Got \(save.stringValue ?? "nil")")
    }
}
