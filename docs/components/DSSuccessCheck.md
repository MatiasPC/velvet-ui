# DSSuccessCheck

An animated success seal: the ring strokes itself, the disc fills, the checkmark draws, and the whole thing pops once with a soft halo and a success haptic on the same beat.

![DSSuccessCheck](../media/DSSuccessCheck.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSSuccessCheck.swift`](../../Sources/VelvetUI/Components/DSSuccessCheck.swift)

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

struct SuccessCheckDemo: View {
    @State private var isPaid = false

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                DSSuccessCheck(isComplete: isPaid, size: 96, accessibilityLabel: "Payment sent")
                    .padding(DSSpacing.md)
                Text(isPaid ? "Payment sent" : "Ready to pay").ds(.title2)
                DSButton(isPaid ? "Reset" : "Pay $24.00", isFullWidth: true) {
                    isPaid.toggle()
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
| `isComplete` | `Bool` | required | Plays the animation when it becomes `true`. Fades the seal out when `false`. |
| `size` | `CGFloat` | `64` | Diameter of the seal. |
| `color` | `Color?` | `nil` | Ring and disc fill. Defaults to the theme's success color. The checkmark uses the palette's text-on-primary color. |
| `haptic` | `DSHapticStyle?` | `.success` | Fired as the check completes. `nil` for none. |
| `accessibilityLabel` | `String` | `"Done"` | What VoiceOver says, and announces when the seal completes. |

## Variants

```swift
HStack(spacing: DSSpacing.lg) {
    DSSuccessCheck(isComplete: true, size: 32)
    DSSuccessCheck(isComplete: true, size: 48, color: DSColors.info, haptic: nil)
}
```
The seal is only a fill and two strokes, so it works at any size from a list row up to a hero.

## Behavior

- The animation plays when `isComplete` becomes `true`, and once on first appear if it already is. A view that re-appears already complete (tab switch, navigating back) shows the finished seal at rest, with no haptic or announcement. It takes about 0.9 seconds.
- Order: the ring strokes itself, the disc fills behind it, then the check draws. A single spring pop peaks as the check finishes, together with one soft halo that expands and fades.
- The haptic fires at that peak, not at the start.
- When `isComplete` goes back to `false` the seal fades out quietly. Setting it to `true` again replays the animation.
- The halo extends past `size`; leave a little room around the seal.
- Reduce Motion: no strokes and no pop. The finished seal crossfades in, and the haptic still fires.

## Accessibility

- While complete, the seal is one image element labelled with your `accessibilityLabel`. While not complete it is hidden from VoiceOver.
- When it completes, the label is announced.
- Give it a label that says what happened ("Payment sent") rather than the default.

## See also

- [Progress](Progress.md) for work that is still running
- [Motion](Motion.md) for ambient effects
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
