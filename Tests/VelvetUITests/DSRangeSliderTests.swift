import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSRangeSlider.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsRangeSlider {
    struct PriceFilterDemo: View {
        @State private var price: ClosedRange<Double> = 100...400

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    HStack {
                        Text("Price").ds(.title3)
                        Spacer()
                        Text("$\(Int(price.lowerBound)) – $\(Int(price.upperBound))").ds(.numeric)
                    }
                    DSRangeSlider(range: $price, in: 0...500, step: 25, minimumDistance: 50)
                        .accessibilityLabel("Price")
                }
                .dsScreenPadding()
            }
        }
    }

    struct RangeSliderVariantsDemo: View {
        @State private var hours: ClosedRange<Double> = 9...17
        @State private var level: ClosedRange<Double> = 0.2...0.7

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                // Whole hours, at least two of them.
                DSRangeSlider(range: $hours, in: 0...24, step: 1, minimumDistance: 2)
                // Continuous 0...1, your own accent; the knobs may meet.
                DSRangeSlider(range: $level, accent: DSColors.secondary)
                // Dimmed and inert.
                DSRangeSlider(range: $level).disabled(true)
            }
        }
    }
}

/// The rules behind `DSRangeSlider`: normalising the bound range, the travel of
/// each knob, which knob a touch grabs, the VoiceOver step and the haptic beat.
/// All of it is in `DSRangeSliderLogic` / `DSRangeSliderFeedback`, which hold no
/// view state.
@MainActor
final class DSRangeSliderTests: XCTestCase {

    /// The Gallery stage's configuration: $0–500 in 25s, at least $50 wide.
    private let price = DSRangeSliderLogic(bounds: 0...500, step: 25, minimumDistance: 50)
    private let digits = DSRangeSliderLogic(bounds: 0...10, step: 1)
    private let unit = DSRangeSliderLogic(bounds: 0...1)
    private let en = Locale(identifier: "en_US")

    func testSnippetsInstantiate() {
        _ = DocSnippetsRangeSlider.PriceFilterDemo().body
        _ = DocSnippetsRangeSlider.RangeSliderVariantsDemo().body
        _ = DSRangeSlider(range: .constant(0.2...0.8)).body
    }

    // MARK: - Minimum distance

    func testMinimumDistanceIsNormalised() {
        XCTAssertEqual(DSRangeSliderLogic(bounds: 0...1, minimumDistance: -1).minimumDistance, 0)
        XCTAssertEqual(DSRangeSliderLogic(bounds: 0...1, minimumDistance: .nan).minimumDistance, 0)
        XCTAssertEqual(DSRangeSliderLogic(bounds: 0...1, minimumDistance: .infinity).minimumDistance, 0)
        XCTAssertEqual(DSRangeSliderLogic(bounds: 0...1, minimumDistance: 5).minimumDistance, 1)
        XCTAssertEqual(price.minimumDistance, 50)
        XCTAssertEqual(unit.minimumDistance, 0)
    }

    // MARK: - Normalising the bound range

    func testValidRangeIsUntouched() {
        XCTAssertEqual(price.normalized(100...400), 100...400)
        XCTAssertEqual(unit.normalized(0.3...0.3), 0.3...0.3)
    }

    func testRangeIsClampedIntoBounds() {
        XCTAssertEqual(price.normalized(-50...600), 0...500)
        XCTAssertEqual(price.normalized(-90 ... -10), 0...50)
    }

    func testRangeIsSnappedToNotches() {
        XCTAssertEqual(price.normalized(110...390), 100...400)
    }

    func testNarrowRangeWidensUpward() {
        XCTAssertEqual(price.normalized(200...220), 200...250)
        XCTAssertEqual(price.normalized(300...300), 300...350)
    }

    func testNarrowRangeAtTheTopIsPinnedThere() {
        XCTAssertEqual(price.normalized(480...500), 450...500)
        XCTAssertEqual(price.normalized(500...500), 450...500)
    }

