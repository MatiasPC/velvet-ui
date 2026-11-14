# DSSegmentedControl

A generic segmented control where a filled pill (or an accent underline) slides between options, with a selection tick on each change.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSSegmentedControl.swift`](../../Sources/VelvetUI/Components/DSSegmentedControl.swift)

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
| `segments` | `[DSSegment<Value>]` | required | The options. Build each with `DSSegment(_ title: String, value: Value, icon: String? = nil)`. Values should be unique: a repeated value keeps only its first segment. |
| `style` | `DSSegmentedControlStyle` | `.pill` | `.pill` or `.underline`. |
| `accent` | `Color?` | `nil` | `.underline` only: overrides both the underline and the selected label. Without it the underline is the theme accent and the selected label is theme ink. Ignored by `.pill`. |
| `haptic` | `DSHapticStyle` | `.selection` | Haptic fired when the selection changes. |

**String shortcut:** `DSSegmentedControl(selection: Binding<String>, options: [String], style: DSSegmentedControlStyle = .pill, accent: Color? = nil, haptic: DSHapticStyle = .selection)`, available when `Value` is `String`.

## Variants

- `.pill`: a raised elevated-background indicator on a rounded secondary-background track, like the native iOS control.
- `.underline`: an accent underline beneath the labels, tab-bar style.
- Segments can carry an SF Symbol: `DSSegment("Map", value: Mode.map, icon: "map")`.

## Behavior

- The indicator slides between segments with a snappy spring (shared geometry). Under Reduce Motion it doesn't travel: it fades out of the old segment and into the new one.
- A selection haptic fires on each change; tapping the already-selected segment does nothing.
- A `selection` that matches no segment shows no indicator.

## Accessibility

- Each segment is a separate button labelled with its title, marked selected when active, with its position as the value ("Week, selected, button, 2 of 3"), like the system control. An icon is hidden from VoiceOver when the segment has a title; an icon-only segment (`DSSegment("", value: …, icon: "map")`) is read by its symbol, so prefer a title.
- Labels and icons scale with Dynamic Type and the control grows with them. A label that no longer fits its segment stays on one line and truncates.

## See also

- [DSToggle](DSToggle.md)
- [DSPageControl](DSPageControl.md)
- [DSStepper](DSStepper.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
