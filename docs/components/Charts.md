# Charts

Two light charts with no Swift Charts dependency: `DSSparkline`, a trend line that draws itself and morphs to new data, and `DSBarChart`, bars that grow from the baseline and can be scrubbed to select.

![Charts](../media/Charts.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSCharts.swift`](../../Sources/VelvetUI/Components/DSCharts.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(gradient: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

```swift
import VelvetUI

struct ChartsDemo: View {
    @State private var revenue: [Double] = [12, 18, 14, 22, 19, 27, 24, 31, 28, 36]
    @State private var week: [Double] = [12, 18, 9, 22, 15, 6, 11]
    @State private var selected: Int?

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Revenue").ds(.callout)
                        DSSparkline(revenue, accessibilityLabel: "Revenue trend")
                            .frame(height: 72)
                    }
                }

                DSCard {
                    DSBarChart(
                        week,
                        labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                        selection: $selected,
                        accessibilityLabel: "Orders this week"
                    )
                    .frame(height: 180)
                }

                DSButton("Shuffle data", isFullWidth: true) {
                    revenue = revenue.map { _ in Double.random(in: 10...40) }
                    week = week.map { _ in Double.random(in: 2...30) }
                }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

### DSSparkline

| Parameter | Type | Default | Description |
|---|---|---|---|
| `values` | `[Double]` | required | The samples, oldest first. Unlabeled first argument. Non-finite values count as 0. |
| `color` | `Color?` | `nil` | Line, fill and dot color. Defaults to the theme accent. |
| `lineWidth` | `CGFloat` | `2` | Stroke width. |
| `showsFill` | `Bool` | `true` | Fade a gradient of the line color under the line. |
| `showsLastPoint` | `Bool` | `true` | Show the breathing dot on the latest value. |
| `accessibilityLabel` | `String` | `"Trend"` | What the chart shows, spoken before the summary. |

### DSBarChart

| Parameter | Type | Default | Description |
|---|---|---|---|
| `values` | `[Double]` | required | One value per bar. Unlabeled first argument. Negative values clamp to 0. |
| `labels` | `[String]?` | `nil` | Text under each bar, matched by index. |
| `selection` | `Binding<Int?>?` | `nil` | Index of the selected bar. Pass a binding to make the chart interactive. |
| `color` | `Color?` | `nil` | Bar color. Defaults to the theme accent. |
| `accessibilityLabel` | `String` | `"Chart"` | What the chart shows. |

Both charts fill the space they are given. Set a height, for example `.frame(height: 72)`.

## Variants

```swift
DSSparkline(revenue, color: DSColors.success, showsFill: false, showsLastPoint: false)
    .frame(height: 40)

DSBarChart(week, color: DSColors.info)
    .frame(height: 96)
```
A sparkline without fill or dot is a plain line, good for table rows. A bar chart without a `selection` binding is static: no gesture, no value label.

## Behavior

- **Scale.** The sparkline maps the lowest value to the bottom of its frame and the highest to the top; flat data is a centred line. The curve is monotone, so it never overshoots the data. The bar chart scales to the tallest bar and starts at zero.
- **Draw-on.** On appear the sparkline line draws itself in one second, the fill fades in behind it, and the dot appears last and breathes.
- **Morph.** When `values` changes and keeps its length, the sparkline line morphs to the new shape and the bars spring to their new heights. A different length redraws the sparkline.
- **Bars.** Bars have rounded tops and grow from the baseline with staggered springs. Negative values clamp to 0.
- **Selection.** Tap or drag across the bars to scrub: each new bar fires a selection haptic and a value label rises above it. Lifting your finger keeps the selection, and tapping the selected bar again clears it. While a bar is selected the others dim.
- Reduce Motion: no draw-on, morph or growth. Data appears at rest, and sparkline changes crossfade. The dot does not breathe.

## Accessibility

- The sparkline is one element: your `accessibilityLabel`, with a spoken summary such as "12 values, from 3 to 18, latest 15".
- Both charts provide an audio graph, so VoiceOver users can play the chart as sound ("Audio Graphs" in the rotor).
- Each bar is its own element ("Mon, 12"). With a `selection` binding each bar is a button that selects it, and the selected bar reports the selected trait.
- Value labels use `.ds(_:)` text, which scales with Dynamic Type.

## See also

- [Progress](Progress.md) for determinate fractions
- [Motion](Motion.md) for `dsBreathe`
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
