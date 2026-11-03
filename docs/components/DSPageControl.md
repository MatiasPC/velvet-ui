# DSPageControl

An animated page indicator where the active dot springs open into a capsule. A drop-in, nicer replacement for UIPageControl.

![DSPageControl](../media/DSPageControl.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSPageControl.swift`](../../Sources/VelvetUI/Components/DSPageControl.swift)

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

struct PageControlDemo: View {
    @State private var page = 0
    private let titles = ["Welcome", "Pick a theme", "Turn on haptics", "You're set"]

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                Text(titles[page]).ds(.title2)
                DSPageControl(currentPage: $page, numberOfPages: titles.count)
                DSButton("Next", isFullWidth: true) {
                    page = (page + 1) % titles.count
                }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `currentPage` | `Binding<Int>` | required | Index of the selected page. |
| `numberOfPages` | `Int` | required | Total number of pages. |
| `activeColor` | `Color?` | `nil` | Selected indicator fill. Defaults to the theme accent. |
| `inactiveColor` | `Color?` | `nil` | Unselected dot fill. Defaults to the palette border color. |
| `dotSize` | `CGFloat` | `DSSpacing.xs` | Diameter of an unselected dot (also the control height). |
| `activeWidth` | `CGFloat` | `DSSpacing.xl` | Width the selected indicator expands to. |
| `spacing` | `CGFloat` | `DSSpacing.xs` | Gap between indicators. |
| `allowsTap` | `Bool` | `true` | Tapping a dot jumps to that page. |



## Variants

- Interactive (default): tap a dot to jump to it.
- Pass `allowsTap: false` for a purely visual indicator, e.g. driven by a `TabView` or scroll position.

## Behavior

- The selected dot stretches into a capsule with a smooth spring as the page changes.
- Tapping a dot fires a selection haptic.

## Accessibility

- One adjustable element labelled "Page" with the value "2 of 5". Swipe up or down to change pages.
- When `allowsTap` is false it is read-only.
- Dynamic Type: dot sizes come from `dotSize`, so they don't scale with text size.

## See also

- [DSSegmentedControl](DSSegmentedControl.md)
- [DSButton](DSButton.md)
- [DSStepper](DSStepper.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
