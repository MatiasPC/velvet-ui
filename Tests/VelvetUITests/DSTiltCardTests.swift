import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSTiltCard.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsTiltCard {
    struct TiltDemo: View {
        var body: some View {
            DSScreen(backdrop: true) {
                VStack {
                    DSTiltCard {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Image(systemName: "creditcard.fill").font(.title2)
                            Text("Velvet Card").ds(.title2)
                            Text("•••• •••• •••• 2048").ds(.numeric)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .dsScreenPadding()
            }
        }
    }

    struct TiltVariantsDemo: View {
        var body: some View {
            VStack(spacing: DSSpacing.lg) {
                // A wider tilt, no haptic
                DSTiltCard(maxTilt: .degrees(20), haptic: nil) {
                    Text("Weekly streak").ds(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Tighter corners, buttons inside keep working
                DSTiltCard(padding: DSSpacing.lg, cornerRadius: DSRadius.surface) {
                    DSButton("Redeem", isFullWidth: true) {}
                }
            }
        }
    }
}

@MainActor
final class DSTiltCardTests: XCTestCase {

    func testSnippetsInstantiate() {
        _ = DocSnippetsTiltCard.TiltDemo()
        _ = DocSnippetsTiltCard.TiltVariantsDemo()
    }

    // MARK: - normalized

    func testNormalizedIsZeroAtRest() {
        let n = DSTiltMath.normalized(.zero)
        XCTAssertEqual(n.width, 0, accuracy: 0.0001)
        XCTAssertEqual(n.height, 0, accuracy: 0.0001)
    }

    func testNormalizedMapsTravelToOne() {
        let n = DSTiltMath.normalized(CGSize(width: DSTiltMetrics.travel / 2, height: -DSTiltMetrics.travel))
        XCTAssertEqual(n.width, 0.5, accuracy: 0.0001)
        XCTAssertEqual(n.height, -1, accuracy: 0.0001)
    }

    func testNormalizedClampsBeyondTravel() {
        let n = DSTiltMath.normalized(CGSize(width: 5_000, height: -5_000))
        XCTAssertEqual(n.width, 1, accuracy: 0.0001)
        XCTAssertEqual(n.height, -1, accuracy: 0.0001)
    }

    func testNormalizedIgnoresNonFiniteInput() {
        let n = DSTiltMath.normalized(CGSize(width: CGFloat.nan, height: CGFloat.infinity))
        XCTAssertEqual(n.width, 0, accuracy: 0.0001)
        XCTAssertEqual(n.height, 0, accuracy: 0.0001)
    }

    // MARK: - magnitude

    func testMagnitudeIsZeroAtRestAndOneAtTheEdge() {
        XCTAssertEqual(DSTiltMath.magnitude(of: .zero), 0, accuracy: 0.0001)
        XCTAssertEqual(DSTiltMath.magnitude(of: CGSize(width: 1, height: 0)), 1, accuracy: 0.0001)
        XCTAssertEqual(DSTiltMath.magnitude(of: CGSize(width: 0, height: -1)), 1, accuracy: 0.0001)
    }

    func testMagnitudeCapsAtOneInTheCorner() {
        // The corner of the clamped square is √2 away from the centre; the sheen must not overshoot.
        XCTAssertEqual(DSTiltMath.magnitude(of: CGSize(width: 1, height: 1)), 1, accuracy: 0.0001)
    }

    // MARK: - rotation

    func testRotationIsZeroAtRest() {
        let r = DSTiltMath.rotation(for: .zero, maxTilt: .degrees(12))
        XCTAssertEqual(r.x, 0, accuracy: 0.0001)
        XCTAssertEqual(r.y, 0, accuracy: 0.0001)
    }

    func testRotationReachesMaxTiltAtTheEdge() {
        let r = DSTiltMath.rotation(for: CGSize(width: 1, height: 1), maxTilt: .degrees(20))
        XCTAssertEqual(abs(r.x), 20, accuracy: 0.0001)
        XCTAssertEqual(abs(r.y), 20, accuracy: 0.0001)
    }

    func testHorizontalDragRotatesAroundTheVerticalAxisOnly() {
        let r = DSTiltMath.rotation(for: CGSize(width: 1, height: 0), maxTilt: .degrees(12))
        XCTAssertEqual(r.x, 0, accuracy: 0.0001)
        XCTAssertEqual(r.y, 12, accuracy: 0.0001)
    }

    func testVerticalDragRotatesAroundTheHorizontalAxisOnly() {
        let r = DSTiltMath.rotation(for: CGSize(width: 0, height: 1), maxTilt: .degrees(12))
        XCTAssertEqual(r.y, 0, accuracy: 0.0001)
        // Dragging down dips the bottom edge away: negative rotation about x in SwiftUI's y-down space.
        XCTAssertEqual(r.x, -12, accuracy: 0.0001)
    }

    func testRotationIsSymmetric() {
        let a = DSTiltMath.rotation(for: CGSize(width: 0.4, height: -0.7), maxTilt: .degrees(12))
        let b = DSTiltMath.rotation(for: CGSize(width: -0.4, height: 0.7), maxTilt: .degrees(12))
        XCTAssertEqual(a.x, -b.x, accuracy: 0.0001)
        XCTAssertEqual(a.y, -b.y, accuracy: 0.0001)
    }

    func testNegativeMaxTiltIsTreatedAsMagnitude() {
        let r = DSTiltMath.rotation(for: CGSize(width: 1, height: 0), maxTilt: .degrees(-12))
        XCTAssertEqual(r.y, 12, accuracy: 0.0001)
    }

    // MARK: - API

    func testDefaultMaxTiltIsTwelveDegrees() {
        XCTAssertEqual(DSTiltMetrics.tilt.degrees, 12, accuracy: 0.0001)
    }
}
