import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSFlipCard.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsFlipCard {
    struct FlipDemo: View {
        var body: some View {
            DSScreen(backdrop: true) {
                // Tap anywhere on the card to turn it over.
                DSFlipCard {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("This month").ds(.footnote)
                        Text("1 248").ds(.displayMedium)
                        Text("Tap to see the trend").ds(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } back: {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("vs. last month").ds(.footnote)
                        Text("+12%").ds(.displayMedium)
                        Text("Tap to flip back").ds(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .dsScreenPadding()
            }
        }
    }

    struct CardFace: View {
        @State private var revealed = false

        var body: some View {
            VStack(spacing: DSSpacing.md) {
                DSFlipCard(isFlipped: $revealed, axis: .vertical) {
                    Text("•••• 4242").ds(.numeric)
                } back: {
                    Text("CVC 123 · 09/28").ds(.numeric)
                }

                DSButton(revealed ? "Hide" : "Reveal", variant: .secondary, size: .small) {
                    withAnimation(DSAnimation.springSmooth) { revealed.toggle() }
                }
            }
        }
    }
}

@MainActor
final class DSFlipCardTests: XCTestCase {

    func testSnippetsInstantiate() {
        _ = DocSnippetsFlipCard.FlipDemo()
        _ = DocSnippetsFlipCard.CardFace()
    }

    // MARK: - Math

    func testRestAngles() {
        XCTAssertEqual(DSFlipMath.angle(isFlipped: false), 0)
        XCTAssertEqual(DSFlipMath.angle(isFlipped: true), 180)
    }

    func testFacesSwapExactlyAtTheEdge() {
        XCTAssertFalse(DSFlipMath.showsBack(angle: 0))
        XCTAssertFalse(DSFlipMath.showsBack(angle: 89.9))
        XCTAssertTrue(DSFlipMath.showsBack(angle: 90))
        XCTAssertTrue(DSFlipMath.showsBack(angle: 180))
        // A spring that overshoots either way must not flicker the wrong face at rest.
        XCTAssertTrue(DSFlipMath.showsBack(angle: 186))
        XCTAssertFalse(DSFlipMath.showsBack(angle: -4))
    }

    func testBackPreRotationCancelsTheHalfTurn() {
        XCTAssertEqual(DSFlipMath.backPreRotation(reduceMotion: false), 180)
        XCTAssertEqual(DSFlipMath.backPreRotation(reduceMotion: true), 0)
    }

    func testSolidBodyIsHeldLongerThanTheSpringTakesToSettle() {
        // springSmooth has a 0.45 s response; the hold must outlast its visible tail.
        XCTAssertGreaterThan(DSFlipMath.settleSeconds, 0.45 * 1.5)
        XCTAssertLessThan(DSFlipMath.settleSeconds, 2)
    }

    func testAxisVectors() {
        XCTAssertEqual(DSFlipAxis.horizontal.vector.y, 1)
        XCTAssertEqual(DSFlipAxis.vertical.vector.x, 1)
    }

    // MARK: - Rendered result

    private func rendered(flipped: Bool, axis: DSFlipAxis) -> NSBitmapImageRep? {
        // Front is all red; back is blue with a green bar on its LEADING edge.
        let card = DSFlipCard(isFlipped: .constant(flipped), axis: axis, style: .flat, padding: 0, cornerRadius: 0) {
            Color.red.frame(width: 100, height: 100)
        } back: {
            ZStack(alignment: .leading) {
                Color.blue
                Color.green.frame(width: 20)
            }
            .frame(width: 100, height: 100)
        }
        let renderer = ImageRenderer(content: card.frame(width: 200, height: 200).background(Color.white))
        renderer.scale = 1
        guard let cg = renderer.cgImage else { return nil }
        return NSBitmapImageRep(cgImage: cg)
    }

    private func count(_ rep: NSBitmapImageRep, where match: (NSColor) -> Bool) -> Int {
        var n = 0
        for x in 0..<rep.pixelsWide {
            for y in 0..<rep.pixelsHigh {
                if let c = rep.colorAt(x: x, y: y), match(c) { n += 1 }
            }
        }
        return n
    }

    func testFlippedCardShowsOnlyTheBackAndNotMirrored() throws {
        for axis in [DSFlipAxis.horizontal, .vertical] {
            let rep = try XCTUnwrap(rendered(flipped: true, axis: axis))
            let red = count(rep) { $0.redComponent > 0.8 && $0.greenComponent < 0.4 && $0.blueComponent < 0.4 }
            XCTAssertEqual(red, 0, "front must be hidden past 90 degrees (\(axis))")
            let bar = count(rep) { $0.greenComponent > 0.6 && $0.redComponent < 0.4 && $0.blueComponent < 0.4 }
            XCTAssertGreaterThan(bar, 100, "back must be visible (\(axis))")
            // Not mirrored: the leading-edge bar sits in the left half (and top half would be unchanged).
            var left = 0, right = 0
            for x in 0..<rep.pixelsWide {
                for y in 0..<rep.pixelsHigh {
                    guard let c = rep.colorAt(x: x, y: y), c.greenComponent > 0.6, c.redComponent < 0.4, c.blueComponent < 0.4 else { continue }
                    if x < rep.pixelsWide / 2 { left += 1 } else { right += 1 }
                }
            }
            XCTAssertGreaterThan(left, right * 10, "back face is mirrored (\(axis))")
        }
    }

    func testRestingCardShowsOnlyTheFront() throws {
        let rep = try XCTUnwrap(rendered(flipped: false, axis: .horizontal))
        let red = count(rep) { $0.redComponent > 0.8 && $0.greenComponent < 0.4 && $0.blueComponent < 0.4 }
        let blue = count(rep) { $0.blueComponent > 0.8 && $0.redComponent < 0.4 && $0.greenComponent < 0.4 }
        XCTAssertGreaterThan(red, 100)
        XCTAssertEqual(blue, 0)
    }
}
