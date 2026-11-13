import SwiftUI

// MARK: - Design System Day Strip
// A horizontal strip of days to pick one from: the booking screen's "which
// day?", a habit tracker's last two weeks, a fitness log's day switcher, a
// delivery slot picker. Each day is a short weekday over its number; the
// selected day sits in an accent capsule that slides to the next one you tap
// (`matchedGeometryEffect`, the same mechanism as `DSSegmentedControl`), and
// the strip glides to keep it centred. Today carries a small dot.
//
// Why not `DatePicker`: the graphical style is a whole month grid (too tall for
// a header) and the compact style hides the days behind a popover. A strip keeps
// the nearby days one tap away, which is what day-to-day screens need.
//
// The calendar rules (every day of the bounds at midnight, clamping a date
// into them, stepping one day for VoiceOver, the spoken value) live in
// `DSDayStripLogic`, a pure type the tests pin with a fixed calendar.
//
// Feel: a tap fires `haptic` (a `.selection` tick by default) and springs the
// capsule over with `DSAnimation.springSnappy`. Under Reduce Motion the capsule
// fades across and the strip jumps instead of gliding. No borders: the strip
// draws no surface of its own; put it on a `DSCard` or the backdrop.

/// The day-picking rules, kept out of the view so they can be tested.
enum DSDayStripLogic {
    /// The most days a strip lists (about ten years), so a careless range can't
    /// build a runaway list.
    static let maxDays = 3_660

    /// Every day from the lower bound's day to the upper bound's day, inclusive,
    /// each at the start of its day in `calendar`. Capped at `maxDays`.
    static func days(in bounds: ClosedRange<Date>, calendar: Calendar) -> [Date] {
        let first = calendar.startOfDay(for: bounds.lowerBound)
        let last = calendar.startOfDay(for: bounds.upperBound)
        var result: [Date] = []
        var offset = 0
        while result.count < maxDays,
              let next = calendar.date(byAdding: .day, value: offset, to: first) {
            let day = calendar.startOfDay(for: next)
            guard day <= last else { break }
            result.append(day)
            offset += 1
        }
        return result
    }

    /// `date`'s day, at its start, moved inside the bounds' first and last day.
    static func clamp(_ date: Date, to bounds: ClosedRange<Date>, calendar: Calendar) -> Date {
        let day = calendar.startOfDay(for: date)
        let first = calendar.startOfDay(for: bounds.lowerBound)
        let last = calendar.startOfDay(for: bounds.upperBound)
        return min(max(day, first), last)
    }

    /// Whether `date` falls on one of the days the strip shows.
    static func contains(_ date: Date, in bounds: ClosedRange<Date>, calendar: Calendar) -> Bool {
        clamp(date, to: bounds, calendar: calendar) == calendar.startOfDay(for: date)
    }

    /// The day `offset` days from `date` (clamped into the bounds first), or
    /// `nil` when that would leave the bounds: VoiceOver's swipe up or down at
    /// the first or last day does nothing.
    static func step(from date: Date, by offset: Int, in bounds: ClosedRange<Date>, calendar: Calendar) -> Date? {
        let start = clamp(date, to: bounds, calendar: calendar)
        guard let moved = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
        let day = calendar.startOfDay(for: moved)
        return contains(day, in: bounds, calendar: calendar) ? day : nil
    }

    /// What VoiceOver reads for the selected day: "Friday, November 13", with
    /// ", Today" when it's today.
    static func accessibilityValue(for date: Date, today: Date, calendar: Calendar, locale: Locale) -> String {
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.wide).month(.wide).day()
        let text = date.formatted(style)
        return calendar.isDate(date, inSameDayAs: today) ? text + ", Today" : text
    }

    /// The short weekday shown over the number ("Fri").
    static func weekdayLabel(for date: Date, calendar: Calendar, locale: Locale) -> String {
        date.formatted(Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).weekday(.abbreviated))
    }

    /// The day of the month shown in the cell ("13").
    static func dayNumber(for date: Date, calendar: Calendar) -> Int {
        calendar.component(.day, from: date)
    }
}

private enum Metrics {
    /// A day cell is at least this wide: DSSpacing.huge (48), above the 44 pt tap target.
    static let cellWidth: CGFloat = DSSpacing.huge
    /// A day cell is at least this tall: DSSpacing.massive (64).
    static let cellHeight: CGFloat = DSSpacing.massive
    /// The today dot: DSSpacing.xxs (4).
    static let dotSize: CGFloat = DSSpacing.xxs
    /// Opacity of a disabled strip, the same as `DSToggle`.
    static let disabledOpacity: Double = 0.5
}

/// A horizontal strip of days: tap one to select it. The selected day sits in
/// an accent capsule that springs across, and today carries a dot.
///
/// Bind it to a `Date` and pass the first and last day to show. A tap writes the
/// start of that day (in the environment's calendar) to the binding. A selection
/// outside the bounds highlights nothing until a day is picked.
public struct DSDayStrip: View {
    @Binding private var selection: Date
    private let bounds: ClosedRange<Date>
    private let accent: Color?
    private let haptic: DSHapticStyle
    private let label: String

