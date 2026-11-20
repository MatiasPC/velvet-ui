import XCTest

/// DSCircularSlider on its stage: a thermostat, 10–30 in half degrees, starting
/// at 21, one adjustable element "Temperature". The arc runs clockwise from the
/// lower left (10) over the top (20) to the lower right (30), open at the bottom.
/// Only the angle of a touch counts, so the test aims along rays from the dial's
/// centre and the expected values hold on any screen size.
final class DSCircularSliderUITests: XCTestCase {
    @MainActor
    func testDragFollowsTheAngleAndHoldsAtTheEndsOfTheGap() {
        let app = StageLauncher.launch("DSCircularSlider")
        let dial = app.element("Temperature")
        XCTAssertTrue(dial.waitForExistence(timeout: 5))
        XCTAssertEqual(dial.stringValue, "21")

        let center = dial.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        /// The point `distance` pt from the centre at `degrees`, clockwise from 3 o'clock.
        func ray(_ degrees: CGFloat, _ distance: CGFloat) -> XCUICoordinate {
            let radians = degrees * .pi / 180
            return center.withOffset(CGVector(dx: distance * cos(radians), dy: distance * sin(radians)))
        }
        /// On the ring itself, where a drag may start.
        func ring(_ degrees: CGFloat) -> XCUICoordinate { ray(degrees, dial.frame.width * 0.42) }
        /// Presses the ring at `from` and drags out to `to`, well past the ring.
        func drag(from: CGFloat, to: CGFloat) {
            ring(from).press(forDuration: 0.1, thenDragTo: ray(to, dial.frame.width * 0.6))
        }

        // From the top (20) round to 9 o'clock: a sixth of the arc, 13.33 → 13.5.
        drag(from: 270, to: 180)
        XCTAssertTrue(dial.waitForValue("13.5"), "Got \(dial.stringValue ?? "nil")")

        // From 3 o'clock (26.5) on into the gap: the knob holds at the maximum.
        drag(from: 0, to: 70)
        XCTAssertTrue(dial.waitForValue("30"), "Got \(dial.stringValue ?? "nil")")

        // Again, and on through the gap past the start: it never jumps to 10.
        drag(from: 0, to: 150)
        StageLauncher.settle()
        XCTAssertEqual(dial.stringValue, "30", "The knob jumped across the gap.")

        StageLauncher.attachScreenshot(app, named: "DSCircularSlider · 30", to: self)

        // From 9 o'clock (13.5) back into the gap: it holds at the minimum.
        drag(from: 180, to: 100)
        XCTAssertTrue(dial.waitForValue("10"), "Got \(dial.stringValue ?? "nil")")

        // A drag that starts on the read-out in the middle never moves the value.
        center.press(forDuration: 0.1, thenDragTo: ray(270, dial.frame.width * 0.6))
        StageLauncher.settle()
        XCTAssertEqual(dial.stringValue, "10", "A drag from the centre moved the dial.")
    }
}
