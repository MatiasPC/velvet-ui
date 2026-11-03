# DSTiltCard

A glass card that tips in 3D toward your finger as you drag, with a specular highlight that slides across the surface like light on glass, then springs back to rest on release.

<!-- GIF pending: ![DSTiltCard](../media/DSTiltCard.gif) -->

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSTiltCard.swift`](../../Sources/VelvetUI/Components/DSTiltCard.swift)

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

struct TiltDemo: View {
    var body: some View {
        DSScreen(backdrop: true) {
            VStack {
                DSTiltCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Image(systemName: "creditcard.fill").font(.title2)
                        Text("Velvet Card").ds(.title2)
                        Text("•••• •••• •••• 2048").ds(.numeric)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

`DSTiltCard(maxTilt:padding:cornerRadius:haptic:content:)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `maxTilt` | `Angle?` | `nil` | Peak rotation reached at the edge of the drag. `nil` is 12°. |
| `padding` | `CGFloat` | `DSSpacing.md` | Inner padding around the content. |
| `cornerRadius` | `CGFloat` | `DSRadius.card` | Corner radius of the glass surface. |
| `haptic` | `DSHapticStyle?` | `.soft` | Fired once when the touch begins. `nil` for none. |
| `content` | `() -> Content` | required | The card's content (trailing closure). |

## Variants

```swift
VStack(spacing: DSSpacing.lg) {
    // A wider tilt, no haptic
    DSTiltCard(maxTilt: .degrees(20), haptic: nil) {
        Text("Weekly streak").ds(.title3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Tighter corners, buttons inside keep working
    DSTiltCard(padding: DSSpacing.lg, cornerRadius: DSRadius.surface) {
        DSButton("Redeem", isFullWidth: true) {}
    }
}
```

## Behavior

- Dragging tips the card in 3D: horizontal drag rotates it around the vertical axis, vertical drag around the horizontal one, so the surface leans toward the finger. The tilt clamps at `maxTilt` once the drag passes ~120 pt from where it started.
- A specular sheen fades in with the tilt and slides across the glass, reading as light catching the glass rather than as a fill. It sits between the glass and the content, so text and icons keep full contrast. It rides the same white highlight language as `DSWash.edge` and `dsEdgeSweep`, a little stronger on light themes.
- The shadow deepens from `.lg` to `.xl` while the card is held.
- Release (or a cancelled touch) springs the card flat with `DSAnimation.springGentle`. While the finger is down the tilt follows it 1:1 with no animation, so it never lags.
- A `.soft` haptic fires once when the touch begins.
- The gesture is simultaneous: a card inside a `ScrollView` does not block scrolling (if the scroll takes over the touch, the card springs flat), and controls inside the card keep their taps.
- macOS: it follows a mouse drag in the same way. There is no haptic.

## Accessibility

- One container element (`.accessibilityElement(children: .contain)`): the content's own elements are read as they are, since the tilt is purely visual.
- **Reduce Motion:** the card never rotates, the shadow does not lift and the sheen does not slide. It rests as an ordinary glass surface and, while held, a still sheen fades in, so a touch still gets visible feedback without movement. The haptic still fires.
- **Reduce Transparency:** the glass surface falls back to a solid fill via `dsSurface`.
- Dynamic Type: all text uses `.ds(_:)` and scales with the user's text size.

## See also

- [DSCard](DSCard.md)
- [DSInteractiveCard](DSCard.md)
- [Motion primitives](Motion.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
