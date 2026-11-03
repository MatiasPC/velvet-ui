# DSRadioGroup

A single-select list for any `Hashable` value: the indicator pops to the accent while its dot grows, and a frosted highlight slides to the chosen row.

<!-- GIF pending: ![DSRadioGroup](../media/DSRadioGroup.gif) -->

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSRadioGroup.swift`](../../Sources/VelvetUI/Components/DSRadioGroup.swift)

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

struct RadioGroupDemo: View {
    enum Plan: Hashable { case free, pro, team }

    @State private var plan = Plan.pro
    @State private var shipping = "Standard"

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                DSCard {
                    DSRadioGroup(selection: $plan, options: [
                        DSRadioOption("Free", value: Plan.free, subtitle: "For trying things out"),
                        DSRadioOption("Pro", value: Plan.pro, subtitle: "Everything, for one person"),
                        DSRadioOption("Team", value: Plan.team, subtitle: "Shared workspaces"),
                    ])
                    .accessibilityLabel("Plan")
                }

                DSCard {
                    DSRadioGroup(selection: $shipping, options: ["Standard", "Express", "Overnight"])
                        .accessibilityLabel("Shipping speed")
                }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

`DSRadioGroup(selection:options:accent:haptic:)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `selection` | `Binding<Value>` | required | The chosen value (`Value: Hashable`). |
| `options` | `[DSRadioOption<Value>]` | required | The rows, top to bottom. Values must be unique. |
| `accent` | `Color?` | `nil` | Fill of the selected indicator. Defaults to the theme accent. |
| `haptic` | `DSHapticStyle` | `.rigid` | Haptic fired when the selection changes. |

Build each option with `DSRadioOption(_ title: String, value: Value, subtitle: String? = nil, icon: String? = nil)`.

**String shortcut:** `DSRadioGroup(selection: Binding<String>, options: [String], accent: Color? = nil, haptic: DSHapticStyle = .rigid)`, available when `Value` is `String`; each string is both the label and the value.

## Variants

```swift
DSRadioGroup(
    selection: $payment,
    options: [
        DSRadioOption("Apple Pay", value: 1, icon: "apple.logo"),
        DSRadioOption("Credit card", value: 2, subtitle: "Visa ending 4242", icon: "creditcard"),
    ],
    accent: theme.palette.success
)
```
Here `payment` is an `Int` state and `theme` is `@DSThemed private var theme`. Any `Hashable` works as the value: an enum, an id, an `Int`, a `UUID`.

## Behavior

- Tapping anywhere on a row selects it. Rows are at least 44 pt tall and as wide as the group. Wrap the group in a `DSCard` for the glass container look.
- The indicator is a 24 pt wash circle (no outline), the same size, colors and haptic as `DSCheckbox`. On select the accent layer springs up from 55 % size with `springBouncy` and fades in, and an inner dot grows a beat later. The previous row's indicator shrinks and fades.
- A highlight (`theme.subtleFill`) slides to the chosen row with `matchedGeometryEffect` and `springSmooth`, resizing between rows with and without a subtitle. Nothing else changes size, so the list never jumps.
- Everything follows `selection`, so changing it from outside (a "reset" button) animates like a tap.
- The haptic fires on a change only: reselecting the current value does nothing. A disabled group dims to 50 % and ignores taps.
- The dot is `theme.onAccent` on the accent fill, and `palette.textOnPrimary` when you pass your own `accent`.
- Reduce Motion: nothing pops, grows or slides. The indicators and the highlight crossfade in place.
- Press: the row dips with `DSPress.scale`.

## Accessibility

- Each row is one button. Its label is the title followed by the subtitle, its value is its position ("2 of 3"), and it carries the selected trait while chosen. Choosing a row also announces "Title, selected".
- The group is a container. Label it for VoiceOver with `.accessibilityLabel("Plan")`.
- Dynamic Type: titles and subtitles scale with the user's text size and rows grow to fit.

## See also

- [DSSegmentedControl](DSSegmentedControl.md)
- [DSListCell](DSListCell.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
