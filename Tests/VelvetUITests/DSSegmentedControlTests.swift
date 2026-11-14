import XCTest
import SwiftUI
@testable import VelvetUI

/// Pins `DSSegmentedControl`'s rules: duplicate values, the tap that changes
/// nothing, the VoiceOver position and the Reduce Motion path.
/// Doc snippets for DSSegmentedControl live in `DocSnippetsInputsTests`.
final class DSSegmentedControlTests: XCTestCase {
    // MARK: - Duplicate values

    func testUniqueValuesKeepEverySegment() {
        XCTAssertEqual(DSSegmentedControlLogic.uniqueIndices(of: ["Day", "Week", "Month"]), [0, 1, 2])
    }

    func testRepeatedValueKeepsTheFirstSegment() {
        XCTAssertEqual(DSSegmentedControlLogic.uniqueIndices(of: ["Day", "Week", "Day", "Month"]), [0, 1, 3])
        XCTAssertEqual(DSSegmentedControlLogic.uniqueIndices(of: [1, 1, 1]), [0])
    }

    func testNoSegmentsIsEmpty() {
        XCTAssertEqual(DSSegmentedControlLogic.uniqueIndices(of: [String]()), [])
    }

    // MARK: - Tapping

    func testTapOnAnotherSegmentSelects() {
        XCTAssertTrue(DSSegmentedControlLogic.shouldSelect("Week", current: "Day"))
    }

    func testTapOnTheSelectedSegmentDoesNothing() {
        // No selection write and no haptic on a tap that changes nothing.
        XCTAssertFalse(DSSegmentedControlLogic.shouldSelect("Day", current: "Day"))
    }

    // MARK: - VoiceOver

    func testPositionIsOneBased() {
        XCTAssertEqual(DSSegmentedControlLogic.accessibilityValue(index: 0, count: 3), "1 of 3")
        XCTAssertEqual(DSSegmentedControlLogic.accessibilityValue(index: 2, count: 3), "3 of 3")
        XCTAssertEqual(DSSegmentedControlLogic.accessibilityValue(index: 0, count: 1), "1 of 1")
    }

    // MARK: - Reduce Motion

    func testIndicatorSlidesOnlyWithoutReduceMotion() {
        XCTAssertTrue(DSSegmentedControlLogic.slidesIndicator(reduceMotion: false))
        XCTAssertFalse(DSSegmentedControlLogic.slidesIndicator(reduceMotion: true))
    }

    // MARK: - Construction

    @MainActor
    func testDuplicateSegmentsBuild() {
        // A repeated value used to hand ForEach two identical IDs; init now drops it.
        _ = DuplicateOptions().body
    }
}

private struct DuplicateOptions: View {
    @State private var period = "Day"

    var body: some View {
        DSSegmentedControl(selection: $period, options: ["Day", "Week", "Day"])
    }
}
