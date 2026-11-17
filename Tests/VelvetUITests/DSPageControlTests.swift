import XCTest
import SwiftUI
@testable import VelvetUI

/// Pins `DSPageControl`'s rules: page counts that used to trap or read "1 of 0",
/// out-of-range bindings, VoiceOver stepping, the 44 pt touch row, mapping a
/// tap to a page (left-to-right and right-to-left) and the Reduce Motion path.
/// Doc snippets for DSPageControl live in `DocSnippetsInputsTests`.
final class DSPageControlTests: XCTestCase {
    // Defaults: 8 pt dots, a 24 pt active capsule, 8 pt gaps.
    private let dot = DSSpacing.xs
    private let active = DSSpacing.xl
    private let gap = DSSpacing.xs

    private func page(atX x: CGFloat, current: Int, count: Int = 4, rightToLeft: Bool = false) -> Int? {
        DSPageControlLogic.page(
            atX: x, numberOfPages: count, currentPage: current,
            dotSize: dot, activeWidth: active, spacing: gap, rightToLeft: rightToLeft
        )
    }

    // MARK: - Page count

    func testNegativeCountDrawsNothing() {
        // `ForEach(0..<n)` traps for a negative n; the control now draws no dots.
        XCTAssertEqual(DSPageControlLogic.pageCount(-3), 0)
        XCTAssertEqual(DSPageControlLogic.pageCount(0), 0)
        XCTAssertEqual(DSPageControlLogic.pageCount(5), 5)
    }

    // MARK: - Displayed page

    func testOutOfRangeBindingShowsTheNearestPage() {
        XCTAssertEqual(DSPageControlLogic.displayedPage(-2, numberOfPages: 4), 0)
        XCTAssertEqual(DSPageControlLogic.displayedPage(9, numberOfPages: 4), 3)
        XCTAssertEqual(DSPageControlLogic.displayedPage(2, numberOfPages: 4), 2)
        XCTAssertEqual(DSPageControlLogic.displayedPage(1, numberOfPages: 0), 0)
    }

    // MARK: - VoiceOver value

    func testValueIsOneBasedAndClamped() {
        XCTAssertEqual(DSPageControlLogic.accessibilityValue(currentPage: 0, numberOfPages: 4), "1 of 4")
        XCTAssertEqual(DSPageControlLogic.accessibilityValue(currentPage: 3, numberOfPages: 4), "4 of 4")
        XCTAssertEqual(DSPageControlLogic.accessibilityValue(currentPage: 6, numberOfPages: 4), "4 of 4")
        XCTAssertEqual(DSPageControlLogic.accessibilityValue(currentPage: -1, numberOfPages: 4), "1 of 4")
    }

    func testNoPagesHasNoValue() {
        // Used to read "1 of 0"; the control is hidden from VoiceOver instead.
        XCTAssertEqual(DSPageControlLogic.accessibilityValue(currentPage: 0, numberOfPages: 0), "")
        XCTAssertEqual(DSPageControl.accessibilityValue(currentPage: 0, numberOfPages: -1), "")
    }

    // MARK: - VoiceOver stepping

    func testStepMovesOnePage() {
        XCTAssertEqual(DSPageControlLogic.step(from: 1, by: 1, numberOfPages: 4), 2)
        XCTAssertEqual(DSPageControlLogic.step(from: 1, by: -1, numberOfPages: 4), 0)
    }

    func testStepStopsAtTheEnds() {
        // nil: no write and no haptic past either end.
        XCTAssertNil(DSPageControlLogic.step(from: 3, by: 1, numberOfPages: 4))
        XCTAssertNil(DSPageControlLogic.step(from: 0, by: -1, numberOfPages: 4))
        XCTAssertNil(DSPageControlLogic.step(from: 0, by: 1, numberOfPages: 1))
        XCTAssertNil(DSPageControlLogic.step(from: 0, by: 1, numberOfPages: 0))
    }

