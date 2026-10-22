# DSSegmentedControl

A generic segmented control where a glass pill (or an accent underline) slides between options, with a selection tick on each change.

![DSSegmentedControl](../media/DSSegmentedControl.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSSegmentedControl.swift`](../../Sources/VelvetUI/Components/DSSegmentedControl.swift)

## Install

```swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
.product(name: "VelvetUI", package: "velvet-ui")   // add to your target's dependencies
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`.dsTheme(DSTheme(gradient: .sunset))`); see [the README](../../README.md#install) and its [quick start](../../README.md#quick-start) for the full theming setup.

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
| `accent` | `Color?` | `nil` | Underline fill and selected label color (underline style). Defaults to the theme accent. |
| `haptic` | `DSHapticStyle` | `.selection` | Haptic fired when the selection changes. |

**String shortcut:** `DSSegmentedControl(selection: Binding<String>, options: [String], style: DSSegmentedControlStyle = .pill, accent: Color? = nil, haptic: DSHapticStyle = .selection)`, available when `Value` is `String`.

## Variants

- `.pill`: a filled indicator on a rounded glass track, like the native iOS control.
- `.underline`: an accent underline beneath the labels, tab-bar style.
- Segments can carry an SF Symbol: `DSSegment("Map", value: Mode.map, icon: "map")`.

## Behavior

- The indicator slides between segments with a snappy spring (shared geometry).
- A selection haptic fires on each change; tapping the already-selected segment does nothing.

## Accessibility

- Each segment is a separate button labelled with its title, and marked selected when active.
- Label text doesn't scale with Dynamic Type yet: the control has a fixed height, so its label keeps a fixed size. Text elsewhere on your screen that uses `.ds(_:)` / `.dsTextStyle(_:)` does scale.

## See also

- [DSToggle](DSToggle.md)
- [DSPageControl](DSPageControl.md)
- [DSStepper](DSStepper.md)
- [All components](../components.md) · [Theming](../../README.md#quick-start)
