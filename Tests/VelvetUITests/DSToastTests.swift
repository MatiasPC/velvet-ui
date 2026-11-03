import XCTest
import SwiftUI
@testable import VelvetUI

/// The pure parts of `.dsToast`: value identity, the flick maths, and the
/// auto-dismiss wait. The modifier itself is SwiftUI plumbing over these.
final class DSToastTests: XCTestCase {

    // MARK: - Value

    /// Two toasts with identical text are still two presentations, so assigning
    /// the binding again always re-presents (and restarts the timer).
    func testValuesAreDistinctPerPresentation() {
        let a = DSToastValue("Saved", type: .success)
        let b = DSToastValue("Saved", type: .success)
        XCTAssertNotEqual(a, b)
        XCTAssertNotEqual(a.id, b.id)
        XCTAssertEqual(a, a)
    }

    func testDefaults() {
        let value = DSToastValue("Hello")
        XCTAssertEqual(value.type, .info)
        XCTAssertEqual(value.duration, 2.5)
        XCTAssertTrue(value.autoDismisses)
    }

    /// Zero, negative and non-finite durations pin the toast until it is cleared.
    func testNonPositiveOrInfiniteDurationIsSticky() {
        XCTAssertFalse(DSToastValue("a", duration: 0).autoDismisses)
        XCTAssertFalse(DSToastValue("a", duration: -1).autoDismisses)
        XCTAssertFalse(DSToastValue("a", duration: .infinity).autoDismisses)
        XCTAssertFalse(DSToastValue("a", duration: .nan).autoDismisses)
        XCTAssertTrue(DSToastValue("a", duration: 0.1).autoDismisses)
    }

    func testEveryTypeHasAHaptic() {
        // The presenter fires `type.haptic` on present; keep the mapping total.
        XCTAssertEqual(DSToastType.success.haptic, .success)
        XCTAssertEqual(DSToastType.error.haptic, .error)
        XCTAssertEqual(DSToastType.warning.haptic, .warning)
        XCTAssertEqual(DSToastType.info.haptic, .light)
    }

    // MARK: - Drag

    func testOutwardDirectionFollowsTheEdge() {
        XCTAssertGreaterThan(DSToastLogic.outward(-10, edge: .top), 0, "up is out for a top toast")
        XCTAssertLessThan(DSToastLogic.outward(10, edge: .top), 0)
        XCTAssertGreaterThan(DSToastLogic.outward(10, edge: .bottom), 0, "down is out for a bottom toast")
        XCTAssertLessThan(DSToastLogic.outward(-10, edge: .bottom), 0)
    }

    func testToastFollowsTheFingerTowardItsEdge() {
        XCTAssertEqual(DSToastLogic.dragOffset(translation: -30, edge: .top), -30)
        XCTAssertEqual(DSToastLogic.dragOffset(translation: 30, edge: .bottom), 30)
    }

    func testToastResistsBeingDraggedIntoTheScreen() {
        let top = DSToastLogic.dragOffset(translation: 50, edge: .top)
        XCTAssertEqual(top, 50 * DSToastLogic.inwardResistance)
        XCTAssertLessThan(abs(top), 50)
        let bottom = DSToastLogic.dragOffset(translation: -50, edge: .bottom)
        XCTAssertEqual(bottom, -50 * DSToastLogic.inwardResistance)
        XCTAssertGreaterThan(DSToastLogic.inwardResistance, 0)
        XCTAssertLessThan(DSToastLogic.inwardResistance, 1)
    }

    func testReleasePastTheThresholdDismisses() {
        let d = DSToastLogic.dismissDistance
        XCTAssertTrue(DSToastLogic.shouldDismiss(translation: -(d + 1), predictedEnd: -(d + 1), edge: .top))
        XCTAssertTrue(DSToastLogic.shouldDismiss(translation: d + 1, predictedEnd: d + 1, edge: .bottom))
    }

    func testShortSlowDragSnapsBack() {
        let d = DSToastLogic.dismissDistance
        XCTAssertFalse(DSToastLogic.shouldDismiss(translation: -(d - 1), predictedEnd: -(d - 1), edge: .top))
        XCTAssertFalse(DSToastLogic.shouldDismiss(translation: d - 1, predictedEnd: d - 1, edge: .bottom))
        XCTAssertFalse(DSToastLogic.shouldDismiss(translation: 0, predictedEnd: 0, edge: .top))
    }

    /// A drag toward the screen never dismisses, however far it is projected.
    func testInwardDragNeverDismisses() {
        XCTAssertFalse(DSToastLogic.shouldDismiss(translation: 200, predictedEnd: 600, edge: .top))
        XCTAssertFalse(DSToastLogic.shouldDismiss(translation: -200, predictedEnd: -600, edge: .bottom))
    }

    /// A quick flick travels little but projects far: it still dismisses.
    func testFastFlickDismissesEvenWhenShort() {
        let short = DSToastLogic.dismissDistance / 2
        let far = DSToastLogic.projectedDismissDistance + 1
        XCTAssertTrue(DSToastLogic.shouldDismiss(translation: -short, predictedEnd: -far, edge: .top))
        XCTAssertTrue(DSToastLogic.shouldDismiss(translation: short, predictedEnd: far, edge: .bottom))
    }

    // MARK: - Auto-dismiss wait

    func testWaitCompletesWhenNotCancelled() async {
        let completed = await DSToastLogic.wait(0.02)
        XCTAssertTrue(completed)
    }

    /// The contract the modifier relies on: a replacement or a manual dismissal
    /// cancels the pending `.task`, and a cancelled wait must report `false`, so the
    /// timer can never clear a toast it no longer owns.
    func testCancelledWaitNeverReportsCompletion() async {
        let timer = Task { await DSToastLogic.wait(30) }
        try? await Task.sleep(for: .milliseconds(20))
        timer.cancel()
        let completed = await timer.value
        XCTAssertFalse(completed)
    }

    func testWaitAlreadyCancelledReturnsFalseImmediately() async {
        let timer = Task { () -> Bool in
            withUnsafeCurrentTask { $0?.cancel() }
            return await DSToastLogic.wait(30)
        }
        let completed = await timer.value
        XCTAssertFalse(completed)
    }
}
