import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSSectionIndex.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsSectionIndex {
    struct Contacts: View {
        let sections: [(letter: String, names: [String])] = [
            ("A", ["Ada", "Alan"]), ("B", ["Barbara"]), ("G", ["Grace", "Guido"]),
        ]

        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DSSpacing.xs) {
                        ForEach(sections, id: \.letter) { section in
                            Text(section.letter).ds(.overline).id(section.letter)
                            ForEach(section.names, id: \.self) { Text($0).ds(.body) }
                        }
                    }
                    .dsScreenPadding()
                }
                .overlay(alignment: .trailing) {
                    DSSectionIndex(sections.map(\.letter)) { letter in
                        proxy.scrollTo(letter, anchor: .top)
                    }
                }
            }
            .dsBackdrop()
        }
    }

    struct Countries: View {
        let letters: [String]
        let onJump: (String) -> Void

        var body: some View {
            DSSectionIndex(letters, accessibilityLabel: "Country index") { letter in
                onJump(letter)
            }
            .padding(.vertical, DSSpacing.xl)
        }
    }
}

@MainActor
final class DSSectionIndexTests: XCTestCase {
    typealias L = DSSectionIndexLogic
    typealias E = DSSectionIndexLogic.Entry

    private let row: CGFloat = 16

    func testSnippetsInstantiate() {
        _ = DocSnippetsSectionIndex.Contacts().body
        _ = DocSnippetsSectionIndex.Countries(letters: ["A", "B"], onJump: { _ in }).body
        _ = DSSectionIndex(["A", "B", "C"]) { _ in }.body
        _ = DSSectionIndex([]) { _ in }.body
    }

    // MARK: Collapsing

    func testEveryTitleWhenTheyFit() {
        XCTAssertEqual(L.entries(count: 5, capacity: 5), [.title(0), .title(1), .title(2), .title(3), .title(4)])
        XCTAssertEqual(L.entries(count: 5, capacity: .max).count, 5)
        XCTAssertEqual(L.entries(count: 0, capacity: 10), [])
    }

    func testCollapsedColumnAlternatesTitlesAndDotsAndKeepsBothEnds() {
        // 26 letters in 13 rows: 7 titles and 6 dots.
        let entries = L.entries(count: 26, capacity: 13)
        XCTAssertEqual(entries.count, 13)
        XCTAssertEqual(entries.first, .title(0))
        XCTAssertEqual(entries.last, .title(25))
        for (i, entry) in entries.enumerated() {
            if i.isMultiple(of: 2) {
                guard case .title = entry else { return XCTFail("Row \(i) should be a title: \(entry)") }
            } else {
                guard case .dot = entry else { return XCTFail("Row \(i) should be a dot: \(entry)") }
            }
        }
    }

    func testAnEvenCapacityDropsToTheOddNumberBelow() {
        XCTAssertEqual(L.entries(count: 26, capacity: 14).count, 13)
    }

    func testDotsCoverEveryHiddenTitleExactlyOnce() {
        for count in 3...40 {
            for capacity in 1..<count {
                let entries = L.entries(count: count, capacity: capacity)
                var covered: [Int] = []
                for entry in entries {
                    switch entry {
                    case .title(let i): covered.append(i)
                    case .dot(let after, let before):
                        XCTAssertLessThan(after, before)
                        covered.append(contentsOf: (after + 1)..<before)
                    }
                }
                XCTAssertEqual(covered, Array(0..<count), "count \(count), capacity \(capacity)")
                XCTAssertLessThanOrEqual(entries.count, max(3, capacity), "count \(count), capacity \(capacity)")
            }
        }
    }

    func testAShortColumnStillShowsFirstDotLast() {
        XCTAssertEqual(L.entries(count: 26, capacity: 1), [.title(0), .dot(after: 0, before: 25), .title(25)])
        XCTAssertEqual(L.entries(count: 2, capacity: 1), [.title(0), .title(1)], "Two titles never collapse.")
    }

    func testCapacity() {
        XCTAssertEqual(L.capacity(height: 320, row: 16), 20)
        XCTAssertEqual(L.capacity(height: 330, row: 16), 20)
        XCTAssertEqual(L.capacity(height: .infinity, row: 16), .max)
        XCTAssertEqual(L.capacity(height: -5, row: 16), 0)
    }

    // MARK: Hit testing

    func testFingerLandsOnTheTitleUnderIt() {
        let entries = L.entries(count: 5, capacity: 5)
        XCTAssertEqual(L.title(atY: 0, rowHeight: row, entries: entries), 0)
        XCTAssertEqual(L.title(atY: 15.9, rowHeight: row, entries: entries), 0)
        XCTAssertEqual(L.title(atY: 16, rowHeight: row, entries: entries), 1)
        XCTAssertEqual(L.title(atY: 4.5 * row, rowHeight: row, entries: entries), 4)
    }

    func testAboveOrBelowTheColumnHoldsTheEnds() {
        let entries = L.entries(count: 5, capacity: 5)
        XCTAssertEqual(L.title(atY: -200, rowHeight: row, entries: entries), 0)
        XCTAssertEqual(L.title(atY: 5 * row, rowHeight: row, entries: entries), 4)
        XCTAssertEqual(L.title(atY: 10_000, rowHeight: row, entries: entries), 4)
        XCTAssertNil(L.title(atY: .nan, rowHeight: row, entries: entries))
        XCTAssertNil(L.title(atY: 10, rowHeight: row, entries: []))
    }

