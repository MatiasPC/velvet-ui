import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSCarousel.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsCarousel {
    struct Trip: Identifiable {
        let id: Int
        let city: String
        let price: String
    }

    struct CarouselDemo: View {
        @State private var page = 0
        private let trips = [
            Trip(id: 0, city: "Lisbon", price: "$480"),
            Trip(id: 1, city: "Kyoto", price: "$1,240"),
            Trip(id: 2, city: "Oaxaca", price: "$620")
        ]

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.md) {
                    DSCarousel(trips, currentPage: $page) { trip in
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text(trip.city).ds(.title2)
                            Text(trip.price).ds(.callout)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(DSSpacing.md)
                        .dsSurface(.glass, radius: DSRadius.card)
                    }
                    .frame(height: 200)

                    DSPageControl(currentPage: $page, numberOfPages: trips.count)
                }
            }
        }
    }

    struct CarouselCompactDemo: View {
        private let tags = [
            Trip(id: 0, city: "Lisbon", price: "$480"),
            Trip(id: 1, city: "Kyoto", price: "$1,240")
        ]

        var body: some View {
            DSCarousel(tags, peek: DSSpacing.lg, spacing: DSSpacing.sm, haptic: nil) { trip in
                Text(trip.city)
                    .ds(.title3)
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .dsSurface(.glassThin, radius: DSRadius.surface)
            }
            .frame(height: 80)
        }
    }
}

@MainActor
final class DSCarouselTests: XCTestCase {

    func testSnippetsInstantiate() {
        _ = DocSnippetsCarousel.CarouselDemo()
        _ = DocSnippetsCarousel.CarouselCompactDemo()
    }

    func testDepthIsIdentityAtCentre() {
        let d = DSCarouselMath.depth(for: 0)
        XCTAssertEqual(d.scale, 1, accuracy: 0.0001)
        XCTAssertEqual(d.opacity, 1, accuracy: 0.0001)
        XCTAssertEqual(d.yaw, 0, accuracy: 0.0001)
    }

    func testDepthAtOnePageAway() {
        let d = DSCarouselMath.depth(for: 1)
        XCTAssertEqual(d.scale, 0.9, accuracy: 0.0001)
        XCTAssertEqual(d.opacity, 0.6, accuracy: 0.0001)
        XCTAssertGreaterThan(abs(d.yaw), 0)
        XCTAssertLessThanOrEqual(abs(d.yaw), 8)
    }

    func testDepthIsSymmetricWithOppositeYaw() {
        let a = DSCarouselMath.depth(for: 0.5)
        let b = DSCarouselMath.depth(for: -0.5)
        XCTAssertEqual(a.scale, b.scale, accuracy: 0.0001)
        XCTAssertEqual(a.opacity, b.opacity, accuracy: 0.0001)
        XCTAssertEqual(a.yaw, -b.yaw, accuracy: 0.0001)
    }

    func testDepthClampsBeyondOne() {
        let far = DSCarouselMath.depth(for: 3)
        let one = DSCarouselMath.depth(for: 1)
        XCTAssertEqual(far.scale, one.scale, accuracy: 0.0001)
        XCTAssertEqual(far.opacity, one.opacity, accuracy: 0.0001)
        XCTAssertEqual(far.yaw, one.yaw, accuracy: 0.0001)
    }

    func testClampedPage() {
        XCTAssertEqual(DSCarouselMath.clampedPage(-2, count: 4), 0)
        XCTAssertEqual(DSCarouselMath.clampedPage(2, count: 4), 2)
        XCTAssertEqual(DSCarouselMath.clampedPage(9, count: 4), 3)
        XCTAssertEqual(DSCarouselMath.clampedPage(5, count: 0), 0)
    }

    func testAccessibilityValue() {
        XCTAssertEqual(DSCarouselMath.accessibilityValue(page: 1, count: 5), "Page 2 of 5")
        XCTAssertEqual(DSCarouselMath.accessibilityValue(page: 99, count: 5), "Page 5 of 5")
    }
}
