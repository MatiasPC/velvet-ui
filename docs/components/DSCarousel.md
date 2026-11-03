# DSCarousel

A snapping carousel where the neighbouring items peek in at the edges and lean away with a little depth. The page index is a plain `Int`, so it pairs directly with `DSPageControl`.

![DSCarousel](../media/DSCarousel.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSCarousel.swift`](../../Sources/VelvetUI/Components/DSCarousel.swift)

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

struct Trip: Identifiable {
    let id: Int
    let city: String
    let price: String
}

struct CarouselDemo: View {
    @State private var page = 0
    private let trips = [
        Trip(id: 0, city: "Lisbon", price: "$480"),
        Trip(id: 1, city: "Kyoto", price: "$1,240"),
        Trip(id: 2, city: "Oaxaca", price: "$620")
    ]

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.md) {
                DSCarousel(trips, currentPage: $page) { trip in
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text(trip.city).ds(.title2)
                        Text(trip.price).ds(.callout)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(DSSpacing.md)
                    .dsSurface(.glass, radius: DSRadius.card)
                }
                .frame(height: 200)

                DSPageControl(currentPage: $page, numberOfPages: trips.count)
            }
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `data` | `RandomAccessCollection` of `Identifiable` | required | The items. Each element's `id` identifies its page. |
| `currentPage` | `Binding<Int>` | none | The page index. Scrolling updates it; changing it scrolls there with a spring. Out-of-range values are clamped. Leave it out and the carousel keeps its own index. |
| `peek` | `CGFloat` | `DSSpacing.xxxl` | Margin on each side of the centred item. `peek - spacing` of each neighbour shows. |
| `spacing` | `CGFloat` | `DSSpacing.sm` | Gap between items. |
| `haptic` | `DSHapticStyle?` | `.selection` | Fired once per page change. `nil` for none. |
| `content` | `(Element) -> View` | required | The view for one item. Trailing closure. |

Each item is as wide as the carousel minus `peek` on both sides. Give the carousel a height and let each item fill it with `.frame(maxHeight: .infinity)`: content taller than the carousel is clipped.

## Variants

```swift
struct CarouselCompactDemo: View {
    private let tags = [
        Trip(id: 0, city: "Lisbon", price: "$480"),
        Trip(id: 1, city: "Kyoto", price: "$1,240")
    ]

    var body: some View {
        DSCarousel(tags, peek: DSSpacing.lg, spacing: DSSpacing.sm, haptic: nil) { trip in
            Text(trip.city)
                .ds(.title3)
                .frame(maxWidth: .infinity, minHeight: 72)
                .dsSurface(.glassThin, radius: DSRadius.surface)
        }
        .frame(height: 80)
    }
}
```
Smaller peek and spacing, no haptic. Without `currentPage` the carousel manages its own index.

## Behavior

- Scrolling snaps to whole items.
- Items away from the centre shrink to about 90%, fade to about 60% and yaw a few degrees towards the centre.
- Setting `currentPage` from code scrolls there with `DSAnimation.springSmooth` (without animation under Reduce Motion). Only user scrolling fires the haptic.
- Reduce Motion: the scale, fade and yaw are skipped (items stay at full size). Snapping stays.

## Accessibility

- The carousel is a container labelled "Carousel" whose value reads "Page 2 of 5". Items stay individually accessible.
- Give each item its own accessibility label inside `content`.

## See also

- [DSPageControl](DSPageControl.md)
- [DSCard](DSCard.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
