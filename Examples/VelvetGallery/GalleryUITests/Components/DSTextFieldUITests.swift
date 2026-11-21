import XCTest

/// DSTextField and DSSearchBar on their stage (a search bar, an "Email" field
/// that validates as you type, a secure "Password" field). Fields are found by
/// their visible label, the name VoiceOver reads, not by placeholder; each step
/// checks the field's value and the error message or "Valid" check it shows.
final class DSTextFieldUITests: XCTestCase {
    @MainActor
    func testLabelNamesTheFieldAndValidationShows() {
        let app = StageLauncher.launch("DSTextField")

        // The label, not the placeholder, names the field.
        let email = app.textFields["Email"].firstMatch
        XCTAssertTrue(email.waitForExistence(timeout: 5), "No text field named \"Email\".")
        XCTAssertTrue(app.secureTextFields["Password"].firstMatch.exists, "No secure field named \"Password\".")

        // (No keyboard assertion: with a hardware keyboard attached the simulator
        // shows none, and typeText fails loudly if the field isn't focused.)
        email.tap()
        StageLauncher.settle()
        app.typeText("ada")
        XCTAssertTrue(email.waitForValue("ada"), "Got \(email.stringValue ?? "nil")")
        let error = app.staticTexts["Enter a valid email"].firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 5), "The error message never appeared.")

        // A valid address clears the error and shows the "Valid" check.
        app.typeText("@velvet.dev")
        XCTAssertTrue(email.waitForValue("ada@velvet.dev"), "Got \(email.stringValue ?? "nil")")
        XCTAssertTrue(waitForAbsence(error), "The error message stayed after a valid address.")
        XCTAssertTrue(app.element("Valid").waitForExistence(timeout: 5), "No \"Valid\" check on a valid address.")

        StageLauncher.attachScreenshot(app, named: "DSTextField · valid email", to: self)
    }

    @MainActor
    func testSearchBarClearButton() {
        let app = StageLauncher.launch("DSTextField")
        let search = app.element("Search destinations")
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Clear text"].exists, "Clear button shown with no text.")

        search.tap()
        StageLauncher.settle()
        app.typeText("Lisbon")
        XCTAssertTrue(search.waitForValue("Lisbon"), "Got \(search.stringValue ?? "nil")")

        let clear = app.buttons["Clear text"].firstMatch
        XCTAssertTrue(clear.waitForExistence(timeout: 5), "No labelled clear button once there is text.")
        clear.tap()
        XCTAssertTrue(waitForAbsence(clear), "The clear button stayed after clearing.")
        XCTAssertNotEqual(search.stringValue, "Lisbon", "Clear left the text in place.")
    }

    private func waitForAbsence(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
