import SwiftUI

// MARK: - Design System Heatmap
// A calendar heatmap: one rounded cell per day, a column per week, the busier
// days in a deeper accent. It is the "how consistent have I been?" view of a
// habit tracker, a workout log, a reading streak, a spending history or a
// commit graph, and it reads at a glance where a bar chart of 100 days can't.
//
// Each day's total is bucketed into five levels (none plus four tints of the
// accent) by its share of the busiest day on screen, so the levels are relative:
// any activity shows, and the deepest tint is always the best day in view.
// Month names sit over the week where a month begins.
//
// Pass a `selection` binding to make it interactive: a tap lifts that day's
// cell (`DSAnimation.springSnappy`, a small shadow) and dims the others, with a
// `.selection` tick; tapping it again clears the selection. The component draws
// no read-out: show the selected day's numbers yourself, as with `DSSlider`.
//
// The calendar rules (which day sits in which cell, the week grid ending on
// `end`, per-day totals, the intensity levels, the month labels, mapping a touch
// to a cell, VoiceOver stepping and the spoken value) live in `DSHeatmapLogic`,
// a pure type the tests pin with a fixed calendar.
//
// Feel: on appear the cells pop in as a diagonal wave from the oldest week.
// Under Reduce Motion they are simply there, and the selection fades instead of
// springing. No borders: empty days are a flat wash, not an outlined square.

/// The heatmap's rules, kept out of the view so they can be tested.
enum DSHeatmapLogic {
    /// Days in a week column.
    static let rows = 7
    /// The most weeks a heatmap draws: one year and a bit.
    static let maxWeeks = 53
    /// Number of tinted levels above "none".
    static let levels = 4
    /// Delay between one diagonal of the entrance wave and the next.
    static let revealStep: Double = 0.012
    /// The whole wave starts within this long, however many weeks there are.
    static let maxRevealDelay: Double = 0.4

    /// `weeks` clamped to `1...maxWeeks`.
    static func clampWeeks(_ weeks: Int) -> Int {
        min(max(weeks, 1), maxWeeks)
    }

