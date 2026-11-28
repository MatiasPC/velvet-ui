import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSHeatmap.md lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsHeatmap {
    struct WorkoutHistoryDemo: View {
        let minutes: [Date: Double]          // minutes per day, keyed by the start of the day
        @State private var day: Date?

        var body: some View {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Workouts").ds(.title3)
                    DSHeatmap(minutes, selection: $day, accessibilityLabel: "Workouts")
                    if let day {
                        Text("\(Int(minutes[day] ?? 0)) min on \(day.formatted(date: .abbreviated, time: .omitted))")
                            .ds(.footnote)
                    }
                }
            }
        }
    }

    struct ReadingStreakDemo: View {
        let pages: [Date: Double]
        @DSThemed private var theme

        var body: some View {
            DSHeatmap(pages, weeks: 8, accent: theme.palette.success, accessibilityLabel: "Pages read")
        }
    }
}

@MainActor
final class DSHeatmapTests: XCTestCase {
    typealias L = DSHeatmapLogic

    /// A fixed calendar so the tests don't depend on the machine's zone, locale or first weekday.
    private func calendar(_ zone: String = "UTC", firstWeekday: Int = 1) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone) ?? .gmt
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
    }

    func testBodiesBuild() {
        _ = DocSnippetsHeatmap.WorkoutHistoryDemo(minutes: [:]).body
        _ = DocSnippetsHeatmap.ReadingStreakDemo(pages: [.now: 12]).body
        _ = DSHeatmap([:]).body
        _ = DSHeatmap([.now: 1], weeks: 0, through: .distantPast, selection: .constant(nil), accent: .red, accessibilityLabel: "Steps").body
    }

    // MARK: The grid

    func testColumnsEndOnTheEndDaysWeekAndLeaveLaterDaysEmpty() {
        let cal = calendar()
        // Wednesday 25 November 2026, at 15:00: its week (Sun 22 – Sat 28) is the last column.
        let columns = L.columns(through: date(2026, 11, 25, hour: 15, in: cal), weeks: 2, calendar: cal)
        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(columns[0], (15...21).map { Optional(date(2026, 11, $0, in: cal)) })
        XCTAssertEqual(columns[1], [22, 23, 24, 25].map { Optional(date(2026, 11, $0, in: cal)) } + [nil, nil, nil],
                       "Days after the end day are empty cells, and every day sits at its start.")
    }

    func testRowsFollowTheCalendarsFirstWeekday() {
        let cal = calendar(firstWeekday: 2)   // Monday first
        let columns = L.columns(through: date(2026, 11, 25, in: cal), weeks: 1, calendar: cal)
        XCTAssertEqual(columns.first?.first ?? nil, date(2026, 11, 23, in: cal), "A Monday-first week starts on Monday 23.")
        XCTAssertEqual(columns.first?.compactMap { $0 }.count, 3)
    }

    func testWeeksAreClamped() {
        let cal = calendar()
        XCTAssertEqual(L.columns(through: date(2026, 11, 28, in: cal), weeks: 0, calendar: cal).count, 1)
        XCTAssertEqual(L.columns(through: date(2026, 11, 28, in: cal), weeks: -4, calendar: cal).count, 1)
        XCTAssertEqual(L.columns(through: date(2026, 11, 28, in: cal), weeks: 500, calendar: cal).count, L.maxWeeks)
        XCTAssertEqual(L.clampWeeks(16), 16)
    }

    func testEveryColumnHasSevenRows() {
        let cal = calendar()
        let columns = L.columns(through: date(2026, 11, 28, in: cal), weeks: 16, calendar: cal)
        XCTAssertTrue(columns.allSatisfy { $0.count == L.rows })
        XCTAssertEqual(L.days(in: columns).count, 16 * 7, "Saturday is the last row, so the grid is full.")
    }

    func testDaysStayAtMidnightAcrossDaylightSaving() {
        // New York springs forward on Sunday 8 March 2026: that day is 23 hours long.
        let cal = calendar("America/New_York")
        let days = L.days(in: L.columns(through: date(2026, 3, 14, in: cal), weeks: 3, calendar: cal))
        XCTAssertEqual(days.count, 21)
        XCTAssertTrue(days.allSatisfy { $0 == cal.startOfDay(for: $0) })
        for (a, b) in zip(days, days.dropFirst()) {
            XCTAssertEqual(cal.dateComponents([.day], from: a, to: b).day, 1, "\(a) → \(b) skipped or repeated a day.")
        }
    }

    // MARK: Values

    func testTotalsAddUpEntriesOfTheSameDayAndIgnoreBadValues() {
        let cal = calendar()
        let totals = L.totals([
            date(2026, 11, 13, hour: 8, in: cal): 2,
            date(2026, 11, 13, hour: 19, in: cal): 1.5,
            date(2026, 11, 14, in: cal): -3,
            date(2026, 11, 15, in: cal): .nan,
            date(2026, 11, 16, in: cal): .infinity,
            date(2026, 11, 17, in: cal): 0,
        ], calendar: cal)
        XCTAssertEqual(totals, [date(2026, 11, 13, in: cal): 3.5])
    }

    func testPeakIsTheBusiestDayOnScreen() {
        let cal = calendar()
        let shown = [date(2026, 11, 13, in: cal), date(2026, 11, 14, in: cal)]
        let totals = [shown[0]: 4.0, shown[1]: 9, date(2026, 1, 1, in: cal): 100]
        XCTAssertEqual(L.peak(of: totals, over: shown), 9, "A day off screen doesn't set the scale.")
        XCTAssertEqual(L.peak(of: [:], over: shown), 0)
    }

    func testLevelsAreQuartersOfThePeak() {
        XCTAssertEqual(L.level(for: 0, peak: 10), 0)
        XCTAssertEqual(L.level(for: 0.1, peak: 10), 1, "Any activity shows.")
        XCTAssertEqual(L.level(for: 2.5, peak: 10), 1)
        XCTAssertEqual(L.level(for: 2.6, peak: 10), 2)
        XCTAssertEqual(L.level(for: 5, peak: 10), 2)
        XCTAssertEqual(L.level(for: 7.5, peak: 10), 3)
        XCTAssertEqual(L.level(for: 10, peak: 10), 4)
        XCTAssertEqual(L.level(for: 50, peak: 10), 4)
        XCTAssertEqual(L.level(for: 3, peak: 0), 0)
        XCTAssertEqual(L.level(for: .nan, peak: 10), 0)
        XCTAssertEqual(L.level(for: 3, peak: .infinity), 0)
    }

    // MARK: Touch

    func testCellUnderAPoint() {
        // Four columns of 10 pt cells, 4 pt apart: 52 × 94.
        let size = CGSize(width: 52, height: 94)
        func hit(_ x: CGFloat, _ y: CGFloat) -> [Int]? {
            L.cell(at: CGPoint(x: x, y: y), in: size, columns: 4, spacing: 4).map { [$0.column, $0.row] }
        }
        XCTAssertEqual(hit(0, 0), [0, 0])
        XCTAssertEqual(hit(5, 5), [0, 0])
        XCTAssertEqual(hit(12, 12), [0, 0], "A gap belongs to the cell before it.")
        XCTAssertEqual(hit(14.5, 14.5), [1, 1])
        XCTAssertEqual(hit(52, 94), [3, 6], "The far edge is the last cell, not past it.")
        XCTAssertEqual(hit(45, 85), [3, 6])
        XCTAssertNil(hit(-1, 5))
        XCTAssertNil(hit(5, 95))
        XCTAssertNil(L.cell(at: .zero, in: .zero, columns: 4, spacing: 4))
        XCTAssertNil(L.cell(at: .zero, in: size, columns: 0, spacing: 4))
    }

    // MARK: VoiceOver

    func testSteppingMovesOneDayAndStopsAtTheEnds() {
        let cal = calendar()
        let days = (13...17).map { date(2026, 11, $0, in: cal) }
        XCTAssertEqual(L.step(from: nil, by: -1, in: days, calendar: cal), days.last, "With nothing selected, a swipe starts on the latest day.")
        XCTAssertEqual(L.step(from: nil, by: 1, in: days, calendar: cal), days.last)
        XCTAssertEqual(L.step(from: date(2026, 11, 15, hour: 9, in: cal), by: -1, in: days, calendar: cal), days[1])
        XCTAssertEqual(L.step(from: days[1], by: 1, in: days, calendar: cal), days[2])
        XCTAssertNil(L.step(from: days[0], by: -1, in: days, calendar: cal))
        XCTAssertNil(L.step(from: days[4], by: 1, in: days, calendar: cal))
        XCTAssertEqual(L.step(from: date(2025, 1, 1, in: cal), by: -1, in: days, calendar: cal), days.last,
                       "A selection off the grid restarts from the latest day.")
        XCTAssertNil(L.step(from: nil, by: 1, in: [], calendar: cal))
    }

    func testSpokenValues() {
        let cal = calendar()
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(L.accessibilityValue(for: date(2026, 11, 13, in: cal), total: 3, calendar: cal, locale: locale),
                       "Friday, November 13, 3")
        XCTAssertEqual(L.accessibilityValue(for: date(2026, 11, 13, in: cal), total: 2.5, calendar: cal, locale: locale),
                       "Friday, November 13, 2.5")
        XCTAssertEqual(L.summary(weeks: 16, activeDays: 37), "16 weeks, 37 active days")
        XCTAssertEqual(L.summary(weeks: 1, activeDays: 1), "1 week, 1 active day")
        XCTAssertEqual(L.summary(weeks: 2, activeDays: 0), "2 weeks, 0 active days")
    }

    // MARK: Labels and motion

    func testMonthNamesSitOverTheWeekAMonthBegins() {
        let cal = calendar()
        // Ten weeks through Saturday 28 November 2026 start on Sunday 20 September.
        let columns = L.columns(through: date(2026, 11, 28, in: cal), weeks: 10, calendar: cal)
        XCTAssertEqual(columns.first?.first ?? nil, date(2026, 9, 20, in: cal))
        XCTAssertEqual(L.monthLabels(for: columns, calendar: cal, locale: Locale(identifier: "en_US")), [1: "Oct", 6: "Nov"])
    }

    func testTheEntranceWaveIsDiagonalAndBounded() {
        XCTAssertEqual(L.revealDelay(column: 0, row: 0), 0)
        XCTAssertEqual(L.revealDelay(column: 1, row: 2), 3 * L.revealStep, accuracy: 1e-9)
        XCTAssertEqual(L.revealDelay(column: 2, row: 1), L.revealDelay(column: 1, row: 2), "Cells on one diagonal start together.")
        XCTAssertEqual(L.revealDelay(column: L.maxWeeks - 1, row: 6), L.maxRevealDelay, "A year-long grid still starts within the cap.")
    }
}
