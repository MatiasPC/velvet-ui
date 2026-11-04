import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSLikeButton.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsLikeButton {
    struct LikeDemo: View {
        @State private var isLiked = false
        @State private var likes = 128

        var body: some View {
            DSScreen(backdrop: true) {
                DSLikeButton(isLiked: $isLiked, count: likes, accessibilityLabel: "Like post")
                    .onChange(of: isLiked) { _, liked in
                        likes += liked ? 1 : -1
                    }
                    .dsScreenPadding()
            }
        }
    }

    struct VariantsDemo: View {
        var body: some View {
            HStack(spacing: DSSpacing.xl) {
                DSLikeButton(isLiked: .constant(true))                              // heart
                DSLikeButton(isLiked: .constant(true), symbol: "star.fill",
                             emptySymbol: "star", tint: DSColors.warning,
                             accessibilityLabel: "Favorite")                        // star
                DSLikeButton(isLiked: .constant(false), symbol: "bookmark.fill",
                             emptySymbol: "bookmark", accessibilityLabel: "Save")   // bookmark
            }
        }
    }
}

@MainActor
final class DSLikeButtonTests: XCTestCase {
    typealias T = DSLikeButtonTimeline

    func testSnippetsInstantiate() {
        _ = DocSnippetsLikeButton.LikeDemo().body
        _ = DocSnippetsLikeButton.VariantsDemo().body
    }

    // MARK: Beat

    func testLikingPopsAndFiresTheHapticOnThePeak() {
        let plan = T.plan(turningOn: true, reduceMotion: false)
        XCTAssertTrue(plan.pops)
        XCTAssertEqual(plan.hapticDelay, T.popRise, accuracy: 0.0001)
        XCTAssertEqual(plan.hapticDelay, T.peak, accuracy: 0.0001)
    }

    func testUnlikingIsQuiet() {
        // No pop and no halo; the haptic still confirms the tap, immediately.
        let plan = T.plan(turningOn: false, reduceMotion: false)
        XCTAssertFalse(plan.pops)
        XCTAssertEqual(plan.hapticDelay, 0)
    }

    func testReduceMotionNeverPopsButStillConfirmsTheTap() {
        for turningOn in [true, false] {
            let plan = T.plan(turningOn: turningOn, reduceMotion: true)
            XCTAssertFalse(plan.pops, "turningOn: \(turningOn)")
            XCTAssertEqual(plan.hapticDelay, 0, "turningOn: \(turningOn)")
        }
    }

    func testTheBeatIsOverWellInsideASecond() {
        XCTAssertEqual(T.total, max(T.popRise + T.popSettle, T.haloDuration), accuracy: 0.0001)
        XCTAssertLessThan(T.total, 1)
        // The haptic lands while the pop is still in flight, not after it ends.
        XCTAssertLessThan(T.peak, T.total)
    }

    // MARK: Accessibility

    func testAccessibilityValueReportsTheStateAndTheCount() {
        XCTAssertEqual(T.accessibilityValue(isLiked: false, count: nil), "Not liked")
        XCTAssertEqual(T.accessibilityValue(isLiked: true, count: nil), "Liked")
        XCTAssertEqual(T.accessibilityValue(isLiked: true, count: 129), "Liked, 129")
        XCTAssertEqual(T.accessibilityValue(isLiked: false, count: 0), "Not liked, 0")
    }
}
