import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import VelvetUI

// Every code snippet on docs/components/DSFlowLayout.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsFlowLayout {
    struct InterestsPicker: View {
        private let interests = ["Design", "SwiftUI", "Motion", "Accessibility",
                                 "Haptics", "Typography", "Color", "Prototyping"]
        @State private var selected: Set<String> = ["SwiftUI", "Motion"]
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @DSThemed private var theme

        var body: some View {
            DSFlowLayout {
                ForEach(interests, id: \.self) { interest in
                    let isSelected = selected.contains(interest)
                    Button {
                        dsHaptic(.selection)
                        withAnimation(reduceMotion ? nil : DSAnimation.springSnappy) {
                            selected.formSymmetricDifference([interest])
                        }
                    } label: {
                        Text(interest)
                            .ds(.buttonSmall, color: isSelected ? theme.onAccent : theme.ink)
                            .padding(.horizontal, DSSpacing.sm)
                            .padding(.vertical, DSSpacing.xs)
                            .background(isSelected ? theme.accent : theme.subtleFill, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    struct FlowVariantsDemo: View {
        private let sizes = ["XS", "S", "M", "L", "XL", "XXL"]

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                // Tighter rows, centred inside a card
                DSCard {
                    DSFlowLayout(spacing: DSSpacing.xxs, lineSpacing: DSSpacing.xxs, alignment: .center) {
                        ForEach(sizes, id: \.self) { size in
                            DSBadge(size)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Right-aligned rows
                DSFlowLayout(alignment: .trailing) {
                    ForEach(sizes, id: \.self) { size in
                        DSBadge(size, variant: .soft)
                    }
                }
            }
        }
    }
}

@MainActor
final class DSFlowLayoutTests: XCTestCase {

    // MARK: - Snippets

    func testSnippetsInstantiate() {
        _ = DocSnippetsFlowLayout.InterestsPicker()
        _ = DocSnippetsFlowLayout.FlowVariantsDemo()
    }

    func testDefaults() {
        let layout = DSFlowLayout()
        XCTAssertEqual(layout.spacing, DSSpacing.xs)
        XCTAssertEqual(layout.lineSpacing, DSSpacing.xs)
        XCTAssertTrue(layout.alignment == .leading)
    }

    // MARK: - Packing

    private func sizes(_ widths: [CGFloat], height: CGFloat = 20) -> [CGSize] {
        widths.map { CGSize(width: $0, height: height) }
    }

    func testNothingPacksToNoRows() {
        XCTAssertTrue(DSFlowLayout.pack([], maxWidth: 200, spacing: 8).isEmpty)
    }

    func testItemsWrapWhenTheNextOneWouldOverflow() {
        // 80 + 8 + 80 = 168 fits in 200; a third would make 256.
        let rows = DSFlowLayout.pack(sizes([80, 80, 80, 80, 80]), maxWidth: 200, spacing: 8)
        XCTAssertEqual(rows.map { $0.items.map(\.index) }, [[0, 1], [2, 3], [4]])
        XCTAssertEqual(rows.map(\.width), [168, 168, 80])
    }

    func testAnItemThatFitsExactlyStaysOnTheRow() {
        let rows = DSFlowLayout.pack(sizes([80, 80]), maxWidth: 168, spacing: 8)
        XCTAssertEqual(rows.count, 1)
    }

    func testSubPointRoundingDoesNotOrphanTheLastItem() {
        // The parent can hand back bounds a hair narrower than the width we reported.
        let rows = DSFlowLayout.pack(sizes([80, 80]), maxWidth: 167.8, spacing: 8)
        XCTAssertEqual(rows.count, 1)
    }

    func testAnItemWiderThanTheContainerGetsItsOwnRow() {
        let rows = DSFlowLayout.pack(sizes([40, 300, 40]), maxWidth: 200, spacing: 8)
        XCTAssertEqual(rows.map { $0.items.map(\.index) }, [[0], [1], [2]])
    }

    func testTheFirstItemNeverWrapsOntoAnEmptyRow() {
        let rows = DSFlowLayout.pack(sizes([300]), maxWidth: 200, spacing: 8)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].items.count, 1)
    }

    func testZeroWidthPutsEveryItemOnItsOwnRow() {
        let rows = DSFlowLayout.pack(sizes([10, 10, 10]), maxWidth: 0, spacing: 8)
        XCTAssertEqual(rows.count, 3)
    }

    func testInfiniteWidthIsOneRow() {
        let rows = DSFlowLayout.pack(sizes([80, 80, 80, 80]), maxWidth: .infinity, spacing: 8)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].width, 80 * 4 + 8 * 3)
    }

    func testARowIsAsTallAsItsTallestItem() {
        let rows = DSFlowLayout.pack(
            [CGSize(width: 40, height: 20), CGSize(width: 40, height: 36), CGSize(width: 40, height: 28)],
            maxWidth: 200, spacing: 8
        )
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].height, 36)
    }

    func testTotalHeightAddsLineSpacingBetweenRowsOnly() {
        let rows = DSFlowLayout.pack(sizes([80, 80, 80, 80, 80]), maxWidth: 200, spacing: 8)
        XCTAssertEqual(DSFlowLayout.totalHeight(of: rows, lineSpacing: 6), 3 * 20 + 2 * 6)
        XCTAssertEqual(DSFlowLayout.totalHeight(of: [], lineSpacing: 6), 0)
        XCTAssertEqual(DSFlowLayout.totalHeight(of: Array(rows.prefix(1)), lineSpacing: 6), 20)
    }

    // MARK: - Alignment

    func testLeadingOffsetByAlignment() {
        XCTAssertEqual(DSFlowLayout.leadingOffset(rowWidth: 100, boundsWidth: 300, alignment: .leading), 0)
        XCTAssertEqual(DSFlowLayout.leadingOffset(rowWidth: 100, boundsWidth: 300, alignment: .center), 100)
        XCTAssertEqual(DSFlowLayout.leadingOffset(rowWidth: 100, boundsWidth: 300, alignment: .trailing), 200)
    }

    func testAnOverflowingRowStartsFlush() {
        XCTAssertEqual(DSFlowLayout.leadingOffset(rowWidth: 400, boundsWidth: 300, alignment: .center), 0)
        XCTAssertEqual(DSFlowLayout.leadingOffset(rowWidth: 400, boundsWidth: 300, alignment: .trailing), 0)
    }

    // MARK: - Through SwiftUI

    private struct Block: View {
        let width: CGFloat
        var height: CGFloat = 20

        var body: some View { Color.clear.frame(width: width, height: height) }
    }

    /// What SwiftUI reports for `view` when it is offered `width` points.
    private func fittingSize<V: View>(_ view: V, width: CGFloat) -> CGSize {
        let proposal = CGSize(width: width, height: 10_000)
        #if canImport(UIKit)
        return UIHostingController(rootView: view).sizeThatFits(in: proposal)
        #else
        return NSHostingController(rootView: view).sizeThatFits(in: proposal)
        #endif
    }

    func testReportsTheWrappedHeightAndFillsTheProposedWidth() {
        let flow = DSFlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(0..<5, id: \.self) { _ in Block(width: 80) }
        }
        let size = fittingSize(flow, width: 200)
        XCTAssertEqual(size.width, 200, accuracy: 0.5)
        XCTAssertEqual(size.height, 3 * 20 + 2 * 8, accuracy: 0.5)
    }

    func testAWiderContainerNeedsFewerRows() {
        let flow = DSFlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(0..<5, id: \.self) { _ in Block(width: 80) }
        }
        XCTAssertEqual(fittingSize(flow, width: 600).height, 20, accuracy: 0.5)
        XCTAssertEqual(fittingSize(flow, width: 90).height, 5 * 20 + 4 * 8, accuracy: 0.5)
    }

    func testRowHeightFollowsTheTallestItem() {
        let flow = DSFlowLayout(spacing: 8, lineSpacing: 8) {
            Block(width: 80)
            Block(width: 80, height: 44)
        }
        XCTAssertEqual(fittingSize(flow, width: 400).height, 44, accuracy: 0.5)
    }

    func testAnEmptyFlowTakesNoSpace() {
        let flow = DSFlowLayout { EmptyView() }
        let size = fittingSize(flow, width: 200)
        XCTAssertEqual(size.height, 0, accuracy: 0.5)
    }
}
