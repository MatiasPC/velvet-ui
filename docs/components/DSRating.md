# DSRating

A star rating you can drag or tap, with a selection tick per star and a pop on the active one. It also has a read-only form with fractional fills.

![DSRating](../media/DSRating.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSRating.swift`](../../Sources/VelvetUI/Components/DSRating.swift)

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

struct RatingDemo: View {
    @State private var stars = 3.0

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.md) {
                Text("How was your stay?").ds(.title3)
                DSRating(rating: $stars, step: 0.5)
                DSRating(value: 4.5)
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `rating` | `Binding<Double>` | required | Current rating, in `0...count`. |
| `count` | `Int` | `5` | Number of stars (minimum 1). |
| `step` | `Double` | `1` | Snap increment: `1` for whole stars, `0.5` for half stars. |
| `symbol` | `String` | `"star.fill"` | SF Symbol for a filled star. |
| `emptySymbol` | `String` | `"star"` | SF Symbol for an empty star. |
| `size` | `CGFloat` | `28` | Point size of each star. |
| `spacing` | `CGFloat` | `DSSpacing.xs` | Gap between stars. |
| `tint` | `Color?` | `nil` | Rated star color. Defaults to the warning amber. |
| `emptyColor` | `Color?` | `nil` | Unrated star color. Defaults to the border color. |
| `haptics` | `Bool` | `true` | Fire haptics while rating. |

**Read-only init:** `DSRating(value: Double, count: Int = 5, symbol: String = "star.fill", emptySymbol: String = "star", size: CGFloat = 20, spacing: CGFloat = DSSpacing.xxs, tint: Color? = nil, emptyColor: Color? = nil)`. It fills stars fractionally (4.5 shows four and a half) and ignores touches.

## Variants

```swift
DSRating(rating: $stars, count: 10, symbol: "heart.fill", emptySymbol: "heart", tint: .pink)
```
Use `step: 0.5` for half stars. Use `DSRating(value:)` for displaying averages.

## Behavior

- Drag across the stars or tap one; the value snaps to `step`.
- A selection tick fires per star crossed and a light haptic on release. The active star pops with a bouncy spring.

## Accessibility

- Editable: one adjustable element labelled "Rating" with the value "3 out of 5 stars". Swipe up or down to change it.
- The read-only init has the same label and value format ("Rating", "3.5 out of 5 stars"). VoiceOver still announces it as adjustable, but swiping does nothing.
- Dynamic Type: stars are sized by the `size` parameter, so they don't scale with text size.

## See also

- [DSStepper](DSStepper.md)
- [DSSegmentedControl](DSSegmentedControl.md)
- [DSToggle](DSToggle.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
