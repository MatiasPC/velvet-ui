import XCTest
import SwiftUI
@testable import VelvetUI

// The Usage snippet on docs/components/DSMarquee.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsMarquee {
    struct NowPlaying: View {
        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Now playing").ds(.overline, color: DSColors.textSecondary)

                    DSMarquee {
                        Text("Midnight City · M83 · Hurry Up, We're Dreaming").ds(.callout)
                    }

                    // Any content, not just text — it scrolls as one line.
                    DSMarquee(velocity: 28) {
                        HStack(spacing: DSSpacing.xs) {
                            DSBadge("LIVE", variant: .filled)
                            Text("Breaking news scrolls by, in full").ds(.footnote)
                        }
                    }
                }
                .dsScreenPadding()
            }
        }
    }
}

@MainActor
final class DSMarqueeTests: XCTestCase {

    func testSnippetInstantiates() {
        _ = DocSnippetsMarquee.NowPlaying()
    }

    func testDefaultVelocity() {
        XCTAssertEqual(DSMarquee<Text>.defaultVelocity, 40)
    }

    func testOffsetStartsAtZero() {
        XCTAssertEqual(DSMarqueeMath.offset(elapsed: 0, distance: 200, velocity: 40), 0)
        XCTAssertEqual(DSMarqueeMath.offset(elapsed: -3, distance: 200, velocity: 40), 0)
    }

    func testOffsetDriftsLeftAtTheVelocity() {
        XCTAssertEqual(DSMarqueeMath.offset(elapsed: 1, distance: 200, velocity: 40), -40, accuracy: 0.001)
        XCTAssertEqual(DSMarqueeMath.offset(elapsed: 2.5, distance: 200, velocity: 40), -100, accuracy: 0.001)
    }

    func testOffsetWrapsExactlyOneCopyWidthPlusGap() {
        // 200 pt of travel at 40 pt/s is 5 s: back to the start, so the seam never shows.
        XCTAssertEqual(DSMarqueeMath.offset(elapsed: 5, distance: 200, velocity: 40), 0, accuracy: 0.001)
        XCTAssertEqual(DSMarqueeMath.offset(elapsed: 6, distance: 200, velocity: 40), -40, accuracy: 0.001)
    }

    func testOffsetStaysWithinOneLoop() {
        for step in 0...200 {
            let offset = DSMarqueeMath.offset(elapsed: Double(step) * 0.37, distance: 150, velocity: 33)
            XCTAssertLessThanOrEqual(offset, 0)
            XCTAssertGreaterThan(offset, -150)
        }
    }

    func testNoMotionWithoutADistanceOrAVelocity() {
        XCTAssertEqual(DSMarqueeMath.offset(elapsed: 4, distance: 0, velocity: 40), 0)
        XCTAssertEqual(DSMarqueeMath.offset(elapsed: 4, distance: 200, velocity: 0), 0)
    }
}