    /// The grid: `weeks` columns of seven days each, oldest first, the last
    /// column holding `end`'s week. Rows follow `calendar.firstWeekday`. Days
    /// after `end`'s day are `nil` (drawn as nothing). Every day is at its start.
    static func columns(through end: Date, weeks: Int, calendar: Calendar) -> [[Date?]] {
        let weeks = clampWeeks(weeks)
        let last = calendar.startOfDay(for: end)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: last)?.start ?? last
        guard let first = calendar.date(byAdding: .day, value: -rows * (weeks - 1), to: calendar.startOfDay(for: weekStart)) else {
            return []
        }
        return (0..<weeks).map { column in
            (0..<rows).map { row -> Date? in
                guard let date = calendar.date(byAdding: .day, value: column * rows + row, to: first) else { return nil }
                let day = calendar.startOfDay(for: date)
                return day <= last ? day : nil
            }
        }
    }

    /// Every drawn day of `columns`, oldest first.
    static func days(in columns: [[Date?]]) -> [Date] {
        columns.flatMap { $0.compactMap { $0 } }
    }

    /// `values` summed per day (keys moved to the start of their day). Negative,
    /// NaN and infinite values are ignored.
    static func totals(_ values: [Date: Double], calendar: Calendar) -> [Date: Double] {
        var result: [Date: Double] = [:]
        for (date, value) in values where value.isFinite && value > 0 {
            result[calendar.startOfDay(for: date), default: 0] += value
        }
        return result
    }

    /// The busiest total among `days`, or 0.
    static func peak(of totals: [Date: Double], over days: [Date]) -> Double {
        days.reduce(0) { max($0, totals[$1] ?? 0) }
    }

    /// The intensity level of a day: 0 for nothing, otherwise 1...4 by its share
    /// of `peak` (any activity is at least level 1).
    static func level(for value: Double, peak: Double) -> Int {
        guard value.isFinite, value > 0, peak.isFinite, peak > 0 else { return 0 }
        let share = min(value / peak, 1)
        return min(max(Int((share * Double(levels)).rounded(.up)), 1), levels)
    }

    /// The cell under `point`, in a grid of `size` with `columns` columns of
    /// `rows` cells and `spacing` between them. A point in a gap belongs to the
    /// cell before it; a point outside the grid is `nil`.
    static func cell(at point: CGPoint, in size: CGSize, columns: Int, spacing: CGFloat) -> (column: Int, row: Int)? {
        guard columns > 0, size.width > 0, size.height > 0,
              point.x >= 0, point.y >= 0, point.x <= size.width, point.y <= size.height else { return nil }
        let columnPitch = (size.width + spacing) / CGFloat(columns)
        let rowPitch = (size.height + spacing) / CGFloat(rows)
        let column = min(Int(point.x / columnPitch), columns - 1)
        let row = min(Int(point.y / rowPitch), rows - 1)
        return (column, row)
    }

    /// The day `offset` days from `date` among `days` (ascending), or `nil` past
    /// either end. With no selection, any step lands on the latest day.
    static func step(from date: Date?, by offset: Int, in days: [Date], calendar: Calendar) -> Date? {
        guard let latest = days.last else { return nil }
        guard let date else { return latest }
        let day = calendar.startOfDay(for: date)
        guard let index = days.firstIndex(of: day) else { return latest }
        let target = index + offset
        return days.indices.contains(target) ? days[target] : nil
    }

    /// What VoiceOver reads for a selected day: "Friday, November 13, 3".
    static func accessibilityValue(for day: Date, total: Double, calendar: Calendar, locale: Locale) -> String {
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.wide).month(.wide).day()
        let amount = total.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
        return "\(day.formatted(style)), \(amount)"
    }

    /// What VoiceOver reads with nothing selected: "16 weeks, 37 active days".
    static func summary(weeks: Int, activeDays: Int) -> String {
        let weekText = weeks == 1 ? "1 week" : "\(weeks) weeks"
        let dayText = activeDays == 1 ? "1 active day" : "\(activeDays) active days"
        return "\(weekText), \(dayText)"
    }

    /// Short month names keyed by column: a column gets one when it holds the
    /// first day of a month ("Nov").
    static func monthLabels(for columns: [[Date?]], calendar: Calendar, locale: Locale) -> [Int: String] {
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).month(.abbreviated)
        var labels: [Int: String] = [:]
        for (index, column) in columns.enumerated() {
            if let first = column.compactMap({ $0 }).first(where: { calendar.component(.day, from: $0) == 1 }) {
                labels[index] = first.formatted(style)
            }
        }
        return labels
    }

    /// When a cell starts its entrance: a diagonal wave from the oldest week's first day.
    static func revealDelay(column: Int, row: Int) -> Double {
        min(Double(max(column + row, 0)) * revealStep, maxRevealDelay)
    }
}

private enum Metrics {
    /// Gap between cells: DSSpacing.xxs (4).
    static let spacing: CGFloat = DSSpacing.xxs
    /// Cell corner radius: DSRadius.xs (4).
    static let cellRadius: CGFloat = DSRadius.xs
    /// Accent opacity per level 1...4 (level 0 is the flat wash).
    static let levelOpacity: [Double] = [0.3, 0.55, 0.8, 1]
    /// How far the selected cell lifts.
    static let selectedScale: CGFloat = 1.35
    /// Opacity of the other cells while one is selected.
    static let dimmedOpacity: Double = 0.45
    /// A cell's size before the entrance wave reaches it.
    static let hiddenScale: CGFloat = 0.4
    /// Opacity of a disabled heatmap, the same as `DSToggle`.
    static let disabledOpacity: Double = 0.5
}

/// A calendar heatmap: a column per week, a cell per day, busier days in a
/// deeper accent. Month names sit over the week where each month begins.
///
/// Pass per-day amounts keyed by any time in that day (several entries on one
/// day are added up). Pass `selection` to let a tap pick a day; without it the
/// heatmap is a static chart.
public struct DSHeatmap: View {
    private let values: [Date: Double]
    private let weeks: Int
    private let end: Date
    private let selection: Binding<Date?>?
    private let accent: Color?
    private let label: String

