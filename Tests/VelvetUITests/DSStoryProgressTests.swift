import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSStoryProgress.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsStoryProgress {
    struct StoryViewer: View {
        let stories: [String]
        var onClose: () -> Void = {}
        @State private var page = 0
        @Environment(\.scenePhase) private var scenePhase

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSStoryProgress(
                    currentPage: $page,
                    numberOfPages: stories.count,
                    isPaused: scenePhase != .active
                ) {
                    onClose()
                }
                Text(stories[page]).ds(.largeTitle)
                Spacer()
            }
            .dsScreenPadding()
            .overlay {
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { page = max(page - 1, 0) }
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if page < stories.count - 1 { page += 1 } else { onClose() }
                        }
                }
                .accessibilityHidden(true)
            }
            .dsBackdrop()
        }
    }

    struct HoldToPauseTips: View {
        @State private var page = 0
        @State private var isHolding = false
        @DSThemed private var theme

        var body: some View {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    DSStoryProgress(
                        currentPage: $page,
                        numberOfPages: 4,
                        duration: 6,
                        isPaused: isHolding,
                        accent: theme.ink,
                        accessibilityLabel: "Tip"
                    ) {
                        page = 0
                    }
                    Text("Tip \(page + 1) of 4").ds(.title3)
                }
            }
            .onLongPressGesture(minimumDuration: 0.2, perform: {}, onPressingChanged: { isHolding = $0 })
        }
    }
}

@MainActor
final class DSStoryProgressTests: XCTestCase {
    private typealias L = DSStoryProgressLogic
    private typealias Clock = DSStoryProgressClock

    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    // MARK: Pages

    func testPageCountIsNeverNegative() {
        XCTAssertEqual(L.pageCount(4), 4)
        XCTAssertEqual(L.pageCount(0), 0)
        XCTAssertEqual(L.pageCount(-3), 0)
    }

    func testOutOfRangePagesShowAsTheNearestPage() {
        XCTAssertEqual(L.displayedPage(2, numberOfPages: 4), 2)
        XCTAssertEqual(L.displayedPage(-1, numberOfPages: 4), 0)
        XCTAssertEqual(L.displayedPage(9, numberOfPages: 4), 3)
        XCTAssertEqual(L.displayedPage(5, numberOfPages: 0), 0)
    }

    func testBadDurationsFallBackToTheDefault() {
        XCTAssertEqual(L.duration(3), 3)
        XCTAssertEqual(L.duration(0), L.defaultDuration)
        XCTAssertEqual(L.duration(-2), L.defaultDuration)
        XCTAssertEqual(L.duration(.infinity), L.defaultDuration)
        XCTAssertEqual(L.duration(.nan), L.defaultDuration)
    }

    // MARK: Segments

    func testSegmentsBeforeAreFullAfterAreEmptyCurrentFollowsTheFraction() {
        XCTAssertEqual(L.fill(segment: 0, currentPage: 2, fraction: 0.4), 1)
        XCTAssertEqual(L.fill(segment: 1, currentPage: 2, fraction: 0.4), 1)
        XCTAssertEqual(L.fill(segment: 2, currentPage: 2, fraction: 0.4), 0.4, accuracy: 0.000_1)
        XCTAssertEqual(L.fill(segment: 3, currentPage: 2, fraction: 0.4), 0)
    }

    func testTheCurrentFillIsClamped() {
        XCTAssertEqual(L.fill(segment: 1, currentPage: 1, fraction: 1.7), 1)
        XCTAssertEqual(L.fill(segment: 1, currentPage: 1, fraction: -0.2), 0)
        XCTAssertEqual(L.fill(segment: 1, currentPage: 1, fraction: .nan), 0)
    }

    // MARK: Advancing

    func testARunOutPageAdvancesUntilTheLastOneFinishes() {
        XCTAssertEqual(L.next(after: 0, numberOfPages: 3), .advance(to: 1))
        XCTAssertEqual(L.next(after: 1, numberOfPages: 3), .advance(to: 2))
        XCTAssertEqual(L.next(after: 2, numberOfPages: 3), .finish)
        XCTAssertEqual(L.next(after: 0, numberOfPages: 1), .finish, "A single page finishes.")
        XCTAssertEqual(L.next(after: 7, numberOfPages: 3), .finish, "Past the end reads as the last page.")
    }

    func testVoiceOverStepsOnePageAndStopsAtTheEnds() {
        XCTAssertEqual(L.step(from: 1, by: 1, numberOfPages: 4), 2)
        XCTAssertEqual(L.step(from: 1, by: -1, numberOfPages: 4), 0)
        XCTAssertNil(L.step(from: 3, by: 1, numberOfPages: 4))
        XCTAssertNil(L.step(from: 0, by: -1, numberOfPages: 4))
        XCTAssertNil(L.step(from: 0, by: 1, numberOfPages: 0))
        XCTAssertEqual(L.step(from: 9, by: -1, numberOfPages: 4), 2, "An out-of-range page steps from the one shown.")
    }

    // MARK: Clock

