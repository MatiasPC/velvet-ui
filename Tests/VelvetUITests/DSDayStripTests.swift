import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSDayStrip.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsDayStrip {
    struct BookingDayDemo: View {
        @State private var day = Date.now

        private var nextMonth: ClosedRange<Date> {
            let today = Calendar.current.startOfDay(for: .now)
            let last = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today
            return today...last
        }

        var body: some View {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Pick a day").ds(.title3)
                    DSDayStrip(selection: $day, in: nextMonth, accessibilityLabel: "Booking day")
                }
            }
        }
    }

    struct HabitHistoryDemo: View {
        @State private var day = Date.now
        @DSThemed private var theme

        private var lastTwoWeeks: ClosedRange<Date> {
            let today = Calendar.current.startOfDay(for: .now)
            let first = Calendar.current.date(byAdding: .day, value: -13, to: today) ?? today
            return first...today
        }

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text(day, format: .dateTime.weekday(.wide).month().day()).ds(.title3)
                DSDayStrip(selection: $day, in: lastTwoWeeks, accent: theme.palette.success)
            }
        }
    }
}

@MainActor
final class DSDayStripTests: XCTestCase {
    typealias L = DSDayStripLogic

    /// A fixed calendar so the tests don't depend on the machine's zone or locale.
    private func calendar(_ zone: String = "UTC") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone) ?? .gmt
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
    }

    func testSnippetsInstantiate() {
        _ = DocSnippetsDayStrip.BookingDayDemo().body
        _ = DocSnippetsDayStrip.HabitHistoryDemo().body
        let now = Date.now
        _ = DSDayStrip(selection: .constant(now), in: now...now).body
        _ = DSDayStrip(selection: .constant(now), in: now...now, accent: .red, haptic: .light, accessibilityLabel: "Day").body
    }

    // MARK: The days

    func testDaysListsEveryDayOfTheBoundsAtMidnight() {
        let cal = calendar()
        let days = L.days(in: date(2026, 11, 13, hour: 15, in: cal)...date(2026, 11, 17, hour: 9, in: cal), calendar: cal)
        XCTAssertEqual(days, (13...17).map { date(2026, 11, $0, in: cal) },
                       "Times are ignored: the first and last day are both included, each at its start.")
    }

    func testOneDayBoundsListOneDay() {
        let cal = calendar()
        let noon = date(2026, 11, 13, hour: 12, in: cal)
        XCTAssertEqual(L.days(in: noon...noon, calendar: cal), [date(2026, 11, 13, in: cal)])
    }

    func testDaysCrossMonthAndYearEnds() {
        let cal = calendar()
        let days = L.days(in: date(2026, 12, 30, in: cal)...date(2027, 1, 2, in: cal), calendar: cal)
        XCTAssertEqual(days.count, 4)
        XCTAssertEqual(days.map { L.dayNumber(for: $0, calendar: cal) }, [30, 31, 1, 2])
    }

    func testDaysSurviveADaylightSavingChange() {
        // 8 March 2026: clocks in New York jump from 2:00 to 3:00, so that day is 23 hours long.
        let cal = calendar("America/New_York")
        let days = L.days(in: date(2026, 3, 7, in: cal)...date(2026, 3, 9, hour: 20, in: cal), calendar: cal)
        XCTAssertEqual(days.map { L.dayNumber(for: $0, calendar: cal) }, [7, 8, 9])
        XCTAssertEqual(days, days.map { cal.startOfDay(for: $0) }, "Every day must be exactly its start, or the selection can't match it.")
    }

    func testDaysAreCapped() {
        let cal = calendar()
        let days = L.days(in: date(2000, 1, 1, in: cal)...date(2100, 1, 1, in: cal), calendar: cal)
        XCTAssertEqual(days.count, L.maxDays)
        XCTAssertEqual(days.first, date(2000, 1, 1, in: cal))
    }

    // MARK: Clamping

    func testClampMovesADateToItsDayInsideTheBounds() {
        let cal = calendar()
        let bounds = date(2026, 11, 10, hour: 18, in: cal)...date(2026, 11, 20, hour: 6, in: cal)
        XCTAssertEqual(L.clamp(date(2026, 11, 13, hour: 15, in: cal), to: bounds, calendar: cal), date(2026, 11, 13, in: cal))
        XCTAssertEqual(L.clamp(date(2026, 11, 1, in: cal), to: bounds, calendar: cal), date(2026, 11, 10, in: cal))
        XCTAssertEqual(L.clamp(date(2026, 12, 25, in: cal), to: bounds, calendar: cal), date(2026, 11, 20, in: cal))
        // The bounds' own days count, even at times before or after the bound itself.
        XCTAssertEqual(L.clamp(date(2026, 11, 10, hour: 1, in: cal), to: bounds, calendar: cal), date(2026, 11, 10, in: cal))
        XCTAssertEqual(L.clamp(date(2026, 11, 20, hour: 23, in: cal), to: bounds, calendar: cal), date(2026, 11, 20, in: cal))
    }

    func testContains() {
        let cal = calendar()
        let bounds = date(2026, 11, 10, in: cal)...date(2026, 11, 20, in: cal)
        XCTAssertTrue(L.contains(date(2026, 11, 10, hour: 8, in: cal), in: bounds, calendar: cal))
        XCTAssertTrue(L.contains(date(2026, 11, 20, hour: 23, in: cal), in: bounds, calendar: cal))
        XCTAssertFalse(L.contains(date(2026, 11, 9, hour: 23, in: cal), in: bounds, calendar: cal))
        XCTAssertFalse(L.contains(date(2026, 11, 21, in: cal), in: bounds, calendar: cal))
    }

    // MARK: VoiceOver steps

    func testStepMovesOneDayAndStopsAtTheEnds() {
        let cal = calendar()
        let bounds = date(2026, 11, 10, in: cal)...date(2026, 11, 12, in: cal)
        let middle = date(2026, 11, 11, hour: 15, in: cal)
        XCTAssertEqual(L.step(from: middle, by: 1, in: bounds, calendar: cal), date(2026, 11, 12, in: cal))
        XCTAssertEqual(L.step(from: middle, by: -1, in: bounds, calendar: cal), date(2026, 11, 10, in: cal))
        XCTAssertNil(L.step(from: date(2026, 11, 12, in: cal), by: 1, in: bounds, calendar: cal), "Past the last day does nothing.")
        XCTAssertNil(L.step(from: date(2026, 11, 10, in: cal), by: -1, in: bounds, calendar: cal), "Before the first day does nothing.")
    }

    func testStepFromOutsideTheBoundsStartsAtTheNearestEnd() {
        let cal = calendar()
        let bounds = date(2026, 11, 10, in: cal)...date(2026, 11, 12, in: cal)
        XCTAssertEqual(L.step(from: date(2026, 10, 1, in: cal), by: 1, in: bounds, calendar: cal), date(2026, 11, 11, in: cal))
        XCTAssertEqual(L.step(from: date(2027, 1, 1, in: cal), by: -1, in: bounds, calendar: cal), date(2026, 11, 11, in: cal))
    }

    // MARK: Labels

    func testAccessibilityValueNamesTheDayAndToday() {
        let cal = calendar()
        let locale = Locale(identifier: "en_US")
        let friday = date(2026, 11, 13, hour: 9, in: cal)
        let today = L.accessibilityValue(for: friday, today: date(2026, 11, 13, hour: 22, in: cal), calendar: cal, locale: locale)
        XCTAssertTrue(today.hasSuffix(", Today"), today)
        for part in ["Friday", "November", "13"] {
            XCTAssertTrue(today.contains(part), "\(today) is missing \(part)")
        }

        let other = L.accessibilityValue(for: friday, today: date(2026, 11, 14, in: cal), calendar: cal, locale: locale)
        XCTAssertFalse(other.contains("Today"), other)
        XCTAssertTrue(other.contains("Friday"), other)
    }

    func testCellLabels() {
        let cal = calendar()
        let friday = date(2026, 11, 13, hour: 9, in: cal)
        XCTAssertEqual(L.weekdayLabel(for: friday, calendar: cal, locale: Locale(identifier: "en_US")), "Fri")
        XCTAssertEqual(L.dayNumber(for: friday, calendar: cal), 13)
    }
}
