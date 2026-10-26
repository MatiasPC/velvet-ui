# DSTiltCard

A glass card that tips in 3D toward your finger as you drag, with a specular highlight that slides across the surface like light on glass, then springs back to rest on release.

![DSTiltCard](../media/DSTiltCard.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSTiltCard.swift`](../../Sources/VelvetUI/Components/DSTiltCard.swift)

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

| Parameter | Type | Default | Description |
|---|---|---|---|
| `maxTilt` | `Angle` | `.degrees(12)` | Peak rotation reached at the edge of the drag. |
| `padding` | `CGFloat` | `DSSpacing.md` | Inner padding around the content. |
| `cornerRadius` | `CGFloat` | `DSRadius.card` | Corner radius of the glass surface. |
| `haptic` | `DSHapticStyle` | `.soft` | Fired once when the drag begins. |
| `content` | `() -> Content` | required | The card's content (trailing closure). |

## Behavior

- Dragging tips the card in 3D: horizontal drag rotates it around the vertical axis, vertical drag around the horizontal one, so the surface leans toward the finger. The tilt clamps at `maxTilt` once the drag passes ~120 pt from where it started.
- A specular sheen fades in with the tilt and slides across the glass, reading as light catching the surface rather than as a fill — the same white highlight language as `DSWash.edge` and `dsEdgeSweep`.
- On release the card springs flat with `DSAnimation.springGentle`; the resting shadow deepens from `.lg` to `.xl` while held.
- A `.soft` haptic fires once as the drag begins.

## Accessibility

- One container element (`.accessibilityElement(children: .contain)`): the content's own elements are read as they are, since the tilt is purely visual.
- **Reduce Motion:** the tilt and sheen are disabled and the card rests flat as an ordinary glass surface; the drag gesture is handed to its subviews so any controls inside keep working.
- **Reduce Transparency:** the glass surface falls back to a solid fill via `dsSurface`.
- Dynamic Type: all text uses `.ds(_:)` and scales with the user's text size.

## See also

- [DSCard](DSCard.md)
- [DSInteractiveCard](DSCard.md)
- [Motion primitives](Motion.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
