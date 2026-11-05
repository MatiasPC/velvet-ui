import XCTest
import SwiftUI
import CoreGraphics
@testable import VelvetUI

/// `DSCorner`: fixed vs concentric corners. The value tests pin the tokens;
/// the render tests draw real views with `ImageRenderer` and read pixels, so
/// they prove the corners resolve against the container (iOS / macOS 26+ only).
@MainActor
final class DSCornerTests: XCTestCase {

    // MARK: - Values

    func testFixedCornerFallsBackToItsRadius() {
        XCTAssertEqual(DSCorner.fixed(DSRadius.md).fallbackRadius, DSRadius.md)
        XCTAssertFalse(DSCorner.fixed(DSRadius.md).isConcentric)
    }

    func testConcentricCornerFallsBackToItsMinimum() {
        XCTAssertEqual(DSCorner.concentric(minimum: DSRadius.lg).fallbackRadius, DSRadius.lg)
        XCTAssertTrue(DSCorner.concentric(minimum: DSRadius.lg).isConcentric)
    }

    func testSemanticTokensMapToRadiusRoles() {
        XCTAssertEqual(DSCorner.card, .fixed(DSRadius.card))
        XCTAssertEqual(DSCorner.chip, .fixed(DSRadius.chip))
        XCTAssertEqual(DSCorner.control, .concentric(minimum: DSRadius.control))
        XCTAssertEqual(DSCorner.nestedSurface, .concentric(minimum: DSRadius.surface))
    }

    func testButtonCornersByRole() {
        XCTAssertEqual(DSButtonSize.small.corner, .chip)
        XCTAssertEqual(DSButtonSize.medium.corner, .control)
        XCTAssertEqual(DSButtonSize.large.corner, .control)
    }

    func testControlsInsideContainersAreConcentric() {
        XCTAssertEqual(DSTextField.corner, .control)
        XCTAssertEqual(DSToast.corner, .control)
        XCTAssertEqual(DSRadioGroupMetrics.highlightCorner, .control)
    }

    // MARK: - Rendering helpers

    private let side: CGFloat = 200

    private struct Pixel { let r, g, b, a: UInt8 }

    /// Renders at 1x and returns the pixel at `point` (top-left origin, points).
    private func pixel<V: View>(_ view: V, at point: CGPoint) throws -> Pixel {
        let renderer = ImageRenderer(content: view.dsTheme(DSTheme()))
        renderer.scale = 1
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
        let o = (Int(point.y) * image.width + Int(point.x)) * 4
        return Pixel(r: rgba[o], g: rgba[o + 1], b: rgba[o + 2], a: rgba[o + 3])
    }

