# DSTimeline

A vertical progress timeline: a rail of nodes joined by a connector that fills as the flow advances. The classic order-status pattern — Ordered → Shipped → Out for delivery → Delivered — and equally at home in multi-step flows, activity histories and wizards. It is the vertical, content-bearing complement to [`DSStepProgress`](Progress.md) (a row of flat capsules with no labels).

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSTimeline.swift`](../../Sources/VelvetUI/Components/DSTimeline.swift)

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

struct TimelineDemo: View {
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
| `nodeSize` | `CGFloat` | `DSSpacing.xxl` (32) | Diameter of each node at the default text size. It scales with Dynamic Type; the glyph and glow follow it. |
| `lineWidth` | `CGFloat` | `DSSpacing.xxxs` (2) | Thickness of the connector rail. |
| `accent` | `Color?` | `nil` | Fill for reached nodes and the filled connector. Defaults to the theme accent. |
| `haptics` | `Bool` | `true` | Fire a `.success` tick when the flow advances. |

`DSTimelineItem(_ title:, subtitle:, icon:)` — `subtitle` and `icon` (an SF Symbol) are optional.

## States

Each step derives its look from `currentStep`:

| Step | Node | Label | Connector below |
|---|---|---|---|
| Before `currentStep` | Accent fill, checkmark (or the item's icon) | `textPrimary` | Accent, filled |
| At `currentStep` | Accent fill, icon or dot, a glow that breathes | `textPrimary` | Empty |
| After `currentStep` | Muted fill, muted icon or empty | `textTertiary` | Empty |

`currentStep` is clamped to `0...items.count`. Pass `items.count` for "everything is done".

## Behavior

- Advancing `currentStep` grows the connector fill from the top and recolors the node with `DSAnimation.springSmooth`. The fill is clipped to its track, so the spring's overshoot never bleeds into the next node.
- The animation and the haptic are keyed on the step, not on appearance. A timeline that opens already at step 3 shows step 3 at once, with no fill and no haptic; only a forward change plays them.
- A `.success` haptic fires once when `currentStep` moves forward, however many steps it jumps (set `haptics: false` to silence it). None on first appearance, when moving back, or when a request past the end is clamped to where it already was.
- The live node carries a `.glow` that breathes (`dsBreathe(.medium)`) on its own layer behind the node, so the node itself never cross-fades when the step changes.
- Rows enter with the shared `dsStaggerIn` cascade.
- The title line is at least a node tall and centred in that height, so each node sits on its title at every text size. Long titles and subtitles wrap and the node stays on the first line.
- The timeline takes its height from its rows. It does not stretch to fill a taller container.
- No borders: nodes are filled circles, the connector is a capsule fill over a track in the palette border tone.
- Reduce Motion: the fill does not grow, it fades in; the live glow rests still; rows appear without the cascade.

## Accessibility

- Each step is one element. VoiceOver reads the title and subtitle as the label and the status ("Completed", "In progress", "Upcoming") as the value.
- Nodes, glyphs and connectors are hidden from VoiceOver; the status is carried by the value, not by color alone.
- Labels and nodes scale with Dynamic Type through the DS text styles and a scaled node size.

## See also

- [DSStepProgress](Progress.md)
- [DSSuccessCheck](DSSuccessCheck.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
