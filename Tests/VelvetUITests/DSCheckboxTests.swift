import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSCheckbox.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsCheckbox {
    struct CheckboxDemo: View {
        @State private var acceptsTerms = true
        @State private var newsletter = false

        var body: some View {
            DSScreen(backdrop: true) {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        DSCheckbox("I accept the terms and conditions", isOn: $acceptsTerms)
                        DSCheckbox("Send me the newsletter", isOn: $newsletter)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .dsScreenPadding()
            }
        }
    }

    struct CheckboxVariantsDemo: View {
        @DSThemed private var theme
        @State private var compact = true
        @State private var confirmed = false
        @State private var selectAll = false

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                DSCheckbox("Compact row", isOn: $compact, size: .small)
                DSCheckbox("Order confirmed", isOn: $confirmed, onColor: theme.palette.success)
                DSCheckbox(isOn: $selectAll, size: .large)
                    .accessibilityLabel("Select all")
            }
        }
    }
}

@MainActor
final class DSCheckboxTests: XCTestCase {

    func testSnippetsInstantiate() {
        _ = DocSnippetsCheckbox.CheckboxDemo()
        _ = DocSnippetsCheckbox.CheckboxVariantsDemo()
    }

    func testBoxSizesGrowAndComeFromTheSpacingScale() {
        XCTAssertEqual(DSCheckboxSize.small.side, 20)
        XCTAssertEqual(DSCheckboxSize.medium.side, 24)
        XCTAssertEqual(DSCheckboxSize.large.side, 28)
        XCTAssertLessThan(DSCheckboxSize.small.side, DSCheckboxSize.medium.side)
        XCTAssertLessThan(DSCheckboxSize.medium.side, DSCheckboxSize.large.side)
    }

    func testEveryBoxFitsInsideTheHitTarget() {
        for size in [DSCheckboxSize.small, .medium, .large] {
            XCTAssertLessThan(size.side, DSCheckbox.minimumHitTarget)
        }
    }

    func testHitTargetIsAtLeastTheHIGMinimum() {
        XCTAssertGreaterThanOrEqual(DSCheckbox.minimumHitTarget, 44)
    }

    func testCheckmarkStrokeScalesWithTheBox() {
        XCTAssertLessThan(DSCheckboxSize.small.markWidth, DSCheckboxSize.medium.markWidth)
        XCTAssertLessThan(DSCheckboxSize.medium.markWidth, DSCheckboxSize.large.markWidth)
        XCTAssertEqual(DSCheckboxSize.medium.markWidth, DSCheckboxSize.medium.side * 0.1, accuracy: 0.0001)
    }

    func testCheckmarkStaysInsideTheBoxWithRoomForTheRoundCaps() {
        for size in [DSCheckboxSize.small, .medium, .large] {
            let rect = CGRect(x: 0, y: 0, width: size.side, height: size.side)
            let bounds = DSCheckmarkShape().path(in: rect).boundingRect
            let inset = size.markWidth / 2
            XCTAssertGreaterThanOrEqual(bounds.minX - inset, rect.minX)
            XCTAssertGreaterThanOrEqual(bounds.minY - inset, rect.minY)
            XCTAssertLessThanOrEqual(bounds.maxX + inset, rect.maxX)
            XCTAssertLessThanOrEqual(bounds.maxY + inset, rect.maxY)
        }
    }

    func testTickIsDrawnOnlyWhileChecked() {
        XCTAssertEqual(DSCheckbox.markProgress(isOn: true), 1)
        XCTAssertEqual(DSCheckbox.markProgress(isOn: false), 0)
    }

    func testReduceMotionRestsAtFullSizeInsteadOfPopping() {
        // Motion allowed: the accent layer pops up from a smaller size.
        XCTAssertLessThan(DSCheckbox.layerScale(isOn: false, reduceMotion: false), 1)
        XCTAssertEqual(DSCheckbox.layerScale(isOn: true, reduceMotion: false), 1)
        // Reduce Motion: nothing travels, in either state.
        XCTAssertEqual(DSCheckbox.layerScale(isOn: false, reduceMotion: true), 1)
        XCTAssertEqual(DSCheckbox.layerScale(isOn: true, reduceMotion: true), 1)
    }

    func testAccessibilityValue() {
        XCTAssertEqual(DSCheckbox.accessibilityValue(isOn: true), "Checked")
        XCTAssertEqual(DSCheckbox.accessibilityValue(isOn: false), "Unchecked")
    }
}
