import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSAvatarGroup.md lives here verbatim.
enum DocSnippetsAvatarGroup {
    struct EventRow: View {
        @State private var showsGuests = false

        var body: some View {
            DSScreen(backdrop: true) {
                DSCard {
                    HStack(spacing: DSSpacing.md) {
                        DSAvatarGroup(
                            names: ["Ana Ruiz", "Ben Cole", "Cy Park", "Di Sol", "Eli Wu"],
                            maxVisible: 3
                        ) { showsGuests = true }

                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text("Design Review").ds(.title3)
                            Text("5 people going").ds(.callout)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .dsScreenPadding()
            }
            .dsSheet(isPresented: $showsGuests) {
                Text("Guest list").ds(.title2).padding(DSSpacing.xl)
            }
        }
    }

    struct VariantsDemo: View {
        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                // Photos where you have them, initials where you don't
                DSAvatarGroup(members: [
                    .init(name: "Ada Lovelace", imageURL: URL(string: "https://picsum.photos/seed/ada/96")),
                    .init(name: "Grace Hopper")
                ])

                // Small and tight
                DSAvatarGroup(names: ["Ana Ruiz", "Ben Cole", "Cy Park"], size: DSSpacing.xxl, overlap: 0.45)
            }
        }
    }
}

@MainActor
final class DSAvatarGroupTests: XCTestCase {
    typealias Logic = DSAvatarGroupLogic

    func testSnippetsInstantiate() {
        _ = DocSnippetsAvatarGroup.EventRow().body
        _ = DocSnippetsAvatarGroup.VariantsDemo().body
    }

    // MARK: - Overflow

    func testEveryoneShownWhenTheyFit() {
        XCTAssertEqual(Logic.visibleCount(total: 3, maxVisible: 4), 3)
        XCTAssertEqual(Logic.visibleCount(total: 4, maxVisible: 4), 4, "an exact fit has no bubble")
        XCTAssertEqual(Logic.overflow(total: 4, maxVisible: 4), 0)
        XCTAssertEqual(Logic.visibleCount(total: 0, maxVisible: 4), 0)
    }

    func testTheBubbleTakesTheLastSlot() {
        XCTAssertEqual(Logic.visibleCount(total: 5, maxVisible: 4), 3)
        XCTAssertEqual(Logic.overflow(total: 5, maxVisible: 4), 2, "3 avatars + a \"+2\" bubble = 4 circles")
        XCTAssertEqual(Logic.overflow(total: 7, maxVisible: 3), 5)
    }

    func testAtLeastTwoSlots() {
        XCTAssertEqual(Logic.slots(maxVisible: 0), 2)
        XCTAssertEqual(Logic.slots(maxVisible: -5), 2)
        XCTAssertEqual(Logic.visibleCount(total: 6, maxVisible: 1), 1, "never just a bubble")
        XCTAssertEqual(Logic.overflow(total: 6, maxVisible: 1), 5)
    }

    // MARK: - VoiceOver

    func testSpokenSummary() {
        XCTAssertEqual(Logic.spokenSummary(names: [], others: 0), "No people")
        XCTAssertEqual(Logic.spokenSummary(names: ["Ana"], others: 0), "Ana")
        XCTAssertEqual(Logic.spokenSummary(names: ["Ana", "Ben"], others: 0), "Ana and Ben")
        XCTAssertEqual(Logic.spokenSummary(names: ["Ana", "Ben", "Cy"], others: 0), "Ana, Ben and Cy")
        XCTAssertEqual(Logic.spokenSummary(names: ["Ana", "Ben"], others: 3), "Ana, Ben and 3 others")
        XCTAssertEqual(Logic.spokenSummary(names: ["Ana", "Ben"], others: 1), "Ana, Ben and 1 other")
        XCTAssertEqual(Logic.spokenSummary(names: ["Ana"], others: 4), "Ana and 4 others")
        XCTAssertEqual(Logic.spokenSummary(names: [], others: 2), "2 others")
    }

    func testSummaryFromTheRealSplit() {
        let names = ["Ana", "Ben", "Cy", "Di", "Eli"]
        let shown = Array(names.prefix(Logic.visibleCount(total: 5, maxVisible: 3)))
        XCTAssertEqual(
            Logic.spokenSummary(names: shown, others: Logic.overflow(total: 5, maxVisible: 3)),
            "Ana, Ben and 3 others"
        )
    }

    // MARK: - Identity and geometry

    func testDuplicateNamesGetDistinctStableIds() {
        XCTAssertEqual(Logic.uniqueIDs(for: ["Ana", "Ben", "Ana", "Ana"]), ["Ana", "Ben", "Ana#1", "Ana#2"])
        XCTAssertEqual(Logic.uniqueIDs(for: ["Ana", "Ben", "Ana", "Ana"]), Logic.uniqueIDs(for: ["Ana", "Ben", "Ana", "Ana"]))
        XCTAssertEqual(DSAvatarGroup.Member(name: "Ana").id, "Ana")
        XCTAssertEqual(DSAvatarGroup.Member(id: "u1", name: "Ana").id, "u1")
    }

    func testOverlapIsClampedAndStepFollowsIt() {
        XCTAssertEqual(Logic.clampedOverlap(-1), 0)
        XCTAssertEqual(Logic.clampedOverlap(2), 0.9)
        XCTAssertEqual(Logic.clampedOverlap(.nan), 0)
        XCTAssertEqual(Logic.step(size: 40, overlap: 0.25), 30, accuracy: 1e-9)
        XCTAssertEqual(Logic.step(size: 40, overlap: 5), 4, accuracy: 1e-9, "a clamped overlap still leaves a step")
    }
}
