import XCTest
@testable import VelvetUI

/// The value mapping behind `DSSlider`: clamping, snapping, touch → value, the
/// VoiceOver step and the spoken value. All of it lives in `DSSliderScale`, which
/// holds no view state, so it can be tested without rendering.
final class DSSliderTests: XCTestCase {

    private let unit = DSSliderScale(bounds: 0...1)
    private let price = DSSliderScale(bounds: 0...500, step: 25)
    private let signed = DSSliderScale(bounds: -10...10, step: 0.5)
    private let offset = DSSliderScale(bounds: 20...30)

    private let en = Locale(identifier: "en_US")

    // MARK: - Clamping

    func testClampsIntoBounds() {
        XCTAssertEqual(unit.clamped(-3), 0)
        XCTAssertEqual(unit.clamped(0.4), 0.4)
        XCTAssertEqual(unit.clamped(7), 1)
        XCTAssertEqual(signed.clamped(-99), -10)
        XCTAssertEqual(signed.clamped(99), 10)
        XCTAssertEqual(offset.clamped(5), 20)
        XCTAssertEqual(offset.clamped(35), 30)
    }

    func testNaNFallsBackToTheLowerBound() {
        XCTAssertEqual(unit.clamped(.nan), 0)
        XCTAssertEqual(signed.clamped(.nan), -10)
        XCTAssertEqual(unit.snapped(.nan), 0)
    }

    func testInfinityClampsToTheBounds() {
        XCTAssertEqual(unit.clamped(.infinity), 1)
        XCTAssertEqual(unit.clamped(-.infinity), 0)
    }

    func testSnappingNeverEscapesBounds() {
        for raw in stride(from: -50.0, through: 550.0, by: 7.3) {
            let snapped = price.snapped(raw)
            XCTAssertGreaterThanOrEqual(snapped, 0)
            XCTAssertLessThanOrEqual(snapped, 500)
        }
    }

    // MARK: - Step normalisation

    func testNonPositiveOrNonFiniteStepIsContinuous() {
        XCTAssertNil(DSSliderScale(bounds: 0...1, step: 0).step)
        XCTAssertNil(DSSliderScale(bounds: 0...1, step: -0.25).step)
        XCTAssertNil(DSSliderScale(bounds: 0...1, step: .nan).step)
        XCTAssertNil(DSSliderScale(bounds: 0...1, step: .infinity).step)
        XCTAssertNil(DSSliderScale(bounds: 0...1, step: nil).step)
        XCTAssertEqual(DSSliderScale(bounds: 0...1, step: 0.1).step, 0.1)
    }

    func testContinuousScaleDoesNotSnap() {
        XCTAssertEqual(unit.snapped(0.123456), 0.123456)
        XCTAssertEqual(DSSliderScale(bounds: 0...1, step: 0).snapped(0.5001), 0.5001)
    }

    // MARK: - Snapping

    func testSnapsToTheNearestNotch() {
        XCTAssertEqual(price.snapped(0), 0)
        XCTAssertEqual(price.snapped(12), 0)
        XCTAssertEqual(price.snapped(13), 25)
        XCTAssertEqual(price.snapped(149), 150)
        XCTAssertEqual(price.snapped(162), 150)
        XCTAssertEqual(price.snapped(163), 175)
        XCTAssertEqual(price.snapped(500), 500)
    }

    func testSnapsFromTheLowerBoundNotFromZero() {
        let scale = DSSliderScale(bounds: 3...20, step: 5)   // 3 8 13 18, then the bound 20
        XCTAssertEqual(scale.snapped(3), 3)
        XCTAssertEqual(scale.snapped(5), 3)
        XCTAssertEqual(scale.snapped(6), 8)
        XCTAssertEqual(scale.snapped(13), 13)
        XCTAssertEqual(scale.snapped(18.4), 18)
        XCTAssertEqual(scale.snapped(19.5), 20)
    }

