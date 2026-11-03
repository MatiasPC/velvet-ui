import XCTest
import SwiftUI
@testable import VelvetUI

// Every snippet on docs/components/DSConfetti.md lives here verbatim.
enum DocSnippetsConfetti {
    struct ConfettiDemo: View {
        @State private var celebrations = 0

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    Text("Order placed").ds(.title2)
                    DSButton("Celebrate") { celebrations += 1 }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dsConfetti(trigger: celebrations, origin: UnitPoint(x: 0.5, y: 0.6))
            }
        }
    }

    struct ConfettiCornersDemo: View {
        @State private var left = 0
        @State private var right = 0

        var body: some View {
            VStack {
                DSButton("Both corners") { left += 1; right += 1 }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dsConfetti(trigger: left, origin: .bottomLeading, count: 50)
            .dsConfetti(trigger: right, origin: .bottomTrailing, count: 50, haptic: .success)
        }
    }
}

@MainActor
final class DSConfettiTests: XCTestCase {

    func testSnippetsInstantiate() {
        _ = DocSnippetsConfetti.ConfettiDemo().body
        _ = DocSnippetsConfetti.ConfettiCornersDemo().body
    }

    func testSameSeedProducesSamePieces() {
        let a = DSConfettiBurst.pieces(count: 40, seed: 7, colorCount: 5)
        let b = DSConfettiBurst.pieces(count: 40, seed: 7, colorCount: 5)
        XCTAssertEqual(a, b)
    }

    func testDifferentSeedsDiffer() {
        XCTAssertNotEqual(
            DSConfettiBurst.pieces(count: 40, seed: 1),
            DSConfettiBurst.pieces(count: 40, seed: 2)
        )
    }

    func testCountIsClamped() {
        XCTAssertEqual(DSConfettiBurst.clampedCount(10_000), 150)
        XCTAssertEqual(DSConfettiBurst.clampedCount(-5), 0)
        XCTAssertEqual(DSConfettiBurst.pieces(count: 10_000, seed: 1).count, 150)
        XCTAssertEqual(DSConfettiBurst.pieces(count: 80, seed: 1).count, 80)
    }

    func testLifetimesAndColorsAreInRange() {
        for piece in DSConfettiBurst.pieces(count: 150, seed: 3, colorCount: 6) {
            XCTAssertGreaterThanOrEqual(piece.lifetime, 1.6)
            XCTAssertLessThanOrEqual(piece.lifetime, 2.4)
            XCTAssertTrue((0..<6).contains(piece.colorIndex))
        }
    }

    func testPiecesStartAtTheOrigin() {
        for piece in DSConfettiBurst.pieces(count: 30, seed: 4) {
            let start = piece.offset(at: piece.delay)
            XCTAssertEqual(start.x, 0, accuracy: 0.001)
            XCTAssertEqual(start.y, 0, accuracy: 0.001)
        }
    }

    func testGravityPullsPiecesPastTheirApex() {
        for piece in DSConfettiBurst.pieces(count: 60, seed: 5) {
            let times = stride(from: piece.delay, through: piece.delay + piece.lifetime, by: 0.02)
            let ys = times.map { piece.offset(at: $0).y }
            let apex = ys.min() ?? 0
            let end = piece.offset(at: piece.delay + piece.lifetime).y
            XCTAssertGreaterThan(end, apex, "A piece must be falling by the end of its life")
            XCTAssertGreaterThan(end, ys[ys.count - 2], "Still descending at the end")
        }
    }

    func testOpacityStartsHighHoldsThenReachesZeroAtEndOfLife() {
        let piece = DSConfettiBurst.pieces(count: 1, seed: 6)[0]
        XCTAssertEqual(piece.opacity(at: piece.delay + piece.lifetime * 0.5), 1, accuracy: 0.0001)
        let fading = piece.opacity(at: piece.delay + piece.lifetime * 0.85)
        XCTAssertGreaterThan(fading, 0)
        XCTAssertLessThan(fading, 1)
        XCTAssertEqual(piece.opacity(at: piece.delay + piece.lifetime), 0)
        XCTAssertEqual(piece.opacity(at: piece.delay + piece.lifetime + 1), 0)
    }

    func testFlutterStaysWithinBounds() {
        let piece = DSConfettiBurst.pieces(count: 1, seed: 8)[0]
        for step in 0..<100 {
            let flutter = piece.flutter(at: Double(step) * 0.02)
            XCTAssertGreaterThan(flutter, 0)
            XCTAssertLessThanOrEqual(flutter, 1)
        }
    }

    func testLiveness() {
        let pieces = DSConfettiBurst.pieces(count: 20, seed: 9)
        XCTAssertTrue(DSConfettiBurst.isAlive(pieces, at: 0))
        XCTAssertFalse(DSConfettiBurst.isAlive(pieces, at: DSConfettiBurst.maxDuration + 0.01))
        XCTAssertFalse(DSConfettiBurst.isAlive([], at: 0))

        let piece = pieces[0]
        XCTAssertFalse(piece.isAlive(at: piece.delay - 0.01))
        XCTAssertTrue(piece.isAlive(at: piece.delay + 0.01))
        XCTAssertFalse(piece.isAlive(at: piece.delay + piece.lifetime))
    }

    func testSplitMixIsDeterministic() {
        var a = DSSplitMix64(seed: 42)
        var b = DSSplitMix64(seed: 42)
        XCTAssertEqual((0..<5).map { _ in a.next() }, (0..<5).map { _ in b.next() })
    }
}
