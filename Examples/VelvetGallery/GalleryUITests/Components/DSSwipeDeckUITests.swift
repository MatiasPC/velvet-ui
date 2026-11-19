import XCTest

/// DSSwipeDeck on its stage: five trips (Lisbon, Kyoto, Oslo, Cusco, Hanoi)
/// with "Skip" / "Save", a "Tally" read-out ("0 saved, 0 skipped") and a
/// "Start over" button. The top card is one accessibility element whose label
/// starts with the city and whose value is the cards left; the cards behind it
/// are hidden. The test drags short of the line, swipes right and left like a
/// person would, and reads the deck and the tally after each step.
final class DSSwipeDeckUITests: XCTestCase {
    /// The top card, found by the city its label starts with.
    private func card(_ app: XCUIApplication, _ city: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", city))
            .firstMatch
    }

    @MainActor
    func testShortDragSpringsBackAndSwipesDecide() {
        let app = StageLauncher.launch("DSSwipeDeck")
        let tally = app.element("Tally")
        XCTAssertTrue(tally.waitForExistence(timeout: 10))
        XCTAssertEqual(tally.stringValue, "0 saved, 0 skipped")

        let lisbon = card(app, "Lisbon")
        XCTAssertTrue(lisbon.waitForExistence(timeout: 10))
        XCTAssertEqual(lisbon.stringValue, "5 cards left")
        XCTAssertFalse(card(app, "Kyoto").exists, "Cards behind the top one are hidden from VoiceOver.")

        // A slow drag of 50 pt, held before letting go: short of the line (40% of
        // the width) and no flick, so the card springs back and nothing is decided.
        let centre = lisbon.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        centre.press(
            forDuration: 0.1,
            thenDragTo: centre.withOffset(CGVector(dx: 50, dy: 0)),
            withVelocity: .slow,
            thenHoldForDuration: 0.3
        )
        StageLauncher.settle()
        XCTAssertEqual(tally.stringValue, "0 saved, 0 skipped")
        XCTAssertTrue(lisbon.exists, "Lisbon should still be on top.")
        XCTAssertEqual(lisbon.stringValue, "5 cards left")

        // Swipe right: saved, and Kyoto comes to the top.
        lisbon.swipeRight()
        XCTAssertTrue(tally.waitForValue("1 saved, 0 skipped", timeout: 10), "Got \(tally.stringValue ?? "nil")")
        let kyoto = card(app, "Kyoto")
        XCTAssertTrue(kyoto.waitForExistence(timeout: 10))
        XCTAssertTrue(kyoto.waitForValue("4 cards left"), "Got \(kyoto.stringValue ?? "nil")")
        XCTAssertFalse(card(app, "Lisbon").exists, "A saved card leaves the deck.")

        // Swipe left: skipped, and Oslo comes to the top.
        kyoto.swipeLeft()
        XCTAssertTrue(tally.waitForValue("1 saved, 1 skipped", timeout: 10), "Got \(tally.stringValue ?? "nil")")
        let oslo = card(app, "Oslo")
        XCTAssertTrue(oslo.waitForExistence(timeout: 10))
        XCTAssertTrue(oslo.waitForValue("3 cards left"), "Got \(oslo.stringValue ?? "nil")")
        StageLauncher.attachScreenshot(app, named: "DSSwipeDeck · after two decisions", to: self)

        // Start over refills the deck.
        app.buttons["Start over"].firstMatch.tap()
        XCTAssertTrue(tally.waitForValue("0 saved, 0 skipped", timeout: 10), "Got \(tally.stringValue ?? "nil")")
        XCTAssertTrue(card(app, "Lisbon").waitForExistence(timeout: 10))
        XCTAssertTrue(card(app, "Lisbon").waitForValue("5 cards left"), "Got \(card(app, "Lisbon").stringValue ?? "nil")")
    }
}