    func testSnapsFractionalStepsWithoutDrift() {
        XCTAssertEqual(signed.snapped(0.26), 0.5)
        XCTAssertEqual(signed.snapped(0.24), 0)
        XCTAssertEqual(signed.snapped(-9.8), -10)
        XCTAssertEqual(signed.snapped(-9.6), -9.5)
        XCTAssertEqual(signed.snapped(9.9), 10)
    }

    func testUpperBoundIsReachableWhenStepDoesNotDivideTheRange() {
        let scale = DSSliderScale(bounds: 0...10, step: 3)   // 0 3 6 9, then the bound 10
        XCTAssertEqual(scale.snapped(10), 10)
        XCTAssertEqual(scale.snapped(9.6), 10)
        XCTAssertEqual(scale.snapped(9.4), 9)
        XCTAssertEqual(scale.snapped(9), 9)
        XCTAssertEqual(scale.snapped(100), 10)
    }

    func testStepLargerThanTheRangeLeavesJustTheTwoEnds() {
        let scale = DSSliderScale(bounds: 0...1, step: 5)
        XCTAssertEqual(scale.snapped(0.2), 0)
        XCTAssertEqual(scale.snapped(0.8), 1)
    }

    func testFloatingPointStepDoesNotProduceNearDuplicateEnds() {
        let scale = DSSliderScale(bounds: 0...0.7, step: 0.1)
        XCTAssertEqual(scale.snapped(0.7), 0.7)
        XCTAssertEqual(scale.snapped(0.69), 0.7)
        XCTAssertEqual(scale.snapped(0.31), 0.30000000000000004, accuracy: 1e-12)
    }

    // MARK: - Position <-> value

    func testFractionMapsTheRangeOntoZeroToOne() {
        XCTAssertEqual(unit.fraction(of: 0), 0)
        XCTAssertEqual(unit.fraction(of: 0.25), 0.25)
        XCTAssertEqual(unit.fraction(of: 1), 1)
        XCTAssertEqual(price.fraction(of: 125), 0.25)
        XCTAssertEqual(signed.fraction(of: 0), 0.5)
        XCTAssertEqual(offset.fraction(of: 25), 0.5)
    }

    func testFractionClampsOutOfRangeValues() {
        XCTAssertEqual(unit.fraction(of: -4), 0)
        XCTAssertEqual(unit.fraction(of: 12), 1)
        XCTAssertEqual(offset.fraction(of: 5), 0)
        XCTAssertEqual(offset.fraction(of: 99), 1)
    }

    func testSingleValueRangeHasNoTravel() {
        let flat = DSSliderScale(bounds: 5...5, step: 1)
        XCTAssertEqual(flat.span, 0)
        XCTAssertEqual(flat.fraction(of: 5), 0)
        XCTAssertEqual(flat.value(atFraction: 0.7), 5)
        XCTAssertEqual(flat.clamped(9), 5)
    }

    func testValueAtFractionStaysOnTheScale() {
        for scale in [unit, price, signed, offset] {
            for fraction in stride(from: 0.0, through: 1.0, by: 0.125) {
                let value = scale.value(atFraction: fraction)
                XCTAssertGreaterThanOrEqual(value, scale.lower)
                XCTAssertLessThanOrEqual(value, scale.upper)
                XCTAssertEqual(scale.snapped(value), value, "A mapped value is already on a notch")
                // Mapping back lands within one notch of where it started.
                let tolerance = (scale.step ?? 0) / scale.span / 2 + 1e-12
                XCTAssertEqual(scale.fraction(of: value), fraction, accuracy: tolerance)
            }
        }
        XCTAssertEqual(unit.value(atFraction: 0.3), 0.3, accuracy: 1e-12)
        XCTAssertEqual(offset.value(atFraction: 0.3), 23, accuracy: 1e-12)
        XCTAssertEqual(price.value(atFraction: 0.3), 150)
        XCTAssertEqual(signed.value(atFraction: 0.75), 5)
    }

    func testValueAtFractionClampsFractionsOutsideTheTrack() {
        XCTAssertEqual(unit.value(atFraction: -2), 0)
        XCTAssertEqual(unit.value(atFraction: 3), 1)
        XCTAssertEqual(unit.value(atFraction: .nan), 0)
    }

