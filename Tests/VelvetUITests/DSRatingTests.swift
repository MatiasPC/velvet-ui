import XCTest
@testable import VelvetUI

/// Pins `DSRating`'s logic: the touch-to-value mapping, VoiceOver steps on the
/// `step` grid, clamping, the per-star selection tick, the Reduce Motion pop and
/// the VoiceOver value format. Doc snippets for DSRating live in
/// `DocSnippetsInputsTests`; the basic value format in `AccessibilityTests`.
final class DSRatingTests: XCTestCase {
    // Default interactive geometry: 28 pt stars, 8 pt gaps, so one star is 36 pt.
    private let size = 28.0
    private let gap = 8.0
    private var cell: Double { size + gap }

    private func value(atX x: Double, step: Double = 1, count: Int = 5) -> Double {
        DSRatingLogic.value(atX: x, size: size, spacing: gap, step: step, count: count)
    }

    // MARK: - Touch to value

    func testWholeStarsRateTheTouchedStar() {
        XCTAssertEqual(value(atX: 10), 1)
        XCTAssertEqual(value(atX: cell * 3 + 5), 4)
        XCTAssertEqual(value(atX: cell * 2), 3, "The leading edge of star 3 rates 3.")
        XCTAssertEqual(value(atX: cell * 4 + size - 1), 5)
    }

    func testHalfStepsSplitEachStar() {
        XCTAssertEqual(value(atX: cell * 2 + 5, step: 0.5), 2.5, "Left half of star 3.")
        XCTAssertEqual(value(atX: cell * 2 + 20, step: 0.5), 3, "Right half of star 3.")
        XCTAssertEqual(value(atX: 0, step: 0.5), 0.5)
    }

    func testOtherStepsSnapToTheirOwnGrid() {
        // Documented as "the value snaps to step": quarters snap to quarters.
        XCTAssertEqual(value(atX: cell + 5, step: 0.25), 1.25)
        XCTAssertEqual(value(atX: cell * 0.25, step: 0.1), 0.3, "Floating-point noise is rounded away.")
    }

    func testTouchesOutsideTheRowClamp() {
        XCTAssertEqual(value(atX: -20), 1, "Never below one step.")
        XCTAssertEqual(value(atX: -20, step: 0.5), 0.5)
        XCTAssertEqual(value(atX: 1_000), 5, "Never above count.")
        XCTAssertEqual(value(atX: 1_000, count: 1), 1)
    }

    func testDegenerateGeometryFallsBackToOneStep() {
        XCTAssertEqual(DSRatingLogic.value(atX: 50, size: 0, spacing: 0, step: 1, count: 5), 1)
        XCTAssertEqual(value(atX: .nan, step: 0.5), 0.5)
    }

    // MARK: - VoiceOver steps

    func testAdjustMovesOneStep() {
        XCTAssertEqual(DSRatingLogic.adjusted(3, .increment, step: 1, count: 5), 4)
        XCTAssertEqual(DSRatingLogic.adjusted(3, .decrement, step: 1, count: 5), 2)
        XCTAssertEqual(DSRatingLogic.adjusted(2.5, .increment, step: 0.5, count: 5), 3)
        XCTAssertEqual(DSRatingLogic.adjusted(2.5, .decrement, step: 0.5, count: 5), 2)
    }

    func testAdjustSnapsAnOffGridValueOntoTheGrid() {
        // Before: 2.3 + 1 read "3.3 out of 5 stars", a value a drag can never produce.
        XCTAssertEqual(DSRatingLogic.adjusted(2.3, .increment, step: 1, count: 5), 3)
        XCTAssertEqual(DSRatingLogic.adjusted(2.3, .decrement, step: 1, count: 5), 2)
        XCTAssertEqual(DSRatingLogic.adjusted(0.3, .increment, step: 0.1, count: 5), 0.4)
        XCTAssertEqual(DSRatingLogic.adjusted(0.3, .decrement, step: 0.1, count: 5), 0.2)
    }

    func testAdjustStopsAtTheBounds() {
        XCTAssertEqual(DSRatingLogic.adjusted(5, .increment, step: 1, count: 5), 5)
        XCTAssertEqual(DSRatingLogic.adjusted(0, .decrement, step: 1, count: 5), 0, "VoiceOver can clear a rating.")
        XCTAssertEqual(DSRatingLogic.adjusted(4.9, .increment, step: 0.3, count: 5), 5)
    }

    func testAdjustPullsAnOutOfRangeValueBackIn() {
        XCTAssertEqual(DSRatingLogic.adjusted(7, .decrement, step: 1, count: 5), 4)
        XCTAssertEqual(DSRatingLogic.adjusted(-2, .increment, step: 1, count: 5), 1)
        XCTAssertEqual(DSRatingLogic.adjusted(.nan, .increment, step: 1, count: 5), 1)
    }

