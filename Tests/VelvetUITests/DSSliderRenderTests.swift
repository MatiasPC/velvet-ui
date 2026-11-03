import XCTest
import SwiftUI
import CoreGraphics
@testable import VelvetUI

/// Renders the slider and finds the knob in the pixels, so the value -> position
/// mapping is checked end to end (including a range other than `0...1`).
@MainActor
final class DSSliderRenderTests: XCTestCase {

    private let width: CGFloat = 300
    private let knob: CGFloat = 28
    private let scaleFactor: CGFloat = 3

    /// Left edge of the knob, in points, found as the first pure-white pixel on
    /// the slider's centre row (the track is accent or neutral grey, never white).
    private func knobLeftEdge(of slider: DSSlider) throws -> CGFloat {
        let renderer = ImageRenderer(content: slider.frame(width: width).dsTheme(DSTheme()))
        renderer.scale = scaleFactor
        let image = try XCTUnwrap(renderer.cgImage)

        var rgba = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let drawn = rgba.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        try XCTSkipUnless(drawn, "Could not create a bitmap context")

        let row = image.height / 2
        for x in 0..<image.width {
            let o = (row * image.width + x) * 4
            if rgba[o] == 255, rgba[o + 1] == 255, rgba[o + 2] == 255, rgba[o + 3] == 255 {
                return CGFloat(x) / scaleFactor
            }
        }
        XCTFail("No knob found on the centre row")
        return 0
    }

    private func expectedLeft(_ fraction: CGFloat) -> CGFloat { fraction * (width - knob) }

    func testKnobSitsAtTheValueOnTheDefaultRange() throws {
        for value in [0.0, 0.25, 0.5, 0.8, 1.0] {
            let left = try knobLeftEdge(of: DSSlider(value: .constant(value)))
            XCTAssertEqual(left, expectedLeft(CGFloat(value)), accuracy: 1.5, "value \(value)")
        }
    }

    func testKnobSitsAtTheValueOnACustomRange() throws {
        // -10...10: 0 is dead centre, the ends are flush.
        let centre = try knobLeftEdge(of: DSSlider(value: .constant(0), in: -10...10))
        XCTAssertEqual(centre, expectedLeft(0.5), accuracy: 1.5)

        let low = try knobLeftEdge(of: DSSlider(value: .constant(-10), in: -10...10))
        XCTAssertEqual(low, 0, accuracy: 1.5)

        let high = try knobLeftEdge(of: DSSlider(value: .constant(10), in: -10...10))
        XCTAssertEqual(high, width - knob, accuracy: 1.5)

        // 0...500 by 25: 125 is a quarter of the way.
        let quarter = try knobLeftEdge(of: DSSlider(value: .constant(125), in: 0...500, step: 25))
        XCTAssertEqual(quarter, expectedLeft(0.25), accuracy: 1.5)
    }

    /// The bound value is clamped for display even before anything writes it back.
    func testOutOfRangeValueIsDrawnAtTheNearestEnd() throws {
        let above = try knobLeftEdge(of: DSSlider(value: .constant(7), in: 0...1))
        XCTAssertEqual(above, width - knob, accuracy: 1.5)

        let below = try knobLeftEdge(of: DSSlider(value: .constant(-3), in: 0...1))
        XCTAssertEqual(below, 0, accuracy: 1.5)
    }
}
