# DSStepper

A minus / number / plus stepper on a glass track. The number rolls, and hitting a limit wiggles the track with a warning haptic so you feel the refusal.

![DSStepper](../media/DSStepper.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSStepper.swift`](../../Sources/VelvetUI/Components/DSStepper.swift)

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

struct StepperDemo: View {
    @State private var guests = 2

    var body: some View {
        DSScreen(backdrop: true) {
            HStack {
                Text("Guests").ds(.title3)
                Spacer()
                DSStepper(value: $guests, in: 1...8)
                    .accessibilityLabel("Guests")
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `value` | `Binding<Int>` | required | The current number. |
| `range` | `ClosedRange<Int>` | `0...99` | Allowed values. Declared as `in range:` at the call site. |
| `step` | `Int` | `1` | Amount added or removed per tap. A non-positive step is treated as 1. |
| `accent` | `Color?` | `nil` | Tint of the − and + glyphs. Defaults to theme ink (the number itself always uses the primary text color). |

Stepping clamps into `range`, so a `step` that doesn't divide the range evenly lands on the bound instead of overshooting.

## Variants

```swift
DSStepper(value: $quantity, in: 0...10, step: 2)
```
At a bound the buttons dim but stay tappable on purpose, so the refusal can be felt.

## Behavior

- The number rolls with a numeric text transition on each change.
- Each successful step fires a selection haptic.
- At a bound the value doesn't move; the track does a short jiggle with a warning haptic.
- Reduce Motion: the jiggle is skipped (the warning haptic still fires).
- Reduce Transparency: the glass track becomes a solid elevated background.

## Accessibility

- One adjustable element: "Stepper", value is the number. Swipe up or down to step.
- Override the label with `.accessibilityLabel("Guests")`, as in the snippet above.
- Dynamic Type: the control has a fixed 44pt height and the glyphs are fixed size. The number uses `.ds(.numeric)` and scales, but its width is reserved from the range, so keep ranges short.

## See also

- [DSToggle](DSToggle.md)
- [DSRating](DSRating.md)
- [DSSegmentedControl](DSSegmentedControl.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