    @State private var gridSize: CGSize = .zero
    @State private var revealed = false
    @DSThemed private var theme
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - values: An amount per day (workouts, minutes, pages, money). Keys can be any time in the day; entries on the same day are summed. Negative and non-finite amounts are ignored.
    ///   - weeks: How many weeks to show, oldest on the leading side. Clamped to 1...53. Defaults to 16.
    ///   - end: The last day shown; its week is the last column. Defaults to now.
    ///   - selection: The selected day (its start), or `nil`. Omit for a static heatmap.
    ///   - accent: The fill the levels are tinted from. Defaults to the theme accent.
    ///   - accessibilityLabel: What VoiceOver reads for the heatmap. Defaults to "Activity".
    public init(
        _ values: [Date: Double],
        weeks: Int = 16,
        through end: Date = .now,
        selection: Binding<Date?>? = nil,
        accent: Color? = nil,
        accessibilityLabel: String = "Activity"
    ) {
        self.values = values
        self.weeks = DSHeatmapLogic.clampWeeks(weeks)
        self.end = end
        self.selection = selection
        self.accent = accent
        self.label = accessibilityLabel
    }

    public var body: some View {
        let columns = DSHeatmapLogic.columns(through: end, weeks: weeks, calendar: calendar)
        let days = DSHeatmapLogic.days(in: columns)
        let totals = DSHeatmapLogic.totals(values, calendar: calendar)
        let peak = DSHeatmapLogic.peak(of: totals, over: days)
        let months = DSHeatmapLogic.monthLabels(for: columns, calendar: calendar, locale: locale)
        let selectedDay = selection?.wrappedValue.map { calendar.startOfDay(for: $0) }

        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
            monthRow(count: columns.count, labels: months)
            grid(columns, totals: totals, peak: peak, selectedDay: selectedDay)
        }
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
        .onAppear {
            // Each cell animates this with its own delayed spring (or none under
            // Reduce Motion), so the wave needs no transaction here.
            revealed = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValue(days: days, totals: totals, selectedDay: selectedDay))
        .modifier(DSHeatmapAdjustable(isEnabled: selection != nil) { offset in
            step(by: offset, in: days)
        })
    }

    private var selectionAnimation: Animation {
        reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy
    }

    // MARK: Rows

    /// Month names over the columns where a month begins. A hidden caption keeps
    /// the row one line tall; each name hangs off its column's leading edge.
    private func monthRow(count: Int, labels: [Int: String]) -> some View {
        HStack(spacing: Metrics.spacing) {
            ForEach(0..<count, id: \.self) { column in
                Text(verbatim: " ")
                    .ds(.caption2)
                    .hidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .leading) {
                        if let name = labels[column] {
                            Text(name)
                                .ds(.caption2, color: theme.palette.textSecondary)
                                .lineLimit(1)
                                .fixedSize()
                        }
                    }
            }
        }
        .accessibilityHidden(true)
    }

    private func grid(_ columns: [[Date?]], totals: [Date: Double], peak: Double, selectedDay: Date?) -> some View {
        HStack(alignment: .top, spacing: Metrics.spacing) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                VStack(spacing: Metrics.spacing) {
                    ForEach(0..<DSHeatmapLogic.rows, id: \.self) { row in
                        cell(column[row], column: index, row: row, totals: totals, peak: peak, selectedDay: selectedDay)
                    }
                }
                .zIndex(selectedDay.map { column.contains($0) } == true ? 1 : 0)
            }
        }
        .contentShape(Rectangle())
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
            gridSize = size
        }
        .onTapGesture(coordinateSpace: .local) { location in
            tap(at: location, columns: columns)
        }
    }

    // MARK: Cells

    @ViewBuilder
    private func cell(_ day: Date?, column: Int, row: Int, totals: [Date: Double], peak: Double, selectedDay: Date?) -> some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.cellRadius, style: .continuous)
        if let day {
            let isSelected = day == selectedDay
            let isDimmed = selectedDay != nil && !isSelected
            let level = DSHeatmapLogic.level(for: totals[day] ?? 0, peak: peak)
            shape
                .fill(fill(for: level))
                .aspectRatio(1, contentMode: .fit)
                .scaleEffect(revealed ? (isSelected ? Metrics.selectedScale : 1) : Metrics.hiddenScale)
                .dsShadow(isSelected ? .sm : .none)
                .opacity(revealed ? (isDimmed ? Metrics.dimmedOpacity : 1) : 0)
                .zIndex(isSelected ? 1 : 0)
                .animation(selectionAnimation, value: isSelected)
                .animation(selectionAnimation, value: isDimmed)
                .animation(
                    reduceMotion ? nil : DSAnimation.springSnappy.delay(DSHeatmapLogic.revealDelay(column: column, row: row)),
                    value: revealed
                )
        } else {
            shape
                .fill(Color.clear)
                .aspectRatio(1, contentMode: .fit)
        }
    }

    private func fill(for level: Int) -> Color {
        guard level > 0 else {
            // A flat wash on a backdrop; off one the wash is near-white, so use the
            // palette's neutral line color (as DSSkeleton does).
            return theme.onBackdrop ? theme.washSurface : theme.palette.border
        }
        let index = min(level, Metrics.levelOpacity.count) - 1
        return (accent ?? theme.accent).opacity(Metrics.levelOpacity[index])
    }

    // MARK: Behavior

    private func tap(at location: CGPoint, columns: [[Date?]]) {
        guard isEnabled, selection != nil,
              let hit = DSHeatmapLogic.cell(at: location, in: gridSize, columns: columns.count, spacing: Metrics.spacing),
              columns.indices.contains(hit.column),
              let day = columns[hit.column][hit.row] else { return }
        let current = selection?.wrappedValue.map { calendar.startOfDay(for: $0) }
        select(current == day ? nil : day)
    }

    private func step(by offset: Int, in days: [Date]) {
        guard isEnabled,
              let day = DSHeatmapLogic.step(from: selection?.wrappedValue, by: offset, in: days, calendar: calendar) else { return }
        guard day != selection?.wrappedValue.map({ calendar.startOfDay(for: $0) }) else { return }
        select(day)
    }

    private func select(_ day: Date?) {
        guard let selection else { return }
        DSHapticEngine.shared.fire(.selection)
        withAnimation(selectionAnimation) { selection.wrappedValue = day }
    }

    private func accessibilityValue(days: [Date], totals: [Date: Double], selectedDay: Date?) -> String {
        if let selectedDay, days.contains(selectedDay) {
            return DSHeatmapLogic.accessibilityValue(for: selectedDay, total: totals[selectedDay] ?? 0, calendar: calendar, locale: locale)
        }
        let active = days.filter { (totals[$0] ?? 0) > 0 }.count
        return DSHeatmapLogic.summary(weeks: weeks, activeDays: active)
    }
}

