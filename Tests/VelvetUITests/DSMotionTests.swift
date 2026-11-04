import XCTest
import SwiftUI
@testable import VelvetUI

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

    /// The drift must stay inside the theme family. If this ever grows past a
    /// handful of degrees the accent stops being recognisable.
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

    // MARK: - Scroll Reveal

    /// Off-centre items recede — never grow — and a stronger intensity pulls them
    /// further back, while the strongest still leaves something on screen.
    func testScrollRevealIntensitiesRecedeAndStayOrdered() {
        let scales = [
            DSScrollRevealIntensity.subtle.minScale,
            DSScrollRevealIntensity.medium.minScale,
            DSScrollRevealIntensity.strong.minScale
        ]
        XCTAssertEqual(scales, scales.sorted(by: >), "a stronger reveal recedes further")
        XCTAssertLessThan(scales[0], 1, "an off-centre item shrinks toward rest, never past it")
        XCTAssertGreaterThan(scales[2], 0, "even the strongest reveal keeps the card on screen")

        let opacities = [
            DSScrollRevealIntensity.subtle.minOpacity,
            DSScrollRevealIntensity.medium.minOpacity,
            DSScrollRevealIntensity.strong.minOpacity
        ]
        XCTAssertEqual(opacities, opacities.sorted(by: >), "a stronger reveal fades further")
        XCTAssertLessThan(opacities[0], 1, "an off-centre item dims below full presence")
        XCTAssertGreaterThan(opacities[2], 0, "even the strongest reveal never fully hides a card")
    }

    /// The intensities read their numbers from the `DSMotion` tokens, not literals.
    func testScrollRevealIntensitiesComeFromTokens() {
        XCTAssertEqual(DSScrollRevealIntensity.subtle.minScale, DSMotion.scrollRevealSubtleScale)
        XCTAssertEqual(DSScrollRevealIntensity.medium.minScale, DSMotion.scrollRevealMediumScale)
        XCTAssertEqual(DSScrollRevealIntensity.strong.minScale, DSMotion.scrollRevealStrongScale)
        XCTAssertEqual(DSScrollRevealIntensity.subtle.minOpacity, DSMotion.scrollRevealSubtleOpacity)
        XCTAssertEqual(DSScrollRevealIntensity.medium.minOpacity, DSMotion.scrollRevealMediumOpacity)
        XCTAssertEqual(DSScrollRevealIntensity.strong.minOpacity, DSMotion.scrollRevealStrongOpacity)
    }

    func testScrollRevealIsFullPresenceInsideTheVisibleArea() {
        for intensity in [DSScrollRevealIntensity.subtle, .medium, .strong] {
            let e = DSScrollRevealMath.effect(for: intensity, phaseValue: 0, reduceMotion: false)
            XCTAssertEqual(e.scale, 1)
            XCTAssertEqual(e.opacity, 1)
        }
    }

    func testScrollRevealReachesTheIntensityAtTheEdgeOnBothSides() {
        for sign in [-1.0, 1.0] {
            let e = DSScrollRevealMath.effect(for: .medium, phaseValue: sign, reduceMotion: false)
            XCTAssertEqual(e.scale, DSScrollRevealIntensity.medium.minScale, accuracy: 1e-9)
            XCTAssertEqual(e.opacity, DSScrollRevealIntensity.medium.minOpacity, accuracy: 1e-9)
        }
    }

    func testScrollRevealInterpolatesAndClamps() {
        let half = DSScrollRevealMath.effect(for: .strong, phaseValue: 0.5, reduceMotion: false)
        XCTAssertEqual(half.scale, (1 + DSScrollRevealIntensity.strong.minScale) / 2, accuracy: 1e-9)
        let beyond = DSScrollRevealMath.effect(for: .strong, phaseValue: 3, reduceMotion: false)
        XCTAssertEqual(beyond.scale, DSScrollRevealIntensity.strong.minScale, accuracy: 1e-9)
    }

    /// Reduce Motion rests at full presence for every phase: no movement, no dimming.
    func testScrollRevealRestsUnderReduceMotion() {
        for intensity in [DSScrollRevealIntensity.subtle, .medium, .strong] {
            for phase in [-1.0, -0.4, 0, 0.7, 1] {
                let e = DSScrollRevealMath.effect(for: intensity, phaseValue: phase, reduceMotion: true)
                XCTAssertEqual(e.scale, 1)
                XCTAssertEqual(e.opacity, 1)
            }
        }
    }
}
