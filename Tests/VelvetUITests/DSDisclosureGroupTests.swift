import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSDisclosureGroup.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsDisclosureGroup {
    struct FAQDemo: View {
        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.sm) {
                    DSDisclosureGroup("Can I cancel anytime?") {
                        Text("Yes — cancel from Settings and keep access until the end of the period.")
                            .ds(.callout, color: DSColors.textSecondary)
                    }
                    DSDisclosureGroup("What's included", subtitle: "3 items", icon: "shippingbox") {
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text("• Unlimited projects").ds(.callout)
                            Text("• Priority support").ds(.callout)
                            Text("• Early access to betas").ds(.callout)
                        }
                    }
                }
                .dsScreenPadding()
            }
        }
    }

    struct AccordionDemo: View {
        @State private var open: Int? = 0

        var body: some View {
            VStack(spacing: DSSpacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    DSDisclosureGroup("Section \(index + 1)", isExpanded: Binding(
                        get: { open == index },
                        set: { open = $0 ? index : nil }
                    )) {
                        Text("Only one section is open at a time.").ds(.callout)
                    }
                }
            }
        }
    }

    struct StartsOpenDemo: View {
        var body: some View {
            DSDisclosureGroup("Details", initiallyExpanded: true, haptic: .soft) {
                Text("Open on first appearance, with a softer tap.").ds(.callout)
            }
        }
    }
}

@MainActor
final class DSDisclosureGroupTests: XCTestCase {

    func testSnippetsInstantiate() {
        _ = DocSnippetsDisclosureGroup.FAQDemo().body
        _ = DocSnippetsDisclosureGroup.AccordionDemo().body
        _ = DocSnippetsDisclosureGroup.StartsOpenDemo().body
    }

    func testRevealHeightScalesWithProgress() {
        typealias Reveal = DSDisclosureReveal
        XCTAssertEqual(Reveal.height(natural: 120, progress: 0), 0)
        XCTAssertEqual(Reveal.height(natural: 120, progress: 0.5), 60)
        XCTAssertEqual(Reveal.height(natural: 120, progress: 1), 120)
    }

    func testRevealHeightNeverGoesNegativeWhenTheSpringUndershoots() {
        // A spring collapsing from 1 to 0 dips below 0 before it settles.
        XCTAssertEqual(DSDisclosureReveal.height(natural: 120, progress: -0.08), 0)
    }

    func testRevealHeightKeepsTheOvershootPastFull() {
        // The small bounce past full height is the point of the spring.
        XCTAssertGreaterThan(DSDisclosureReveal.height(natural: 120, progress: 1.05), 120)
    }

    func testRevealWithNoContentHasNoHeight() {
        XCTAssertEqual(DSDisclosureReveal.height(natural: 0, progress: 1), 0)
    }

    func testAccessibilityValueReportsTheOpenState() {
        XCTAssertEqual(DSDisclosureGroup<EmptyView>.accessibilityValue(isExpanded: true), "Expanded")
        XCTAssertEqual(DSDisclosureGroup<EmptyView>.accessibilityValue(isExpanded: false), "Collapsed")
    }

    func testAccessibilityHintDescribesTheAction() {
        XCTAssertEqual(DSDisclosureGroup<EmptyView>.accessibilityHint(isExpanded: false), "Shows the details")
        XCTAssertEqual(DSDisclosureGroup<EmptyView>.accessibilityHint(isExpanded: true), "Hides the details")
    }
}
