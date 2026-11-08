import XCTest

/// DSKeypad on its stage (an en_US amount: two decimals, at most 7 digits). The
/// read-out above the pad is one accessibility element, "Amount", whose value is
/// the raw text the keys build, so every assertion reads what a VoiceOver user
/// would hear after each key.
final class DSKeypadUITests: XCTestCase {
    @MainActor
    func testKeysBuildAnAmountAndRefuseWhatWouldBreakIt() {
        let app = StageLauncher.launch("DSKeypad")
        let amount = app.element("Amount")
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        XCTAssertEqual(amount.stringValue, "0")

        // Keys are labelled with their digit, "Decimal point" and "Delete". They carry
        // the keyboard-key trait, which can surface them as keys rather than buttons,
        // so match the label on any element type.
        func key(_ label: String) -> XCUIElement {
            app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
        }
        XCTAssertTrue(key("7").waitForExistence(timeout: 5))

        // A leading zero is replaced, not kept: "0" then "5" reads "5".
        key("0").tap()
        XCTAssertTrue(amount.waitForValue("0"), "Got \(amount.stringValue ?? "nil")")
        key("5").tap()
        XCTAssertTrue(amount.waitForValue("5"), "Got \(amount.stringValue ?? "nil")")

        key("2").tap()
        key("Decimal point").tap()
        XCTAssertTrue(amount.waitForValue("52."), "Got \(amount.stringValue ?? "nil")")

        // A second separator is refused.
        key("Decimal point").tap()
        StageLauncher.settle()
        XCTAssertEqual(amount.stringValue, "52.", "A second decimal point was accepted.")

        key("4").tap()
        key("9").tap()
        XCTAssertTrue(amount.waitForValue("52.49"), "Got \(amount.stringValue ?? "nil")")

        // A third decimal is refused.
        key("1").tap()
        StageLauncher.settle()
        XCTAssertEqual(amount.stringValue, "52.49", "A third decimal was accepted.")

        StageLauncher.attachScreenshot(app, named: "DSKeypad · $52.49", to: self)

        // Delete walks back one character at a time, separator included.
        key("Delete").tap()
        XCTAssertTrue(amount.waitForValue("52.4"), "Got \(amount.stringValue ?? "nil")")
        key("Delete").tap()
        key("Delete").tap()
        XCTAssertTrue(amount.waitForValue("52"), "Got \(amount.stringValue ?? "nil")")
        key("Delete").tap()
        key("Delete").tap()
        XCTAssertTrue(amount.waitForValue("0"), "Got \(amount.stringValue ?? "nil")")

        // Delete on empty is refused and leaves it empty.
        key("Delete").tap()
        StageLauncher.settle()
        XCTAssertEqual(amount.stringValue, "0")
    }
}
