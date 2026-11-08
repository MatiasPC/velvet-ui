import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSKeypad.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsKeypad {
    struct SendMoneyDemo: View {
        @State private var amount = ""

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.xl) {
                    Text(amount.isEmpty ? "$0" : "$" + amount)
                        .ds(.displayMedium)
                        .accessibilityLabel("Amount")
                    DSKeypad(text: $amount, maxLength: 7, decimalPlaces: 2)
                }
                .dsScreenPadding()
            }
        }
    }

    struct PasscodeDemo: View {
        @State private var pin = ""
        @DSThemed private var theme

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                HStack(spacing: DSSpacing.md) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < pin.count ? theme.accent : theme.subtleFill)
                            .frame(width: DSSpacing.sm, height: DSSpacing.sm)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Passcode")
                .accessibilityValue("\(pin.count) of 4 digits")
                DSKeypad(text: $pin, maxLength: 4)
                    .onChange(of: pin) { _, code in
                        if code.count == 4 { /* verify the code, then clear it */ }
                    }
            }
        }
    }
}

@MainActor
final class DSKeypadTests: XCTestCase {
    typealias L = DSKeypadLogic

    func testSnippetsInstantiate() {
        _ = DocSnippetsKeypad.SendMoneyDemo().body
        _ = DocSnippetsKeypad.PasscodeDemo().body
        _ = DSKeypad(text: .constant("")).body
    }

    /// Types `keys` into an amount pad (two decimals, "." separator) and returns the text.
    private func type(_ keys: [DSKeypadKey], into start: String = "",
                      maxLength: Int? = nil, decimalPlaces: Int = 2, separator: String = ".") -> String {
        keys.reduce(start) { text, key in
            if case .accepted(let next) = L.apply(key, to: text, maxLength: maxLength,
                                                  decimalPlaces: decimalPlaces, separator: separator) {
                return next
            }
            return text
        }
    }

    // MARK: Layout

    func testRowsAreAThreeByFourGrid() {
        let amount = L.rows(decimalPlaces: 2)
        XCTAssertEqual(amount.count, 4)
        XCTAssertTrue(amount.allSatisfy { $0.count == 3 })
        XCTAssertEqual(amount[0], [.digit(1), .digit(2), .digit(3)])
        XCTAssertEqual(amount[3], [.decimal, .digit(0), .delete])
        // Every digit appears exactly once.
        let digits = amount.joined().compactMap { key -> Int? in
            if case .digit(let d) = key { return d }
            return nil
        }
        XCTAssertEqual(digits.sorted(), Array(0...9))
    }

    func testAnIntegerPadHasNoSeparatorKey() {
        XCTAssertEqual(L.rows(decimalPlaces: 0)[3], [nil, .digit(0), .delete])
    }

    // MARK: Digits

    func testDigitsAppend() {
        XCTAssertEqual(L.apply(.digit(4), to: "12", maxLength: nil, decimalPlaces: 0, separator: "."), .accepted("124"))
        XCTAssertEqual(type([.digit(1), .digit(2), .digit(3)]), "123")
    }

    func testMaxLengthCountsDigitsNotTheSeparator() {
        XCTAssertEqual(L.apply(.digit(5), to: "1234", maxLength: 4, decimalPlaces: 0, separator: "."), .refused)
        // "12.3" holds three digits, so a fourth still fits under maxLength 4.
        XCTAssertEqual(L.apply(.digit(4), to: "12.3", maxLength: 4, decimalPlaces: 2, separator: "."), .accepted("12.34"))
        XCTAssertEqual(type([.digit(9), .digit(9), .digit(9), .digit(9), .digit(9)], maxLength: 3), "999")
    }

    func testANonPositiveMaxLengthMeansNoLimit() {
        XCTAssertEqual(L.apply(.digit(1), to: "99", maxLength: 0, decimalPlaces: 0, separator: "."), .accepted("991"))
        XCTAssertEqual(L.apply(.digit(1), to: "99", maxLength: -3, decimalPlaces: 0, separator: "."), .accepted("991"))
    }

    func testAPinKeepsItsLeadingZeros() {
        XCTAssertEqual(type([.digit(0), .digit(0), .digit(7)], maxLength: 4, decimalPlaces: 0), "007")
    }

    func testAnAmountReplacesALoneLeadingZero() {
        XCTAssertEqual(L.apply(.digit(5), to: "0", maxLength: nil, decimalPlaces: 2, separator: "."), .accepted("5"))
        XCTAssertEqual(L.apply(.digit(0), to: "0", maxLength: nil, decimalPlaces: 2, separator: "."), .refused)
        XCTAssertEqual(type([.digit(0), .digit(0), .digit(8)]), "8")
        // Replacing the zero keeps the length, so it is allowed even at the limit.
        XCTAssertEqual(L.apply(.digit(5), to: "0", maxLength: 1, decimalPlaces: 2, separator: "."), .accepted("5"))
    }