    // MARK: - Guards

    func testStepIsGuarded() {
        XCTAssertEqual(DSRatingLogic.effectiveStep(0), 1)
        XCTAssertEqual(DSRatingLogic.effectiveStep(-1), 1)
        XCTAssertEqual(DSRatingLogic.effectiveStep(.nan), 1)
        XCTAssertEqual(DSRatingLogic.effectiveStep(0.5), 0.5)
        XCTAssertEqual(DSRatingLogic.effectiveStep(2), 1)
    }

    func testClampKeepsTheValueInRange() {
        XCTAssertEqual(DSRatingLogic.clamped(-1, count: 5), 0)
        XCTAssertEqual(DSRatingLogic.clamped(6, count: 5), 5)
        XCTAssertEqual(DSRatingLogic.clamped(3.5, count: 5), 3.5)
        XCTAssertEqual(DSRatingLogic.clamped(.nan, count: 5), 0)
    }

    // MARK: - Fill and the active star

    func testFillFractions() {
        XCTAssertEqual(DSRatingLogic.fillFraction(for: 2, value: 3.5), 1)
        XCTAssertEqual(DSRatingLogic.fillFraction(for: 3, value: 3.5), 0.5)
        XCTAssertEqual(DSRatingLogic.fillFraction(for: 4, value: 3.5), 0)
        XCTAssertEqual(DSRatingLogic.fillFraction(for: 0, value: .nan), 0)
    }

    func testActiveStarIsTheTopLitStar() {
        XCTAssertEqual(DSRatingLogic.activeStar(for: 0), -1)
        XCTAssertEqual(DSRatingLogic.activeStar(for: 0.5), 0)
        XCTAssertEqual(DSRatingLogic.activeStar(for: 1), 0)
        XCTAssertEqual(DSRatingLogic.activeStar(for: 3.5), 3)
        XCTAssertEqual(DSRatingLogic.activeStar(for: 4), 3)
    }

    // MARK: - Haptic beat

    func testTickFiresOnEnteringAStar() {
        XCTAssertTrue(DSRatingLogic.shouldTick(from: nil, to: 1), "The first touch ticks.")
        XCTAssertTrue(DSRatingLogic.shouldTick(from: 1, to: 2))
        XCTAssertTrue(DSRatingLogic.shouldTick(from: 3, to: 3.5), "Half of star 4 lights: the finger entered it.")
        XCTAssertTrue(DSRatingLogic.shouldTick(from: 3.5, to: 3), "Back out of star 4.")
    }

    func testTickIsSilentInsideOneStar() {
        // Before, the tick fired on 2.5 → 3, mid-star, and not on entering star 4.
        XCTAssertFalse(DSRatingLogic.shouldTick(from: 2.5, to: 3))
        XCTAssertFalse(DSRatingLogic.shouldTick(from: 3, to: 2.5))
        XCTAssertFalse(DSRatingLogic.shouldTick(from: 3, to: 3))
    }

    // MARK: - Reduce Motion

    func testActiveStarPopsUnlessReduceMotion() {
        XCTAssertEqual(DSRatingLogic.popScale(isActive: true, reduceMotion: false), DSRatingLogic.activeScale)
        XCTAssertGreaterThan(DSRatingLogic.activeScale, 1)
        XCTAssertEqual(DSRatingLogic.popScale(isActive: true, reduceMotion: true), 1)
        XCTAssertEqual(DSRatingLogic.popScale(isActive: false, reduceMotion: false), 1)
    }

    // MARK: - VoiceOver value

    func testValueFormat() {
        XCTAssertEqual(DSRatingLogic.formatted(3), "3")
        XCTAssertEqual(DSRatingLogic.formatted(10), "10")
        XCTAssertEqual(DSRatingLogic.formatted(0), "0")
        XCTAssertEqual(DSRatingLogic.formatted(-0.0), "0")
        XCTAssertEqual(DSRatingLogic.formatted(2.5), "2.5")
        XCTAssertEqual(DSRatingLogic.formatted(2.25), "2.25")
        XCTAssertEqual(DSRatingLogic.formatted(4.333), "4.33")
        XCTAssertEqual(DSRatingLogic.formatted(0.1 * 3), "0.3")
    }

    func testAccessibilityValueReadsWhatIsDrawn() {
        XCTAssertEqual(DSRating.accessibilityValue(rating: 7, count: 5), "5 out of 5 stars")
        XCTAssertEqual(DSRating.accessibilityValue(rating: -1, count: 5), "0 out of 5 stars")
        XCTAssertEqual(DSRating.accessibilityValue(rating: 2.25, count: 5), "2.25 out of 5 stars")
        XCTAssertEqual(DSRating.accessibilityValue(rating: 4.5, count: 10), "4.5 out of 10 stars")
    }
}
