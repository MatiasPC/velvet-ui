# DSChip / DSChipGroup

Selectable pill chips for filters, tags, categories and interest pickers. `DSChipGroup` lays them out on a wrapping flow that breaks onto as many lines as the width needs, and manages single or multiple selection. Selecting a chip springs its fill into the accent and ticks a selection haptic.

![DSChip](../media/DSChip.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSChip.swift`](../../Sources/VelvetUI/Components/DSChip.swift)

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

struct ChipDemo: View {
    @State private var topics: Set<String> = ["Design"]
    @State private var sort: String? = "Trending"

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                // Multiple selection — tap to add or remove.
                DSChipGroup(
                    ["Design", "Engineering", "Product", "Research", "Marketing"],
                    selection: $topics
                )
                // Single selection — tap the selected chip again to clear it.
                DSChipGroup(["Trending", "Newest", "Top rated", "Nearby"], selection: $sort)
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

### DSChipGroup

| Parameter | Type | Default | Description |
|---|---|---|---|
| `items` | `[DSChipItem<Value>]` | required | The chips, in order. Build each with `DSChipItem(_ title: String, value: Value, icon: String? = nil)` (`Value: Hashable`). |
| `selection` | `Binding<Set<Value>>` | required | Multiple selection: tapping a chip inserts or removes its value. |
| `selection` | `Binding<Value?>` | required | Single selection: tapping a chip selects it; tapping the selected chip clears it (`nil`). |
| `spacing` | `CGFloat` | `DSSpacing.xs` | Gap between chips and between lines. |
| `accent` | `Color?` | `nil` | Fill for selected chips. Defaults to the theme accent. |

**String shortcut:** `DSChipGroup(_ options: [String], selection: Binding<Set<String>>, …)` and `DSChipGroup(_ options: [String], selection: Binding<String?>, …)`, available when `Value` is `String` — each option is its own value.

### DSChip

A single chip you can place on its own (a filter outside a group, an "Add tag" affordance):

```swift
DSChip("Add tag", icon: "plus") { addTag() }
DSChip("Design", isSelected: isOn) { isOn.toggle() }
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `title` | `String` | required | The chip's label, and its VoiceOver label. |
| `icon` | `String?` | `nil` | Optional leading SF Symbol. Decorative — hidden from VoiceOver. |
| `isSelected` | `Bool` | `false` | Whether the chip reads as selected. |
| `accent` | `Color?` | `nil` | Fill when selected. Defaults to the theme accent. |
| `haptic` | `DSHapticStyle` | `.selection` | Fired on tap. |
| `action` | `() -> Void` | required | Called on tap. In a `DSChipGroup` this toggles selection. |

## Behavior

- Chips flow left to right and wrap onto a new line whenever the next one would overflow the available width, using a custom `Layout` — no horizontal scrolling.
- Selecting a chip crossfades its fill from `theme.subtleFill` to the accent with a snappy spring, lifts it with a soft shadow, and ticks a selection haptic.
- No borders: an unselected chip reads through the subtle surface, a selected one through the accent fill.

## Accessibility

- Each chip is a button labelled with its title, and marked selected when active. A leading icon is decorative and hidden from VoiceOver.
- Chip labels use the rounded button text style so they scale with Dynamic Type alongside the rest of your screen.

## See also

- [DSSegmentedControl](DSSegmentedControl.md)
- [DSBadge](DSBadge.md)
- [DSButton](DSButton.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
