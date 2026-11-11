import XCTest
@testable import VelvetUI

/// Pins `DSCodeField`'s input rules: which characters count as digits, the
/// clamp to `length`, when a keystroke ticks, when `onComplete` fires, and the
/// guard on a zero or negative `length`. The VoiceOver value is also covered in
/// `AccessibilityTests`; doc snippets live in `DocSnippetsInputsTests`.
final class DSCodeFieldTests: XCTestCase {
    // MARK: - Sanitizing

    func testKeepsDigitsOnly() {
        XCTAssertEqual(DSCodeFieldLogic.sanitize("123-456", length: 6), "123456")
        XCTAssertEqual(DSCodeFieldLogic.sanitize(" 12 ab 3 ", length: 6), "123")
        XCTAssertEqual(DSCodeFieldLogic.sanitize("", length: 6), "")
        XCTAssertEqual(DSCodeFieldLogic.sanitize("abc", length: 6), "")
    }

    func testKeepsLeadingZeros() {
        XCTAssertEqual(DSCodeFieldLogic.sanitize("000123", length: 6), "000123")
    }

    func testClampsToLength() {
        XCTAssertEqual(DSCodeFieldLogic.sanitize("1234567", length: 6), "123456")
        XCTAssertEqual(DSCodeFieldLogic.sanitize("98765", length: 4), "9876")
    }

    func testDigitsFromOtherScriptsBecomeASCII() {
        // Arabic-Indic and fullwidth digits, as typed on those keyboards.
        XCTAssertEqual(DSCodeFieldLogic.sanitize("٤٢٨٥", length: 6), "4285")
        XCTAssertEqual(DSCodeFieldLogic.sanitize("１２３", length: 6), "123")
    }

    func testNumberLikeCharactersThatArentOneDigitAreDropped() {
        // `isNumber` accepts these; a code box can't show them.
        XCTAssertEqual(DSCodeFieldLogic.sanitize("1½2", length: 6), "12")
        XCTAssertEqual(DSCodeFieldLogic.sanitize("Ⅻ34", length: 6), "34")
    }

    // MARK: - Length guard

    func testBoxCountIsAtLeastOne() {
        XCTAssertEqual(DSCodeFieldLogic.boxCount(6), 6)
        XCTAssertEqual(DSCodeFieldLogic.boxCount(1), 1)
        XCTAssertEqual(DSCodeFieldLogic.boxCount(0), 1)
        XCTAssertEqual(DSCodeFieldLogic.boxCount(-3), 1)
    }

    func testNonPositiveLengthClampsToOneDigit() {
        XCTAssertEqual(DSCodeFieldLogic.sanitize("123", length: 0), "1")
        XCTAssertEqual(DSCodeFieldLogic.sanitize("123", length: -2), "1")
    }

    // MARK: - Haptic and completion

    func testTypingADigitTicks() {
        let change = DSCodeFieldLogic.change(from: "12", to: "123", length: 6)
        XCTAssertEqual(change, .init(haptic: true, completes: false))
    }

    func testDeletingIsSilent() {
        let change = DSCodeFieldLogic.change(from: "123", to: "12", length: 6)
        XCTAssertEqual(change, .init(haptic: false, completes: false))
    }

    func testTheLastDigitTicksAndCompletes() {
        let change = DSCodeFieldLogic.change(from: "12345", to: "123456", length: 6)
        XCTAssertEqual(change, .init(haptic: true, completes: true))
    }

    func testAutofillOfTheWholeCodeCompletesOnce() {
        let change = DSCodeFieldLogic.change(from: "", to: "428519", length: 6)
        XCTAssertEqual(change, .init(haptic: true, completes: true))
    }

    func testAnExtraKeystrokeOnAFullCodeDoesNotSubmitAgain() {
        // "123456" + "7" is clamped back to "123456": nothing new happened.
        let typed = DSCodeFieldLogic.sanitize("1234567", length: 6)
        let change = DSCodeFieldLogic.change(from: "123456", to: typed, length: 6)
        XCTAssertEqual(change, .init(haptic: false, completes: false))
    }

    func testRetypingTheLastDigitCompletesAgain() {
        XCTAssertFalse(DSCodeFieldLogic.change(from: "123456", to: "12345", length: 6).completes)
        XCTAssertTrue(DSCodeFieldLogic.change(from: "12345", to: "123459", length: 6).completes)
    }

    func testPastingADifferentFullCodeCompletes() {
        let change = DSCodeFieldLogic.change(from: "123456", to: "654321", length: 6)
        XCTAssertEqual(change, .init(haptic: false, completes: true))
    }

    func testOneBoxFieldCompletesOnTheFirstDigit() {
        XCTAssertTrue(DSCodeFieldLogic.change(from: "", to: "7", length: 0).completes)
    }

    // MARK: - VoiceOver value

    func testAccessibilityValueUsesTheGuardedLength() {
        XCTAssertEqual(DSCodeFieldLogic.accessibilityValue(code: "", length: 0, state: .normal), "0 of 1 digit")
        XCTAssertEqual(
            DSCodeFieldLogic.accessibilityValue(code: "42", length: 4, state: .error),
            "4 2, 2 of 4 digits, incorrect code"
        )
    }
}
