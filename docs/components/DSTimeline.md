# DSTimeline

A vertical progress timeline: a rail of nodes joined by a connector that fills as the flow advances. The classic order-status pattern — Ordered → Shipped → Out for delivery → Delivered — and equally at home in multi-step flows, activity histories and wizards. It is the vertical, content-bearing complement to [`DSStepProgress`](Progress.md) (a row of flat capsules with no labels).

![DSTimeline](../media/DSTimeline.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSTimeline.swift`](../../Sources/VelvetUI/Components/DSTimeline.swift)

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

struct DeliveryStatus: View {
    @State private var step = 2

    var body: some View {
        DSScreen(backdrop: true) {
            DSCard {
                DSTimeline(
                    [
                        DSTimelineItem("Order placed", subtitle: "March 3, 9:41 AM", icon: "bag"),
                        DSTimelineItem("Shipped", subtitle: "Picked up by courier", icon: "shippingbox"),
                        DSTimelineItem("Out for delivery", subtitle: "Arriving today", icon: "box.truck"),
                        DSTimelineItem("Delivered", icon: "house")
                    ],
                    currentStep: step
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `items` | `[DSTimelineItem]` | required | The stops, top to bottom. |
| `currentStep` | `Int` | required | Index of the live step. Steps before it are complete, the one at it is current, steps after it are upcoming. Pass `items.count` when every step is done. |
| `nodeSize` | `CGFloat` | `28` | Diameter of each node; the glyph and glow scale with it. |
| `lineWidth` | `CGFloat` | `DSSpacing.xxxs` (2) | Thickness of the connector rail. |
| `accent` | `Color?` | `nil` | Fill for reached nodes and the filled connector. Defaults to the theme accent. |
| `haptics` | `Bool` | `true` | Fire a `.success` tick when the flow advances. |

`DSTimelineItem(_ title:, subtitle:, icon:)` — `subtitle` and `icon` (an SF Symbol) are optional.

## States

Each step derives its look from `currentStep`:

| Step | Node | Label | Connector below |
|---|---|---|---|
| Before `currentStep` | Accent fill, checkmark (or the item's icon) | `textPrimary` | Accent, filled |
| At `currentStep` | Accent fill, icon or dot, soft glow, a resting breath | `textPrimary` | Empty |
| After `currentStep` | Wash fill, muted icon or empty | `textTertiary` | Empty |

## Behavior

- Advancing `currentStep` grows the connector fill from the top and lands the node change with `DSAnimation.springSmooth`.
- The live node carries a `.glow` and a `dsBreathe(.subtle)` so the current step reads as active without a border.
- Rows enter with the shared `dsStaggerIn` cascade.
- A `.success` haptic fires once when `currentStep` moves forward (set `haptics: false` to silence it). No haptic on first appearance or when moving back.
- No borders: nodes are filled circles over a wash; the connector is a capsule fill over a wash track.

## Accessibility

- Each step is one element. VoiceOver reads the title and subtitle as the label and the status ("Completed", "In progress", "Upcoming") as the value.
- The resting breath on the live node settles static under Reduce Motion (via `dsBreathe`).
- Labels scale with Dynamic Type through the DS text styles.

## See also

- [DSStepProgress](Progress.md)
- [DSSuccessCheck](DSSuccessCheck.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
