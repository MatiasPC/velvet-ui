import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSActivityRings.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsActivityRings {
    struct TodayRings: View {
        @DSThemed private var theme
        @State private var move = 0.82
        @State private var exercise = 0.60
        @State private var stand = 0.45

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    DSCard {
                        DSActivityRings([
                            DSRing(progress: move, color: theme.palette.error, label: "Move"),
                            DSRing(progress: exercise, color: theme.palette.success, label: "Exercise"),
                            DSRing(progress: stand, color: theme.palette.info, label: "Stand")
                        ]) {
                            Text("\(Int(((move + exercise + stand) / 3 * 100).rounded()))%").ds(.title2)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    DSButton("Finish a workout", isFullWidth: true) { exercise = 1 }
                }
                .dsScreenPadding()
            }
        }
    }

    struct VariantsDemo: View {
        var body: some View {
            HStack(spacing: DSSpacing.xl) {
                // One goal, no centre, in the theme accent
                DSActivityRings([DSRing(progress: 0.7, label: "Budget")], size: 96, lineWidth: 12)

                // A quiet one: no haptic when it closes
                DSActivityRings([DSRing(progress: 1, label: "Storage")], size: 96, lineWidth: 12, haptic: nil)
            }
        }
    }
}

@MainActor
final class DSActivityRingsTests: XCTestCase {
    typealias Math = DSRingMath

    func testSnippetsInstantiate() {
        _ = DocSnippetsActivityRings.TodayRings().body
        _ = DocSnippetsActivityRings.VariantsDemo().body
    }

    // MARK: - Model

    func testFractionSanitizesProgress() {
        XCTAssertEqual(DSRing(progress: 0.4).fraction, 0.4)
        XCTAssertEqual(DSRing(progress: -2).fraction, 0, "negative progress counts as empty")
        XCTAssertEqual(DSRing(progress: .nan).fraction, 0, "NaN counts as empty")
        XCTAssertEqual(DSRing(progress: -.infinity).fraction, 0)
        XCTAssertEqual(DSRing(progress: .infinity).fraction, 1, "+infinity reads as a closed ring")
        XCTAssertEqual(DSRing(progress: 1.7).fraction, 1.7, "the real value survives for VoiceOver")
    }

    func testArcIsClampedToAFullRing() {
        XCTAssertEqual(DSRing(progress: 0.5).drawnFraction, 0.5)
        XCTAssertEqual(DSRing(progress: 1).drawnFraction, 1)
        XCTAssertEqual(DSRing(progress: 3).drawnFraction, 1, "progress above 1 never draws past a closed ring")
        XCTAssertEqual(DSRing(progress: -1).drawnFraction, 0)
    }

    func testIsClosedAtTheGoal() {
        XCTAssertFalse(DSRing(progress: 0.999).isClosed)
        XCTAssertTrue(DSRing(progress: 1).isClosed)
        XCTAssertTrue(DSRing(progress: 1.4).isClosed)
        XCTAssertFalse(DSRing(progress: .nan).isClosed)
    }

    // MARK: - Close detection and the haptic beat

    func testOnlyAnOpenRingReachingItsGoalIsALiveClose() {
        XCTAssertTrue(Math.isLiveClose(from: 0.9, to: 1))
        XCTAssertTrue(Math.isLiveClose(from: 0, to: 1.5))
        XCTAssertFalse(Math.isLiveClose(from: 1, to: 1.5), "already closed: no second close")
        XCTAssertFalse(Math.isLiveClose(from: 1, to: 0.4), "re-opening is not a close")
        XCTAssertFalse(Math.isLiveClose(from: 0.2, to: 0.8))
    }

    func testSimultaneousClosesShareOneHaptic() {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        XCTAssertTrue(Math.shouldFireBeat(lastBeat: nil, now: start), "the first close always buzzes")
        XCTAssertFalse(Math.shouldFireBeat(lastBeat: start, now: start), "same instant: shared")
        XCTAssertFalse(Math.shouldFireBeat(lastBeat: start, now: start.addingTimeInterval(Math.beatWindow / 2)))
        XCTAssertTrue(Math.shouldFireBeat(lastBeat: start, now: start.addingTimeInterval(Math.beatWindow)), "a later close buzzes again")
        XCTAssertTrue(Math.shouldFireBeat(lastBeat: start, now: start.addingTimeInterval(2)))
    }

