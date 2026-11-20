import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSCircularSlider.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsCircularSlider {
    struct ThermostatDemo: View {
        @State private var temperature: Double = 21

        var body: some View {
            DSScreen(backdrop: true) {
                DSCard {
                    DSCircularSlider(value: $temperature, in: 10...30, step: 0.5,
                                     accessibilityLabel: "Temperature") {
                        VStack(spacing: DSSpacing.xxs) {
                            Text(temperature.formatted(.number.precision(.fractionLength(1))) + "°")
                                .ds(.displayMedium)
                            Text("Heating to").ds(.footnote)
                        }
                    }
                    .frame(maxWidth: 280)
                    .frame(maxWidth: .infinity)
                }
                .dsScreenPadding()
            }
        }
    }

    struct CircularSliderVariantsDemo: View {
        @State private var volume: Double = 0.4
        @State private var minutes: Double = 25

        var body: some View {
            HStack(spacing: DSSpacing.xl) {
                // A bare 0...1 dial: VoiceOver reads a percentage.
                DSCircularSlider(value: $volume, accessibilityLabel: "Volume")
                    .frame(width: 120, height: 120)
                // Five-minute notches, your own accent.
                DSCircularSlider(value: $minutes, in: 5...60, step: 5,
                                 accent: DSColors.secondary, accessibilityLabel: "Timer") {
                    Text("\(Int(minutes)) min").ds(.numeric)
                }
                .frame(width: 120, height: 120)
                // Dimmed and inert.
                DSCircularSlider(value: $volume).disabled(true)
                    .frame(width: 120, height: 120)
            }
        }
    }
}

/// The rules behind `DSCircularSlider`: the arc's angles, which value a touch
/// means, holding at an end instead of jumping across the gap, which touches
/// grab the knob, and the haptic beat. All of it lives in
/// `DSCircularSliderLogic`, `DSCircularSliderTracker` and
/// `DSCircularSliderFeedback`, which hold no view state.
@MainActor
final class DSCircularSliderTests: XCTestCase {

    /// The Gallery stage's thermostat: 10–30 in half degrees.
    private let thermostat = DSCircularSliderLogic(bounds: 10...30, step: 0.5)
    private let unit = DSCircularSliderLogic(bounds: 0...1)
    private let en = Locale(identifier: "en_US")
    private let accuracy = 1e-9

    private let center = CGPoint(x: 100, y: 100)
    private let radius: CGFloat = 86

    /// A point `distance` from `center` at `degrees` (clockwise from 3 o'clock).
    private func point(_ degrees: Double, _ distance: CGFloat) -> CGPoint {
        let radians = degrees * .pi / 180
        return CGPoint(x: center.x + distance * CGFloat(cos(radians)),
                       y: center.y + distance * CGFloat(sin(radians)))
    }

    /// The fraction a tracking drag last showed, or `nil` when it isn't tracking.
    private func tracked(_ tracker: DSCircularSliderTracker) -> Double? {
        if case .tracking(let fraction) = tracker.phase { return fraction }
        return nil
    }

    func testSnippetsInstantiate() {
        _ = DocSnippetsCircularSlider.ThermostatDemo().body
        _ = DocSnippetsCircularSlider.CircularSliderVariantsDemo().body
        _ = DSCircularSlider(value: .constant(0.5)).body
        _ = DSCircularSlider(value: .constant(20), in: 10...30) { Text("20°") }.body
    }

    // MARK: - Arc

    func testArcRunsClockwiseFromTheLowerLeftOverTheTop() {
        XCTAssertEqual(DSCircularSliderLogic.angle(ofFraction: 0), 135)
        XCTAssertEqual(DSCircularSliderLogic.angle(ofFraction: 0.5), 270, "The middle of the range is at 12 o'clock.")
        XCTAssertEqual(DSCircularSliderLogic.angle(ofFraction: 1), 405)
        XCTAssertEqual(DSCircularSliderLogic.angle(ofFraction: -1), 135)
        XCTAssertEqual(DSCircularSliderLogic.angle(ofFraction: 2), 405)
        XCTAssertEqual(DSCircularSliderLogic.angle(ofFraction: .nan), 135)
        XCTAssertEqual(DSCircularSliderLogic.arcTrim, 0.75, accuracy: accuracy)
    }

