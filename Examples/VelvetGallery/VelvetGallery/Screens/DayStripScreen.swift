import SwiftUI
import VelvetUI

/// Days relative to today, for the examples below.
private enum Days {
    static var today: Date { Calendar.current.startOfDay(for: .now) }

    static func from(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: today) ?? today
    }

    /// Whole days from today to `date` (negative in the past).
    static func offset(of date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: today, to: Calendar.current.startOfDay(for: date)).day ?? 0
    }

    static func describe(_ date: Date) -> String {
        switch offset(of: date) {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        case let n where n > 0: return "In \(n) days"
        case let n: return "\(-n) days ago"
        }
    }
}

struct DayStripScreen: View {
    @State private var booking = Date.now
    @State private var habit = Date.now
    @State private var delivery = Days.from(2)
    @State private var locked = Date.now

    var body: some View {
        GalleryScreen(title: "Day Strip", caption: "Tap a day: the capsule springs over and the strip recentres. Today has a dot") {
            LabeledExample("Booking, the next 30 days") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        HStack {
                            Text("Pick a day").ds(.title3)
                            Spacer()
                            Text(Days.describe(booking)).ds(.footnote, color: DSColors.textSecondary)
                        }
                        DSDayStrip(selection: $booking, in: Days.today...Days.from(30), accessibilityLabel: "Booking day")
                    }
                }
            }

            LabeledExample("Habit history, the last two weeks, custom accent") {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text(habit, format: .dateTime.weekday(.wide).month().day()).ds(.title3)
                    DSDayStrip(selection: $habit, in: Days.from(-13)...Days.today, accent: DSColors.success, haptic: .soft)
                }
            }

            LabeledExample("Delivery, a short window on a card") {
                DSCard {
                    DSDayStrip(selection: $delivery, in: Days.from(1)...Days.from(5), accessibilityLabel: "Delivery day")
                }
            }

            LabeledExample("Disabled") {
                DSDayStrip(selection: $locked, in: Days.from(-3)...Days.from(10))
                    .disabled(true)
            }

            Text("With VoiceOver on, the strip is one control: swipe up or down to move a day, and it reads the date and \"Today\".")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Recording stage: a booking strip from three days ago to four weeks ahead,
/// starting on today. The strip is the accessibility element "Booking day"; the
/// read-out under it is "Days from today", whose value is the selected day's
/// offset ("0", "3", "-2"), which the UI test reads back.
struct DayStripStage: View {
    let autoplay: Bool
    @State private var day = Days.today

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Pick a day").ds(.title3)
                DSDayStrip(selection: $day, in: Days.from(-3)...Days.from(27), accessibilityLabel: "Booking day")
                Text(Days.describe(day))
                    .ds(.footnote, color: DSColors.textSecondary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Days from today")
                    .accessibilityValue("\(Days.offset(of: day))")
            }
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for offset in [1, 2, 4, 3, 0] {
                    await stagePause(1.0)
                    if Task.isCancelled { return }
                    withAnimation(DSAnimation.springSnappy) { day = Days.from(offset) }
                }
            }
        }
    }
}