    func testTheClockFillsOverTheDuration() {
        let clock = Clock(page: 0, isPaused: false, at: start)
        XCTAssertEqual(clock.fraction(for: 0, at: start, duration: 4), 0)
        XCTAssertEqual(clock.fraction(for: 0, at: start.addingTimeInterval(1), duration: 4), 0.25, accuracy: 0.000_1)
        XCTAssertEqual(clock.fraction(for: 0, at: start.addingTimeInterval(9), duration: 4), 1)
        XCTAssertEqual(clock.remaining(at: start.addingTimeInterval(1), duration: 4), 3, accuracy: 0.000_1)
        XCTAssertEqual(clock.remaining(at: start.addingTimeInterval(9), duration: 4), 0)
    }

    func testAPageTheClockIsNotTimingStartsEmpty() {
        let clock = Clock(page: 0, isPaused: false, at: start)
        XCTAssertEqual(clock.fraction(for: 1, at: start.addingTimeInterval(2), duration: 4), 0)
    }

    func testAPauseBanksTheTimeAndAResumeContinuesFromThere() {
        var clock = Clock(page: 0, isPaused: false, at: start)
        clock.sync(page: 0, isPaused: true, at: start.addingTimeInterval(1))
        // Ten seconds paused: nothing moves.
        XCTAssertEqual(clock.elapsed(at: start.addingTimeInterval(11)), 1, accuracy: 0.000_1)
        clock.sync(page: 0, isPaused: false, at: start.addingTimeInterval(11))
        XCTAssertEqual(clock.elapsed(at: start.addingTimeInterval(12)), 2, accuracy: 0.000_1)
        XCTAssertEqual(clock.remaining(at: start.addingTimeInterval(12), duration: 4), 2, accuracy: 0.000_1)
    }

    func testRepeatedSyncsDontDoubleCount() {
        var clock = Clock(page: 0, isPaused: false, at: start)
        clock.sync(page: 0, isPaused: false, at: start.addingTimeInterval(1))
        clock.sync(page: 0, isPaused: true, at: start.addingTimeInterval(2))
        clock.sync(page: 0, isPaused: true, at: start.addingTimeInterval(5))
        XCTAssertEqual(clock.elapsed(at: start.addingTimeInterval(8)), 2, accuracy: 0.000_1)
    }

    func testStartingPausedHoldsAtZero() {
        let clock = Clock(page: 2, isPaused: true, at: start)
        XCTAssertEqual(clock.elapsed(at: start.addingTimeInterval(30)), 0)
        XCTAssertEqual(clock.fraction(for: 2, at: start.addingTimeInterval(30), duration: 4), 0)
    }

    func testANewPageRestartsTheClockFromZero() {
        var clock = Clock(page: 0, isPaused: false, at: start)
        clock.sync(page: 1, isPaused: false, at: start.addingTimeInterval(3))
        XCTAssertEqual(clock.page, 1)
        XCTAssertEqual(clock.elapsed(at: start.addingTimeInterval(4)), 1, accuracy: 0.000_1)

        // A page picked while paused starts from zero and stays there.
        clock.sync(page: 2, isPaused: true, at: start.addingTimeInterval(5))
        XCTAssertEqual(clock.elapsed(at: start.addingTimeInterval(20)), 0)
    }

    func testFinishingHoldsTheLastSegmentFullUntilThePageChanges() {
        var clock = Clock(page: 2, isPaused: false, at: start)
        clock.finish()
        XCTAssertTrue(clock.isFinished)
        XCTAssertEqual(clock.fraction(for: 2, at: start, duration: 4), 1)
        // A pause or resume on the same page keeps it finished, so onFinish isn't called again.
        clock.sync(page: 2, isPaused: true, at: start.addingTimeInterval(1))
        clock.sync(page: 2, isPaused: false, at: start.addingTimeInterval(2))
        XCTAssertTrue(clock.isFinished)
        // Moving away clears it.
        clock.sync(page: 0, isPaused: false, at: start.addingTimeInterval(3))
        XCTAssertFalse(clock.isFinished)
        XCTAssertEqual(clock.fraction(for: 0, at: start.addingTimeInterval(3), duration: 4), 0)
    }

    // MARK: VoiceOver

    func testSpokenValueIsOneBasedAndClamped() {
        XCTAssertEqual(L.accessibilityValue(currentPage: 1, numberOfPages: 5), "2 of 5")
        XCTAssertEqual(L.accessibilityValue(currentPage: 9, numberOfPages: 5), "5 of 5")
        XCTAssertEqual(L.accessibilityValue(currentPage: 0, numberOfPages: 0), "")
    }

    // MARK: Rendering

    func testItBuildsWithAndWithoutPages() {
        let page = Binding.constant(1)
        _ = DSStoryProgress(currentPage: page, numberOfPages: 4).body
        _ = DSStoryProgress(currentPage: page, numberOfPages: 0, duration: -1, isPaused: true).body
        _ = DocSnippetsStoryProgress.StoryViewer(stories: ["Lisbon", "Porto"]).body
        _ = DocSnippetsStoryProgress.HoldToPauseTips().body
    }
}