    private func requireConcentricOS() throws {
        guard #available(iOS 26, macOS 26, *) else {
            throw XCTSkip("Corner concentricity needs iOS / macOS 26")
        }
    }

    /// A black square clipped to `corner`, inset by `inset` inside a container of `radius`.
    private func nested(_ corner: DSCorner, inset: CGFloat, containerRadius: CGFloat) -> some View {
        Color.black
            .clipShape(corner.shape)
            .padding(inset)
            .frame(width: side, height: side)
            .dsContainer(radius: containerRadius)
    }

    // MARK: - Shape resolution

    func testConcentricShapeFollowsTheContainerCorner() throws {
        try requireConcentricOS()
        // Container 60, inset 20 -> inner radius 40: just inside the inner corner is empty.
        let p = try pixel(nested(.concentric(minimum: 0), inset: 20, containerRadius: 60), at: CGPoint(x: 23, y: 23))
        XCTAssertEqual(p.a, 0)
    }

    func testFixedShapeIgnoresTheContainer() throws {
        try requireConcentricOS()
        let p = try pixel(nested(.fixed(0), inset: 20, containerRadius: 60), at: CGPoint(x: 23, y: 23))
        XCTAssertEqual(p.a, 255)
    }

    func testConcentricShapeNeverGoesBelowItsMinimum() throws {
        try requireConcentricOS()
        // Container 20, inset 16 -> concentric 4. With minimum 12 the corner is rounder.
        let probe = CGPoint(x: 18, y: 18)
        let clamped = try pixel(nested(.concentric(minimum: DSRadius.control), inset: 16, containerRadius: 20), at: probe)
        let raw = try pixel(nested(.concentric(minimum: 0), inset: 16, containerRadius: 20), at: probe)
        XCTAssertEqual(clamped.a, 0)
        XCTAssertEqual(raw.a, 255)
    }

    func testWithoutAContainerTheConcentricShapeUsesItsMinimum() throws {
        try requireConcentricOS()
        let bare = Color.black.clipShape(DSCorner.concentric(minimum: 0).shape).frame(width: side, height: side)
        XCTAssertEqual(try pixel(bare, at: CGPoint(x: 1, y: 1)).a, 255)
    }

    // MARK: - Surfaces publish their shape

    func testSurfaceIsAContainerForItsContent() throws {
        try requireConcentricOS()
        let view = Color.black
            .clipShape(DSCorner.concentric(minimum: 0).shape)
            .padding(20)
            .frame(width: side, height: side)
            .dsSurface(.solid, radius: 60, edge: false)
        // Concentric content leaves the corner to the (light) surface fill, not black.
        let p = try pixel(view, at: CGPoint(x: 23, y: 23))
        XCTAssertGreaterThan(Int(p.r), 100)
    }

    func testCardIsAContainerForItsContent() throws {
        try requireConcentricOS()
        // Red content: on iOS, ImageRenderer draws glass materials near-black,
        // so black content couldn't be told apart from the surface.
        let card = DSCard(style: .elevated, padding: 20, cornerRadius: 60) {
            Color.red
                .clipShape(DSCorner.concentric(minimum: 0).shape)
                .frame(width: 160, height: 160)
        }
        let center = try pixel(card, at: CGPoint(x: 100, y: 100))
        let corner = try pixel(card, at: CGPoint(x: 23, y: 23))
        XCTAssertTrue(center.r > 200 && center.g < 100, "content is drawn")
        XCTAssertFalse(corner.r > 200 && corner.g < 100, "content corner should be rounded away")
    }

    func testFlatCardIsAContainerForItsContent() throws {
        try requireConcentricOS()
        let card = DSCard(style: .flat, padding: 20, cornerRadius: 60) {
            Color.black
                .clipShape(DSCorner.concentric(minimum: 0).shape)
                .frame(width: 160, height: 160)
        }
        let p = try pixel(card, at: CGPoint(x: 23, y: 23))
        XCTAssertFalse(p.r < 40 && p.a > 200, "content corner should be rounded away")
    }

    func testConcentricSurfaceClipsToTheResolvedCorner() throws {
        try requireConcentricOS()
        let view = Color.clear
            .dsSurface(.solid, corner: .concentric(minimum: 0), edge: false)
            .padding(20)
            .frame(width: side, height: side)
            .dsContainer(radius: 60)
        XCTAssertEqual(try pixel(view, at: CGPoint(x: 23, y: 23)).a, 0)
        XCTAssertEqual(try pixel(view, at: CGPoint(x: 100, y: 100)).a, 255)
    }

    func testConcentricCardClipsToTheResolvedCorner() throws {
        try requireConcentricOS()
        let card = DSCard(style: .outlined, padding: 0, corner: .concentric(minimum: 0)) {
            Color.clear.frame(width: 160, height: 160)
        }
        let view = card.padding(20).frame(width: side, height: side).dsContainer(radius: 60)
        XCTAssertEqual(try pixel(view, at: CGPoint(x: 23, y: 23)).a, 0)
        XCTAssertGreaterThan(try pixel(view, at: CGPoint(x: 100, y: 100)).a, 0)
    }

    // MARK: - Edge and glow follow the corner

    func testConcentricSurfaceDrawsAnInsideEdge() throws {
        try requireConcentricOS()
        let view = Color.clear
            .frame(width: side, height: side)
            .dsWashEdge(corner: .concentric(minimum: 0))
        XCTAssertGreaterThan(try pixel(view, at: CGPoint(x: 0, y: 100)).a, 0)
        XCTAssertEqual(try pixel(view, at: CGPoint(x: 3, y: 100)).a, 0)
        XCTAssertEqual(try pixel(view, at: CGPoint(x: 100, y: 100)).a, 0)
    }

    func testConcentricEdgeIsAsThinAsTheFixedEdge() throws {
        try requireConcentricOS()
        // Over opaque black: both edges must cover the outer pixel column the
        // same way (1pt inside), whatever the shape type.
        func edge(_ corner: DSCorner) -> some View {
            Color.black.frame(width: 120, height: 120).dsWashEdge(corner: corner)
        }
        let probe = CGPoint(x: 0, y: 60)
        let fixed = try pixel(edge(.fixed(0)), at: probe)
        let concentric = try pixel(edge(.concentric(minimum: 0)), at: probe)
        XCTAssertGreaterThan(fixed.r, 0)
        XCTAssertEqual(Int(concentric.r), Int(fixed.r), accuracy: 2)
        XCTAssertEqual(try pixel(edge(.concentric(minimum: 0)), at: CGPoint(x: 1, y: 60)).r, 0)
    }

    func testCornerSurfaceDrawsTheEdgeByDefault() throws {
        func surface(_ build: (AnyView) -> AnyView) -> some View {
            build(AnyView(Color.black.frame(width: 120, height: 120)))
        }
        let probe = CGPoint(x: 0, y: 60)
        let byDefault = try pixel(surface { AnyView($0.dsSurface(.solid, corner: .control)) }, at: probe)
        let withEdge = try pixel(surface { AnyView($0.dsSurface(.solid, corner: .control, edge: true)) }, at: probe)
        let withoutEdge = try pixel(surface { AnyView($0.dsSurface(.solid, corner: .control, edge: false)) }, at: probe)
        XCTAssertEqual(byDefault.r, withEdge.r)
        XCTAssertNotEqual(byDefault.r, withoutEdge.r)
    }

    func testFixedWashEdgeStillDraws() throws {
        let view = Color.clear.frame(width: side, height: side).dsWashEdge(corner: .fixed(DSRadius.card))
        XCTAssertGreaterThan(try pixel(view, at: CGPoint(x: 0, y: 100)).a, 0)
        XCTAssertEqual(try pixel(view, at: CGPoint(x: 100, y: 100)).a, 0)
    }

    func testSurfaceEdgeIsOptional() throws {
        try requireConcentricOS()
        func surface(edge: Bool) -> some View {
            Color.clear.frame(width: side, height: side)
                .dsSurface(.glassThin, corner: .concentric(minimum: 0), edge: edge)
        }
        // The renderer draws the material opaque, so the white edge shows in the
        // colour, not the alpha.
        let without = try pixel(surface(edge: false), at: CGPoint(x: 0, y: 100))
        let with = try pixel(surface(edge: true), at: CGPoint(x: 0, y: 100))
        XCTAssertGreaterThan(Int(with.r) + Int(with.g) + Int(with.b),
                             Int(without.r) + Int(without.g) + Int(without.b))
    }

    func testFocusGlowOnlyShowsWhenActive() throws {
        func glow(_ active: Bool) -> some View {
            Color.white.frame(width: side, height: side)
                .dsFocusGlow(.black, corner: .control, isActive: active)
        }
        // Drawn over opaque white: ImageRenderer reuses its buffer between
        // same-size renders and doesn't clear it for a transparent frame, so
        // the glow is read from the colour, never from alpha on clear.
        XCTAssertEqual(try pixel(glow(false), at: CGPoint(x: 1, y: 100)).r, 255)
        XCTAssertLessThan(try pixel(glow(true), at: CGPoint(x: 1, y: 100)).r, 255)
    }

    func testContainerRadiusIsHonoured() throws {
        try requireConcentricOS()
        // Same inset, smaller container -> smaller inner radius -> the probe is filled.
        let probe = CGPoint(x: 23, y: 23)
        XCTAssertEqual(try pixel(nested(.concentric(minimum: 0), inset: 20, containerRadius: 60), at: probe).a, 0)
        XCTAssertEqual(try pixel(nested(.concentric(minimum: 0), inset: 20, containerRadius: 22), at: probe).a, 255)
    }
}
