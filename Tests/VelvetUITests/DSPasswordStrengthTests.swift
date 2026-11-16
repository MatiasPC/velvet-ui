import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSPasswordStrength.md lives here
// verbatim, so a drifting API breaks the build instead of the docs.
enum DocSnippetsPasswordStrength {
    struct SignUpPasswordDemo: View {
        @State private var password = ""

        var body: some View {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    DSTextField(label: "New password", placeholder: "At least 8 characters", icon: "lock",
                                text: $password, isSecure: true)
                    DSPasswordStrength(password: password)
                    DSButton("Create account", isFullWidth: true) {
                        // create the account
                    }
                    .disabled(DSPasswordStrength.level(of: password) < .good)
                }
            }
        }
    }

    struct VaultPhraseDemo: View {
        @State private var phrase = ""

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSTextField(label: "Vault phrase", placeholder: "Four or more words", text: $phrase, isSecure: true)
                DSPasswordStrength(password: phrase, minLength: 12, haptic: .success,
                                   accessibilityLabel: "Phrase strength")
            }
        }
    }
}

@MainActor
final class DSPasswordStrengthTests: XCTestCase {
    typealias L = DSPasswordStrengthLogic
    typealias Level = DSPasswordStrength.Level

    func testBodiesBuild() {
        _ = DocSnippetsPasswordStrength.SignUpPasswordDemo().body
        _ = DocSnippetsPasswordStrength.VaultPhraseDemo().body
        _ = DSPasswordStrength(password: "").body
        _ = DSPasswordStrength(password: "Sunflower7!x", minLength: 10, haptic: .success, accessibilityLabel: "Strength").body
    }

    // MARK: Levels

    func testEmptyIsEmpty() {
        XCTAssertEqual(L.level("", minLength: 8), .empty)
        XCTAssertEqual(L.hint("", minLength: 8), "Use at least 8 characters")
    }

    func testShorterThanTheMinimumIsWeak() {
        XCTAssertEqual(L.level("Ab1!xyz", minLength: 8), .weak, "Every kind of character can't make up for length.")
        XCTAssertEqual(L.hint("Ab1!xyz", minLength: 8), "Use at least 8 characters")
    }

    func testCommonPasswordsAreWeakHoweverTheyAreDecorated() {
        for password in ["password", "Password1!", "qwerty123", "123456789", "P@ssw0rd!!", "!!letmein2024"] {
            XCTAssertEqual(L.level(password, minLength: 8), .weak, password)
            XCTAssertEqual(L.hint(password, minLength: 8), "Avoid common passwords", password)
        }
    }

    func testACommonWordInsideALongerPasswordIsNotCommon() {
        XCTAssertFalse(L.analyze("my password is long").isCommon)
        XCTAssertNotEqual(L.level("my password is long", minLength: 8), .weak)
    }

    func testFewDistinctCharactersAreWeak() {
        XCTAssertEqual(L.level("aaaaaaaaaaab", minLength: 8), .weak)
        XCTAssertEqual(L.hint("abababababab", minLength: 8), "Avoid repeating characters")
    }

    func testTheScoreClimbsWithKindsAndLength() {
        XCTAssertEqual(L.level("sunflower", minLength: 8), .fair, "One kind, just long enough.")
        XCTAssertEqual(L.level("sunflower7", minLength: 8), .fair, "Two kinds.")
        XCTAssertEqual(L.level("sunflower7!", minLength: 8), .good, "Three kinds.")
        XCTAssertEqual(L.level("Sunflower7!", minLength: 8), .good, "Four kinds, 11 characters.")
        XCTAssertEqual(L.level("Sunflower7!x", minLength: 8), .strong, "Four kinds and minLength + 4 characters.")
        XCTAssertEqual(L.level("sunflower7!Kite", minLength: 8), .strong)
    }

    func testALongPassphraseIsStrongWithoutSymbolSoup() {
        XCTAssertEqual(L.level("correct horse battery staple", minLength: 8), .strong)
        XCTAssertNil(L.hint("correct horse battery staple", minLength: 8))
    }

