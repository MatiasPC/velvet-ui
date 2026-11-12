import XCTest

/// DSTagField on its stage (a profile's skills, at most four, starting with
/// "SwiftUI" and "Design systems"). The read-out under the field is one
/// accessibility element, "Tags", whose value is the list joined with ", ", so
/// every assertion reads what the field holds after each step. Tags are typed
/// on the keyboard and removed through their "Remove <tag>" buttons, the way a
/// VoiceOver user would find them.
final class DSTagFieldUITests: XCTestCase {
    @MainActor
    func testTypingAddsTagsAndTheRulesHold() {
        let app = StageLauncher.launch("DSTagField")
        let tags = app.element("Tags")
        XCTAssertTrue(tags.waitForExistence(timeout: 5))
        XCTAssertEqual(tags.stringValue, "SwiftUI, Design systems")

        let field = app.textFields["Add a skill"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        // (No keyboard assertion: with a hardware keyboard attached the simulator
        // shows none, and typeText fails loudly if the field isn't focused.)
        field.tap()
        StageLauncher.settle()

        // A comma ends a tag; surrounding spaces are trimmed.
        app.typeText(" swift ,")
        XCTAssertTrue(tags.waitForValue("SwiftUI, Design systems, swift"), "Got \(tags.stringValue ?? "nil")")

        // A duplicate in another letter case is refused; the list is unchanged.
        app.typeText("SWIFTUI,")
        StageLauncher.settle()
        XCTAssertEqual(tags.stringValue, "SwiftUI, Design systems, swift", "A case-insensitive duplicate was added.")

        // Tapping a tag removes it.
        let remove = app.buttons["Remove Design systems"].firstMatch
        XCTAssertTrue(remove.waitForExistence(timeout: 5))
        remove.tap()
        XCTAssertTrue(tags.waitForValue("SwiftUI, swift"), "Got \(tags.stringValue ?? "nil")")

        // A paste-like run adds each piece; past the limit of four the rest is refused.
        field.tap()
        StageLauncher.settle()
        app.typeText("ios, kit, macos\n")
        XCTAssertTrue(tags.waitForValue("SwiftUI, swift, ios, kit"), "Got \(tags.stringValue ?? "nil")")
        StageLauncher.settle()
        XCTAssertEqual(tags.stringValue, "SwiftUI, swift, ios, kit", "A fifth tag got past maxTags: 4.")

        StageLauncher.attachScreenshot(app, named: "DSTagField · four skills", to: self)
    }
}
