import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSCardStack.md lives here
// verbatim, so a drifting API breaks the build instead of the docs.
enum DocSnippetsCardStack {
    struct OrderUpdate: Identifiable {
        let id: String
        let detail: String
    }

    struct OrderUpdates: View {
        @State private var isExpanded = false
        let updates = [
            OrderUpdate(id: "Your order shipped", detail: "Arrives Thursday"),
            OrderUpdate(id: "Out for delivery", detail: "4 stops away"),
            OrderUpdate(id: "Delivered", detail: "Left at the front door"),
        ]

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                HStack {
                    Text("Orders").ds(.title3)
                    Spacer()
                    if isExpanded {
                        DSButton("Show less", variant: .ghost, size: .small) { isExpanded = false }
                    }
                }
                DSCardStack(updates, isExpanded: $isExpanded, accessibilityLabel: "Order updates") { update in
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text(update.id).ds(.body)
                        Text(update.detail).ds(.callout)
                    }
                }
            }
            .dsScreenPadding()
        }
    }

    struct BoardingPass: Identifiable {
        let id: String
        let gate: String
    }

    struct BoardingPasses: View {
        @State private var showAll = false
        let passes = [
            BoardingPass(id: "LIS → AMS", gate: "Gate 14"),
            BoardingPass(id: "AMS → OSL", gate: "Gate D7"),
        ]

        var body: some View {
            VStack(spacing: DSSpacing.md) {
                DSCardStack(passes, isExpanded: $showAll, haptic: .medium, accessibilityLabel: "Boarding passes") { pass in
                    HStack {
                        Text(pass.id).ds(.title3)
                        Spacer()
                        Text(pass.gate).ds(.callout)
                    }
                }
                if showAll {
                    DSButton("Done", variant: .secondary, isFullWidth: true) { showAll = false }
                }
            }
            .dsScreenPadding()
        }
    }
}

@MainActor
final class DSCardStackTests: XCTestCase {
    private typealias L = DSCardStackLogic

    private struct Card: Identifiable {
        let id: Int
    }

    func testDocSnippetsAndInitsBuild() {
        _ = DocSnippetsCardStack.OrderUpdates().body
        _ = DocSnippetsCardStack.BoardingPasses().body
        _ = DSCardStack([Card(id: 1), Card(id: 2)], isExpanded: .constant(false)) { card in Text("\(card.id)") }.body
        _ = DSCardStack([Card](), isExpanded: .constant(true), haptic: .rigid, accessibilityLabel: "Empty") { card in
            Text("\(card.id)")
        }.body
    }

    // MARK: Progress and depth

    func testProgressIsClampedToTheTwoStates() {
        XCTAssertEqual(L.clamped(0), 0)
        XCTAssertEqual(L.clamped(0.25), 0.25, accuracy: 0.0001)
        XCTAssertEqual(L.clamped(1), 1)
        XCTAssertEqual(L.clamped(1.08), 1, "A spring's overshoot must not push cards past the column.")
        XCTAssertEqual(L.clamped(-0.05), 0, "A spring's undershoot must not lift cards above the pile.")
        XCTAssertEqual(L.clamped(.nan), 0)
        XCTAssertEqual(L.clamped(.infinity), 0)
    }

    func testDepthStopsAtTheLastPeekingCard() {
        XCTAssertEqual(L.depth(index: 0), 0)
        XCTAssertEqual(L.depth(index: 1), 1)
        XCTAssertEqual(L.depth(index: 2), 2)
        XCTAssertEqual(L.depth(index: 3), 2)
        XCTAssertEqual(L.depth(index: 40), 2)
        XCTAssertEqual(L.depth(index: -1), 0)
    }

    func testOnlyMoreThanOneCardExpands() {
        XCTAssertFalse(L.canExpand(count: -1))
        XCTAssertFalse(L.canExpand(count: 0))
        XCTAssertFalse(L.canExpand(count: 1))
        XCTAssertTrue(L.canExpand(count: 2))
        XCTAssertTrue(L.canExpand(count: 9))
    }

    // MARK: Collapsed pile

    func testCollapsedCardsPeekOneStepLowerEach() {
        // Equal heights: each card behind ends one peek step lower than the one in front.
        let heights: [CGFloat] = [80, 80, 80]
        XCTAssertEqual(L.collapsedOrigins(heights: heights), [0, L.peekStep, 2 * L.peekStep])
        XCTAssertEqual(L.collapsedHeight(heights: heights), 80 + 2 * L.peekStep)
    }

    func testCollapsedCardsAreBottomAligned() {
        // A shorter card behind sits lower, so its bottom edge still lands one step down.
        let origins = L.collapsedOrigins(heights: [100, 60])
        XCTAssertEqual(origins[1] + 60, 100 + L.peekStep, accuracy: 0.0001)
    }

    func testATallerCardBehindNeverRisesAboveThePile() {
        let heights: [CGFloat] = [60, 200]
        XCTAssertEqual(L.collapsedOrigins(heights: heights), [0, 0])
        XCTAssertEqual(L.collapsedHeight(heights: heights), 200, "The pile is as tall as what shows.")
    }

    func testCardsPastThePeekWaitBehindTheLastPeekingOne() {
        let heights: [CGFloat] = [80, 80, 80, 80, 80]
        let origins = L.collapsedOrigins(heights: heights)
        XCTAssertEqual(origins[3], origins[2])
        XCTAssertEqual(origins[4], origins[2])
        XCTAssertEqual(L.collapsedHeight(heights: heights), 80 + 2 * L.peekStep, "Waiting cards add no height.")
        XCTAssertEqual(L.opacity(index: 2, progress: 0), 1)
        XCTAssertEqual(L.opacity(index: 3, progress: 0), 0)
        XCTAssertEqual(L.opacity(index: 4, progress: 0.5), 0.5, accuracy: 0.0001)
        XCTAssertEqual(L.opacity(index: 4, progress: 1), 1)
    }

