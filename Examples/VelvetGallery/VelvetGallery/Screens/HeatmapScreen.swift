import SwiftUI
import VelvetUI

/// Repeatable fake histories, keyed by the start of each day, ending today.
private enum HeatmapData {
    static var today: Date { Calendar.current.startOfDay(for: .now) }

    static func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: today) ?? today
    }

    /// Whole days from today to `date` (negative in the past).
    static func offset(of date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: today, to: Calendar.current.startOfDay(for: date)).day ?? 0
    }

    /// Workout minutes: most days, a rest day now and then, a quiet fortnight.
    static let workouts: [Date: Double] = history(days: 371) { offset in
        if (40...53).contains(offset) { return 0 }
        let pattern: [Double] = [45, 30, 0, 60, 20, 75, 0, 35, 50, 15]
        return pattern[(offset * 7 + offset / 9) % pattern.count]
    }

    /// Pages read: short streaks with gaps.
    static let pages: [Date: Double] = history(days: 70) { offset in
        offset % 6 < 4 ? Double(8 + (offset * 13) % 40) : 0
    }

    private static func history(days: Int, amount: (Int) -> Double) -> [Date: Double] {
        var values: [Date: Double] = [:]
        for offset in 0..<days {
            let value = amount(offset)
            if value > 0 { values[day(-offset)] = value }
        }
        return values
    }
}

struct HeatmapScreen: View {
    @State private var selected: Date?
    @State private var year: Date?

    var body: some View {
        GalleryScreen(title: "Heatmap", caption: "A cell per day, busier days in a deeper accent. Tap a day to lift it") {
            LabeledExample("Workouts, the last 16 weeks") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        HStack {
                            Text("Workouts").ds(.title3)
                            Spacer()
                            Text(readout(selected, in: HeatmapData.workouts, unit: "min"))
                                .ds(.footnote, color: DSColors.textSecondary)
                        }
                        DSHeatmap(HeatmapData.workouts, selection: $selected, accessibilityLabel: "Workouts")
                    }
                }
            }

            LabeledExample("Reading, eight weeks, static, custom accent") {
                DSHeatmap(HeatmapData.pages, weeks: 8, accent: DSColors.success, accessibilityLabel: "Pages read")
            }

            LabeledExample("A whole year (scrolls sideways)") {
                ScrollView(.horizontal) {
                    DSHeatmap(HeatmapData.workouts, weeks: 53, selection: $year, accessibilityLabel: "Workouts this year")
                        .frame(width: 53 * DSSpacing.md)
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(.trailing)
            }

            LabeledExample("Disabled") {
                DSHeatmap(HeatmapData.pages, weeks: 10, selection: .constant(nil))
                    .disabled(true)
            }

            Text("With VoiceOver on, the heatmap is one control: it reads the weeks and active days, then swipe up or down to walk the days.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }

    private func readout(_ day: Date?, in values: [Date: Double], unit: String) -> String {
        guard let day else { return "Tap a day" }
        let amount = Int(values[day] ?? 0)
        return "\(day.formatted(.dateTime.month(.abbreviated).day())) · \(amount) \(unit)"
    }
}

/// Recording stage: twelve weeks of workouts ending today. The heatmap is the
/// accessibility element "Workouts"; the read-out under it is "Selected day",
/// whose value is the selected day's offset from today ("-9") or "none", which
/// the UI test reads back.
struct HeatmapStage: View {
    let autoplay: Bool
    @State private var day: Date?

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                // Not "Workouts": the UI test finds the heatmap by that label.
                Text("Your training").ds(.title3)
                DSHeatmap(HeatmapData.workouts, weeks: 12, selection: $day, accessibilityLabel: "Workouts")
                Text(day.map { $0.formatted(.dateTime.weekday(.wide).month().day()) } ?? "Tap a day")
                    .ds(.footnote, color: DSColors.textSecondary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Selected day")
                    .accessibilityValue(day.map { "\(HeatmapData.offset(of: $0))" } ?? "none")
            }
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for offset in [-2, -9, -30, -61, -5, 0] {
                    await stagePause(1.0)
                    if Task.isCancelled { return }
                    withAnimation(DSAnimation.springSnappy) { day = HeatmapData.day(offset) }
                }
                await stagePause(1.0)
                withAnimation(DSAnimation.springSnappy) { day = nil }
            }
        }
    }
}
