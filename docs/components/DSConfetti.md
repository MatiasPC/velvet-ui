# dsConfetti

A one-shot burst of confetti from any point of a view, fired whenever a trigger value changes. Colored from the active theme.

![dsConfetti](../media/DSConfetti.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSConfetti.swift`](../../Sources/VelvetUI/Animation/DSConfetti.swift)

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

struct ConfettiDemo: View {
    @State private var celebrations = 0

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                Text("Order placed").ds(.title2)
                DSButton("Celebrate") { celebrations += 1 }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dsConfetti(trigger: celebrations, origin: UnitPoint(x: 0.5, y: 0.6))
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `trigger` | `Equatable` | required | One burst fires every time this value changes. It does not fire on first appearance. |
| `origin` | `UnitPoint` | `.center` | Where the burst starts, in the unit space of the view you attach it to. |
| `count` | `Int` | `80` | Number of pieces, limited to 150. |
| `haptic` | `DSHapticStyle?` | `nil` | Haptic fired with the burst. |

## Variants

```swift
struct ConfettiCornersDemo: View {
    @State private var left = 0
    @State private var right = 0

    var body: some View {
        VStack {
            DSButton("Both corners") { left += 1; right += 1 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsConfetti(trigger: left, origin: .bottomLeading, count: 50)
        .dsConfetti(trigger: right, origin: .bottomTrailing, count: 50, haptic: .success)
    }
}
```

Attach it to a container that covers the area the paper should fall through, such as the screen root, and pick `origin` in that container's unit space. Pieces are drawn inside the bounds of the view the modifier is attached to.

## Behavior

- Pieces fan upward and outward, slow down from air drag, then drift down under gravity while spinning and tumbling.
- Each piece lives 1.6 to 2.4 s and fades out over the last 30%.
- Colors come from the theme: the accent, the gradient stops, lighter tints of each, and the theme ink, which keeps the burst visible against the backdrop.
- Several triggers in a row overlap; earlier pieces finish their fall.
- Nothing runs while idle: the animation stops once the last piece is gone.
- `haptic` is `nil` by default because the action that triggers confetti (a button press, a confirmed slide) usually has its own haptic. Set it when the trigger is a state change with no haptic of its own.
- Reduce Motion: no pieces are drawn. The haptic, if set, still fires.

## Accessibility

- Purely decorative: ignores touches and is hidden from VoiceOver.
- Announce the outcome in your own UI (the success text or a toast), not through the confetti.

## See also

- [DSSlideToConfirm](DSSlideToConfirm.md)
- [DSToast](DSToast.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