    func testMinimumDistanceOffTheGridLandsOnNotches() {
        // 0...10 by 3 has notches 0 3 6 9 10; a 2-wide gap from 10 needs 6.
        let uneven = DSRangeSliderLogic(bounds: 0...10, step: 3, minimumDistance: 2)
        XCTAssertEqual(uneven.normalized(9...10), 6...10)
        XCTAssertEqual(uneven.limits(for: .upper, in: 3...6), 6...10)
        XCTAssertEqual(uneven.limits(for: .lower, in: 3...10), 0...6)
    }

    // MARK: - Moving a knob

    func testKnobsStopAtTheGap() {
        XCTAssertEqual(price.moving(.lower, to: 1000, in: 100...400), 350...400)
        XCTAssertEqual(price.moving(.upper, to: -10, in: 100...400), 100...150)
    }

    func testKnobsStopAtTheBounds() {
        XCTAssertEqual(price.moving(.lower, to: -1, in: 100...400), 0...400)
        XCTAssertEqual(price.moving(.upper, to: 9999, in: 100...400), 100...500)
    }

    func testMovingSnapsAndLeavesTheOtherEndAlone() {
        XCTAssertEqual(price.moving(.lower, to: 37, in: 100...400), 25...400)
        XCTAssertEqual(price.moving(.upper, to: 262, in: 100...400), 100...250)
    }

    func testKnobsMayMeetWithoutAMinimumDistance() {
        XCTAssertEqual(digits.moving(.lower, to: 9, in: 2...6), 6...6)
        XCTAssertEqual(digits.moving(.upper, to: 0, in: 2...6), 2...2)
        XCTAssertEqual(unit.moving(.lower, to: 0.5, in: 0.2...0.4), 0.4...0.4)
    }

    func testRangeNeverInvertsOrEscapes() {
        var range: ClosedRange<Double> = 100...400
        for target in stride(from: -100.0, through: 600.0, by: 13.7) {
            for thumb in [DSRangeThumb.lower, .upper] {
                range = price.moving(thumb, to: target, in: range)
                XCTAssertGreaterThanOrEqual(range.lowerBound, 0)
                XCTAssertLessThanOrEqual(range.upperBound, 500)
                XCTAssertGreaterThanOrEqual(range.upperBound - range.lowerBound, 50)
            }
        }
    }

    // MARK: - VoiceOver

    func testAdjustingStepsOneNotch() {
        XCTAssertEqual(price.adjusted(.lower, direction: 1, in: 100...400), 125...400)
        XCTAssertEqual(price.adjusted(.lower, direction: -1, in: 100...400), 75...400)
        XCTAssertEqual(price.adjusted(.upper, direction: -1, in: 100...400), 100...375)
        XCTAssertEqual(price.adjusted(.upper, direction: 1, in: 100...400), 100...425)
    }

    func testAdjustingStopsAtTheLimits() {
        XCTAssertEqual(price.adjusted(.lower, direction: 1, in: 350...400), 350...400)
        XCTAssertEqual(price.adjusted(.upper, direction: -1, in: 350...400), 350...400)
        XCTAssertEqual(price.adjusted(.upper, direction: 1, in: 100...500), 100...500)
        XCTAssertEqual(price.adjusted(.lower, direction: -1, in: 0...400), 0...400)
    }

    func testSpokenValues() {
        XCTAssertEqual(price.scale.accessibilityValue(price.value(of: .lower, in: 100...400), locale: en), "100")
        XCTAssertEqual(price.scale.accessibilityValue(price.value(of: .upper, in: 100...400), locale: en), "400")
        XCTAssertEqual(unit.scale.accessibilityValue(0.25, locale: en), "25 percent")
    }

    // MARK: - Limits

    func testAtLimit() {
        XCTAssertTrue(price.isAtLimit(.lower, in: 0...400))
        XCTAssertTrue(price.isAtLimit(.lower, in: 350...400))
        XCTAssertFalse(price.isAtLimit(.lower, in: 100...400))
        XCTAssertTrue(price.isAtLimit(.upper, in: 100...500))
        XCTAssertTrue(price.isAtLimit(.upper, in: 100...150))
        XCTAssertFalse(price.isAtLimit(.upper, in: 100...400))
    }

