# DSFlowLayout

A wrapping layout: it lays its subviews out left-to-right and drops to a new line the moment the next one won't fit. The missing primitive behind tag clouds, filter chips, keyword lists and any set of pill-shaped items whose count you don't control — the one case a `VStack`/`HStack` can't handle and `DSGrid` gets wrong (chips aren't a grid; they're different widths).

![DSFlowLayout](../media/DSFlowLayout.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSFlowLayout.swift`](../../Sources/VelvetUI/Layout/DSFlowLayout.swift)

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

struct InterestsPicker: View {
    private let interests = ["Design", "SwiftUI", "Motion", "Accessibility",
                             "Haptics", "Typography", "Color", "Prototyping"]
    @State private var selected: Set<String> = ["SwiftUI", "Motion"]

    var body: some View {
        DSFlowLayout {
            ForEach(interests, id: \.self) { interest in
                Button {
                    DSHapticEngine.shared.fire(.selection)
                    withAnimation(DSAnimation.springSnappy) {
                        selected.formSymmetricDifference([interest])
                    }
                } label: {
                    Text(interest)
                        .ds(.buttonSmall)
                        .padding(.horizontal, DSSpacing.sm)
                        .padding(.vertical, DSSpacing.xs)
                        .dsSurface(.glassThin, radius: DSRadius.chip)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

`DSFlowLayout` is a `Layout`, not a container view — you use it exactly like a `VStack`, and it works with `ForEach`, conditional subviews and `withAnimation`.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `spacing` | `CGFloat` | `DSSpacing.xs` | Horizontal gap between items on the same row. |
| `lineSpacing` | `CGFloat` | `DSSpacing.xs` | Vertical gap between rows. |
| `alignment` | `HorizontalAlignment` | `.leading` | How a row narrower than the container sits within it: `.leading`, `.center` or `.trailing`. |

## Behavior

- Greedy first-fit packing: items fill a row until the next one would overflow the proposed width, then wrap. An item wider than the whole container lands on its own row rather than clipping or vanishing.
- Because it's a real `Layout`, motion is free and on-system: wrap a change to the content in `withAnimation(DSAnimation.springSmooth)` and items added, removed or resized glide to their new positions along the Velvet spring instead of snapping.
- Reports its true wrapped height, so it composes inside a `VStack`, a `DSCard` or a `ScrollView` with no fixed-height guesswork.

## Theming

A layout positions, it never paints — `DSFlowLayout` has no colors, fills or borders of its own and adds no haptics. Style the items you put inside it (a glass chip, a `DSBadge`, a `Button`) with the usual theme roles; selection feedback and haptics belong on those items, not on the layout.

## Accessibility

- Transparent to assistive tech: each subview keeps its own accessibility element, label, value and traits. VoiceOver reads the items in order.
- Dynamic Type: rows re-pack automatically as item widths grow with larger text, so nothing is clipped. Keep item labels on `.ds(_:)` so they scale.
- No motion of its own; reflow animation only runs when the caller opts in with `withAnimation`, so it respects Reduce Motion by default.

## See also

- [DSBadge](DSBadge.md)
- [DSSegmentedControl](DSSegmentedControl.md)
- [Layout helpers](../components.md#layout) · [All components](../../README.md#components) · [Theming](../../README.md#theming)
