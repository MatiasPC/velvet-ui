# DSSegmentedControl

A generic segmented control where a filled pill (or an accent underline) slides between options, with a selection tick on each change.

![DSSegmentedControl](../media/DSSegmentedControl.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSSegmentedControl.swift`](../../Sources/VelvetUI/Components/DSSegmentedControl.swift)

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

struct SegmentedControlDemo: View {
    enum Range: Hashable { case day, week, month }

    @State private var range = Range.week
    @State private var tab = "Overview"

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                DSSegmentedControl(
                    selection: $range,
                    segments: [
                        DSSegment("Day", value: Range.day),
                        DSSegment("Week", value: Range.week),
                        DSSegment("Month", value: Range.month),
                    ]
                )
                DSSegmentedControl(
                    selection: $tab,
                    options: ["Overview", "Details", "Reviews"],
                    style: .underline
                )
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `selection` | `Binding<Value>` | required | The selected value (`Value: Hashable`). |
| `segments` | `[DSSegment<Value>]` | required | The options. Build each with `DSSegment(_ title: String, value: Value, icon: String? = nil)`. |
| `style` | `DSSegmentedControlStyle` | `.pill` | `.pill` or `.underline`. |
| `accent` | `Color?` | `nil` | `.underline` only: overrides both the underline and the selected label. Without it the underline is the theme accent and the selected label is theme ink. Ignored by `.pill`. |
| `haptic` | `DSHapticStyle` | `.selection` | Haptic fired when the selection changes. |

**String shortcut:** `DSSegmentedControl(selection: Binding<String>, options: [String], style: DSSegmentedControlStyle = .pill, accent: Color? = nil, haptic: DSHapticStyle = .selection)`, available when `Value` is `String`.

## Variants

- `.pill`: a raised elevated-background indicator on a rounded secondary-background track, like the native iOS control.
- `.underline`: an accent underline beneath the labels, tab-bar style.
- Segments can carry an SF Symbol: `DSSegment("Map", value: Mode.map, icon: "map")`.

## Behavior

- The indicator slides between segments with a snappy spring (shared geometry).
- A selection haptic fires on each change; tapping the already-selected segment does nothing.

## Accessibility

- Each segment is a separate button labelled with its title, and marked selected when active. An icon is hidden from VoiceOver when the segment has a title.
- Label text doesn't scale with Dynamic Type yet: the control has a fixed height, so its label keeps a fixed size. Text elsewhere on your screen that uses `.ds(_:)` / `.dsTextStyle(_:)` does scale.

## See also

- [DSToggle](DSToggle.md)
- [DSPageControl](DSPageControl.md)
- [DSStepper](DSStepper.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
