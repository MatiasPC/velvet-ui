import XCTest

/// DSCodeField on its stage (six digits; "428519" verifies, anything else is an
/// error). The field is one accessibility element, "Verification code", whose
/// value spells the digits, the progress and the state; the stage's
/// "Submissions" read-out counts `onComplete` calls. The test types on the
/// keyboard the way a person would and checks both after each step.
final class DSCodeFieldUITests: XCTestCase {
    @MainActor
    func testTypingFillsTheBoxesAndSubmitsOncePerCode() {
        let app = StageLauncher.launch("DSCodeField")
        let field = app.textFields["Verification code"].firstMatch
        let submissions = app.element("Submissions")
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(submissions.waitForExistence(timeout: 5))
        XCTAssertEqual(field.stringValue, "0 of 6 digits")
        XCTAssertEqual(submissions.stringValue, "0")

        // The real field is a 1 pt point in the middle of the boxes; tapping the
        // boxes there focuses it, like a finger would.
        // (No keyboard assertion: with a hardware keyboard attached the simulator
        // shows none, and typeText fails loudly if the field isn't focused.)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        StageLauncher.settle()

        app.typeText("428")
        XCTAssertTrue(field.waitForValue("4 2 8, 3 of 6 digits", timeout: 10), "Got \(field.stringValue ?? "nil")")
        XCTAssertEqual(submissions.stringValue, "0")

        app.typeText("519")
        XCTAssertTrue(
            field.waitForValue("4 2 8 5 1 9, 6 of 6 digits, verified", timeout: 10),
            "Got \(field.stringValue ?? "nil")"
        )
        XCTAssertTrue(submissions.waitForValue("1", timeout: 10), "Got \(submissions.stringValue ?? "nil")")
        StageLauncher.attachScreenshot(app, named: "DSCodeField · verified", to: self)

        // A seventh digit is clamped away and doesn't submit the code again.
        app.typeText("7")
        StageLauncher.settle()
        XCTAssertEqual(field.stringValue, "4 2 8 5 1 9, 6 of 6 digits, verified")
        XCTAssertEqual(submissions.stringValue, "1", "An extra keystroke on a full code submitted it again.")

        // Delete the last digit, type a wrong one: a new code, a new submission, an error.
        app.typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssertTrue(field.waitForValue("4 2 8 5 1, 5 of 6 digits", timeout: 10), "Got \(field.stringValue ?? "nil")")
        app.typeText("0")
        XCTAssertTrue(
            field.waitForValue("4 2 8 5 1 0, 6 of 6 digits, incorrect code", timeout: 10),
            "Got \(field.stringValue ?? "nil")"
        )
        XCTAssertTrue(submissions.waitForValue("2", timeout: 10), "Got \(submissions.stringValue ?? "nil")")
        StageLauncher.attachScreenshot(app, named: "DSCodeField · incorrect code", to: self)
    }
}
