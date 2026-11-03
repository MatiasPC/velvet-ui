import XCTest
import SwiftUI
import CoreGraphics
@testable import VelvetUI

@MainActor
final class DSSlideToConfirmTests: XCTestCase {

    private let track = DSSlideToConfirm.trackHeight

    // MARK: - Collapse mask geometry

    /// Size of the capsule the mask draws for a track `trackWidth` wide: a negative
    /// padding grows it past the track, a positive one closes it in.
    private func maskSize(trackWidth: CGFloat, isCollapsed: Bool) -> CGSize {
        let padding = DSSlideToConfirm.collapseMaskPadding(trackWidth: trackWidth, isCollapsed: isCollapsed)
        return CGSize(
            width: trackWidth - 2 * padding.horizontal,
            height: track - 2 * padding.vertical
        )
    }

    /// The bug: a capsule exactly as tall as the track sits tangent to the idle
    /// knob (also exactly as tall as the track) and its antialiased edge shaves
    /// the knob's top and bottom. At rest the mask must be strictly larger than
    /// the track on every side.
    func testMaskClearsTheTrackAtRest() {
        for width in [200, 320, 430] as [CGFloat] {
            let size = maskSize(trackWidth: width, isCollapsed: false)
            XCTAssertGreaterThan(size.height, track, "The mask must clear the knob's top and bottom")
            XCTAssertGreaterThan(size.width, width, "The mask must clear the knob's leading and trailing edge")
            // Room for the knob's `.sm` shadow (radius 8, y 2) as well.
            let shadowReach = DSShadow.sm.radius + DSShadow.sm.y
            XCTAssertGreaterThanOrEqual((size.height - track) / 2, shadowReach)
        }
    }

    /// The collapsed end state is unchanged by the fix: exactly `trackHeight`
    /// wide and tall, so the capsule is a circle.
    func testCollapsedMaskIsExactlyTrackHeightSquare() {
        for width in [200, 320, 430] as [CGFloat] {
            let size = maskSize(trackWidth: width, isCollapsed: true)
            XCTAssertEqual(size.width, track, accuracy: 0.0001)
            XCTAssertEqual(size.height, track, accuracy: 0.0001)
        }
    }

    /// Both axes close in the same direction (never one growing while the other
    /// shrinks), so interpolating between rest and collapsed — which is what the
    /// spring does — shrinks the mask monotonically with no bulge or pop.
    func testMaskOnlyShrinksFromRestToCollapsed() {
        let width: CGFloat = 320
        let rest = maskSize(trackWidth: width, isCollapsed: false)
        let collapsed = maskSize(trackWidth: width, isCollapsed: true)
        XCTAssertGreaterThan(rest.width, collapsed.width)
        XCTAssertGreaterThan(rest.height, collapsed.height)

        var previous = rest
        for step in 1...20 {
            let t = CGFloat(step) / 20
            let size = CGSize(
                width: rest.width + (collapsed.width - rest.width) * t,
                height: rest.height + (collapsed.height - rest.height) * t
            )
            XCTAssertLessThan(size.width, previous.width)
            XCTAssertLessThan(size.height, previous.height)
            XCTAssertGreaterThanOrEqual(size.height, track - 0.0001, "Never crops the track before the end")
            previous = size
        }
    }

    /// A track narrower than it is tall can't collapse any further.
    func testNarrowTrackDoesNotInvertTheMask() {
        let size = maskSize(trackWidth: track - 10, isCollapsed: true)
        XCTAssertEqual(size.height, track, accuracy: 0.0001)
        XCTAssertGreaterThan(size.width, 0)
    }

    // MARK: - Rendered knob

    /// Renders the idle control and counts the fully opaque pixels down the
    /// knob's vertical diameter. With the old mask the top and bottom rows were
    /// shaved (168x166 at @3x); a true circle measures the full diameter.
    func testIdleKnobRendersAsATrueCircle() throws {
        let scale: CGFloat = 3
        let margin: CGFloat = 24
        let view = DSSlideToConfirm("Slide to pay") {}
            .frame(width: 240)
            .padding(margin)
            .dsTheme(DSTheme())

        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        let image = try XCTUnwrap(renderer.cgImage)
        let alpha = try Self.alphaChannel(of: image)

        let knobCentreX = Int((margin + track / 2) * scale)
        let knobTop = Int(margin * scale)
        let diameter = Int(track * scale)

        var opaqueRows = 0
        for y in 0..<alpha.height where alpha[knobCentreX, y] >= 250 {
            opaqueRows += 1
        }
        XCTAssertGreaterThanOrEqual(opaqueRows, diameter, "The knob must span its full diameter")

        // The very first and last rows of the circle, not just the count.
        XCTAssertGreaterThanOrEqual(alpha[knobCentreX, knobTop], 250, "Top of the knob is shaved")
        XCTAssertGreaterThanOrEqual(alpha[knobCentreX, knobTop + diameter - 1], 250, "Bottom of the knob is shaved")
        // And the leftmost column of the circle, on its horizontal diameter.
        XCTAssertGreaterThanOrEqual(alpha[Int(margin * scale), knobTop + diameter / 2], 250, "Leading edge of the knob is shaved")
    }

    // MARK: - Helpers

    private struct AlphaPlane {
        let width: Int
        let height: Int
        let bytes: [UInt8]
        subscript(x: Int, y: Int) -> UInt8 { bytes[y * width + x] }
    }

    /// The alpha channel of `image`, redrawn into a known RGBA layout so the
    /// result does not depend on how the renderer packed its pixels.
    private static func alphaChannel(of image: CGImage) throws -> AlphaPlane {
        let width = image.width
        let height = image.height
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        let drewImage = rgba.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        try XCTSkipUnless(drewImage, "Could not create a bitmap context")
        let alpha = stride(from: 3, to: rgba.count, by: 4).map { rgba[$0] }
        return AlphaPlane(width: width, height: height, bytes: alpha)
    }
}
