import XCTest
@testable import VelvetUI

/// The rules behind `DSTimeline`: which step is complete, current or upcoming,
/// which connectors are filled, and when a change in `currentStep` is progress
/// (the only time the spring runs and the success haptic fires).
final class DSTimelineTests: XCTestCase {

    // MARK: - Clamping

    func testClampKeepsTheStepInsideZeroToCount() {
        XCTAssertEqual(DSTimelineProgress.clamped(-3, count: 4), 0)
        XCTAssertEqual(DSTimelineProgress.clamped(0, count: 4), 0)
        XCTAssertEqual(DSTimelineProgress.clamped(2, count: 4), 2)
        XCTAssertEqual(DSTimelineProgress.clamped(4, count: 4), 4)
        XCTAssertEqual(DSTimelineProgress.clamped(9, count: 4), 4)
    }

    func testClampOfAnEmptyTimelineIsZero() {
        XCTAssertEqual(DSTimelineProgress.clamped(0, count: 0), 0)
        XCTAssertEqual(DSTimelineProgress.clamped(5, count: 0), 0)
        XCTAssertEqual(DSTimelineProgress.clamped(-1, count: 0), 0)
    }

    // MARK: - Status

    private func statuses(step: Int, count: Int = 4) -> [DSTimelineStatus] {
        (0..<count).map { DSTimelineProgress.status(index: $0, currentStep: step, count: count) }
    }

    func testStatusSplitsStepsAroundTheLiveOne() {
        XCTAssertEqual(statuses(step: 2), [.complete, .complete, .current, .upcoming])
    }

    func testFirstStepIsLiveAtZero() {
        XCTAssertEqual(statuses(step: 0), [.current, .upcoming, .upcoming, .upcoming])
    }

    func testStepEqualToCountMeansEverythingIsComplete() {
        XCTAssertEqual(statuses(step: 4), [.complete, .complete, .complete, .complete])
    }

    func testOutOfRangeStepsBehaveLikeTheNearestEnd() {
        XCTAssertEqual(statuses(step: -5), statuses(step: 0))
        XCTAssertEqual(statuses(step: 99), statuses(step: 4))
    }

    // MARK: - Connectors

    func testConnectorIsFilledOnceItsStepIsDone() {
        let filled = (0..<4).map { DSTimelineProgress.isConnectorFilled(after: $0, currentStep: 2, count: 4) }
        XCTAssertEqual(filled, [true, true, false, false])
    }

    func testNoConnectorIsFilledAtTheStart() {
        let filled = (0..<4).map { DSTimelineProgress.isConnectorFilled(after: $0, currentStep: 0, count: 4) }
        XCTAssertEqual(filled, [false, false, false, false])
    }

    func testConnectorFillFollowsTheClampedStep() {
        let filled = (0..<4).map { DSTimelineProgress.isConnectorFilled(after: $0, currentStep: 40, count: 4) }
        XCTAssertEqual(filled, [true, true, true, true])
    }

    // MARK: - Advance (spring and haptic gate)

    func testOnlyForwardMovementIsAnAdvance() {
        XCTAssertTrue(DSTimelineProgress.isAdvance(from: 1, to: 2))
        XCTAssertTrue(DSTimelineProgress.isAdvance(from: 0, to: 4))
        XCTAssertFalse(DSTimelineProgress.isAdvance(from: 2, to: 2))
        XCTAssertFalse(DSTimelineProgress.isAdvance(from: 3, to: 1))
    }

    /// `DSTimeline` observes the clamped step, so a request beyond the end after
    /// the flow already finished is a no-op, not a second celebration.
    func testRequestsPastTheEndDoNotCountAsAdvances() {
        let requested = [2, 2, 3, 1, 4, 9, 12]
        let clamped = requested.map { DSTimelineProgress.clamped($0, count: 4) }
        let advances = zip(clamped, clamped.dropFirst()).filter {
            DSTimelineProgress.isAdvance(from: $0, to: $1)
        }
        // 2 -> 3 and 1 -> 4; 4 -> 4 twice is not progress.
        XCTAssertEqual(advances.count, 2)
    }
}
