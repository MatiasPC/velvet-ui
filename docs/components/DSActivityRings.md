# DSActivityRings

Concentric goal rings, the "close your rings" pattern: several goals nested as rings that fill with a spring, and a ring that lights up with a glow and one haptic the moment it closes.

<!-- GIF pending: ![DSActivityRings](../media/DSActivityRings.gif) -->

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSActivityRings.swift`](../../Sources/VelvetUI/Components/DSActivityRings.swift)

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

struct TodayRings: View {
    @DSThemed private var theme
    @State private var move = 0.82
    @State private var exercise = 0.60
    @State private var stand = 0.45

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                DSCard {
                    DSActivityRings([
                        DSRing(progress: move, color: theme.palette.error, label: "Move"),
                        DSRing(progress: exercise, color: theme.palette.success, label: "Exercise"),
                        DSRing(progress: stand, color: theme.palette.info, label: "Stand")
                    ]) {
                        Text("\(Int(((move + exercise + stand) / 3 * 100).rounded()))%").ds(.title2)
                    }
                    .frame(maxWidth: .infinity)
                }

                DSButton("Finish a workout", isFullWidth: true) { exercise = 1 }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

`DSActivityRings(_:size:lineWidth:spacing:spring:haptic:accessibilityLabel:center:)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `rings` | `[DSRing]` | required | The rings, outermost first. |
| `size` | `CGFloat` | `160` | Outer diameter of the whole set. The rings stay inside it. |
| `lineWidth` | `CGFloat` | `14` | Stroke width of every ring. |
| `spacing` | `CGFloat` | `DSSpacing.xxs` | Gap between adjacent rings. |
| `spring` | `Animation` | `DSAnimation.springSmooth` | The fill animation, on appear and on change. |
| `haptic` | `DSHapticStyle?` | `.success` | Fired when a ring closes. `nil` for none. |
| `accessibilityLabel` | `String` | `"Activity rings"` | What VoiceOver calls the set. |
| `center` | `() -> View` | none | Content nested inside the innermost ring. Leave it out for no centre. |

`DSRing(progress:color:label:)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `progress` | `Double` | required | Fraction of the goal reached. `1` is a closed ring. |
| `color` | `Color?` | `nil` | Ring colour. `nil` follows the theme accent. |
| `label` | `String?` | `nil` | The name VoiceOver speaks ("Move"). `nil` falls back to "Ring 1", "Ring 2"… |

## Variants

```swift
HStack(spacing: DSSpacing.xl) {
    // One goal, no centre, in the theme accent
    DSActivityRings([DSRing(progress: 0.7, label: "Budget")], size: 96, lineWidth: 12)

    // A quiet one: no haptic when it closes
    DSActivityRings([DSRing(progress: 1, label: "Storage")], size: 96, lineWidth: 12, haptic: nil)
}
```
Budgets, storage, quiz completion or any "how close am I" view work with one ring or several. A thinner `lineWidth` fits more rings in the same `size`.

## Behavior

- Rings are drawn outermost first, each one lane (`lineWidth + spacing`) inside the one before. A ring that would no longer leave a hole in the middle is not drawn.
- Each ring fills from empty when the view appears, and animates to its new value whenever `progress` changes.
- Closing: when a ring goes from open to closed (`progress` reaching `1` while it is on screen) it lights up with a glow in its own colour and one haptic fires, both as the spring lands. A closed ring keeps its glow until it re-opens.
- A ring that is already closed when the view appears glows but does not buzz, and re-renders never buzz. Only a real transition does.
- Rings that close at the same moment share one haptic.
- Past the goal: `progress` above `1` is clamped to a full, closed ring. The arc does not wrap or overlap. VoiceOver still speaks the real number ("120 percent"). Negative and non-numeric values count as `0`.
- The track behind each ring is the palette border colour, like the other progress components.
- Reduce Motion: no sweep. Rings jump to their value, and the glow and haptic still mark a close.

## Accessibility

- The rings are one VoiceOver element. Its label is `accessibilityLabel`; its value lists every ring, outermost first: "Move 82 percent. Exercise 60 percent. Stand 100 percent, complete".
- Give each ring a `label`. Without one it is read as "Ring 1", "Ring 2".
- Centre content is a separate element, so a summary there stays reachable.
- A ring closing is not announced. VoiceOver users hear the new value when they focus the rings.

## See also

- [Progress](Progress.md) for a single circular, linear or step indicator
- [DSSuccessCheck](DSSuccessCheck.md) for a one-off success moment
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
