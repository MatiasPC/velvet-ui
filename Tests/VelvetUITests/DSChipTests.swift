import XCTest
import SwiftUI
@testable import VelvetUI

// The Variants and standalone snippets on docs/components/DSChip.md live here
// verbatim (the Usage snippet is in DocSnippetsInputsTests), so a drifting API
// breaks the build instead of the docs.
enum DocSnippetsChip {
    enum Sort: Hashable { case trending, newest, topRated }

    struct ChipStandaloneDemo: View {
        @State private var isOn = false
        private func addTag() {}

        var body: some View {
            VStack {
                DSChip("Add tag", icon: "plus") { addTag() }
                DSChip("Design", isSelected: isOn) { isOn.toggle() }
            }
        }
    }

    struct ChipVariantsDemo: View {
        @State private var media: Set<String> = ["photos"]
        @State private var sort: Sort? = .trending
        @DSThemed private var theme

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                // Leading icons and a custom accent for the selected fill
                DSChipGroup(
                    [
                        DSChipItem("Photos", value: "photos", icon: "photo"),
                        DSChipItem("Videos", value: "videos", icon: "video"),
                        DSChipItem("Audio", value: "audio", icon: "waveform")
                    ],
                    selection: $media,
                    accent: theme.palette.success
                )

                // Any Hashable value, not just strings
                DSChipGroup(
                    [
                        DSChipItem("Trending", value: Sort.trending),
                        DSChipItem("Newest", value: Sort.newest),
                        DSChipItem("Top rated", value: Sort.topRated)
                    ],
                    selection: $sort,
                    spacing: DSSpacing.sm
                )
            }
        }
    }
}

@MainActor
final class DSChipTests: XCTestCase {

    func testSnippetsInstantiate() {
        _ = DocSnippetsChip.ChipStandaloneDemo()
        _ = DocSnippetsChip.ChipVariantsDemo()
    }

    // MARK: - Single selection

    func testTappingAnUnselectedChipSelectsIt() {
        XCTAssertEqual(DSChipGroup<String>.toggled("Newest", from: nil), "Newest")
        XCTAssertEqual(DSChipGroup<String>.toggled("Newest", from: "Trending"), "Newest")
    }

    func testTappingTheSelectedChipClearsTheSelection() {
        XCTAssertNil(DSChipGroup<String>.toggled("Newest", from: "Newest"))
    }

    // MARK: - Multiple selection

    func testTappingAnUnselectedChipAddsItToTheSet() {
        XCTAssertEqual(DSChipGroup<String>.toggled("Product", in: ["Design"]), ["Design", "Product"])
        XCTAssertEqual(DSChipGroup<String>.toggled("Design", in: []), ["Design"])
    }

    func testTappingASelectedChipRemovesItFromTheSet() {
        XCTAssertEqual(DSChipGroup<String>.toggled("Design", in: ["Design", "Product"]), ["Product"])
        XCTAssertEqual(DSChipGroup<String>.toggled("Design", in: ["Design"]), [])
    }

    func testTogglingTwiceRestoresTheSelection() {
        let start: Set<Int> = [1, 3]
        let once = DSChipGroup<Int>.toggled(2, in: start)
        XCTAssertEqual(DSChipGroup<Int>.toggled(2, in: once), start)
    }

    // MARK: - Items

    func testAnItemIsIdentifiedByItsValue() {
        let item = DSChipItem("Photos", value: "photos", icon: "photo")
        XCTAssertEqual(item.id, "photos")
        XCTAssertEqual(item.title, "Photos")
        XCTAssertEqual(item.icon, "photo")
        XCTAssertNil(DSChipItem("Docs", value: 1).icon)
    }

    func testStringShortcutsCompile() {
        var multiple: Set<String> = []
        _ = DSChipGroup(["A", "B", "C"], selection: Binding(get: { multiple }, set: { multiple = $0 }))
        var single: String?
        _ = DSChipGroup(["A", "B", "C"], selection: Binding(get: { single }, set: { single = $0 }))
    }
}