// MARK: - Accessibility

/// Swipe up or down for the next or previous day, only when the heatmap is
/// interactive (a static chart isn't adjustable).
private struct DSHeatmapAdjustable: ViewModifier {
    let isEnabled: Bool
    let step: (Int) -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content.accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: step(1)
                case .decrement: step(-1)
                @unknown default: break
                }
            }
        } else {
            content
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSHeatmapPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var selected: Date?

    /// A repeatable fake habit: most weekdays, fewer weekends, a quiet stretch.
    private var workouts: [Date: Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var values: [Date: Double] = [:]
        for offset in 0..<120 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let amount = Double((offset * 7 + offset / 5) % 5)
            if !(30...40).contains(offset) { values[day] = amount }
        }
        return values
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Workouts").ds(.title3)
                        DSHeatmap(workouts, selection: $selected, accessibilityLabel: "Workouts")
                        Text(selected.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Tap a day")
                            .ds(.footnote, color: DSColors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Static, eight weeks, custom accent").ds(.overline, color: DSColors.textSecondary)
                    DSHeatmap(workouts, weeks: 8, accent: DSColors.success)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Disabled").ds(.overline, color: DSColors.textSecondary)
                    DSHeatmap(workouts, weeks: 10, selection: $selected)
                        .disabled(true)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Heatmap — Light") {
    DSHeatmapPreviewHost().preferredColorScheme(.light)
}

#Preview("Heatmap — Dark") {
    DSHeatmapPreviewHost().preferredColorScheme(.dark)
}
#endif
