import XCTest
import CoreGraphics
@testable import VelvetUI

/// The rules behind `DSExpandableText`: the line limit actually used, when copy
/// counts as truncated (which is the only time the toggle appears) and how tall
/// the clipped frame is in each state.
final class DSExpandableTextTests: XCTestCase {

    // MARK: - Line limit

    func testLineLimitBelowOneMeansOneLine() {
        XCTAssertEqual(DSExpandableTextLayout.lines(for: 0), 1)
        XCTAssertEqual(DSExpandableTextLayout.lines(for: -4), 1)
    }

    func testLineLimitAboveZeroIsKept() {
        XCTAssertEqual(DSExpandableTextLayout.lines(for: 1), 1)
        XCTAssertEqual(DSExpandableTextLayout.lines(for: 3), 3)
        XCTAssertEqual(DSExpandableTextLayout.lines(for: 12), 12)
    }

    // MARK: - Truncation (toggle visibility)

    func testCopyTallerThanTheClampIsTruncated() {
        XCTAssertTrue(DSExpandableTextLayout.isTruncated(collapsedHeight: 60, fullHeight: 140))
    }

    func testCopyThatFitsHasNoToggle() {
        XCTAssertFalse(DSExpandableTextLayout.isTruncated(collapsedHeight: 60, fullHeight: 60))
        XCTAssertFalse(DSExpandableTextLayout.isTruncated(collapsedHeight: 40, fullHeight: 40))
    }

    func testLayoutRoundingBelowTheToleranceIsNotTruncation() {
        XCTAssertFalse(DSExpandableTextLayout.isTruncated(collapsedHeight: 60, fullHeight: 60.3))
        XCTAssertTrue(DSExpandableTextLayout.isTruncated(collapsedHeight: 60, fullHeight: 61))
    }

    func testNothingMeasuredYetIsNotTruncated() {
        XCTAssertFalse(DSExpandableTextLayout.isTruncated(collapsedHeight: 0, fullHeight: 0))
    }

    // MARK: - Reveal height

    func testHeightIsUnconstrainedUntilBothProbesHaveMeasured() {
        XCTAssertNil(DSExpandableTextLayout.revealHeight(isExpanded: false, collapsedHeight: 0, fullHeight: 0))
        XCTAssertNil(DSExpandableTextLayout.revealHeight(isExpanded: true, collapsedHeight: 60, fullHeight: 0))
        XCTAssertNil(DSExpandableTextLayout.revealHeight(isExpanded: false, collapsedHeight: 0, fullHeight: 140))
    }

    func testCollapsedHoldsTheClampHeightAndExpandedTheFullHeight() {
        XCTAssertEqual(DSExpandableTextLayout.revealHeight(isExpanded: false, collapsedHeight: 60, fullHeight: 140), 60)
        XCTAssertEqual(DSExpandableTextLayout.revealHeight(isExpanded: true, collapsedHeight: 60, fullHeight: 140), 140)
    }

    func testShortCopyHasTheSameHeightInBothStates() {
        XCTAssertEqual(DSExpandableTextLayout.revealHeight(isExpanded: false, collapsedHeight: 40, fullHeight: 40), 40)
        XCTAssertEqual(DSExpandableTextLayout.revealHeight(isExpanded: true, collapsedHeight: 40, fullHeight: 40), 40)
    }
}
