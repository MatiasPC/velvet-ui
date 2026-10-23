import XCTest
import SwiftUI
@testable import VelvetUI

// Every snippet on docs/components/DSNumberTicker.md lives here verbatim.
enum DocSnippetsNumberTicker {
    struct NumberTickerDemo: View {
        @State private var balance = 1_284.50

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Balance").ds(.overline)
                    DSNumberTicker(balance, format: .currency(code: "USD"))
                    DSButton("Add $100") { balance += 100 }
                }
                .dsScreenPadding()
            }
        }
    }

    struct NumberTickerVariantsDemo: View {
        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                DSNumberTicker(8_432, style: .displayLarge)
                DSNumberTicker(0.42, format: .percent, style: .numeric)
                DSNumberTicker(3.14159, format: .number.precision(.fractionLength(2)))
            }
        }
    }
}

@MainActor
final class DSNumberTickerTests: XCTestCase {

    func testSnippetsInstantiate() {
        _ = DocSnippetsNumberTicker.NumberTickerDemo().body
        _ = DocSnippetsNumberTicker.NumberTickerVariantsDemo().body
    }

    private func slots(_ text: String) -> [DSNumberTickerSlot] {
        DSNumberTicker.slots(for: text)
    }

    func testPlainDigitsAreAllDigitSlots() {
        let result = slots("128")
        XCTAssertEqual(result.map(\.digit), [1, 2, 8])
    }

    func testIdsCountFromTheRight() {
        XCTAssertEqual(slots("128").map(\.id), [2, 1, 0])
    }

    func testGroupingSeparatorsAreStaticSlots() {
        let result = slots("1,234")
        XCTAssertEqual(result.map(\.digit), [1, nil, 2, 3, 4])
        XCTAssertEqual(result[1].character, ",")
    }

    func testDecimalPointIsStatic() {
        let result = slots("3.14")
        XCTAssertEqual(result.map(\.digit), [3, nil, 1, 4])
    }

    func testCurrencySymbolIsStatic() {
        let result = slots("$9.50")
        XCTAssertNil(result[0].digit)
        XCTAssertEqual(result[0].character, "$")
        XCTAssertEqual(result.compactMap(\.digit), [9, 5, 0])
    }

    func testNegativeSignAndPercentAreStatic() {
        XCTAssertEqual(slots("-42").map(\.digit), [nil, 4, 2])
        XCTAssertEqual(slots("42%").map(\.digit), [4, 2, nil])
    }

    func testEmptyStringHasNoSlots() {
        XCTAssertTrue(slots("").isEmpty)
    }

    func testGrowthFrom99To100KeepsUnitsAndTensIdentity() {
        let before = slots("99")
        let after = slots("100")
        XCTAssertEqual(before.map(\.id), [1, 0])
        XCTAssertEqual(after.map(\.id), [2, 1, 0])
        // The two existing places keep their ids; only id 2 is new.
        XCTAssertEqual(Set(before.map(\.id)).subtracting(after.map(\.id)), [])
        XCTAssertEqual(Set(after.map(\.id)).subtracting(before.map(\.id)), [2])
    }

    func testNonASCIIDigitsAreNotRolled() {
        XCTAssertEqual(slots("٣").map(\.digit), [nil])
    }

    func testAccessibilityLabelIsTheFullFormattedString() {
        XCTAssertEqual(DSNumberTicker.accessibilityLabel(for: "$1,384.50"), "$1,384.50")
    }
}