    // MARK: - Touch mapping

    /// The knob's centre travels the track inset by the knob radius at each end,
    /// so a finger on the knob's centre and the value it reports agree.
    func testTouchMappingInsetsByTheKnobRadius() {
        let width: CGFloat = 300
        let knob: CGFloat = 28
        func value(_ x: CGFloat) -> Double? {
            unit.value(atX: x, trackWidth: width, knobDiameter: knob)
        }
        XCTAssertEqual(value(14), 0)                 // knob centre flush-leading
        XCTAssertEqual(value(300 - 14), 1)           // knob centre flush-trailing
        XCTAssertEqual(try XCTUnwrap(value(150)), 0.5, accuracy: 1e-12)   // dead centre
    }

    func testTouchBeyondTheTrackClamps() {
        XCTAssertEqual(unit.value(atX: -500, trackWidth: 300, knobDiameter: 28), 0)
        XCTAssertEqual(unit.value(atX: 0, trackWidth: 300, knobDiameter: 28), 0)
        XCTAssertEqual(unit.value(atX: 300, trackWidth: 300, knobDiameter: 28), 1)
        XCTAssertEqual(unit.value(atX: 9000, trackWidth: 300, knobDiameter: 28), 1)
    }

    func testTouchMappingUsesTheCustomRangeAndStep() {
        XCTAssertEqual(price.value(atX: 150, trackWidth: 300, knobDiameter: 28), 250)
        XCTAssertEqual(price.value(atX: 14 + 272 * 0.31, trackWidth: 300, knobDiameter: 28), 150)
        XCTAssertEqual(signed.value(atX: 150, trackWidth: 300, knobDiameter: 28), 0)
        XCTAssertEqual(offset.value(atX: 286, trackWidth: 300, knobDiameter: 28), 30)
    }

    func testTouchMappingNeedsAMeasuredTrack() {
        XCTAssertNil(unit.value(atX: 10, trackWidth: 0, knobDiameter: 28), "Before the track is measured")
        XCTAssertNil(unit.value(atX: 10, trackWidth: 28, knobDiameter: 28), "No room to travel")
        XCTAssertNil(unit.value(atX: 10, trackWidth: 20, knobDiameter: 28), "Narrower than the knob")
    }

    // MARK: - VoiceOver adjustment

    func testContinuousAdjustmentMovesATenthOfTheRange() {
        XCTAssertEqual(unit.adjusted(0.5, direction: 1), 0.6, accuracy: 1e-12)
        XCTAssertEqual(unit.adjusted(0.5, direction: -1), 0.4, accuracy: 1e-12)
        XCTAssertEqual(offset.adjusted(25, direction: 1), 26, accuracy: 1e-12)
        XCTAssertEqual(DSSliderScale(bounds: 0...200).adjusted(100, direction: -1), 80, accuracy: 1e-12)
    }

    func testAdjustmentStopsAtTheBounds() {
        XCTAssertEqual(unit.adjusted(0.95, direction: 1), 1)
        XCTAssertEqual(unit.adjusted(1, direction: 1), 1)
        XCTAssertEqual(unit.adjusted(0.02, direction: -1), 0)
        XCTAssertEqual(unit.adjusted(0, direction: -1), 0)
        XCTAssertEqual(price.adjusted(500, direction: 1), 500)
        XCTAssertEqual(price.adjusted(0, direction: -1), 0)
    }

    func testSteppedAdjustmentMovesOneNotch() {
        XCTAssertEqual(price.adjusted(150, direction: 1), 175)
        XCTAssertEqual(price.adjusted(150, direction: -1), 125)
        XCTAssertEqual(signed.adjusted(0, direction: 1), 0.5)
        XCTAssertEqual(signed.adjusted(0, direction: -1), -0.5)
    }

