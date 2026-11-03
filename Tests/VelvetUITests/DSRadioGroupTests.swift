import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSRadioGroup.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsRadioGroup {
    struct RadioGroupDemo: View {
        enum Plan: Hashable { case free, pro, team }

        @State private var plan = Plan.pro
        @State private var shipping = "Standard"

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    DSCard {
                        DSRadioGroup(selection: $plan, options: [
                            DSRadioOption("Free", value: Plan.free, subtitle: "For trying things out"),
                            DSRadioOption("Pro", value: Plan.pro, subtitle: "Everything, for one person"),
                            DSRadioOption("Team", value: Plan.team, subtitle: "Shared workspaces"),
                        ])
                        .accessibilityLabel("Plan")
                    }

                    DSCard {
                        DSRadioGroup(selection: $shipping, options: ["Standard", "Express", "Overnight"])
                            .accessibilityLabel("Shipping speed")
                    }
                }
                .dsScreenPadding()
            }
        }
    }

    struct RadioGroupVariantsDemo: View {
        @DSThemed private var theme
        @State private var payment = 2

        var body: some View {
            DSRadioGroup(
                selection: $payment,
                options: [
                    DSRadioOption("Apple Pay", value: 1, icon: "apple.logo"),
                    DSRadioOption("Credit card", value: 2, subtitle: "Visa ending 4242", icon: "creditcard"),
                ],
                accent: theme.palette.success
            )
        }
    }
}

@MainActor
final class DSRadioGroupTests: XCTestCase {
    typealias M = DSRadioGroupMetrics

    func testSnippetsInstantiate() {
        _ = DocSnippetsRadioGroup.RadioGroupDemo()
        _ = DocSnippetsRadioGroup.RadioGroupVariantsDemo()
    }

    // MARK: Any Hashable

    func testOptionIdIsItsValueForAnyHashable() {
        enum Plan: Hashable { case free, pro }
        XCTAssertEqual(DSRadioOption("Free", value: Plan.free).id, .free)
        XCTAssertEqual(DSRadioOption("One", value: 1).id, 1)
        let uuid = UUID()
        XCTAssertEqual(DSRadioOption("Row", value: uuid).id, uuid)
    }

    func testStringConvenienceUsesTheLabelAsTheValue() {
        let group = DSRadioGroup(selection: .constant("Express"), options: ["Standard", "Express"])
        _ = group.body
    }

    func testGroupBuildsForEnumIntAndUUIDSelections() {
        enum Plan: Hashable { case free, pro }
        _ = DSRadioGroup(selection: .constant(Plan.pro), options: [
            DSRadioOption("Free", value: Plan.free),
            DSRadioOption("Pro", value: Plan.pro, subtitle: "Everything"),
        ]).body
        _ = DSRadioGroup(selection: .constant(2), options: [
            DSRadioOption("One", value: 1),
            DSRadioOption("Two", value: 2, icon: "2.circle"),
        ]).body
        let ids = [UUID(), UUID()]
        _ = DSRadioGroup(selection: .constant(ids[0]), options: ids.map { DSRadioOption("Row", value: $0) }).body
    }

    // MARK: Layout

    func testIndicatorIsTheSameBoxAsACheckboxMedium() {
        // DSCheckboxSize.medium is DSSpacing.xl; the two must stay in step.
        XCTAssertEqual(M.indicatorSide, DSSpacing.xl)
        XCTAssertEqual(M.indicatorSide, 24)
    }

    func testDotIsSmallerThanTheIndicator() {
        XCTAssertGreaterThan(M.dotSide, 0)
        XCTAssertLessThan(M.dotSide, M.indicatorSide)
    }

    func testEveryRowMeetsTheHitTarget() {
        XCTAssertGreaterThanOrEqual(M.hitTarget, 44)
        XCTAssertGreaterThanOrEqual(M.minimumRowHeight, 44)
        // A one-line row is already tall enough from its padding and indicator.
        XCTAssertGreaterThanOrEqual(DSSpacing.sm * 2 + M.indicatorSide, 44)
    }

    // MARK: Motion

    func testReduceMotionRestsAtFullSizeInsteadOfPopping() {
        // Motion allowed: the accent layer pops up and the dot grows from nothing.
        XCTAssertLessThan(M.layerScale(isSelected: false, reduceMotion: false), 1)
        XCTAssertEqual(M.layerScale(isSelected: true, reduceMotion: false), 1)
        XCTAssertEqual(M.dotScale(isSelected: false, reduceMotion: false), 0)
        XCTAssertEqual(M.dotScale(isSelected: true, reduceMotion: false), 1)
        // Reduce Motion: nothing travels, in either state.
        XCTAssertEqual(M.layerScale(isSelected: false, reduceMotion: true), 1)
        XCTAssertEqual(M.layerScale(isSelected: true, reduceMotion: true), 1)
        XCTAssertEqual(M.dotScale(isSelected: false, reduceMotion: true), 1)
        XCTAssertEqual(M.dotScale(isSelected: true, reduceMotion: true), 1)
    }

    // MARK: Selection

    func testReselectingTheCurrentValueIsNotAChange() {
        XCTAssertFalse(M.isChange(to: "Pro", from: "Pro"))
        XCTAssertTrue(M.isChange(to: "Team", from: "Pro"))
        XCTAssertTrue(M.isChange(to: 2, from: 1))
    }

    // MARK: Accessibility

    func testAccessibilityLabelAppendsTheSubtitle() {
        XCTAssertEqual(M.accessibilityLabel(title: "Pro", subtitle: nil), "Pro")
        XCTAssertEqual(M.accessibilityLabel(title: "Pro", subtitle: ""), "Pro")
        XCTAssertEqual(
            M.accessibilityLabel(title: "Pro", subtitle: "Everything, for one person"),
            "Pro, Everything, for one person"
        )
    }

    func testAccessibilityValueIsTheOneBasedPosition() {
        XCTAssertEqual(M.accessibilityValue(position: 1, count: 3), "1 of 3")
        XCTAssertEqual(M.accessibilityValue(position: 3, count: 3), "3 of 3")
    }

    func testSelectionIsAnnounced() {
        XCTAssertEqual(M.announcement(title: "Team"), "Team, selected")
    }
}