    func testAStraightRunCostsALevelStep() {
        XCTAssertTrue(L.hasRun("abcd"))
        XCTAssertTrue(L.hasRun("x4321y"))
        XCTAssertTrue(L.hasRun("zzzz"))
        XCTAssertTrue(L.hasRun("aabcd"), "A run can start after a repeat.")
        XCTAssertFalse(L.hasRun("abc"))
        XCTAssertFalse(L.hasRun("abab"))
        XCTAssertFalse(L.hasRun("ace1357"))
        XCTAssertEqual(L.level("abcd1234efgh", minLength: 8), .fair, "Score 3, minus one for the run.")
        XCTAssertEqual(L.hint("abcd1234efgh", minLength: 8), "Avoid sequences like 1234 or abcd")
    }

    func testTheMinimumIsAtLeastOne() {
        XCTAssertEqual(L.clampedMinimum(0), 1)
        XCTAssertEqual(L.clampedMinimum(-5), 1)
        XCTAssertEqual(L.hint("", minLength: 0), "Use at least 1 character")
    }

    func testAShorterMinimumLowersTheBar() {
        XCTAssertEqual(L.level("garden", minLength: 8), .weak)
        XCTAssertEqual(L.level("garden", minLength: 6), .fair)
    }

    func testThePublicLevelMatchesTheMeter() {
        for password in ["", "short", "sunflower", "sunflower7!", "correct horse battery staple"] {
            XCTAssertEqual(DSPasswordStrength.level(of: password), L.level(password, minLength: 8), password)
        }
    }

    func testLevelsAreOrdered() {
        XCTAssertEqual(Level.allCases, [.empty, .weak, .fair, .good, .strong])
        XCTAssertTrue(Level.fair < .good)
        XCTAssertEqual(Level.allCases.map(\.title), ["Empty", "Weak", "Fair", "Good", "Strong"])
    }

    // MARK: Hints

    func testTheHintNamesTheMissingKindInOrder() {
        XCTAssertEqual(L.hint("sunflower", minLength: 8), "Add a number")
        XCTAssertEqual(L.hint("sunflower7", minLength: 8), "Add a symbol")
        XCTAssertEqual(L.hint("sunflower7!", minLength: 8), "Add a capital letter")
        XCTAssertEqual(L.hint("Sunflower7!", minLength: 8), "Make it longer")
        XCTAssertNil(L.hint("Sunflower7!x", minLength: 8), "No hint once it is strong.")
    }

    func testKinds() {
        XCTAssertEqual(L.Kind.of("a"), .lowercase)
        XCTAssertEqual(L.Kind.of("Ñ"), .uppercase)
        XCTAssertEqual(L.Kind.of("7"), .digit)
        XCTAssertEqual(L.Kind.of(" "), .symbol)
        XCTAssertEqual(L.Kind.of("€"), .symbol)
        XCTAssertEqual(L.analyze("aB3 ").kinds, [.lowercase, .uppercase, .digit, .symbol])
    }

    // MARK: Meter, haptic, VoiceOver

    func testSegmentsFollowTheLevel() {
        XCTAssertEqual(Level.allCases.map(L.filledSegments), [0, 1, 2, 3, 4])
    }

    func testTheHapticFiresOnlyOnBecomingStrong() {
        XCTAssertTrue(L.firesHaptic(from: .good, to: .strong))
        XCTAssertTrue(L.firesHaptic(from: .empty, to: .strong), "A pasted strong password still lands the beat.")
        XCTAssertFalse(L.firesHaptic(from: .strong, to: .strong))
        XCTAssertFalse(L.firesHaptic(from: .fair, to: .good), "No haptic on every step.")
        XCTAssertFalse(L.firesHaptic(from: .strong, to: .good))
    }

    func testSpokenValueAndAnnouncements() {
        XCTAssertEqual(L.accessibilityValue(level: .fair, hint: "Add a number"), "Fair. Add a number")
        XCTAssertEqual(L.accessibilityValue(level: .strong, hint: nil), "Strong")
        XCTAssertEqual(L.announcement(from: .fair, to: .good), "Password strength: Good")
        XCTAssertNil(L.announcement(from: .good, to: .good))
        XCTAssertNil(L.announcement(from: .weak, to: .empty), "Clearing the field isn't announced.")
    }
}