    func testAngleOfAPointIsClockwiseOnScreen() {
        XCTAssertEqual(DSCircularSliderLogic.angle(of: CGPoint(x: 150, y: 100), center: center), 0, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.angle(of: CGPoint(x: 100, y: 150), center: center), 90, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.angle(of: CGPoint(x: 50, y: 100), center: center), 180, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.angle(of: CGPoint(x: 100, y: 50), center: center), 270, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.angle(of: point(135, 40), center: center), 135, accuracy: 1e-6)
    }

    func testAngleOnTheArcMapsToItsFraction() {
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 135, previous: nil), 0, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 180, previous: nil), 1.0 / 6, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 270, previous: nil), 0.5, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 0, previous: nil), 5.0 / 6, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 45, previous: nil), 1, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 405, previous: nil), 1, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: -90, previous: nil), 0.5, accuracy: accuracy)
    }

    func testATouchInTheGapGoesToTheNearerEnd() {
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 60, previous: nil), 1)
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 89, previous: nil), 1)
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 91, previous: nil), 0)
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 120, previous: nil), 0)
    }

    func testADragIntoTheGapHoldsAtTheEndItCameFrom() {
        // Past the maximum, even beyond the gap's middle: still the maximum.
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 120, previous: 0.97), 1)
        // Below the minimum, even beyond the gap's middle: still the minimum.
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 60, previous: 0.02), 0)
    }

    func testADragNeverJumpsAcrossTheGap() {
        // Held at the maximum, the finger comes out of the gap just past the start.
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 140, previous: 1), 1)
        // Held at the minimum, the finger comes out just before the end.
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 30, previous: 0), 0)
        // A real move along the arc is followed.
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 300, previous: 0.5), 165.0 / 270, accuracy: accuracy)
        XCTAssertEqual(DSCircularSliderLogic.fraction(atAngle: 40, previous: 1), 265.0 / 270, accuracy: accuracy)
    }

    func testFractionMapsToSnappedValues() {
        XCTAssertEqual(thermostat.value(atFraction: 0), 10)
        XCTAssertEqual(thermostat.value(atFraction: 0.5), 20)
        XCTAssertEqual(thermostat.value(atFraction: 1.0 / 6), 13.5, "13.33… snaps to the nearest half degree.")
        XCTAssertEqual(thermostat.value(atFraction: 5.0 / 6), 26.5)
        XCTAssertEqual(thermostat.value(atFraction: 1), 30)
        XCTAssertEqual(unit.value(atFraction: 0.25), 0.25, accuracy: accuracy)
    }

    // MARK: - Tracking a drag

    func testADragStartingOnTheContentNeverMovesTheValue() {
        var tracker = DSCircularSliderTracker()
        XCTAssertNil(tracker.move(to: point(270, 30), center: center, radius: radius))
        XCTAssertEqual(tracker.phase, .ignoring)
        XCTAssertNil(tracker.move(to: point(270, 86), center: center, radius: radius),
                     "Sliding out onto the ring doesn't take over a drag that started in the middle.")
        tracker.end()
        XCTAssertEqual(tracker.phase, .idle)
    }

    func testADragOnTheRingFollowsTheAngle() {
        var tracker = DSCircularSliderTracker()
        let top = tracker.move(to: point(270, 86), center: center, radius: radius)
        XCTAssertEqual(top ?? -1, 0.5, accuracy: 1e-6)
        XCTAssertEqual(tracked(tracker) ?? -1, 0.5, accuracy: 1e-6)

        // Far outside the ring works too: only the angle counts.
        let left = tracker.move(to: point(180, 300), center: center, radius: radius)
        XCTAssertEqual(left ?? -1, 1.0 / 6, accuracy: 1e-6)

        // Right over the centre the angle is noise, so the value holds.
        XCTAssertNil(tracker.move(to: point(10, 5), center: center, radius: radius))
        XCTAssertEqual(tracked(tracker) ?? -1, 1.0 / 6, accuracy: 1e-6)
    }

    func testADragAroundTheGapHoldsTheMaximum() {
        var tracker = DSCircularSliderTracker()
        _ = tracker.move(to: point(0, 86), center: center, radius: radius)
        XCTAssertEqual(tracker.move(to: point(40, 120), center: center, radius: radius) ?? -1, 265.0 / 270, accuracy: 1e-6)
        XCTAssertEqual(tracker.move(to: point(70, 150), center: center, radius: radius), 1)
        XCTAssertEqual(tracker.move(to: point(120, 150), center: center, radius: radius), 1)
        XCTAssertEqual(tracker.move(to: point(150, 150), center: center, radius: radius), 1,
                       "Out of the gap past the start, the knob stays at the maximum.")
        // Back over the top it follows again.
        XCTAssertEqual(tracker.move(to: point(30, 150), center: center, radius: radius) ?? -1, 255.0 / 270, accuracy: 1e-6)
    }

    func testAnUnmeasuredDialIgnoresTouches() {
        var tracker = DSCircularSliderTracker()
        XCTAssertNil(tracker.move(to: point(270, 86), center: center, radius: 0))
        XCTAssertEqual(tracker.phase, .ignoring)
    }

    // MARK: - VoiceOver

    func testValueReadsLikeDSSlider() {
        XCTAssertEqual(thermostat.scale.accessibilityValue(21, locale: en), "21")
        XCTAssertEqual(thermostat.scale.accessibilityValue(13.5, locale: en), "13.5")
        XCTAssertEqual(unit.scale.accessibilityValue(0.4, locale: en), "40 percent")
    }

    func testVoiceOverStepsOneNotchAndStopsAtTheEnds() {
        XCTAssertEqual(thermostat.scale.adjusted(21, direction: 1), 21.5)
        XCTAssertEqual(thermostat.scale.adjusted(21, direction: -1), 20.5)
        XCTAssertEqual(thermostat.scale.adjusted(30, direction: 1), 30)
        XCTAssertEqual(thermostat.scale.adjusted(10, direction: -1), 10)
    }

    // MARK: - Haptics

    func testSteppedDragTicksPerNotchAndDetentsAtTheEnds() {
        var feedback = DSCircularSliderFeedback()
        feedback.begin(value: 21, atBound: false)
        XCTAssertNil(feedback.haptic(for: 21, atBound: false, stepped: true), "Grabbing the knob is silent.")
        XCTAssertEqual(feedback.haptic(for: 21.5, atBound: false, stepped: true), .selection)
        XCTAssertNil(feedback.haptic(for: 21.5, atBound: false, stepped: true), "Same notch, no second tick.")
        XCTAssertEqual(feedback.haptic(for: 30, atBound: true, stepped: true), .rigid, "The end wins over the tick.")
        XCTAssertNil(feedback.haptic(for: 30, atBound: true, stepped: true), "Holding in the gap is silent.")
        XCTAssertEqual(feedback.haptic(for: 29.5, atBound: false, stepped: true), .selection)
        XCTAssertEqual(feedback.haptic(for: 30, atBound: true, stepped: true), .rigid, "Arriving again fires again.")
    }

    func testContinuousDragOnlyDetents() {
        var feedback = DSCircularSliderFeedback()
        feedback.begin(value: 0.5, atBound: false)
        XCTAssertNil(feedback.haptic(for: 0.6, atBound: false, stepped: false))
        XCTAssertNil(feedback.haptic(for: 0.9, atBound: false, stepped: false))
        XCTAssertEqual(feedback.haptic(for: 1, atBound: true, stepped: false), .rigid)
    }

    func testGrabbingTheKnobAtAnEndIsSilentAndResetClears() {
        var feedback = DSCircularSliderFeedback()
        feedback.begin(value: 10, atBound: true)
        XCTAssertNil(feedback.haptic(for: 10, atBound: true, stepped: true))
        XCTAssertEqual(feedback.haptic(for: 10.5, atBound: false, stepped: true), .selection)
        feedback.reset()
        XCTAssertFalse(feedback.atBound)
        XCTAssertNil(feedback.lastValue)
    }
}