    // MARK: - Geometry

    func testRingsStepInByOneLaneEach() {
        let size: CGFloat = 160, line: CGFloat = 14, gap: CGFloat = 4
        XCTAssertEqual(Math.outerDiameter(index: 0, size: size, lineWidth: line, spacing: gap), 160)
        XCTAssertEqual(Math.outerDiameter(index: 1, size: size, lineWidth: line, spacing: gap), 124)
        XCTAssertEqual(Math.outerDiameter(index: 2, size: size, lineWidth: line, spacing: gap), 88)
    }

    func testRingsThatLeaveNoHoleAreDropped() {
        let size: CGFloat = 160, line: CGFloat = 14, gap: CGFloat = 4
        XCTAssertNotNil(Math.outerDiameter(index: 3, size: size, lineWidth: line, spacing: gap), "52 pt still has a 24 pt hole")
        XCTAssertNil(Math.outerDiameter(index: 4, size: size, lineWidth: line, spacing: gap), "16 pt can't hold a 14 pt stroke")
        XCTAssertNil(Math.outerDiameter(index: 0, size: 20, lineWidth: 14, spacing: 4))
    }

    func testEveryDrawnRingFitsInsideTheFrameWithAHole() {
        let size: CGFloat = 120, line: CGFloat = 10, gap: CGFloat = 2
        var previous = CGFloat.infinity
        for index in 0..<10 {
            guard let diameter = Math.outerDiameter(index: index, size: size, lineWidth: line, spacing: gap) else { continue }
            XCTAssertLessThanOrEqual(diameter, size)
            XCTAssertLessThan(diameter, previous, "rings must nest, outermost first")
            XCTAssertGreaterThan(diameter - 2 * line, 0, "the hole must stay open")
            previous = diameter
        }
    }

    // MARK: - VoiceOver

    func testPercentRoundsAndCaps() {
        XCTAssertEqual(Math.percent(of: DSRing(progress: 0.824)), 82)
        XCTAssertEqual(Math.percent(of: DSRing(progress: 0.826)), 83)
        XCTAssertEqual(Math.percent(of: DSRing(progress: 1.2)), 120, "over the goal reads as it is")
        XCTAssertEqual(Math.percent(of: DSRing(progress: -1)), 0)
        XCTAssertEqual(Math.percent(of: DSRing(progress: .nan)), 0)
        XCTAssertEqual(Math.percent(of: DSRing(progress: 1e300)), 99_999, "a runaway value must not trap")
    }

    func testSpokenRingUsesItsLabelAndMarksClosed() {
        XCTAssertEqual(Math.spoken(DSRing(progress: 0.6, label: "Exercise"), index: 1), "Exercise 60 percent")
        XCTAssertEqual(Math.spoken(DSRing(progress: 1, label: "Move"), index: 0), "Move 100 percent, complete")
        XCTAssertEqual(Math.spoken(DSRing(progress: 1.25, label: "Move"), index: 0), "Move 125 percent, complete")
    }

    func testUnlabelledRingsAreNamedByPosition() {
        XCTAssertEqual(Math.spoken(DSRing(progress: 0.5), index: 0), "Ring 1 50 percent")
        XCTAssertEqual(Math.spoken(DSRing(progress: 0.5), index: 2), "Ring 3 50 percent")
    }

    func testAccessibilityValueListsEveryRingOutermostFirst() {
        let rings = [
            DSRing(progress: 0.82, label: "Move"),
            DSRing(progress: 0.60, label: "Exercise"),
            DSRing(progress: 1, label: "Stand")
        ]
        XCTAssertEqual(
            Math.accessibilityValue(rings),
            "Move 82 percent. Exercise 60 percent. Stand 100 percent, complete"
        )
        XCTAssertEqual(Math.accessibilityValue([]), "")
    }
}
