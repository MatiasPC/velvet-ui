import XCTest

/// DSPasswordStrength on its stage: a sign-up card with a visible password
/// field ("Choose a password"), the meter under it and a "Create account"
/// button that is enabled from Good. The meter is one accessibility element,
/// "Password strength", whose value is the level and the hint ("Fair. Add a
/// number"), so the test types the way a person would and reads the meter
/// after each step.
final class DSPasswordStrengthUITests: XCTestCase {
    @MainActor
    func testTypingRaisesTheLevelAndCommonPasswordsStayWeak() {
        let app = StageLauncher.launch("DSPasswordStrength")
        let meter = app.element("Password strength")
        XCTAssertTrue(meter.waitForExistence(timeout: 5))
        XCTAssertEqual(meter.stringValue, "Empty. Use at least 8 characters")

        let field = app.textFields["Choose a password"].firstMatch
        let create = app.buttons["Create account"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertFalse(create.isEnabled, "Create account should wait for a good password.")
        field.tap()
        StageLauncher.settle()

        // Too short, then long enough but one kind of character.
        app.typeText("sun")
        XCTAssertTrue(meter.waitForValue("Weak. Use at least 8 characters"), "Got \(meter.stringValue ?? "nil")")
        app.typeText("flower")
        XCTAssertTrue(meter.waitForValue("Fair. Add a number"), "Got \(meter.stringValue ?? "nil")")

        // A number and a symbol make it good, and the button turns on.
        app.typeText("7!")
        XCTAssertTrue(meter.waitForValue("Good. Add a capital letter"), "Got \(meter.stringValue ?? "nil")")
        XCTAssertTrue(create.isEnabled, "Create account should be enabled from Good.")

        // A capital and a little more length make it strong: no hint left.
        app.typeText("Kite")
        XCTAssertTrue(meter.waitForValue("Strong"), "Got \(meter.stringValue ?? "nil")")
        StageLauncher.attachScreenshot(app, named: "DSPasswordStrength · strong", to: self)

        // Clear, then a decorated common password stays weak.
        app.buttons["Clear"].firstMatch.tap()
        XCTAssertTrue(meter.waitForValue("Empty. Use at least 8 characters"), "Got \(meter.stringValue ?? "nil")")
        field.tap()
        StageLauncher.settle()
        app.typeText("password1")
        XCTAssertTrue(meter.waitForValue("Weak. Avoid common passwords"), "Got \(meter.stringValue ?? "nil")")
        XCTAssertFalse(create.isEnabled, "A common password shouldn't enable Create account.")
    }
}
