# DSTabBar

A floating glass tab bar. The selected tab sits on an accent capsule that slides between tabs, and its icon swaps to the filled variant with one bounce.

![DSTabBar](../media/DSTabBar.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSTabBar.swift`](../../Sources/VelvetUI/Components/DSTabBar.swift)

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

struct TabBarDemo: View {
    enum Tab: Hashable { case home, search, inbox, profile }
    @State private var tab = Tab.home

    var body: some View {
        DSScreen(backdrop: true) {
            Text(String(describing: tab).capitalized).ds(.title1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            DSTabBar(selection: $tab, items: [
                DSTabItem("Home", value: .home, icon: "house", selectedIcon: "house.fill"),
                DSTabItem("Search", value: .search, icon: "magnifyingglass"),
                DSTabItem("Inbox", value: .inbox, icon: "tray", selectedIcon: "tray.fill", badge: 3),
                DSTabItem("Profile", value: .profile, icon: "person", selectedIcon: "person.fill")
            ])
            .dsScreenPadding()
        }
    }
}
```

## Parameters

`DSTabBar`:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `selection` | `Binding<Value>` | required | The selected tab's value. `Value` is any `Hashable`. |
| `items` | `[DSTabItem<Value>]` | required | The tabs, in order. |
| `accent` | `Color?` | `nil` | Fill of the selected capsule. Defaults to the theme accent. |
| `haptic` | `DSHapticStyle` | `.selection` | Fired when the selection changes. |

`DSTabItem(_ title:, value:, icon:, selectedIcon:, badge:)`:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `title` | `String` | required | Short label under the icon. |
| `value` | `Value` | required | Written to `selection` when chosen. |
| `icon` | `String` | required | SF Symbol name. |
| `selectedIcon` | `String?` | `nil` | Symbol shown while selected. `nil` reuses `icon`. |
| `badge` | `Int?` | `nil` | Count badge on the icon. `nil` or `0` shows none. |

## Variants

```swift
DSTabBar(selection: $section, items: [
    DSTabItem("Feed", value: "feed", icon: "square.stack"),
    DSTabItem("Map", value: "map", icon: "map"),
    DSTabItem("Saved", value: "saved", icon: "bookmark", selectedIcon: "bookmark.fill")
], accent: .indigo)
```
Three tabs with a custom accent and `String` values. Any `Hashable` works, including enums.

## Behavior

- The bar is a glass capsule with a large shadow. It sizes to its container, so place it with `.safeAreaInset(edge: .bottom)` and `.dsScreenPadding()`.
- Tabs share the width equally; labels never change width on selection, so nothing jitters.
- Selecting a tab slides the accent capsule with a snappy spring, swaps to `selectedIcon`, and bounces the icon once. A selection haptic fires only when the selection changes; tapping the selected tab does nothing.
- Pressing a tab scales it slightly.
- Reduce Motion: the capsule moves with a short ease (no overshoot) and the bounce is skipped.

## Accessibility

- The bar is a tab-bar container; each tab is a button labelled with its title. The selected tab has the selected trait.
- A badge is read as the value, for example "3 new". Tabs without a badge have no value.
- The layout uses padding rather than a fixed height, so labels and icons grow with Dynamic Type.

## See also

- [DSSegmentedControl](DSSegmentedControl.md)
- [DSBadge](DSBadge.md)
- [DSPageControl](DSPageControl.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
