# DSHeatmap

A calendar heatmap: a column per week, a rounded cell per day, busier days in a deeper accent. It's the "how consistent have I been?" view for a habit tracker, a workout log, a reading streak, a spending history or a commit graph. Month names sit over the week where each month begins. With a `selection` binding, tap a day to lift its cell and dim the rest.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSHeatmap.swift`](../../Sources/VelvetUI/Components/DSHeatmap.swift)

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
```

The heatmap draws no read-out of its own, like `DSSlider`. Show the selected day's numbers yourself, as here. The binding holds the **start** of the tapped day in the environment's calendar, so key your own dictionary the same way to look it up.

Keys of `values` can be any time in the day: entries on the same day are added up (so you can pass one entry per workout).

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `values` | `[Date: Double]` | required | An amount per day: workouts, minutes, pages, money. Entries on the same day are summed; negative, NaN and infinite amounts are ignored. |
| `weeks` | `Int` | `16` | How many weeks to show, oldest on the leading side. Clamped to 1...53. |
| `end` (`through:`) | `Date` | `.now` | The last day shown. Its week is the last column; later days in that week are left empty. |
| `selection` | `Binding<Date?>?` | `nil` | The selected day, or `nil`. Omit it for a static heatmap: no taps, not adjustable. |
| `accent` | `Color?` | `nil` | The color the levels are tinted from. `nil` follows the theme accent. |
| `accessibilityLabel` | `String` | `"Activity"` | What VoiceOver reads for the heatmap. Name what it counts: "Workouts", "Pages read". |

## Variants

```swift
struct ReadingStreakDemo: View {
    let pages: [Date: Double]
    @DSThemed private var theme

    var body: some View {
        DSHeatmap(pages, weeks: 8, accent: theme.palette.success, accessibilityLabel: "Pages read")
    }
}
```

A full year is 53 narrow columns: give it a fixed width inside a horizontal `ScrollView` (with `.defaultScrollAnchor(.trailing)` so it opens on this week) rather than squeezing it into a phone's width.

## Behavior

- **Levels.** A day with nothing is a flat wash (`theme.washSurface` on a backdrop, the palette's neutral line color off one). Any activity is one of four tints of the accent (30%, 55%, 80%, 100%), by its share of the busiest day on screen. The scale is relative: the deepest tint is always the best day in view.
- **Layout.** The heatmap fills the width it's offered. Columns share it equally, each cell is square, and the height follows (seven cells and their gaps, plus one caption line for the month names). Gaps are `DSSpacing.xxs`, corners `DSRadius.xs`.
- **Weeks** follow the environment's `calendar` (`firstWeekday`, time zone) and month names its `locale`. Days are found with `Calendar.date(byAdding: .day, …)`, so a daylight-saving change never shifts a cell off its day.
- **Selection.** A tap anywhere in the grid picks the cell under it (a gap belongs to the cell before it); empty cells after `end` do nothing. The cell lifts (scale 1.35 and a small shadow) and the other days dim, on `DSAnimation.springSnappy`, with a `.selection` tick. Tapping the selected day clears the selection.
- **Entrance.** On appear the cells pop in as a diagonal wave from the oldest week's first day, each on `springSnappy`; the whole wave starts within 0.4 s, however many weeks are drawn.
- **Reduce Motion:** no wave (the cells are simply there), and the selection fades instead of springing.
- **Disabled** (`.disabled(true)`): dimmed to 50%; taps and VoiceOver adjustments do nothing.
- No borders and no surface of its own: put it on a `DSCard` or the backdrop.

## Accessibility

- VoiceOver reads the heatmap as one element: the `accessibilityLabel`, then a summary ("16 weeks, 37 active days") or, with a day selected, that day and its amount ("Friday, November 13, 45").
- With a `selection` binding it's adjustable: swipe up or down for the next or previous day (the first swipe starts on the latest day), stopping at the ends.
- Cells are small (a 16-week heatmap on a phone has ~16 pt cells), so the tap target is the whole grid, and VoiceOver users step through days instead of hunting for a cell.

## See also

- [Charts](Charts.md): `DSBarChart` for a handful of values with labels, `DSSparkline` for a trend.
- [DSDayStrip](DSDayStrip.md): pick a day from the nearby days.
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
