# DSSlider

A continuous value slider on a slim track. An accent fill trails a white knob that lifts and glows under your finger; give it a `step` and it snaps to notches with a tick for each.

<!-- GIF pending: ![DSSlider](../media/DSSlider.gif) -->

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSSlider.swift`](../../Sources/VelvetUI/Components/DSSlider.swift)

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

struct SliderDemo: View {
    @State private var volume = 0.6

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                HStack {
                    Text("Volume").ds(.title3)
                    Spacer()
                    Text("\(Int(volume * 100))%").ds(.numeric)
                }
                DSSlider(value: $volume)
                    .accessibilityLabel("Volume")
            }
            .dsScreenPadding()
        }
    }
}
```

The slider draws no value of its own. Show a read-out beside it, as above, when people need to see the number.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `value` | `Binding<Double>` | required | The current value. It is kept inside `in`: an out-of-range value is clamped, and the clamped value is written back. |
| `bounds` | `ClosedRange<Double>` | `0...1` | Allowed values. Declared as `in bounds:` at the call site. Both ends must be finite. |
| `step` | `Double?` | `nil` | Snap increment, counted from the lower bound. `nil`, zero or negative means continuous. |
| `accent` | `Color?` | `nil` | Fill of the trail behind the knob. Defaults to the theme accent. |
| `haptics` | `Bool` | `true` | Set `false` to silence the end detents and the notch ticks. |

Drag the knob, or tap anywhere on the track to jump there. The value is always clamped to `bounds`; with a `step` it is also snapped. The upper bound is always reachable: `0...10` by `3` has notches at 0, 3, 6, 9 and 10, the same way [DSStepper](DSStepper.md) lands on a bound it can't divide into.

## Variants

```swift
struct SliderVariantsDemo: View {
    @State private var price = 150.0
    @State private var temperature = -2.0
    @State private var opacity = 0.8

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            // Notched: a selection tick on every 25.
            DSSlider(value: $price, in: 0...500, step: 25)
            // A range that crosses zero, in half-degree notches.
            DSSlider(value: $temperature, in: -10...10, step: 0.5)
            // Your own accent, and no haptics.
            DSSlider(value: $opacity, accent: DSColors.secondary, haptics: false)
            // Dimmed and inert.
            DSSlider(value: $opacity).disabled(true)
        }
    }
}
```

## Behavior

- The knob follows your finger on a light spring. Touching down on the track moves it to that spot.
- A continuous slider is silent while you drag and fires one rigid detent when you arrive at either end.
- A stepped slider also fires a selection tick each time the value lands on a new notch. Touching down on the notch it already rests on is silent.
- While grabbed, the knob lifts to 112% and a soft accent halo appears.
- Reduce Motion: the knob doesn't lift and follows your finger with no spring lag; the halo stays, since it is only a change of opacity.
- Disabled (`.disabled(true)`): dimmed to 50% and ignores touches.
- Reduce Transparency: nothing changes. The track is a flat fill, and the knob is opaque.
- On a `dsBackdrop()` screen the track is the frosted wash; on a plain screen it is the neutral grey [DSToggle](DSToggle.md) uses for its off track, so it never disappears into a white background.

## Accessibility

- One adjustable element: "Slider". Swipe up or down to change it: one notch for a stepped slider, a tenth of the range for a continuous one. Each move fires a selection tick.
- The value reads as "60 percent" for the default `0...1` continuous slider, and as the number itself otherwise ("150", "-2.5"), with as many decimals as `step` needs (two for a continuous slider).
- Override the label with `.accessibilityLabel("Volume")`, as in the snippet above. To change how the value is spoken (units, say), use `.accessibilityValue("150 dollars")`.
- A disabled slider ignores VoiceOver adjustments too.
- Dynamic Type: nothing in the control scales; the 44pt hit area is fixed.

## See also

- [DSStepper](DSStepper.md)
- [DSRating](DSRating.md)
- [DSToggle](DSToggle.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
