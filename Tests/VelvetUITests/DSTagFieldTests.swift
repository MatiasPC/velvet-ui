import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSTagField.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsTagField {
    struct ProfileSkillsDemo: View {
        @State private var skills = ["SwiftUI", "Design systems"]

        var body: some View {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Skills").ds(.title3)
                    DSTagField(tags: $skills, placeholder: "Add a skill")
                }
            }
        }
    }

    struct InviteDemo: View {
        @State private var emails: [String] = []

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSTagField(tags: $emails, placeholder: "Email address", maxTags: 5)
                Text("\(emails.count) of 5 invites").ds(.footnote)
            }
        }
    }
}

@MainActor
final class DSTagFieldTests: XCTestCase {
    typealias L = DSTagFieldLogic

    func testSnippetsInstantiate() {
        _ = DocSnippetsTagField.ProfileSkillsDemo().body
        _ = DocSnippetsTagField.InviteDemo().body
        _ = DSTagField(tags: .constant([])).body
        _ = DSTagField(tags: .constant(["a"]), placeholder: "Label", maxTags: 2, accent: .red, haptic: .soft).body
    }

    // MARK: Normalising

    func testNormalizedTrimsAndCollapsesWhitespace() {
        XCTAssertEqual(L.normalized("  swift  "), "swift")
        XCTAssertEqual(L.normalized("design   systems"), "design systems")
        XCTAssertEqual(L.normalized("\tnew\nline "), "new line")
        XCTAssertEqual(L.normalized("   "), "")
        XCTAssertEqual(L.normalized(""), "")
    }

    // MARK: Adding one tag

    func testAddAppendsANormalisedTag() {
        XCTAssertEqual(L.add(" iOS ", to: ["Swift"], maxTags: nil), .added(["Swift", "iOS"]))
    }

    func testBlankIsIgnoredWithoutARefusal() {
        XCTAssertEqual(L.add("", to: ["Swift"], maxTags: nil), .ignored)
        XCTAssertEqual(L.add("   ", to: ["Swift"], maxTags: nil), .ignored)
    }

    func testDuplicateIsRefusedIgnoringCaseAndPointsAtTheExistingTag() {
        let tags = ["Design", "Swift", "iOS"]
        XCTAssertEqual(L.add("swift", to: tags, maxTags: nil), .refused(.duplicate(index: 1)))
        XCTAssertEqual(L.add("IOS ", to: tags, maxTags: nil), .refused(.duplicate(index: 2)))
        XCTAssertEqual(L.add("design", to: tags, maxTags: 3), .refused(.duplicate(index: 0)),
                       "A duplicate on a full field is reported as a duplicate, which is the more useful reason.")
    }

    func testFullFieldRefuses() {
        XCTAssertEqual(L.add("c", to: ["a", "b"], maxTags: 2), .refused(.full))
        XCTAssertEqual(L.add("c", to: ["a"], maxTags: 2), .added(["a", "c"]))
    }

    func testNonPositiveLimitMeansNoLimit() {
        XCTAssertNil(L.limit(nil))
        XCTAssertNil(L.limit(0))
        XCTAssertNil(L.limit(-3))
        XCTAssertEqual(L.limit(4), 4)
        XCTAssertEqual(L.add("c", to: ["a", "b"], maxTags: 0), .added(["a", "b", "c"]))
    }

    // MARK: Splitting the draft

    func testSplitKeepsTheTextAfterTheLastSeparator() {
        XCTAssertEqual(L.split("swi").complete, [])
        XCTAssertEqual(L.split("swi").remainder, "swi")
        XCTAssertEqual(L.split("swift,").complete, ["swift"])
        XCTAssertEqual(L.split("swift,").remainder, "")
        XCTAssertEqual(L.split("a, b;c\nd").complete, ["a", " b", "c"])
        XCTAssertEqual(L.split("a, b;c\nd").remainder, "d")
    }

    // MARK: Ingesting

