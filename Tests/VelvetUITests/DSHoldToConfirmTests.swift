import XCTest
import SwiftUI
import CoreGraphics
@testable import VelvetUI

/// The pure parts of `DSHoldToConfirm`: the charge schedule that paces the
/// detents (and, by summing to `duration`, the confirmation), the clamp on
/// `duration`, and the words VoiceOver reads (shared with `DSSlideToConfirm`).
final class DSHoldToConfirmTests: XCTestCase {

    // MARK: - Charge schedule

    func testScheduleDelaysSumToTheDuration() {
        for duration in [0.6, 1.2, 3.0] {
            let total = DSHoldToConfirm.chargeSchedule(duration: duration).reduce(0) { $0 + $1.delay }
            XCTAssertEqual(total, duration, accuracy: 1e-9)
        }
    }

    func testScheduleHasSixEvenSteps() {
        let steps = DSHoldToConfirm.chargeSchedule(duration: 1.2)
        XCTAssertEqual(steps.count, 6)
        XCTAssertEqual(Set(steps.map(\.delay)).count, 1, "Every step waits the same time")
    }

    /// The detents tighten as the ring closes, from just above the touch-down
    /// detent up to the slide's 0.6 ceiling, and the last step hands off to the
    /// success haptic instead of ticking.
    func testDetentsRampAndTheLastStepIsSilent() {
        let steps = DSHoldToConfirm.chargeSchedule(duration: 1.2)
        let ticks = steps.compactMap(\.intensity)
        XCTAssertEqual(ticks.count, steps.count - 1)
        XCTAssertNil(steps.last?.intensity)
        XCTAssertEqual(ticks, ticks.sorted())
        XCTAssertGreaterThan(ticks.first ?? 0, DSHoldToConfirm.touchDownIntensity)
        XCTAssertLessThan(ticks.last ?? 1, 0.6)
        XCTAssertEqual(DSHoldToConfirm.touchDownIntensity, 0.2)
    }

    // MARK: - Duration

    func testDurationIsNeverShorterThanATap() {
        XCTAssertEqual(DSHoldToConfirm.clampedDuration(0), 0.2)
        XCTAssertEqual(DSHoldToConfirm.clampedDuration(-3), 0.2)
        XCTAssertEqual(DSHoldToConfirm.clampedDuration(0.05), 0.2)
        XCTAssertEqual(DSHoldToConfirm.clampedDuration(2.5), 2.5)
    }

    func testNonFiniteDurationFallsBackToTheDefault() {
        XCTAssertEqual(DSHoldToConfirm.clampedDuration(.nan), 1.2)
        XCTAssertEqual(DSHoldToConfirm.clampedDuration(.infinity), 1.2)
    }

    func testScheduleHonoursTheClamp() {
        let total = DSHoldToConfirm.chargeSchedule(duration: 0).reduce(0) { $0 + $1.delay }
        XCTAssertEqual(total, 0.2, accuracy: 1e-9)
    }

    // MARK: - VoiceOver

    func testAccessibilityValueMatchesTheSlide() {
        for (processing, confirmed) in [(false, false), (true, false), (false, true)] {
            XCTAssertEqual(
                DSHoldToConfirm.accessibilityValue(isProcessing: processing, isConfirmed: confirmed, confirmedLabel: "Done"),
                DSSlideToConfirm.accessibilityValue(isProcessing: processing, isConfirmed: confirmed, confirmedLabel: "Done")
            )
        }
        XCTAssertEqual(DSHoldToConfirm.accessibilityValue(isProcessing: true, isConfirmed: false, confirmedLabel: "Done"), "Processing")
        XCTAssertEqual(DSHoldToConfirm.accessibilityValue(isProcessing: false, isConfirmed: true, confirmedLabel: "Done"), "Done")
        XCTAssertEqual(DSHoldToConfirm.accessibilityHint, DSSlideToConfirm.accessibilityHint,
                       "VoiceOver confirms with a double-tap, no hold")
    }
}

/// The ring is a progress indicator, not a border: at rest nothing is stroked.
@MainActor
final class DSHoldToConfirmRenderTests: XCTestCase {

    func testIdlePillDrawsNoRing() throws {
        let accent = Color(red: 1, green: 0, blue: 1)   // a colour nothing else on the pill uses
        let view = DSHoldToConfirm("Hold to delete", accent: accent) {}
            .frame(width: 280)
            .padding(8)
            .dsTheme(DSTheme())
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.cgImage)

        var rgba = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let drawn = rgba.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        try XCTSkipUnless(drawn, "Could not create a bitmap context")

        var magenta = 0
        for i in stride(from: 0, to: rgba.count, by: 4) where rgba[i + 3] > 200 && rgba[i] > 200 && rgba[i + 1] < 60 && rgba[i + 2] > 200 {
            magenta += 1
        }
        XCTAssertEqual(magenta, 0, "At rest the accent ring (trim 0) must draw nothing")
    }
}