    // MARK: - Touch

    func testTouchMapsWithTheKnobInset() {
        // 128 wide, 28 knob: 100 pt of travel from x = 14 to x = 114.
        XCTAssertEqual(price.value(atX: 14, trackWidth: 128, knobDiameter: 28), 0)
        XCTAssertEqual(price.value(atX: 64, trackWidth: 128, knobDiameter: 28), 250)
        XCTAssertEqual(price.value(atX: 114, trackWidth: 128, knobDiameter: 28), 500)
        XCTAssertEqual(price.value(atX: -40, trackWidth: 128, knobDiameter: 28), 0)
        XCTAssertEqual(price.value(atX: 400, trackWidth: 128, knobDiameter: 28), 500)
        XCTAssertNil(price.value(atX: 10, trackWidth: 20, knobDiameter: 28))
    }

    func testTouchGrabsTheNearerKnob() {
        XCTAssertEqual(price.thumb(nearest: 120, in: 100...400), .lower)
        XCTAssertEqual(price.thumb(nearest: 20, in: 100...400), .lower)
        XCTAssertEqual(price.thumb(nearest: 390, in: 100...400), .upper)
        XCTAssertEqual(price.thumb(nearest: 480, in: 100...400), .upper)
        // Exactly halfway: the upper knob, which has room to move.
        XCTAssertEqual(price.thumb(nearest: 250, in: 100...400), .upper)
    }

    func testTouchOnStackedKnobsFollowsTheSide() {
        XCTAssertEqual(digits.thumb(nearest: 7, in: 5...5), .upper)
        XCTAssertEqual(digits.thumb(nearest: 3, in: 5...5), .lower)
        XCTAssertEqual(digits.thumb(nearest: 5, in: 5...5), .upper)
        // At the top of the track only the lower knob can move.
        XCTAssertEqual(digits.thumb(nearest: 10, in: 10...10), .lower)
        XCTAssertEqual(digits.thumb(nearest: 0, in: 0...0), .upper)
    }

    // MARK: - Haptics

    func testSteppedDragTicksPerNotchAndDetentsAtTheLimit() {
        var feedback = DSRangeSliderFeedback()
        feedback.begin(value: 100, atLimit: false)
        XCTAssertNil(feedback.haptic(for: 100, atLimit: false, stepped: true), "Grabbing a knob is silent.")
        XCTAssertEqual(feedback.haptic(for: 125, atLimit: false, stepped: true), .selection)
        XCTAssertNil(feedback.haptic(for: 125, atLimit: false, stepped: true), "Same notch, no second tick.")
        XCTAssertEqual(feedback.haptic(for: 350, atLimit: true, stepped: true), .rigid, "The limit wins over the tick.")
        XCTAssertNil(feedback.haptic(for: 350, atLimit: true, stepped: true), "Resting at the limit is silent.")
        XCTAssertEqual(feedback.haptic(for: 325, atLimit: false, stepped: true), .selection)
        XCTAssertEqual(feedback.haptic(for: 350, atLimit: true, stepped: true), .rigid, "Arriving again fires again.")
    }

    func testContinuousDragOnlyDetents() {
        var feedback = DSRangeSliderFeedback()
        feedback.begin(value: 0.5, atLimit: false)
        XCTAssertNil(feedback.haptic(for: 0.6, atLimit: false, stepped: false))
        XCTAssertNil(feedback.haptic(for: 0.9, atLimit: false, stepped: false))
        XCTAssertEqual(feedback.haptic(for: 1, atLimit: true, stepped: false), .rigid)
    }

    func testGrabbingAKnobAtItsLimitIsSilent() {
        var feedback = DSRangeSliderFeedback()
        feedback.begin(value: 0, atLimit: true)
        XCTAssertNil(feedback.haptic(for: 0, atLimit: true, stepped: true))
        XCTAssertEqual(feedback.haptic(for: 25, atLimit: false, stepped: true), .selection)
    }
}
