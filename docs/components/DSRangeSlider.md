# DSRangeSlider

Two knobs on one slim track, for picking a span: a price filter, an age range, opening hours. The accent fill runs between the knobs, the knobs never cross, and `minimumDistance` keeps a gap between them.

<!-- GIF pending: ![DSRangeSlider](../media/DSRangeSlider.gif) -->

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSRangeSlider.swift`](../../Sources/VelvetUI/Components/DSRangeSlider.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(style: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup. Copying sources instead? `DSRangeSlider` shares its value mapping with [DSSlider](DSSlider.md), so `velvet.swift add DSRangeSlider` copies both.

## Usage

```swift
import VelvetUI

struct PriceFilterDemo: View {
    @State private var price: ClosedRange<Double> = 100...400

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                HStack {
                    Text("Price").ds(.title3)
                    Spacer()
                    Text("$\(Int(price.lowerBound)) – $\(Int(price.upperBound))").ds(.numeric)
                }
                DSRangeSlider(range: $price, in: 0...500, step: 25, minimumDistance: 50)
                    .accessibilityLabel("Price")
            }
            .dsScreenPadding()
        }
    }
}
```

The slider draws no values of its own. Show a read-out beside it, as above.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `range` | `Binding<ClosedRange<Double>>` | required | The selected span. It is kept inside `in`, on the notches and at least `minimumDistance` wide; a range that breaks those rules is corrected and written back. |
| `bounds` | `ClosedRange<Double>` | `0...1` | Allowed values. Declared as `in bounds:` at the call site. Both ends must be finite. |
| `step` | `Double?` | `nil` | Snap increment, counted from the lower bound. `nil`, zero or negative means continuous. The upper bound is always reachable, as in [DSSlider](DSSlider.md). |
| `minimumDistance` | `Double` | `0` | The smallest allowed `upperBound − lowerBound`. `0` lets the knobs meet. Negative or non-finite means `0`; it is capped at the width of `bounds`. |
| `accent` | `Color?` | `nil` | Fill between the knobs. Defaults to the theme accent. |

Correcting an invalid range: both ends are clamped into `bounds` and snapped to the nearest notch. If the range is then narrower than `minimumDistance`, the upper end moves up to the first notch that is far enough; when there is no room above, the range is pinned to the top of the track (`480...500` with a gap of 50 becomes `450...500`).

## Variants

```swift
struct RangeSliderVariantsDemo: View {
    @State private var hours: ClosedRange<Double> = 9...17
    @State private var level: ClosedRange<Double> = 0.2...0.7

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            // Whole hours, at least two of them.
            DSRangeSlider(range: $hours, in: 0...24, step: 1, minimumDistance: 2)
            // Continuous 0...1, your own accent; the knobs may meet.
            DSRangeSlider(range: $level, accent: DSColors.secondary)
            // Dimmed and inert.
            DSRangeSlider(range: $level).disabled(true)
        }
    }
}
```

## Behavior

- Touching down grabs the nearer knob, which keeps following the finger until you lift it, so the knobs never swap mid-drag. A tap on the track moves the nearer knob there.
- When the knobs sit on top of each other, the side you drag toward decides which one moves. At the top of the track it is always the lower knob, since the upper one can't go further.
- A moving knob stops at the end of the track and at `minimumDistance` from the other knob. The other knob never moves.
- Haptics, as in [DSSlider](DSSlider.md): a stepped slider ticks (`.selection`) on each new notch; every slider fires one firm `.rigid` detent when the moving knob arrives at its limit, whether that is the end of the track or the gap. Grabbing a knob is silent.
- While grabbed, the knob lifts to 112% and a soft accent halo appears; it is drawn above the other knob.
- Reduce Motion: the knob doesn't lift and follows the finger with no spring lag; the halo stays, since it only changes opacity.
- Disabled (`.disabled(true)`): dimmed to 50% and ignores touches and VoiceOver adjustments.
- Reduce Transparency: nothing changes. The track is a flat fill, and the knobs are opaque.
- On a `dsBackdrop()` screen the track is the frosted wash; on a plain screen it is the neutral grey DSSlider uses.

## Accessibility

- Two adjustable elements, "Minimum" and "Maximum", inside a container. Put your own label on the container with `.accessibilityLabel("Price")`; VoiceOver reads it as you enter the slider.
- Swipe up or down on a knob to move it one notch (a tenth of the range for a continuous slider). It stops where a drag would, and each move fires a selection tick.
- Values read like DSSlider's: "25 percent" for the default continuous `0...1`, otherwise the number itself ("100", "-2.5") with as many decimals as `step` needs.
- Dynamic Type: nothing in the control scales; the 44 pt hit area is fixed.

## See also

- [DSSlider](DSSlider.md)
- [DSStepper](DSStepper.md)
- [DSChip](DSChip.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