    /// A value that is not on a notch moves to the next notch in that direction,
    /// never past it (the bug of "value + step, then round").
    func testSteppedAdjustmentFromBetweenNotchesLandsOnTheNextOne() {
        XCTAssertEqual(price.adjusted(140, direction: 1), 150)
        XCTAssertEqual(price.adjusted(140, direction: -1), 125)
        XCTAssertEqual(price.adjusted(137, direction: 1), 150)
        XCTAssertEqual(price.adjusted(137, direction: -1), 125)
    }

    func testSteppedAdjustmentReachesAnUnalignedUpperBound() {
        let scale = DSSliderScale(bounds: 0...10, step: 3)
        XCTAssertEqual(scale.adjusted(9, direction: 1), 10)
        XCTAssertEqual(scale.adjusted(10, direction: 1), 10)
        XCTAssertEqual(scale.adjusted(10, direction: -1), 9)
        XCTAssertEqual(scale.adjusted(9, direction: -1), 6)
    }

    func testAdjustingEveryNotchWalksTheWholeScale() {
        var value = price.lower
        var visited = [value]
        while true {
            let next = price.adjusted(value, direction: 1)
            if next == value { break }
            value = next
            visited.append(value)
        }
        XCTAssertEqual(visited.count, 21)   // 0, 25 ... 500
        XCTAssertEqual(visited.last, 500)
    }

    // MARK: - Feedback helpers

    func testBoundDetection() {
        XCTAssertTrue(unit.isAtBound(0))
        XCTAssertTrue(unit.isAtBound(1))
        XCTAssertTrue(unit.isAtBound(1 - 1e-12))
        XCTAssertFalse(unit.isAtBound(0.001))
        XCTAssertFalse(unit.isAtBound(0.5))
        XCTAssertTrue(price.isAtBound(500))
        XCTAssertFalse(price.isAtBound(475))
        // Relative to the range, not absolute: a tiny range still has a middle.
        let tiny = DSSliderScale(bounds: 0...0.001)
        XCTAssertFalse(tiny.isAtBound(0.0005))
        XCTAssertTrue(tiny.isAtBound(0.001))
    }

    // MARK: - Spoken value

    func testDefaultRangeReadsAsAPercentage() {
        XCTAssertEqual(unit.accessibilityValue(0, locale: en), "0 percent")
        XCTAssertEqual(unit.accessibilityValue(0.604, locale: en), "60 percent")
        XCTAssertEqual(unit.accessibilityValue(1, locale: en), "100 percent")
    }

    func testOtherRangesReadTheValueItself() {
        XCTAssertEqual(price.accessibilityValue(150, locale: en), "150")
        XCTAssertEqual(offset.accessibilityValue(23.456, locale: en), "23.46")
        XCTAssertEqual(offset.accessibilityValue(25, locale: en), "25")
        XCTAssertEqual(DSSliderScale(bounds: 0...100).accessibilityValue(42.5, locale: en), "42.5")
    }

    func testSteppedValueUsesJustTheDecimalsTheStepNeeds() {
        XCTAssertEqual(signed.accessibilityValue(-2.5, locale: en), "-2.5")
        XCTAssertEqual(signed.accessibilityValue(3, locale: en), "3")
        XCTAssertEqual(DSSliderScale(bounds: 0...1, step: 0.25).accessibilityValue(0.75, locale: en), "0.75")
        XCTAssertEqual(DSSliderScale(bounds: 0...1, step: 0.1).accessibilityValue(0.3, locale: en), "0.3")
    }

    /// A stepped slider over 0...1 reads the value, not a percentage, because
    /// its notches are values (a 0.25 step reads 0.25, 0.5, 0.75).
    func testSteppedUnitRangeIsNotAPercentage() {
        XCTAssertEqual(DSSliderScale(bounds: 0...1, step: 0.25).accessibilityValue(0.5, locale: en), "0.5")
    }

    func testSpokenValueIsClamped() {
        XCTAssertEqual(unit.accessibilityValue(4, locale: en), "100 percent")
        XCTAssertEqual(price.accessibilityValue(-30, locale: en), "0")
    }
}
