import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSCountdown.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsCountdown {
    struct FlashSaleDemo: View {
        let endsAt: Date

        var body: some View {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Sale ends in").ds(.title3)
                    DSCountdown(to: endsAt, accessibilityLabel: "Sale ends in")
                }
            }
        }
    }

    struct ResendCodeDemo: View {
        @State private var resendAt = Date.now.addingTimeInterval(30)
        @State private var canResend = false

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSCountdown(to: resendAt, haptic: .light, accessibilityLabel: "Resend code in") {
                    canResend = true
                }
                DSButton("Resend code", variant: .secondary, size: .small) {
                    canResend = false
                    resendAt = .now.addingTimeInterval(30)
                }
                .disabled(!canResend)
            }
        }
    }
}

@MainActor
final class DSCountdownTests: XCTestCase {
    typealias L = DSCountdownLogic

    private let target = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func testBodiesBuild() {
        _ = DocSnippetsCountdown.FlashSaleDemo(endsAt: .now.addingTimeInterval(90)).body
        _ = DocSnippetsCountdown.ResendCodeDemo().body
        _ = DSCountdown(to: .now).body
        _ = DSCountdown(to: .distantFuture, accent: .red, haptic: .light, accessibilityLabel: "Ends in") {}.body
    }

    // MARK: Seconds left

    func testRemainingRoundsUpSoZeroOnlyShowsAtTheEnd() {
        XCTAssertEqual(L.remainingSeconds(from: target.addingTimeInterval(-59.3), to: target), 60)
        XCTAssertEqual(L.remainingSeconds(from: target.addingTimeInterval(-59), to: target), 59)
        XCTAssertEqual(L.remainingSeconds(from: target.addingTimeInterval(-0.001), to: target), 1,
                       "A sliver of a second left still reads 1, not 0.")
        XCTAssertEqual(L.remainingSeconds(from: target, to: target), 0)
    }

    func testRemainingIsNeverNegative() {
        XCTAssertEqual(L.remainingSeconds(from: target.addingTimeInterval(3_600), to: target), 0)
        XCTAssertEqual(L.remainingSeconds(from: .distantFuture, to: .distantPast), 0)
    }

    func testRemainingIsCappedForFarTargets() {
        XCTAssertEqual(L.remainingSeconds(from: .distantPast, to: .distantFuture), L.maxSeconds)
    }

    // MARK: Units

    func testPartsSplitTheSeconds() {
        let seconds = 2 * 86_400 + 5 * 3_600 + 7 * 60 + 9
        XCTAssertEqual(L.parts(seconds), .init(days: 2, hours: 5, minutes: 7, seconds: 9))
        XCTAssertEqual(L.parts(59), .init(days: 0, hours: 0, minutes: 0, seconds: 59))
        XCTAssertEqual(L.parts(3_600), .init(days: 0, hours: 1, minutes: 0, seconds: 0))
        XCTAssertEqual(L.parts(-5), .init(days: 0, hours: 0, minutes: 0, seconds: 0))
    }

    func testTilesGrowWithTheTimeLeft() {
        XCTAssertEqual(L.units(for: 0), [.minutes, .seconds], "Minutes and seconds always show.")
        XCTAssertEqual(L.units(for: 3_599), [.minutes, .seconds])
        XCTAssertEqual(L.units(for: 3_600), [.hours, .minutes, .seconds])
        XCTAssertEqual(L.units(for: 86_399), [.hours, .minutes, .seconds])
        XCTAssertEqual(L.units(for: 86_400), [.days, .hours, .minutes, .seconds])
    }

    func testDigitsAreAtLeastTwo() {
        XCTAssertEqual(L.digits(0), "00")
        XCTAssertEqual(L.digits(5), "05")
        XCTAssertEqual(L.digits(42), "42")
        XCTAssertEqual(L.digits(365), "365", "A long countdown keeps every day digit.")
        XCTAssertEqual(L.digits(-3), "00")
    }

    func testCaptions() {
        XCTAssertEqual(L.Unit.allCases.map(\.caption), ["days", "hrs", "min", "sec"])
    }

    // MARK: Ticking

    func testDelayWakesJustPastTheNextSecondBoundary() throws {
        let delay = try XCTUnwrap(L.delayToNextTick(from: target.addingTimeInterval(-59.25), to: target))
        XCTAssertEqual(delay, 0.25 + L.tickSlack, accuracy: 0.000_1)
        // After that sleep the displayed value has moved on by exactly one.
        let woken = target.addingTimeInterval(-59.25 + delay)
        XCTAssertEqual(L.remainingSeconds(from: woken, to: target), 59)
    }

    func testDelayOnABoundaryIsAWholeSecond() throws {
        let delay = try XCTUnwrap(L.delayToNextTick(from: target.addingTimeInterval(-30), to: target))
        XCTAssertEqual(delay, 1 + L.tickSlack, accuracy: 0.000_1)
    }

    func testNoDelayOnceTheTargetHasPassed() {
        XCTAssertNil(L.delayToNextTick(from: target, to: target))
        XCTAssertNil(L.delayToNextTick(from: target.addingTimeInterval(1), to: target))
    }

    func testUrgentIsTheLastTenSeconds() {
        XCTAssertFalse(L.isUrgent(11))
        XCTAssertTrue(L.isUrgent(10))
        XCTAssertTrue(L.isUrgent(1))
        XCTAssertFalse(L.isUrgent(0), "Finished isn't urgent: the tile returns to rest.")
    }

    // MARK: Finishing

    func testFinishFiresOnceWithTheHapticWhenSeenReachingZero() {
        var tracker = L.Tracker()
        XCTAssertEqual(tracker.advance(to: 2), .tick)
        XCTAssertEqual(tracker.advance(to: 1), .tick)
        XCTAssertEqual(tracker.advance(to: 0), .finished(crossedZero: true))
        XCTAssertTrue(tracker.isFinished)
        XCTAssertEqual(tracker.advance(to: 0), .tick, "The finish fires once.")
    }

    func testAnAlreadyPassedTargetFinishesQuietly() {
        var tracker = L.Tracker()
        XCTAssertEqual(tracker.advance(to: 0), .finished(crossedZero: false),
                       "onFinish still runs, but no haptic for a countdown that was over before it appeared.")
    }

    // MARK: VoiceOver

    func testSpokenValueSkipsZeroUnitsAndPluralises() {
        XCTAssertEqual(L.accessibilityValue(86_400 + 2 * 3_600 + 5), "1 day, 2 hours, 5 seconds")
        XCTAssertEqual(L.accessibilityValue(61), "1 minute, 1 second")
        XCTAssertEqual(L.accessibilityValue(42), "42 seconds")
        XCTAssertEqual(L.accessibilityValue(0), "0 seconds")
    }
}