    func testDecimalPlacesCapTheFraction() {
        XCTAssertEqual(type([.digit(1), .decimal, .digit(2), .digit(5), .digit(9)]), "1.25")
        XCTAssertEqual(L.apply(.digit(9), to: "1.25", maxLength: nil, decimalPlaces: 2, separator: "."), .refused)
        XCTAssertEqual(type([.digit(3), .decimal, .digit(1), .digit(4)], decimalPlaces: 1), "3.1")
        // Zeros after the separator are real digits of an amount.
        XCTAssertEqual(type([.digit(0), .decimal, .digit(0), .digit(5)]), "0.05")
    }

    func testOutOfRangeDigitsAreRefused() {
        XCTAssertEqual(L.apply(.digit(10), to: "1", maxLength: nil, decimalPlaces: 0, separator: "."), .refused)
        XCTAssertEqual(L.apply(.digit(-1), to: "1", maxLength: nil, decimalPlaces: 0, separator: "."), .refused)
    }

    // MARK: Separator

    func testOneSeparatorAtMost() {
        XCTAssertEqual(L.apply(.decimal, to: "12", maxLength: nil, decimalPlaces: 2, separator: "."), .accepted("12."))
        XCTAssertEqual(L.apply(.decimal, to: "12.", maxLength: nil, decimalPlaces: 2, separator: "."), .refused)
        XCTAssertEqual(L.apply(.decimal, to: "12.5", maxLength: nil, decimalPlaces: 2, separator: "."), .refused)
    }

    func testASeparatorFirstBecomesZeroPoint() {
        XCTAssertEqual(L.apply(.decimal, to: "", maxLength: nil, decimalPlaces: 2, separator: "."), .accepted("0."))
        XCTAssertEqual(type([.decimal, .digit(5)]), "0.5")
    }

    func testAnIntegerPadRefusesTheSeparator() {
        XCTAssertEqual(L.apply(.decimal, to: "12", maxLength: nil, decimalPlaces: 0, separator: "."), .refused)
    }

    func testTheSeparatorFollowsTheLocale() {
        XCTAssertEqual(type([.digit(4), .decimal, .digit(9), .digit(9)], separator: ","), "4,99")
        XCTAssertEqual(L.apply(.decimal, to: "4,9", maxLength: nil, decimalPlaces: 2, separator: ","), .refused)
        // The fraction cap counts the digits after the locale's separator.
        XCTAssertEqual(L.apply(.digit(1), to: "4,99", maxLength: nil, decimalPlaces: 2, separator: ","), .refused)
        // The separator key types the locale's separator, not ".".
        XCTAssertEqual(L.apply(.decimal, to: "4", maxLength: nil, decimalPlaces: 2, separator: ","), .accepted("4,"))
    }

    // MARK: Delete

    func testDeleteRemovesTheLastCharacter() {
        XCTAssertEqual(L.apply(.delete, to: "12.5", maxLength: nil, decimalPlaces: 2, separator: "."), .accepted("12."))
        XCTAssertEqual(L.apply(.delete, to: "12.", maxLength: nil, decimalPlaces: 2, separator: "."), .accepted("12"))
        XCTAssertEqual(L.apply(.delete, to: "7", maxLength: nil, decimalPlaces: 0, separator: "."), .accepted(""))
    }

    func testDeleteOnEmptyIsRefused() {
        XCTAssertEqual(L.apply(.delete, to: "", maxLength: nil, decimalPlaces: 0, separator: "."), .refused)
    }

    func testAMultiCharacterSeparatorIsDeletedWhole() {
        XCTAssertEqual(L.apply(.delete, to: "3٫", maxLength: nil, decimalPlaces: 2, separator: "٫"), .accepted("3"))
        XCTAssertEqual(L.apply(.delete, to: "3::", maxLength: nil, decimalPlaces: 2, separator: "::"), .accepted("3"))
    }

    func testTypingThenDeletingEverythingReturnsToEmpty() {
        let typed = type([.digit(1), .digit(2), .decimal, .digit(3)])
        XCTAssertEqual(typed, "12.3")
        XCTAssertEqual(type(Array(repeating: .delete, count: 6), into: typed), "")
    }

    // MARK: Digit count

    func testDigitCountIgnoresEverythingButASCIIDigits() {
        XCTAssertEqual(L.digitCount(""), 0)
        XCTAssertEqual(L.digitCount("12.34"), 4)
        XCTAssertEqual(L.digitCount("4,99"), 3)
    }

    // MARK: Accessibility

    func testKeyLabels() {
        XCTAssertEqual(L.accessibilityLabel(for: .digit(0)), "0")
        XCTAssertEqual(L.accessibilityLabel(for: .digit(7)), "7")
        XCTAssertEqual(L.accessibilityLabel(for: .decimal), "Decimal point")
        XCTAssertEqual(L.accessibilityLabel(for: .delete), "Delete")
    }
}
