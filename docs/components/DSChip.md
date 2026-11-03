# DSChip / DSChipGroup

Selectable pill chips for filters, tags, categories and interest pickers. `DSChipGroup` lays them out with [`DSFlowLayout`](DSFlowLayout.md), which breaks onto as many lines as the width needs, and manages single or multiple selection. Selecting a chip springs its fill into the accent and ticks a selection haptic.

<!-- GIF pending: ![DSChip](../media/DSChip.gif) -->

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSChip.swift`](../../Sources/VelvetUI/Components/DSChip.swift)

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

## Variants

```swift
enum Sort: Hashable { case trending, newest, topRated }

struct ChipVariantsDemo: View {
    @State private var media: Set<String> = ["photos"]
    @State private var sort: Sort? = .trending
    @DSThemed private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            // Leading icons and a custom accent for the selected fill
            DSChipGroup(
                [
                    DSChipItem("Photos", value: "photos", icon: "photo"),
                    DSChipItem("Videos", value: "videos", icon: "video"),
                    DSChipItem("Audio", value: "audio", icon: "waveform")
                ],
                selection: $media,
                accent: theme.palette.success
            )

            // Any Hashable value, not just strings
            DSChipGroup(
                [
                    DSChipItem("Trending", value: Sort.trending),
                    DSChipItem("Newest", value: Sort.newest),
                    DSChipItem("Top rated", value: Sort.topRated)
                ],
                selection: $sort,
                spacing: DSSpacing.sm
            )
        }
    }
}
```

## Behavior

- Chips flow left to right and wrap onto a new line whenever the next one would overflow the available width, using [`DSFlowLayout`](DSFlowLayout.md) — no horizontal scrolling. `DSChipGroup` depends on it, so copying `DSChip` into an app with the CLI brings it along.
- Selecting a chip crossfades its fill from `theme.subtleFill` to the accent with a snappy spring, lifts it with a soft shadow, and ticks a selection haptic.
- Pressing scales the chip to `DSPress.scale`. The press is a `ButtonStyle`, so a touch that becomes a scroll releases the chip instead of leaving it shrunk.
- No borders: an unselected chip reads through the subtle surface, a selected one through the accent fill.
- Reduce Motion: the fill changes with a quick fade instead of a spring.

## Accessibility

- Each chip is a button labelled with its title, and marked selected when active. A leading icon is decorative and hidden from VoiceOver.
- Chip labels use the `buttonSmall` text style, so they scale with Dynamic Type alongside the rest of your screen.
- A chip is as tall as its label plus `DSSpacing.xs` above and below, a little under the 44 pt minimum target. Keep `spacing` generous (`DSSpacing.sm`) where chips sit close together.

## See also

- [DSFlowLayout](DSFlowLayout.md)
- [DSSegmentedControl](DSSegmentedControl.md)
- [DSBadge](DSBadge.md)
- [DSButton](DSButton.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
