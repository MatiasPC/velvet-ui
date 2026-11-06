import XCTest

/// DSStepper on its stage (quantity 1 in 0...9): tapping + and − moves the
/// VoiceOver value one step, and a tap at the lower bound is refused, so the
/// value stays put.
final class DSStepperUITests: XCTestCase {
    @MainActor
    func testTapsStepTheValueAndStopAtTheBound() {
        let app = StageLauncher.launch("DSStepper")
        // The stage doesn't relabel the stepper, so it reads its default label.
        let stepper = app.element("Stepper")
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        XCTAssertEqual(stepper.stringValue, "1")

        // The stepper is one accessibility element; its − and + glyphs are 44 pt
        // buttons at either end, so tap them by position.
        let minus = stepper.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        let plus = stepper.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))

        plus.tap()
        XCTAssertTrue(stepper.waitForValue("2"), "Got \(stepper.stringValue ?? "nil")")

        minus.tap()
        minus.tap()
        XCTAssertTrue(stepper.waitForValue("0"), "Got \(stepper.stringValue ?? "nil")")

        // At the lower bound − is refused (warning haptic and a wiggle), not applied.
        minus.tap()
        StageLauncher.settle()
        XCTAssertEqual(stepper.stringValue, "0", "A step past the lower bound moved the value.")

        plus.tap()
        XCTAssertTrue(stepper.waitForValue("1"), "Got \(stepper.stringValue ?? "nil")")
    }
}
