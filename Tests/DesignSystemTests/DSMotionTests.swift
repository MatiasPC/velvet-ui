import XCTest
import SwiftUI
@testable import DesignSystem

@MainActor
final class DSMotionTests: XCTestCase {

    // MARK: - Reduce Motion

    /// The contract every ambient effect relies on: with Reduce Motion on,
    /// `loop` hands back `nil`, which SwiftUI applies instantly — so the effect
    /// settles at its resting state instead of being silently skipped.
    func testLoopReturnsNilUnderReduceMotion() {
        XCTAssertNil(DSMotion.loop(DSAnimation.ambient, unless: true))
    }

    func testLoopReturnsAnimationWhenMotionAllowed() {
        XCTAssertNotNil(DSMotion.loop(DSAnimation.ambient, unless: false))
        XCTAssertNotNil(DSMotion.loop(DSAnimation.ambient, autoreverses: false, unless: false))
    }

    // MARK: - Bounds

    /// The drift must stay inside the gradient family. If this ever grows past a
    /// handful of degrees the theme stops being recognisable.
    func testHueDriftStaysWithinTheThemeFamily() {
        XCTAssertLessThanOrEqual(DSMotion.driftDegrees, 15)
        XCTAssertGreaterThan(DSMotion.driftDegrees, 0)
    }

    func testJiggleIsASmallRotation() {
        XCTAssertLessThanOrEqual(DSMotion.jiggleDegrees, 10)
        XCTAssertGreaterThan(DSMotion.jiggleDegrees, 0)
    }

    // MARK: - Breathe

    func testBreatheIntensitiesAreOrdered() {
        let scales = [
            DSBreatheIntensity.subtle.scale,
            DSBreatheIntensity.medium.scale,
            DSBreatheIntensity.strong.scale
        ]
        XCTAssertEqual(scales, scales.sorted())
        XCTAssertGreaterThan(scales[0], 1, "Breathing swells outward; it never shrinks below rest")

        let dips = [
            DSBreatheIntensity.subtle.dip,
            DSBreatheIntensity.medium.dip,
            DSBreatheIntensity.strong.dip
        ]
        XCTAssertEqual(dips, dips.sorted())
        XCTAssertLessThan(dips[2], 0.5, "Even the strongest breath must stay legible")
    }

    // MARK: - Durations

    /// Ambient loops are slower than any interaction curve — that is what makes
    /// them read as background rather than as feedback.
    func testAmbientLoopsAreSlowerThanInteractions() {
        XCTAssertGreaterThan(DSMotion.breatheDuration, 1.0)
        XCTAssertGreaterThan(DSMotion.driftDuration, DSMotion.breatheDuration)
        XCTAssertGreaterThan(DSMotion.sweepDuration, 1.0)
    }

    // MARK: - Jiggle Envelope

    /// The shake has to peak at `jiggleDegrees`, alternate sign, shrink every
    /// swing and end at rest — otherwise it reads as a loop instead of a nudge.
    func testJiggleEnvelopeDecaysToRest() {
        let swings = DSMotion.jiggleSwings
        XCTAssertGreaterThanOrEqual(swings.count, 3)
        XCTAssertEqual(swings.first, DSMotion.jiggleDegrees)
        XCTAssertEqual(swings.last, 0)

        let magnitudes = swings.map(abs)
        XCTAssertEqual(magnitudes.max(), DSMotion.jiggleDegrees)
        for (earlier, later) in zip(magnitudes, magnitudes.dropFirst()) {
            XCTAssertGreaterThan(earlier, later, "each swing must be smaller than the one before")
        }
        for (a, b) in zip(swings, swings.dropFirst()) where a != 0 && b != 0 {
            XCTAssertLessThan(a * b, 0, "consecutive swings must alternate sign")
        }
    }

    func testJiggleDurationIsQuick() {
        XCTAssertGreaterThan(DSMotion.jiggleDuration, 0.2)
        XCTAssertLessThan(DSMotion.jiggleDuration, 0.8)
    }
}
