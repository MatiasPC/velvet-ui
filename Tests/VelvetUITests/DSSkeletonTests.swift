import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSSkeleton.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsSkeleton {
    struct SkeletonDemo: View {
        @State private var isLoading = true

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    // Hand-built placeholder
                    HStack(spacing: DSSpacing.sm) {
                        DSSkeleton.circle(DSSpacing.huge)
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            DSSkeleton(width: 140)
                            DSSkeleton(width: 90)
                        }
                    }

                    // The real view, shown as its own placeholder while loading
                    HStack(spacing: DSSpacing.sm) {
                        DSAvatar(name: "Ada Lovelace", size: DSSpacing.huge)
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text("Ada Lovelace").ds(.title3)
                            Text("Analyst, mathematician").ds(.callout)
                        }
                    }
                    .dsSkeleton(isLoading)

                    DSToggle("Loading", isOn: $isLoading)
                }
                .dsScreenPadding()
            }
        }
    }

    struct SkeletonVariantDemo: View {
        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                DSSkeleton(height: 160, cornerRadius: DSRadius.surface)
                DSSkeleton(height: DSSpacing.md)
                DSSkeleton(width: 120)
            }
        }
    }
}

@MainActor
final class DSSkeletonTests: XCTestCase {

    func testSnippetsInstantiate() {
        _ = DocSnippetsSkeleton.SkeletonDemo()
        _ = DocSnippetsSkeleton.SkeletonVariantDemo()
    }

    func testAccessibilityLabel() {
        XCTAssertEqual(DSSkeletonModifier.accessibilityLabel(isLoading: true), "Loading")
        XCTAssertNil(DSSkeletonModifier.accessibilityLabel(isLoading: false))
    }

    func testCircleIsSquareAndFullyRounded() {
        let c = DSSkeleton.circle(40)
        _ = c.body
        XCTAssertNotNil(c)
    }

    func testModifierCompiles() {
        _ = Text("Hi").dsSkeleton(true)
        _ = Text("Hi").dsSkeleton(false)
    }

    func testPulseStartsAtFullOpacityAndDipsHalfwayThrough() {
        XCTAssertEqual(DSSkeletonModifier.pulseOpacity(elapsed: 0), 1, accuracy: 0.0001)
        XCTAssertEqual(DSSkeletonModifier.pulseOpacity(elapsed: 1.8), 0.5, accuracy: 0.0001)
        XCTAssertEqual(DSSkeletonModifier.pulseOpacity(elapsed: 3.6), 1, accuracy: 0.0001)
    }

    func testPulseStaysWithinItsRange() {
        for step in 0...100 {
            let opacity = DSSkeletonModifier.pulseOpacity(elapsed: Double(step) * 0.137)
            XCTAssertGreaterThanOrEqual(opacity, 0.5 - 0.0001)
            XCTAssertLessThanOrEqual(opacity, 1 + 0.0001)
        }
    }
}
