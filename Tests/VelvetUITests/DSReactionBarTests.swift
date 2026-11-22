import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSReactionBar.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsReactionBar {
    struct MessageReactions: View {
        @State private var reaction: String?

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    DSReactionBar(selection: $reaction)
                    Text("Dinner at eight?")
                        .ds(.body)
                        .padding(DSSpacing.md)
                        .dsSurface(.glass, radius: DSRadius.card)
                }
                .dsScreenPadding()
            }
        }
    }

    struct RideFeedback: View {
        @State private var mood: String?

        var body: some View {
            DSCard {
                VStack(spacing: DSSpacing.md) {
                    Text("How was your ride?").ds(.title3)
                    DSReactionBar(selection: $mood, reactions: ["😡", "🙁", "😐", "🙂", "😍"],
                                  accessibilityLabel: "Ride rating")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

@MainActor
final class DSReactionBarTests: XCTestCase {
    typealias L = DSReactionBarLogic

    private let cell: CGFloat = 44
    private var reactions: [String] { DSReactionBar.defaultReactions }

    func testSnippetsInstantiate() {
        _ = DocSnippetsReactionBar.MessageReactions().body
        _ = DocSnippetsReactionBar.RideFeedback().body
        _ = DSReactionBar(selection: .constant(nil)).body
    }

    func testDefaultReactions() {
        XCTAssertEqual(reactions, ["👍", "❤️", "😂", "😮", "😢", "🙏"])
        XCTAssertEqual(Set(reactions).count, reactions.count, "Default reactions must be unique.")
    }

    // MARK: Hit testing

    func testTouchLandsOnTheEmojiUnderIt() {
        XCTAssertEqual(L.index(at: CGPoint(x: 0, y: 22), cell: cell, count: 6, rowHeight: cell), 0)
        XCTAssertEqual(L.index(at: CGPoint(x: 43.9, y: 22), cell: cell, count: 6, rowHeight: cell), 0)
        XCTAssertEqual(L.index(at: CGPoint(x: 44, y: 22), cell: cell, count: 6, rowHeight: cell), 1)
        XCTAssertEqual(L.index(at: CGPoint(x: 5.5 * 44, y: 22), cell: cell, count: 6, rowHeight: cell), 5)
    }

    func testPastAnEndHoldsTheEndEmoji() {
        XCTAssertEqual(L.index(at: CGPoint(x: -20, y: 22), cell: cell, count: 6, rowHeight: cell), 0)
        XCTAssertEqual(L.index(at: CGPoint(x: 6 * 44 + 20, y: 22), cell: cell, count: 6, rowHeight: cell), 5)
        // Rising off the bar while sliding still counts, within the slack.
        XCTAssertEqual(L.index(at: CGPoint(x: 100, y: -40), cell: cell, count: 6, rowHeight: cell), 2)
    }

    func testFarFromTheBarHoversNothing() {
        let slack = cell * L.releaseSlack
        XCTAssertNil(L.index(at: CGPoint(x: 100, y: -slack - 1), cell: cell, count: 6, rowHeight: cell))
        XCTAssertNil(L.index(at: CGPoint(x: 100, y: cell + slack + 1), cell: cell, count: 6, rowHeight: cell))
        XCTAssertNil(L.index(at: CGPoint(x: -slack - 1, y: 22), cell: cell, count: 6, rowHeight: cell))
        XCTAssertNil(L.index(at: CGPoint(x: 6 * cell + slack + 1, y: 22), cell: cell, count: 6, rowHeight: cell))
    }

    func testDegenerateInputsHoverNothing() {
        XCTAssertNil(L.index(at: CGPoint(x: 10, y: 10), cell: cell, count: 0, rowHeight: cell))
        XCTAssertNil(L.index(at: CGPoint(x: 10, y: 10), cell: 0, count: 6, rowHeight: cell))
        XCTAssertNil(L.index(at: CGPoint(x: .nan, y: 10), cell: cell, count: 6, rowHeight: cell))
        XCTAssertNil(L.index(at: CGPoint(x: 10, y: .infinity), cell: cell, count: 6, rowHeight: cell))
    }

    // MARK: Swell

    func testNoFingerRestsEveryEmoji() {
        for i in 0..<6 {
            XCTAssertEqual(L.scale(at: i, fingerX: nil, cell: cell, count: 6), 1)
            XCTAssertEqual(L.lift(forScale: 1, cell: cell), 0)
        }
    }

    func testTheEmojiUnderTheFingerPeaksAndNeighboursFallOff() {
        let x = 2.5 * cell   // centre of the third emoji
        let scales = (0..<6).map { L.scale(at: $0, fingerX: x, cell: cell, count: 6) }
        XCTAssertEqual(scales[2], L.peakScale, accuracy: 0.0001)
        XCTAssertGreaterThan(scales[1], 1)
        XCTAssertLessThan(scales[1], scales[2])
        XCTAssertEqual(scales[1], scales[3], accuracy: 0.0001, "The falloff is symmetric.")
        XCTAssertLessThan(scales[0], scales[1])
        XCTAssertEqual(scales[5], 1, "Beyond the reach an emoji rests.")
        XCTAssertTrue(scales.allSatisfy { $0 >= 1 && $0 <= L.peakScale })
    }

    func testTheEndEmojiStillPeaksWithTheFingerPastIt() {
        XCTAssertEqual(L.scale(at: 0, fingerX: -30, cell: cell, count: 6), L.peakScale, accuracy: 0.0001)
        XCTAssertEqual(L.scale(at: 5, fingerX: 6 * cell + 30, cell: cell, count: 6), L.peakScale, accuracy: 0.0001)
    }

    func testTheSwellRisesInProportion() {
        XCTAssertEqual(L.lift(forScale: L.peakScale, cell: cell), (L.peakScale - 1) * cell * L.liftFactor, accuracy: 0.0001)
        XCTAssertEqual(L.lift(forScale: 0.8, cell: cell), 0, "A shrink never sinks the emoji.")
        XCTAssertGreaterThan(L.lift(forScale: L.peakScale, cell: cell), L.lift(forScale: 1.2, cell: cell))
    }

    // MARK: Picking

    func testPickingSetsAndPickingAgainTakesItBack() {
        XCTAssertEqual(L.picked("😂", current: nil), "😂")
        XCTAssertEqual(L.picked("😂", current: "👍"), "😂")
        XCTAssertNil(L.picked("😂", current: "😂"))
    }

    func testHapticsForAPickATakeBackAndNoChange() {
        XCTAssertEqual(L.haptic(from: nil, to: "👍"), .soft)
        XCTAssertEqual(L.haptic(from: "👍", to: "😂"), .soft)
        XCTAssertEqual(L.haptic(from: "👍", to: nil), .light)
        XCTAssertNil(L.haptic(from: "👍", to: "👍"))
        XCTAssertNil(L.haptic(from: nil, to: nil))
    }

    func testOnlyANewPickJumpsAndNeverUnderReduceMotion() {
        XCTAssertTrue(L.jumps(from: nil, to: "👍", reduceMotion: false))
        XCTAssertTrue(L.jumps(from: "😢", to: "👍", reduceMotion: false))
        XCTAssertFalse(L.jumps(from: "👍", to: nil, reduceMotion: false))
        XCTAssertFalse(L.jumps(from: "👍", to: "👍", reduceMotion: false))
        XCTAssertFalse(L.jumps(from: nil, to: "👍", reduceMotion: true))
    }

    func testTheJumpIsOverWellInsideASecond() {
        XCTAssertLessThan(L.jumpRise + L.jumpFall, 0.6)
        XCTAssertGreaterThan(L.jumpHeight, 0)
    }

    // MARK: Tracker

    func testTheFirstTouchDoesNotTickButCrossingIntoANewEmojiDoes() {
        var t = DSReactionBarTracker()
        XCTAssertFalse(t.move(to: 1, x: 60))
        XCTAssertTrue(t.isTracking)
        XCTAssertEqual(t.hovered, 1)
        XCTAssertFalse(t.move(to: 1, x: 70), "Moving within one emoji is silent.")
        XCTAssertTrue(t.move(to: 2, x: 100))
        XCTAssertTrue(t.move(to: 1, x: 60))
    }

    func testLeavingAndComingBackToTheSameEmojiIsSilent() {
        var t = DSReactionBarTracker()
        _ = t.move(to: 3, x: 150)
        XCTAssertFalse(t.move(to: nil, x: 150))
        XCTAssertNil(t.hovered)
        XCTAssertNil(t.fingerX, "Outside the bar nothing swells.")
        XCTAssertFalse(t.move(to: 3, x: 150))
        XCTAssertTrue(t.move(to: 4, x: 200))
    }

    func testEndingPicksTheHoveredEmojiAndResets() {
        var t = DSReactionBarTracker()
        _ = t.move(to: 0, x: 10)
        _ = t.move(to: 4, x: 200)
        XCTAssertEqual(t.end(), 4)
        XCTAssertEqual(t, DSReactionBarTracker())
        XCTAssertFalse(t.isTracking)
    }

    func testEndingOutsideTheBarPicksNothing() {
        var t = DSReactionBarTracker()
        _ = t.move(to: 2, x: 100)
        _ = t.move(to: nil, x: 100)
        XCTAssertNil(t.end())
    }

    func testANewDragStartsFresh() {
        var t = DSReactionBarTracker()
        _ = t.move(to: 2, x: 100)
        _ = t.end()
        XCTAssertFalse(t.move(to: 4, x: 200), "The first touch of the next drag doesn't tick.")
    }

    // MARK: VoiceOver

    func testSwipingUpStepsForwardAndStopsAtTheLast() {
        XCTAssertEqual(L.adjusted(nil, in: reactions, increment: true), "👍")
        XCTAssertEqual(L.adjusted("👍", in: reactions, increment: true), "❤️")
        XCTAssertEqual(L.adjusted("🙏", in: reactions, increment: true), "🙏")
    }

    func testSwipingDownStepsBackAndTakesTheReactionBackFromTheFirst() {
        XCTAssertEqual(L.adjusted("❤️", in: reactions, increment: false), "👍")
        XCTAssertNil(L.adjusted("👍", in: reactions, increment: false))
        XCTAssertNil(L.adjusted(nil, in: reactions, increment: false))
    }

    func testAnUnknownSelectionReadsAsNone() {
        XCTAssertEqual(L.adjusted("🦄", in: reactions, increment: true), "👍")
        XCTAssertNil(L.adjusted("🦄", in: reactions, increment: false))
        XCTAssertEqual(L.adjusted("🦄", in: [], increment: true), "🦄", "No reactions: nothing to step to.")
    }

    func testAccessibilityValue() {
        XCTAssertEqual(L.accessibilityValue(nil), "None")
        XCTAssertEqual(L.accessibilityValue("😂"), "😂")
    }
}
