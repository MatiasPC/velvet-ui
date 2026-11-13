# DSDayStrip

A horizontal strip of days to pick one from: the booking screen's "which day?", a habit tracker's last two weeks, a fitness log's day switcher, a delivery slot. Each day is a short weekday over its number. Tap one and an accent capsule springs over to it while the strip glides to keep it centred. Today carries a small dot.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSDayStrip.swift`](../../Sources/VelvetUI/Components/DSDayStrip.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(style: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

```swift
import VelvetUI

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
```

Build the bounds with `Calendar.date(byAdding: .day, …)`, not `addingTimeInterval(86_400)`: days around a daylight-saving change aren't 24 hours long.

`DatePicker` is still the right control for an arbitrary date (a birthday, a deadline months away). Use the strip when the useful days are nearby and should be one tap away.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `selection` | `Binding<Date>` | required | The selected day. A tap writes the **start** of the tapped day, in the environment's calendar. |
| `bounds` (`in:`) | `ClosedRange<Date>` | required | The first and last day to show. Times are ignored: both end days are included. At most 3,660 days (about ten years) are listed. |
| `accent` | `Color?` | `nil` | The selection capsule's fill. `nil` follows the theme accent (text in `theme.onAccent`). |
| `haptic` | `DSHapticStyle` | `.selection` | Fired when a tap or a VoiceOver swipe changes the day. Tapping the selected day does nothing. |
| `accessibilityLabel` | `String` | `"Date"` | What VoiceOver reads for the strip. Name what the day is for: "Booking day", "Delivery day". |

The strip compares days, not instants: a binding at 15:30 selects that day's cell. A selection outside the bounds highlights no cell until a day is picked (the binding isn't rewritten).

## Variants

```swift
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
```

The strip shows weekdays and day numbers only. When the month matters (a range that crosses one, a booking far out), show the full date above it, as here.

## Behavior

- Days scroll horizontally in a lazy stack and snap to whole cells. On appear the selected day is scrolled to the centre (or as near as the ends allow), and every change of selection, by tap or from your code, glides it there with `DSAnimation.springSmooth`.
- The selected day sits in an accent capsule with a small shadow; moving the selection slides the capsule between cells with `DSAnimation.springSnappy`.
- Today has a dot under its number and its number in `theme.ink`. On the selected day the dot turns `theme.onAccent`.
- A tap dips the cell (`DSPress.scale`) and fires `haptic`. A touch that turns into a scroll releases the cell without selecting it.
- Weekday names and the spoken date follow the environment's `locale` and `calendar`, so `.environment(\.locale, …)` and `.environment(\.calendar, …)` work as for any SwiftUI view.
- Cells are at least 48 × 64 pt and grow with Dynamic Type. The strip draws no surface: put it on a `DSCard` or the backdrop. No borders.
- **Reduce Motion:** the capsule fades across instead of sliding, and the strip jumps to the selection instead of gliding.
- **Disabled** (`.disabled(true)`): dimmed to 50%; taps and VoiceOver adjustments do nothing.

## Accessibility

- VoiceOver reads the strip as one adjustable control: the `accessibilityLabel`, then the selected day ("Friday, November 13, Today"). Swipe up or down for the next or previous day; at the first or last day nothing moves.
- Text uses `.ds(_:)` styles, so weekdays and numbers scale with Dynamic Type.

## See also

- [DSSegmentedControl](DSSegmentedControl.md): pick one of a few fixed options.
- [DSCard](DSCard.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
