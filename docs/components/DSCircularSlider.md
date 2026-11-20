# DSCircularSlider

A value on a dial: a thermostat, a sleep timer, a volume knob, a daily goal. The 270° arc is open at the bottom, the accent fill trails a white knob around it, and your own content (usually the read-out) sits in the middle.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSCircularSlider.swift`](../../Sources/VelvetUI/Components/DSCircularSlider.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(style: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup. Copying sources instead? `DSCircularSlider` shares its value mapping with [DSSlider](DSSlider.md), so `velvet.swift add DSCircularSlider` copies both.

## Usage

```swift
import VelvetUI

struct ThermostatDemo: View {
    @State private var temperature: Double = 21

    var body: some View {
        DSScreen(backdrop: true) {
            DSCard {
                DSCircularSlider(value: $temperature, in: 10...30, step: 0.5,
                                 accessibilityLabel: "Temperature") {
                    VStack(spacing: DSSpacing.xxs) {
                        Text(temperature.formatted(.number.precision(.fractionLength(1))) + "°")
                            .ds(.displayMedium)
                        Text("Heating to").ds(.footnote)
                    }
                }
                .frame(maxWidth: 280)
                .frame(maxWidth: .infinity)
            }
            .dsScreenPadding()
        }
    }
}
```

The dial is square and fills the width it is offered, so cap it with a `frame` as above.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `value` | `Binding<Double>` | required | The value. It is kept inside `in`: an out-of-range value is clamped and written back. |
| `bounds` | `ClosedRange<Double>` | `0...1` | Allowed values. Declared as `in bounds:` at the call site. Both ends must be finite. |
| `step` | `Double?` | `nil` | Snap increment, counted from the lower bound. `nil`, zero or negative means continuous. The upper bound is always reachable, as in [DSSlider](DSSlider.md). |
| `accent` | `Color?` | `nil` | Colour of the filled arc. Defaults to the theme accent. |
| `accessibilityLabel` | `String` | `"Dial"` | What VoiceOver calls the dial ("Temperature", "Volume"). |
| `content` | `() -> some View` | none | Drawn in the middle, inside the ring. Leave it out for a bare dial. VoiceOver doesn't read it; it reads the value. |

## Variants

```swift
struct CircularSliderVariantsDemo: View {
    @State private var volume: Double = 0.4
    @State private var minutes: Double = 25

    var body: some View {
        HStack(spacing: DSSpacing.xl) {
            // A bare 0...1 dial: VoiceOver reads a percentage.
            DSCircularSlider(value: $volume, accessibilityLabel: "Volume")
                .frame(width: 120, height: 120)
            // Five-minute notches, your own accent.
            DSCircularSlider(value: $minutes, in: 5...60, step: 5,
                             accent: DSColors.secondary, accessibilityLabel: "Timer") {
                Text("\(Int(minutes)) min").ds(.numeric)
            }
            .frame(width: 120, height: 120)
            // Dimmed and inert.
            DSCircularSlider(value: $volume).disabled(true)
                .frame(width: 120, height: 120)
        }
    }
}
```

## Behavior

- The arc runs clockwise from the lower left, over the top, to the lower right. The minimum is at the lower left, the maximum at the lower right, and the middle of the range at 12 o'clock.
- Touch the ring anywhere and the knob springs to that angle, then follows the finger around. A drag that *starts* in the middle half of the dial (on the content) never moves the value; once a drag owns the knob, it ignores the finger only very close to the centre.
- Drag into the open gap at the bottom and the knob waits at the end it came from. It never jumps across the gap to the other end: to get from the maximum back to the minimum you sweep back over the top, as on a real dial.
- Haptics, as in [DSSlider](DSSlider.md): a stepped dial ticks (`.selection`) on each new notch; every dial fires one firm `.rigid` detent when the knob arrives at either end. Grabbing the knob where it already rests is silent.
- While grabbed, the knob lifts to 112% and a soft accent halo appears.
- Reduce Motion: the knob doesn't lift and follows the finger with no spring lag; the halo stays, since it only changes opacity.
- Disabled (`.disabled(true)`): dimmed to 50% and ignores touches and VoiceOver adjustments.
- Reduce Transparency: nothing changes. The track is a flat fill, and the knob is opaque.
- On a `dsBackdrop()` screen the track is the frosted wash; on a plain screen it is the neutral grey DSSlider uses.
- Right-to-left layouts: the dial still turns clockwise, like every physical dial; only the content follows the layout direction.

## Accessibility

- One adjustable element named by `accessibilityLabel`. Swipe up or down to move one notch (a tenth of the range for a continuous dial); each move fires a selection tick.
- Values read like DSSlider's: "40 percent" for the default continuous `0...1`, otherwise the number itself ("21", "13.5") with as many decimals as `step` needs. Put the unit in your label if it matters ("Temperature, degrees").
- The content in the middle is visual only. If it holds a button, give the button its own place on screen as well.
- Dynamic Type: the content scales with its own `.ds(_:)` styles; the ring scales with the dial's frame.

## See also

- [DSSlider](DSSlider.md)
- [DSRangeSlider](DSRangeSlider.md)
- [DSActivityRings](DSActivityRings.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