    func testCollapsedCardsStepBackInScale() {
        XCTAssertEqual(L.scale(index: 0, progress: 0), 1, accuracy: 0.0001)
        XCTAssertEqual(L.scale(index: 1, progress: 0), 0.95, accuracy: 0.0001)
        XCTAssertEqual(L.scale(index: 2, progress: 0), 0.90, accuracy: 0.0001)
        XCTAssertEqual(L.scale(index: 7, progress: 0), 0.90, accuracy: 0.0001)
        XCTAssertEqual(L.scale(index: 2, progress: 0.5), 0.95, accuracy: 0.0001)
        XCTAssertEqual(L.scale(index: 2, progress: 1), 1, accuracy: 0.0001)
        XCTAssertEqual(L.scale(index: 2, progress: 1.2), 1, accuracy: 0.0001)
    }

    // MARK: Expanded column

    func testExpandedCardsStandInAColumn() {
        let heights: [CGFloat] = [80, 50, 120]
        XCTAssertEqual(L.expandedOrigins(heights: heights), [0, 80 + L.spacing, 130 + 2 * L.spacing])
        XCTAssertEqual(L.expandedHeight(heights: heights), 250 + 2 * L.spacing)
        XCTAssertEqual(L.expandedOrigins(heights: heights, spacing: 0), [0, 80, 130])
    }

    func testEmptyAndSingleStacks() {
        XCTAssertEqual(L.collapsedOrigins(heights: []), [])
        XCTAssertEqual(L.collapsedHeight(heights: []), 0)
        XCTAssertEqual(L.expandedHeight(heights: []), 0)
        XCTAssertEqual(L.layout(heights: [], progress: 1).height, 0)
        XCTAssertEqual(L.layout(heights: [64], progress: 0).height, 64)
        XCTAssertEqual(L.layout(heights: [64], progress: 1).height, 64, "One card looks the same both ways.")
    }

    func testBadHeightsCountAsZero() {
        XCTAssertEqual(L.expandedHeight(heights: [.nan, 40, -10], spacing: 0), 40)
        XCTAssertEqual(L.collapsedOrigins(heights: [.infinity, 40]), [0, 0])
    }

    // MARK: In between

    func testLayoutInterpolatesBetweenPileAndColumn() {
        let heights: [CGFloat] = [80, 80, 80]
        let collapsed = L.layout(heights: heights, progress: 0)
        let expanded = L.layout(heights: heights, progress: 1)
        let half = L.layout(heights: heights, progress: 0.5)

        XCTAssertEqual(collapsed.origins, L.collapsedOrigins(heights: heights))
        XCTAssertEqual(expanded.origins, L.expandedOrigins(heights: heights))
        XCTAssertEqual(collapsed.height, L.collapsedHeight(heights: heights))
        XCTAssertEqual(expanded.height, L.expandedHeight(heights: heights))

        for i in heights.indices {
            XCTAssertEqual(half.origins[i], (collapsed.origins[i] + expanded.origins[i]) / 2, accuracy: 0.0001)
        }
        XCTAssertEqual(half.height, (collapsed.height + expanded.height) / 2, accuracy: 0.0001)

        // An overshooting spring holds the column; an undershoot holds the pile.
        XCTAssertEqual(L.layout(heights: heights, progress: 1.1).origins, expanded.origins)
        XCTAssertEqual(L.layout(heights: heights, progress: -0.1).height, collapsed.height)
    }

    func testTheStackGrowsAsItOpens() {
        let heights: [CGFloat] = [72, 72, 72, 72]
        var previous: CGFloat = 0
        for step in 0...10 {
            let height = L.layout(heights: heights, progress: Double(step) / 10).height
            XCTAssertGreaterThanOrEqual(height, previous)
            previous = height
        }
    }

    // MARK: Accessibility

    func testAccessibilityValue() {
        XCTAssertEqual(L.accessibilityValue(count: 3, isExpanded: false), "3 cards, collapsed")
        XCTAssertEqual(L.accessibilityValue(count: 3, isExpanded: true), "3 cards, expanded")
        XCTAssertEqual(L.accessibilityValue(count: 1, isExpanded: false), "1 card")
        XCTAssertEqual(L.accessibilityValue(count: 0, isExpanded: true), "0 cards")
        XCTAssertEqual(L.accessibilityValue(count: -4, isExpanded: false), "0 cards")
    }

    // MARK: Layout in a host

    func testHostedStackReportsPileThenColumnHeight() {
        let cards = [Card(id: 1), Card(id: 2), Card(id: 3)]
        func height(expanded: Bool) -> CGFloat {
            let view = DSCardStack(cards, isExpanded: .constant(expanded)) { _ in
                Color.clear.frame(height: 40)
            }
            .frame(width: 320)
            .dsTheme(DSTheme())
            #if canImport(UIKit)
            return UIHostingController(rootView: view).sizeThatFits(in: CGSize(width: 320, height: 2000)).height
            #elseif canImport(AppKit)
            return NSHostingController(rootView: view).sizeThatFits(in: CGSize(width: 320, height: 2000)).height
            #endif
        }
        // Each card is 40 pt of content plus DSSpacing.md padding above and below.
        let card = 40 + 2 * DSSpacing.md
        XCTAssertEqual(height(expanded: false), card + 2 * L.peekStep, accuracy: 1)
        XCTAssertEqual(height(expanded: true), 3 * card + 2 * L.spacing, accuracy: 1)
    }
}
