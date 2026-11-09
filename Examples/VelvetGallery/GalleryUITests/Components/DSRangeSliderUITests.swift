import XCTest

/// DSRangeSlider on its stage: a price filter, $0–500 in 25s, at least $50 wide,
/// starting at $100–400. Each knob is an adjustable element, "Minimum" and
/// "Maximum". The test drags a knob past either end of the screen; the logic
/// stops it at the track's end or at the gap, so the expected values hold on
/// any screen width.
final class DSRangeSliderUITests: XCTestCase {
    @MainActor
    func testKnobsDragToTheEndsAndStopAtTheGap() {
        let app = StageLauncher.launch("DSRangeSlider")
        let minimum = app.element("Minimum")
        let maximum = app.element("Maximum")
        XCTAssertTrue(minimum.waitForExistence(timeout: 5))
        XCTAssertTrue(maximum.waitForExistence(timeout: 5))
        XCTAssertEqual(minimum.stringValue, "100")
        XCTAssertEqual(maximum.stringValue, "400")

        /// A point near the left (0) or right (1) edge of the screen, level with `knob`.
        func edge(_ fraction: CGFloat, besides knob: XCUIElement) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: app.frame.width * fraction, dy: knob.frame.midY))
        }
        /// Presses the centre of `knob` and drags it to the screen edge.
        func drag(_ knob: XCUIElement, to fraction: CGFloat) {
            knob.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.1, thenDragTo: edge(fraction, besides: knob))
        }

        drag(minimum, to: 0.02)
        XCTAssertTrue(minimum.waitForValue("0"), "Got \(minimum.stringValue ?? "nil")")
        XCTAssertEqual(maximum.stringValue, "400", "Dragging the minimum moved the maximum.")

        drag(maximum, to: 0.98)
        XCTAssertTrue(maximum.waitForValue("500"), "Got \(maximum.stringValue ?? "nil")")

        // The minimum can't pass the maximum: it stops $50 short.
        drag(minimum, to: 0.98)
        XCTAssertTrue(minimum.waitForValue("450"), "Got \(minimum.stringValue ?? "nil")")
        XCTAssertEqual(maximum.stringValue, "500")

        StageLauncher.attachScreenshot(app, named: "DSRangeSlider · $450–500", to: self)

        drag(minimum, to: 0.02)
        XCTAssertTrue(minimum.waitForValue("0"), "Got \(minimum.stringValue ?? "nil")")

        // And the maximum stops $50 above the minimum.
        drag(maximum, to: 0.02)
        XCTAssertTrue(maximum.waitForValue("50"), "Got \(maximum.stringValue ?? "nil")")
        XCTAssertEqual(minimum.stringValue, "0")
    }
}