    func testTypingACommaCommitsTheWord() {
        let result = L.ingest("swift,", into: ["design"], maxTags: nil)
        XCTAssertEqual(result.tags, ["design", "swift"])
        XCTAssertEqual(result.draft, "")
        XCTAssertEqual(result.added, ["swift"])
        XCTAssertEqual(result.refusals, [])
    }

    func testDraftWithoutASeparatorWaits() {
        let result = L.ingest("swi", into: [], maxTags: nil)
        XCTAssertEqual(result, L.Ingest(tags: [], draft: "swi", added: [], refusals: []))
    }

    func testReturnCommitsTheRemainder() {
        let result = L.ingest("  swift  ", into: [], maxTags: nil, commitRemainder: true)
        XCTAssertEqual(result.tags, ["swift"])
        XCTAssertEqual(result.draft, "")
    }

    func testReturnOnAnEmptyDraftDoesNothing() {
        let result = L.ingest("", into: ["a"], maxTags: nil, commitRemainder: true)
        XCTAssertEqual(result, L.Ingest(tags: ["a"], draft: "", added: [], refusals: []))
    }

    func testPasteAddsEveryPieceAndSkipsBlanksAndDuplicates() {
        let result = L.ingest("design, swift,, Design ,ios", into: ["iOS"], maxTags: nil, commitRemainder: true)
        XCTAssertEqual(result.tags, ["iOS", "design", "swift"])
        XCTAssertEqual(result.added, ["design", "swift"])
        XCTAssertEqual(result.refusals, [.duplicate(index: 1), .duplicate(index: 0)])
        XCTAssertEqual(result.draft, "")
    }

    func testPastePastTheLimitKeepsTheFirstPieceThatDidNotFitInTheDraft() {
        let result = L.ingest("a,b,c,d", into: [], maxTags: 2, commitRemainder: false)
        XCTAssertEqual(result.tags, ["a", "b"])
        XCTAssertEqual(result.added, ["a", "b"])
        XCTAssertEqual(result.refusals, [.full])
        XCTAssertEqual(result.draft, "c", "The text that didn't fit stays visible instead of vanishing.")
    }

    func testTypingIntoAFullFieldIsRefusedAndKept() {
        let result = L.ingest("extra,", into: ["a", "b"], maxTags: 2)
        XCTAssertEqual(result.tags, ["a", "b"])
        XCTAssertEqual(result.refusals, [.full])
        XCTAssertEqual(result.draft, "extra")
    }

    // MARK: Delete on the keyboard

    func testBackspaceArmsThenRemovesOnlyOnAnEmptyDraft() {
        XCTAssertEqual(L.backspace(draft: "sw", tagCount: 2, armed: false), .passThrough)
        XCTAssertEqual(L.backspace(draft: "sw", tagCount: 2, armed: true), .passThrough)
        XCTAssertEqual(L.backspace(draft: "", tagCount: 0, armed: false), .passThrough)
        XCTAssertEqual(L.backspace(draft: "", tagCount: 2, armed: false), .arm)
        XCTAssertEqual(L.backspace(draft: "", tagCount: 2, armed: true), .removeLast)
    }

    // MARK: VoiceOver

    func testAnnouncements() {
        XCTAssertNil(L.announcement(tags: ["a"]))
        XCTAssertEqual(L.announcement(added: ["swift"], tags: ["swift"]), "Added swift")
        XCTAssertEqual(L.announcement(added: ["a", "b"], tags: ["a", "b"]), "Added a, b")
        XCTAssertEqual(L.announcement(removed: "swift", tags: []), "Removed swift")
        XCTAssertEqual(L.announcement(refusals: [.duplicate(index: 0)], tags: ["Swift"]), "Swift is already added")
        XCTAssertEqual(L.announcement(refusals: [.full], tags: ["a"]), "Tag limit reached")
        XCTAssertEqual(
            L.announcement(added: ["b"], refusals: [.full], tags: ["a", "b"]),
            "Added b. Tag limit reached"
        )
    }
}
