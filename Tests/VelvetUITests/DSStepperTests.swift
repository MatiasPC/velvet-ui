import XCTest
@testable import VelvetUI

/// Pins `DSStepper`'s arithmetic: clamping, refusals at the bounds, uneven
/// steps, guarded step sizes, out-of-range values and the reserved label width.
/// Doc snippets for DSStepper live in `DocSnippetsInputsTests`.
final class DSStepperTests: XCTestCase {
    // MARK: - Stepping inside the range

    func testStepMovesByDelta() {
        XCTAssertEqual(DSStepperLogic.outcome(value: 3, delta: 1, in: 0...99), .moved(to: 4))
        XCTAssertEqual(DSStepperLogic.outcome(value: 3, delta: -1, in: 0...99), .moved(to: 2))
        XCTAssertEqual(DSStepperLogic.outcome(value: 25, delta: 5, in: 0...100), .moved(to: 30))
    }

    func testNegativeRangesStep() {
        XCTAssertEqual(DSStepperLogic.outcome(value: -3, delta: -2, in: -10...10), .moved(to: -5))
        XCTAssertEqual(DSStepperLogic.outcome(value: -1, delta: 1, in: -10...10), .moved(to: 0))
    }

    // MARK: - Bounds

    func testUnevenStepClampsToTheBoundInsteadOfOvershooting() {
        // step 5 over 0...12: 10 + 5 lands on 12, not 15; 2 - 5 lands on 0, not -3.
        XCTAssertEqual(DSStepperLogic.outcome(value: 10, delta: 5, in: 0...12), .moved(to: 12))
        XCTAssertEqual(DSStepperLogic.outcome(value: 2, delta: -5, in: 0...12), .moved(to: 0))
    }

    func testStepAtABoundIsRefused() {
        XCTAssertEqual(DSStepperLogic.outcome(value: 99, delta: 1, in: 0...99), .refused)
        XCTAssertEqual(DSStepperLogic.outcome(value: 0, delta: -1, in: 0...99), .refused)
        XCTAssertEqual(DSStepperLogic.outcome(value: 12, delta: 5, in: 0...12), .refused)
    }

    func testSingleValueRangeRefusesBothWays() {
        XCTAssertEqual(DSStepperLogic.outcome(value: 4, delta: 1, in: 4...4), .refused)
        XCTAssertEqual(DSStepperLogic.outcome(value: 4, delta: -1, in: 4...4), .refused)
    }

    func testOutOfRangeValueSnapsToTheNearestBound() {
        // A binding that starts outside the range is pulled back in by the next step.
        XCTAssertEqual(DSStepperLogic.outcome(value: 150, delta: 1, in: 0...99), .moved(to: 99))
        XCTAssertEqual(DSStepperLogic.outcome(value: 0, delta: -1, in: 1...9), .moved(to: 1))
    }

    func testExtremeValuesDoNotOverflow() {
        XCTAssertEqual(DSStepperLogic.outcome(value: Int.max, delta: 1, in: 0...Int.max), .refused)
        XCTAssertEqual(DSStepperLogic.outcome(value: Int.min, delta: -1, in: Int.min...0), .refused)
        XCTAssertEqual(DSStepperLogic.outcome(value: Int.max - 1, delta: 5, in: 0...Int.max), .moved(to: Int.max))
    }

    // MARK: - Step size

    func testNonPositiveStepFallsBackToOne() {
        XCTAssertEqual(DSStepperLogic.effectiveStep(0), 1)
        XCTAssertEqual(DSStepperLogic.effectiveStep(-3), 1)
        XCTAssertEqual(DSStepperLogic.effectiveStep(1), 1)
        XCTAssertEqual(DSStepperLogic.effectiveStep(5), 5)
    }

    // MARK: - Reserved label width

    func testWidestValueStringIsTheLongerBound() {
        XCTAssertEqual(DSStepperLogic.widestValueString(in: 0...99), "99")
        XCTAssertEqual(DSStepperLogic.widestValueString(in: 0...100), "100")
        XCTAssertEqual(DSStepperLogic.widestValueString(in: -100...9), "-100")
        XCTAssertEqual(DSStepperLogic.widestValueString(in: 1...9), "1")
    }
}
