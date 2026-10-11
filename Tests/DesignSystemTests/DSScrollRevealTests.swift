import XCTest
import SwiftUI
@testable import DesignSystem

@MainActor
final class DSScrollRevealTests: XCTestCase {

    private let ladder: [DSScrollRevealIntensity] = [.subtle, .medium, .strong]

    // MARK: - Ordering

    /// Each step up the ladder must travel further, shrink more and dim more —
    /// otherwise `.subtle` / `.medium` / `.strong` stop meaning anything.
    func testIntensitiesAreOrdered() {
        let rise = ladder.map(\.rise)
        XCTAssertEqual(rise, rise.sorted())

        let scaleDip = ladder.map(\.scaleDip)
        XCTAssertEqual(scaleDip, scaleDip.sorted())

        let dim = ladder.map(\.dim)
        XCTAssertEqual(dim, dim.sorted())
    }

    // MARK: - Bounds

    /// At the viewport edge the element may fade and shrink but must never
    /// vanish or invert: a row the user is scrolling toward has to stay readable.
    func testEdgeStateStaysVisible() {
        for intensity in ladder {
            XCTAssertGreaterThan(intensity.rise, 0, "a reveal has to travel some distance")
            XCTAssertGreaterThan(intensity.scaleDip, 0)
            XCTAssertLessThan(intensity.scaleDip, 1, "the element must keep a positive scale at the edge")
            XCTAssertGreaterThan(intensity.dim, 0)
            XCTAssertLessThan(intensity.dim, 1, "the element must never be fully transparent")
        }
    }
}