    func testStepStartsFromTheDisplayedPage() {
        // A binding stuck at 9 of 4 pages reads "4 of 4"; swiping down goes to 3.
        XCTAssertEqual(DSPageControlLogic.step(from: 9, by: -1, numberOfPages: 4), 2)
        XCTAssertNil(DSPageControlLogic.step(from: 9, by: 1, numberOfPages: 4))
    }

    // MARK: - Tapping

    func testTapOnTheCurrentPageDoesNothing() {
        XCTAssertFalse(DSPageControlLogic.shouldSelect(2, current: 2))
        XCTAssertTrue(DSPageControlLogic.shouldSelect(1, current: 2))
    }

    func testTouchRowIsAtLeast44PointsTall() {
        XCTAssertEqual(DSPageControlLogic.minimumHitTarget, 44)
        // 8 pt dots get 18 pt above and below.
        XCTAssertEqual(DSPageControlLogic.verticalHitSlop(dotSize: dot), 18)
        XCTAssertEqual(dot + 2 * DSPageControlLogic.verticalHitSlop(dotSize: dot), 44)
        // Dots already that tall get none.
        XCTAssertEqual(DSPageControlLogic.verticalHitSlop(dotSize: 60), 0)
    }

    func testTapLandsOnTheDotUnderTheFinger() {
        // Page 0 active: [0, 24] gap [32, 40] gap [48, 56] gap [64, 72].
        XCTAssertEqual(page(atX: 12, current: 0), 0)
        XCTAssertEqual(page(atX: 36, current: 0), 1)
        XCTAssertEqual(page(atX: 52, current: 0), 2)
        XCTAssertEqual(page(atX: 68, current: 0), 3)
    }

    func testGapsSplitBetweenNeighbours() {
        // The gap between page 0 (ends at 24) and page 1 (starts at 32) splits at 28.
        XCTAssertEqual(page(atX: 27.9, current: 0), 0)
        XCTAssertEqual(page(atX: 28, current: 0), 1)
    }

    func testLayoutFollowsTheActiveCapsule() {
        // Page 2 active: [0, 8] gap [16, 24] gap [32, 56] gap [64, 72].
        XCTAssertEqual(page(atX: 4, current: 2), 0)
        XCTAssertEqual(page(atX: 20, current: 2), 1)
        XCTAssertEqual(page(atX: 44, current: 2), 2)
        XCTAssertEqual(page(atX: 68, current: 2), 3)
    }

    func testTouchesOutsideTheDotsGoToTheEnds() {
        XCTAssertEqual(page(atX: -4, current: 1), 0)
        XCTAssertEqual(page(atX: 200, current: 1), 3)
    }

    func testRightToLeftMirrorsTheMapping() {
        // Page 0 sits at the right edge in a right-to-left layout.
        XCTAssertEqual(page(atX: 68, current: 0, rightToLeft: true), 0)
        XCTAssertEqual(page(atX: 4, current: 0, rightToLeft: true), 3)
    }

    func testNoPagesMapsToNothing() {
        XCTAssertNil(page(atX: 0, current: 0, count: 0))
        XCTAssertEqual(page(atX: 100, current: 0, count: 1), 0)
    }

    // MARK: - Reduce Motion

    func testCapsuleSpringsOnlyWithoutReduceMotion() {
        XCTAssertEqual(DSPageControlLogic.animation(reduceMotion: false), DSAnimation.springSmooth)
        XCTAssertNil(DSPageControlLogic.animation(reduceMotion: true))
    }

    // MARK: - Construction

    @MainActor
    func testEdgeCountsBuild() {
        _ = EdgeCounts().body
    }
}

private struct EdgeCounts: View {
    @State private var page = 7

    var body: some View {
        VStack {
            DSPageControl(currentPage: $page, numberOfPages: -1)
            DSPageControl(currentPage: $page, numberOfPages: 0)
            DSPageControl(currentPage: $page, numberOfPages: 3, allowsTap: false)
        }
    }
}
