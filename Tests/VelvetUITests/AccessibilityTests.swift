import XCTest
@testable import VelvetUI

final class AccessibilityTests: XCTestCase {
    func testToggleValue() {
        XCTAssertEqual(DSToggle.accessibilityValue(isOn: true), "On")
        XCTAssertEqual(DSToggle.accessibilityValue(isOn: false), "Off")
    }

    func testRatingValue() {
        XCTAssertEqual(DSRating.accessibilityValue(rating: 3, count: 5), "3 out of 5 stars")
        XCTAssertEqual(DSRating.accessibilityValue(rating: 2.5, count: 5), "2.5 out of 5 stars")
        XCTAssertEqual(DSRating.accessibilityValue(rating: 0, count: 5), "0 out of 5 stars")
    }

    func testPageControlValueIsOneBased() {
        XCTAssertEqual(DSPageControl.accessibilityValue(currentPage: 0, numberOfPages: 4), "1 of 4")
        XCTAssertEqual(DSPageControl.accessibilityValue(currentPage: 3, numberOfPages: 4), "4 of 4")
    }

    func testPageControlClamping() {
        XCTAssertEqual(DSPageControl.clampedPage(-1, numberOfPages: 4), 0)
        XCTAssertEqual(DSPageControl.clampedPage(4, numberOfPages: 4), 3)
        XCTAssertEqual(DSPageControl.clampedPage(2, numberOfPages: 4), 2)
        XCTAssertEqual(DSPageControl.clampedPage(1, numberOfPages: 0), 0)
    }

    func testToastLabels() {
        XCTAssertEqual(DSToast.accessibilityLabel(message: "Saved", type: .success), "Success: Saved")
        XCTAssertEqual(DSToast.accessibilityLabel(message: "Failed", type: .error), "Error: Failed")
        XCTAssertEqual(DSToast.accessibilityLabel(message: "Low", type: .warning), "Warning: Low")
        XCTAssertEqual(DSToast.accessibilityLabel(message: "FYI", type: .info), "Info: FYI")
    }

    func testCodeFieldValue() {
        XCTAssertEqual(DSCodeField.accessibilityValue(code: "", length: 6, state: .normal), "0 of 6 digits")
        XCTAssertEqual(DSCodeField.accessibilityValue(code: "123", length: 6, state: .normal), "1 2 3, 3 of 6 digits")
        XCTAssertEqual(DSCodeField.accessibilityValue(code: "1234", length: 4, state: .error), "1 2 3 4, 4 of 4 digits, incorrect code")
        XCTAssertEqual(DSCodeField.accessibilityValue(code: "1234", length: 4, state: .success), "1 2 3 4, 4 of 4 digits, verified")
    }

    func testSlideValue() {
        XCTAssertEqual(DSSlideToConfirm.accessibilityValue(isProcessing: false, isConfirmed: false, confirmedLabel: "Paid"), "")
        XCTAssertEqual(DSSlideToConfirm.accessibilityValue(isProcessing: true, isConfirmed: false, confirmedLabel: "Paid"), "Processing")
        XCTAssertEqual(DSSlideToConfirm.accessibilityValue(isProcessing: false, isConfirmed: true, confirmedLabel: "Paid"), "Paid")
        XCTAssertEqual(DSSlideToConfirm.accessibilityHint, "Double-tap to confirm")
    }
}
