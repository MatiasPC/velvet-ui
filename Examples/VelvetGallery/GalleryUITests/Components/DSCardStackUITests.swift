import XCTest

/// DSCardStack on its stage: four order updates in a pile named "Order updates"
/// (value "4 cards, collapsed"), a "Show less" button while it's expanded and a
/// "Stack state" read-out ("Collapsed" / "Expanded"). Collapsed, the pile is one
/// button and the cards inside are not read; expanded, each card's text is its
/// own element. The test taps the pile open like a person would, reads the cards,
/// then closes it with "Show less".
final class DSCardStackUITests: XCTestCase {
    private func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    @MainActor
    func testTapExpandsAndShowLessCollapses() {
        let app = StageLauncher.launch("DSCardStack")
        let state = app.element("Stack state")
        XCTAssertTrue(state.waitForExistence(timeout: 10))
        XCTAssertEqual(state.stringValue, "Collapsed")

        let stack = app.element("Order updates")
        XCTAssertTrue(stack.waitForExistence(timeout: 10))
        XCTAssertEqual(stack.stringValue, "4 cards, collapsed")
        let lastCard = app.staticTexts["Left at the front door"]
        XCTAssertFalse(lastCard.exists, "Cards inside a collapsed pile are not read on their own.")
        XCTAssertFalse(app.buttons["Show less"].exists)

        // Tap the pile: it fans out and every card is read on its own.
        stack.tap()
        XCTAssertTrue(state.waitForValue("Expanded", timeout: 10), "Got \(state.stringValue ?? "nil")")
        XCTAssertTrue(lastCard.waitForExistence(timeout: 10), "The third card should be readable once expanded.")
        XCTAssertTrue(app.staticTexts["Tell us how it went"].waitForExistence(timeout: 10), "So should the fourth.")
        StageLauncher.settle()
        StageLauncher.attachScreenshot(app, named: "DSCardStack · expanded", to: self)

        // Show less: back to one pile, the cards inside are hidden again.
        let showLess = app.buttons["Show less"].firstMatch
        XCTAssertTrue(showLess.waitForExistence(timeout: 10))
        showLess.tap()
        XCTAssertTrue(state.waitForValue("Collapsed", timeout: 10), "Got \(state.stringValue ?? "nil")")
        XCTAssertTrue(stack.waitForValue("4 cards, collapsed", timeout: 10), "Got \(stack.stringValue ?? "nil")")
        XCTAssertTrue(waitUntilGone(lastCard), "A collapsed pile hides its cards from VoiceOver again.")
    }
}
