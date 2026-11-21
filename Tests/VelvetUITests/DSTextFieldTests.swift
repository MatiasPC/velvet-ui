import XCTest
import SwiftUI
@testable import VelvetUI

/// Pins `DSTextField` / `DSSearchBar` rules: the VoiceOver name, the status each
/// state carries, when an error is announced, the Reduce Motion path and when the
/// search bar offers its clear button.
/// Doc snippets for DSTextField live in `DocSnippetsInputsTests`.
final class DSTextFieldTests: XCTestCase {
    // MARK: - VoiceOver name

    func testLabelIsTheName() {
        XCTAssertEqual(DSTextFieldLogic.accessibilityLabel(label: "Email", placeholder: "you@example.com"), "Email")
    }

    func testPlaceholderNamesAFieldWithoutALabel() {
        XCTAssertEqual(DSTextFieldLogic.accessibilityLabel(label: "", placeholder: "Email"), "Email")
        XCTAssertEqual(DSTextFieldLogic.accessibilityLabel(label: "   ", placeholder: "Email"), "Email")
    }

    func testNameIsTrimmed() {
        XCTAssertEqual(DSTextFieldLogic.accessibilityLabel(label: "  Email \n", placeholder: "x"), "Email")
        XCTAssertEqual(DSTextFieldLogic.accessibilityLabel(label: "", placeholder: " Search "), "Search")
    }

    // MARK: - Status

    func testStatusOfEachState() {
        XCTAssertEqual(DSTextFieldLogic.status(of: .normal), .none)
        XCTAssertEqual(DSTextFieldLogic.status(of: .focused), .none)
        XCTAssertEqual(DSTextFieldLogic.status(of: .error("Too short")), .error("Too short"))
        XCTAssertEqual(DSTextFieldLogic.status(of: .success), .success)
        XCTAssertEqual(DSTextFieldLogic.status(of: .disabled), .disabled)
    }

    func testErrorAndDisabledFlags() {
        XCTAssertTrue(DSTextFieldLogic.isError(.error("x")))
        XCTAssertFalse(DSTextFieldLogic.isError(.success))
        XCTAssertTrue(DSTextFieldLogic.isDisabled(.disabled))
        XCTAssertFalse(DSTextFieldLogic.isDisabled(.normal))
    }

    func testErrorMessageOnlyForANonBlankError() {
        XCTAssertEqual(DSTextFieldLogic.errorMessage(of: .error("Enter a valid email")), "Enter a valid email")
        XCTAssertNil(DSTextFieldLogic.errorMessage(of: .error("")))
        XCTAssertNil(DSTextFieldLogic.errorMessage(of: .error("  ")))
        XCTAssertNil(DSTextFieldLogic.errorMessage(of: .normal))
        XCTAssertNil(DSTextFieldLogic.errorMessage(of: .success))
    }

    func testOnlySuccessHasASpokenIcon() {
        XCTAssertEqual(DSTextFieldLogic.statusIconLabel(for: .success), "Valid")
        XCTAssertNil(DSTextFieldLogic.statusIconLabel(for: .error("x")))
        XCTAssertNil(DSTextFieldLogic.statusIconLabel(for: .normal))
    }

    // MARK: - Announcements

    func testNewErrorIsAnnounced() {
        XCTAssertEqual(DSTextFieldLogic.announcement(from: nil, to: "Enter a valid email"), "Enter a valid email")
    }

    func testChangedErrorIsAnnounced() {
        XCTAssertEqual(DSTextFieldLogic.announcement(from: "Too short", to: "Already taken"), "Already taken")
    }

    func testSameErrorAndClearingAreSilent() {
        XCTAssertNil(DSTextFieldLogic.announcement(from: "Too short", to: "Too short"))
        XCTAssertNil(DSTextFieldLogic.announcement(from: "Too short", to: nil))
        XCTAssertNil(DSTextFieldLogic.announcement(from: nil, to: nil))
    }

    // MARK: - Reduce Motion

    func testStatusMovesOnlyWithoutReduceMotion() {
        XCTAssertTrue(DSTextFieldLogic.movesStatus(reduceMotion: false))
        XCTAssertFalse(DSTextFieldLogic.movesStatus(reduceMotion: true))
    }

    // MARK: - Search bar

    func testClearShowsOnlyWithText() {
        XCTAssertFalse(DSSearchBarLogic.showsClear(""))
        XCTAssertTrue(DSSearchBarLogic.showsClear("L"))
        XCTAssertTrue(DSSearchBarLogic.showsClear(" "))
    }

    func testClearButtonHasAName() {
        XCTAssertEqual(DSSearchBarLogic.clearLabel, "Clear text")
    }

    // MARK: - Construction

    @MainActor
    func testEveryStateBuilds() {
        _ = TextFieldStates().body
    }
}

private struct TextFieldStates: View {
    @State private var text = "Ada"

    var body: some View {
        VStack {
            DSTextField(label: "Name", placeholder: "Your name", icon: "person", text: $text)
            DSTextField(placeholder: "Email", text: $text, state: .error("Enter a valid email"))
            DSTextField(label: "Name", placeholder: "Your name", text: $text, state: .success)
            DSTextField(label: "Locked", placeholder: "n/a", text: $text, state: .disabled)
            DSTextField(label: "Password", placeholder: "secret", text: $text, isSecure: true)
            DSSearchBar(text: $text)
        }
    }
}
