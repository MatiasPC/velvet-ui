import XCTest
import SwiftUI
@testable import VelvetUI

final class TypographyTests: XCTestCase {
    private let sizes: [CGFloat] = [34, 28, 22, 20, 17, 17, 15, 13, 12, 11, 15, 13, 11, 60, 40, 17, 11]
    private let styles: [Font.TextStyle] = [
        .largeTitle, .title, .title2, .title3, .headline, .body, .callout, .footnote,
        .caption, .caption2, .subheadline, .footnote, .caption2, .largeTitle, .largeTitle, .body, .caption2,
    ]

    func testSizes() {
        XCTAssertEqual(DSTextStyle.allCases.count, sizes.count)
        for (s, expected) in zip(DSTextStyle.allCases, sizes) {
            XCTAssertEqual(s.size, expected, "\(s)")
        }
    }

    func testTextStyles() {
        for (s, expected) in zip(DSTextStyle.allCases, styles) {
            XCTAssertEqual(s.textStyle, expected, "\(s)")
        }
    }

    func testFontIsFixedSystemFont() {
        for s in DSTextStyle.allCases {
            let base = Font.system(size: s.size, weight: s.weight, design: s.design)
            let mono: Bool = [.displayLarge, .displayMedium, .numeric].contains(s)
            XCTAssertEqual(s.font, mono ? base.monospacedDigit() : base, "\(s)")
        }
    }
}