    func testSlidingOverADotWalksThroughTheTitlesItHides() {
        // first, dot hiding 1...24, last
        let entries = L.entries(count: 26, capacity: 1)
        var seen: [Int] = []
        var y = row
        while y < 2 * row {
            if let i = L.title(atY: y, rowHeight: row, entries: entries), seen.last != i { seen.append(i) }
            y += 0.1
        }
        XCTAssertEqual(seen, Array(1...24))
    }

    func testADotThatHidesNothingSplitsBetweenItsNeighbours() {
        let entries: [E] = [.title(0), .dot(after: 0, before: 1), .title(1)]
        XCTAssertEqual(L.title(atY: row * 1.2, rowHeight: row, entries: entries), 0)
        XCTAssertEqual(L.title(atY: row * 1.8, rowHeight: row, entries: entries), 1)
    }

    func testRowOfATitleFindsItsDot() {
        let entries = L.entries(count: 26, capacity: 1)
        XCTAssertEqual(L.row(ofTitle: 0, in: entries), 0)
        XCTAssertEqual(L.row(ofTitle: 12, in: entries), 1)
        XCTAssertEqual(L.row(ofTitle: 25, in: entries), 2)
        XCTAssertNil(L.row(ofTitle: 30, in: entries))
    }

    // MARK: Fan

    func testFanPeaksUnderTheFingerAndFallsOffWithinReach() {
        XCTAssertEqual(L.fan(row: 4, fingerY: 4.5 * row, rowHeight: row, rows: 10), 1, accuracy: 1e-9)
        let near = L.fan(row: 5, fingerY: 4.5 * row, rowHeight: row, rows: 10)
        XCTAssertGreaterThan(near, 0)
        XCTAssertLessThan(near, 1)
        XCTAssertEqual(L.fan(row: 8, fingerY: 4.5 * row, rowHeight: row, rows: 10), 0)
        XCTAssertEqual(L.fan(row: 4, fingerY: nil, rowHeight: row, rows: 10), 0, "No finger, no fan.")
    }

    func testFanIsSymmetricAndHeldInsideTheColumn() {
        let above = L.fan(row: 3, fingerY: 4.5 * row, rowHeight: row, rows: 10)
        let below = L.fan(row: 5, fingerY: 4.5 * row, rowHeight: row, rows: 10)
        XCTAssertEqual(above, below, accuracy: 1e-9)
        // A finger far below the column fans the last rows, as if it were at the bottom edge.
        XCTAssertEqual(L.fan(row: 9, fingerY: 900, rowHeight: row, rows: 10),
                       L.fan(row: 9, fingerY: 10 * row, rowHeight: row, rows: 10))
    }

    // MARK: Tracker

    func testTheFirstTouchJumpsAndEachNewTitleJumpsOnce() {
        var t = DSSectionIndexTracker()
        XCTAssertFalse(t.isTracking)
        XCTAssertTrue(t.move(to: 3, y: 50), "The first touch jumps.")
        XCTAssertTrue(t.isTracking)
        XCTAssertFalse(t.move(to: 3, y: 55), "Same title: no second jump, no second tick.")
        XCTAssertTrue(t.move(to: 4, y: 70))
        XCTAssertTrue(t.move(to: 3, y: 50), "Coming back is a jump too.")
        XCTAssertEqual(t.hovered, 3)
    }

    func testEndingResetsSoTheNextTouchJumpsAgain() {
        var t = DSSectionIndexTracker()
        _ = t.move(to: 3, y: 50)
        t.end()
        XCTAssertFalse(t.isTracking)
        XCTAssertNil(t.hovered)
        XCTAssertTrue(t.move(to: 3, y: 50), "Touching the same title again jumps again.")
    }

    func testAMoveOverNothingKeepsTheFingerButDoesNotJump() {
        var t = DSSectionIndexTracker()
        XCTAssertFalse(t.move(to: nil, y: 10))
        XCTAssertTrue(t.isTracking)
    }

    // MARK: VoiceOver

    func testSwipingUpStepsToTheNextSectionAndStopsAtTheLast() {
        XCTAssertEqual(L.adjusted(nil, count: 5, increment: true), 1, "Before any jump the index reads as the first.")
        XCTAssertEqual(L.adjusted(1, count: 5, increment: true), 2)
        XCTAssertNil(L.adjusted(4, count: 5, increment: true))
    }

    func testSwipingDownStepsBackAndStopsAtTheFirst() {
        XCTAssertEqual(L.adjusted(2, count: 5, increment: false), 1)
        XCTAssertNil(L.adjusted(0, count: 5, increment: false))
        XCTAssertEqual(L.adjusted(nil, count: 5, increment: false), 0, "Down before any jump jumps to the first.")
        XCTAssertNil(L.adjusted(nil, count: 0, increment: true))
    }

    func testAStaleIndexIsClamped() {
        XCTAssertEqual(L.adjusted(9, count: 5, increment: false), 3)
        XCTAssertEqual(L.accessibilityValue(9, titles: ["A", "B"]), "B")
    }

    func testAccessibilityValue() {
        XCTAssertEqual(L.accessibilityValue(nil, titles: ["A", "B"]), "A")
        XCTAssertEqual(L.accessibilityValue(1, titles: ["A", "B"]), "B")
        XCTAssertEqual(L.accessibilityValue(nil, titles: []), "")
    }
}
