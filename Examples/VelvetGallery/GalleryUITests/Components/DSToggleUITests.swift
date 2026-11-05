import XCTest

/// DSToggle on its stage: a tap flips the VoiceOver value, a second tap flips it back.
final class DSToggleUITests: XCTestCase {
    @MainActor
    func testTapTogglesTheValue() {
        let app = StageLauncher.launch("DSToggle")
        let toggle = app.element("Push notifications")
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.stringValue, "Off")

        toggle.tap()
        XCTAssertTrue(toggle.waitForValue("On"), "Got \(toggle.stringValue ?? "nil")")

        toggle.tap()
        XCTAssertTrue(toggle.waitForValue("Off"), "Got \(toggle.stringValue ?? "nil")")
    }
}
