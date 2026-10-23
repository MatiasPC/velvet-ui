import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSSuccessCheck.md lives here verbatim.
enum DocSnippetsSuccessCheck {
    struct SuccessCheckDemo: View {
        @State private var isPaid = false

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    DSSuccessCheck(isComplete: isPaid, size: 96, accessibilityLabel: "Payment sent")
                        .padding(DSSpacing.md)
                    Text(isPaid ? "Payment sent" : "Ready to pay").ds(.title2)
                    DSButton(isPaid ? "Reset" : "Pay $24.00", isFullWidth: true) {
                        isPaid.toggle()
                    }
                }
                .dsScreenPadding()
            }
        }
    }

    struct VariantsDemo: View {
        var body: some View {
            HStack(spacing: DSSpacing.lg) {
                DSSuccessCheck(isComplete: true, size: 32)
                DSSuccessCheck(isComplete: true, size: 48, color: DSColors.info, haptic: nil)
            }
        }
    }
}

@MainActor
final class DSSuccessCheckTests: XCTestCase {
    typealias T = DSSuccessCheckTimeline

    func testSnippetsInstantiate() {
        _ = DocSnippetsSuccessCheck.SuccessCheckDemo().body
        _ = DocSnippetsSuccessCheck.VariantsDemo().body
    }

    func testCheckPointsStayInsideTheRing() {
        // The ring's inner radius is 0.5 minus its stroke; the check must sit within it.
        for point in T.checkPoints {
            let distance = hypot(point.x - 0.5, point.y - 0.5)
            XCTAssertLessThan(distance, 0.4, "check point \(point) is too close to the ring")
            XCTAssertTrue((0...1).contains(point.x) && (0...1).contains(point.y))
        }
        XCTAssertEqual(T.checkPoints.count, 3)
    }

    func testPopPeaksExactlyWhenTheCheckCompletes() {
        XCTAssertEqual(T.popStart + T.popRise, T.checkStart + T.checkDuration, accuracy: 0.0001)
        XCTAssertEqual(T.peak, T.checkStart + T.checkDuration, accuracy: 0.0001)
        XCTAssertEqual(T.peakDelayFromPopStart, T.popRise, accuracy: 0.0001)
    }

    func testStagesAreOrderedAndTotalIsAboutNineTenths() {
        XCTAssertLessThan(T.ringStart, T.discStart)
        XCTAssertLessThan(T.discStart, T.checkStart)
        XCTAssertGreaterThanOrEqual(T.popStart, 0)
        XCTAssertTrue((0.7...0.95).contains(T.total), "total \(T.total) outside the intended range")
    }

    func testAccessibilityLabelOnlyWhileComplete() {
        XCTAssertEqual(T.accessibilityLabel("Done", isComplete: true), "Done")
        XCTAssertNil(T.accessibilityLabel("Done", isComplete: false))
    }
}