    @Namespace private var namespace
    @DSThemed private var theme
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - selection: The selected day. A tap writes the start of the tapped day.
    ///   - bounds: The first and last day to show (times are ignored). At most about ten years of days.
    ///   - accent: The selection capsule's fill. Defaults to the theme accent.
    ///   - haptic: Fired when a tap or a VoiceOver swipe changes the day. Defaults to `.selection`.
    ///   - accessibilityLabel: What VoiceOver reads for the strip. Defaults to "Date".
    public init(
        selection: Binding<Date>,
        in bounds: ClosedRange<Date>,
        accent: Color? = nil,
        haptic: DSHapticStyle = .selection,
        accessibilityLabel: String = "Date"
    ) {
        self._selection = selection
        self.bounds = bounds
        self.accent = accent
        self.haptic = haptic
        self.label = accessibilityLabel
    }

    public var body: some View {
        let days = DSDayStripLogic.days(in: bounds, calendar: calendar)
        let selectedDay = calendar.startOfDay(for: selection)
        let today = calendar.startOfDay(for: .now)

        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        dayCell(day, isSelected: day == selectedDay, isToday: day == today)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .onAppear {
                proxy.scrollTo(DSDayStripLogic.clamp(selection, to: bounds, calendar: calendar), anchor: .center)
            }
            .onChange(of: selectedDay) { _, day in
                guard DSDayStripLogic.contains(day, in: bounds, calendar: calendar) else { return }
                withAnimation(reduceMotion ? nil : DSAnimation.springSmooth) {
                    proxy.scrollTo(day, anchor: .center)
                }
            }
        }
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(DSDayStripLogic.accessibilityValue(for: selection, today: today, calendar: calendar, locale: locale))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(by: 1)
            case .decrement: step(by: -1)
            @unknown default: break
            }
        }
    }

    private var selectionAnimation: Animation {
        reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy
    }

    // MARK: Cells

    private func dayCell(_ day: Date, isSelected: Bool, isToday: Bool) -> some View {
        Button {
            select(day)
        } label: {
            VStack(spacing: DSSpacing.xxs) {
                Text(DSDayStripLogic.weekdayLabel(for: day, calendar: calendar, locale: locale))
                    .ds(.caption2, color: isSelected ? selectedForeground : theme.palette.textSecondary)
                    .lineLimit(1)
                Text(DSDayStripLogic.dayNumber(for: day, calendar: calendar), format: .number)
                    .ds(.numeric, color: numberColor(isSelected: isSelected, isToday: isToday))
                    .monospacedDigit()
                Circle()
                    .fill(isSelected ? selectedForeground : (accent ?? theme.accent))
                    .frame(width: Metrics.dotSize, height: Metrics.dotSize)
                    .opacity(isToday ? 1 : 0)
            }
            .padding(.vertical, DSSpacing.xs)
            .padding(.horizontal, DSSpacing.xxs)
            .frame(minWidth: Metrics.cellWidth, minHeight: Metrics.cellHeight)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(accent ?? theme.accent)
                        .matchedGeometryEffect(id: "selection", in: namespace)
                        .dsShadow(.sm)
                }
            }
            .padding(.horizontal, DSSpacing.xxxs)
            .contentShape(Rectangle())
            .animation(selectionAnimation, value: isSelected)
        }
        .buttonStyle(DSDayStripCellStyle())
    }

    private var selectedForeground: Color {
        // A custom accent falls back to the palette's text-on-primary, as DSChip does.
        accent == nil ? theme.onAccent : theme.palette.textOnPrimary
    }

    private func numberColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected { return selectedForeground }
        return isToday ? theme.ink : theme.palette.textPrimary
    }

    // MARK: Behavior

    private func select(_ day: Date) {
        guard day != calendar.startOfDay(for: selection) else { return }
        DSHapticEngine.shared.fire(haptic)
        withAnimation(selectionAnimation) { selection = day }
    }

    private func step(by offset: Int) {
        guard isEnabled,
              let day = DSDayStripLogic.step(from: selection, by: offset, in: bounds, calendar: calendar) else { return }
        select(day)
    }
}

// MARK: - Button Style

/// Press feedback as a `ButtonStyle`, so a touch that turns into a scroll
/// releases the cell instead of leaving it scaled down (same as `DSChip`).
private struct DSDayStripCellStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DSPress.scale : 1)
            .animation(DSPress.animation, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSDayStripPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var booking = Date.now
    @State private var habit = Date.now

    private var today: Date { Calendar.current.startOfDay(for: .now) }
    private func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: today) ?? today
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Pick a day").ds(.title3)
                        DSDayStrip(selection: $booking, in: today...day(30), accessibilityLabel: "Booking day")
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Last two weeks, custom accent").ds(.overline, color: DSColors.textSecondary)
                    DSDayStrip(selection: $habit, in: day(-13)...today, accent: DSColors.secondary)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Disabled").ds(.overline, color: DSColors.textSecondary)
                    DSDayStrip(selection: $habit, in: day(-3)...day(10))
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

#Preview("Day Strip — Light") {
    DSDayStripPreviewHost().preferredColorScheme(.light)
}

#Preview("Day Strip — Dark") {
    DSDayStripPreviewHost().preferredColorScheme(.dark)
}
#endif
