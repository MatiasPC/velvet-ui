# DSCheckbox

A themed checkbox for lists, forms and consent rows: an empty ring-shaped box that pops to the accent while its checkmark draws on, with a rigid haptic.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSCheckbox.swift`](../../Sources/VelvetUI/Components/DSCheckbox.swift)

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

struct CheckboxDemo: View {
    @State private var acceptsTerms = true
    @State private var newsletter = false

    var body: some View {
        DSScreen(backdrop: true) {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    DSCheckbox("I accept the terms and conditions", isOn: $acceptsTerms)
                    DSCheckbox("Send me the newsletter", isOn: $newsletter)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `label` | `String?` | `nil` | Text beside the box (unlabeled first argument). The label is part of the tap target. |
| `isOn` | `Binding<Bool>` | required | The checked state. |
| `size` | `DSCheckboxSize` | `.medium` | `.small` (20 pt box), `.medium` (24 pt) or `.large` (28 pt). |
| `onColor` | `Color?` | `nil` | Box fill while checked. Defaults to the theme accent. |
| `haptic` | `DSHapticStyle` | `.rigid` | Haptic fired on every change. |

## Variants

```swift
VStack(alignment: .leading, spacing: DSSpacing.xxs) {
    DSCheckbox("Compact row", isOn: $compact, size: .small)
    DSCheckbox("Order confirmed", isOn: $confirmed, onColor: theme.palette.success)
    DSCheckbox(isOn: $selectAll, size: .large)
        .accessibilityLabel("Select all")
}
```
Here `theme` is `@DSThemed private var theme`. Without a label it is just the box, for use in your own rows; give it a VoiceOver label yourself.

## Behavior

- Tapping the box **or its label** toggles `isOn`, fires the haptic and plays the animation. A disabled checkbox dims to 50 % and ignores taps.
- The box always lays out at least 44×44 pt, so the hit target meets Apple's minimum at every size. `.small` shrinks the box, not the row; in a dense list, drop the stack spacing to zero.
- Checking: the accent layer springs up from 55 % size with `DSAnimation.springBouncy` and fades in, and the checkmark draws on (`trim`) a beat later. Unchecking: the tick undraws at once while the layer shrinks and fades.
- The animation follows `isOn`, so it also plays when the binding changes from outside (a "select all" parent). A checkbox that appears already checked, for example one scrolling into a lazy list, shows the finished tick without replaying the draw.
- The unchecked box is a filled ring: an outer shape in `palette.textSecondary` (at least 3:1 against the card in light and dark, WCAG 1.4.11) and an inner one in `palette.backgroundElevated`, plus the specular `dsWashEdge`. Both are fills; there is no stroke.
- The tick is `theme.onAccent` on the accent fill, and `palette.textOnPrimary` when you pass your own `onColor`.
- Reduce Motion: nothing pops or draws. The box crossfades, and the tick is simply there when checked.
- Press: the row dips with `DSPress` (the lone box dips with `DSPress.iconScale`).

## Accessibility

- One element. Its label is the `label` text; add `.accessibilityLabel("…")` when you use the box without one.
- Value is "Checked" or "Unchecked". It carries the toggle trait, plus the selected trait while checked, and reads as dimmed when `.disabled`.
- Dynamic Type: the label text scales with the user's text size. The box and the 44 pt minimum stay fixed.

## See also

- [DSToggle](DSToggle.md)
- [DSSegmentedControl](DSSegmentedControl.md)
- [DSListCell](DSListCell.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
