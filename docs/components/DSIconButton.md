# DSIconButton

An icon-only button, with no background, that shrinks under your thumb and ticks a light haptic. Use it for toolbar-style actions like share, favorite and more.

![DSIconButton](../media/DSIconButton.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSButton.swift`](../../Sources/VelvetUI/Components/DSButton.swift)

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

struct IconButtonDemo: View {
    var body: some View {
        DSScreen(backdrop: true) {
            HStack(spacing: DSSpacing.md) {
                DSIconButton(icon: "square.and.arrow.up", accessibilityLabel: "Share") { }
                DSIconButton(icon: "heart", haptic: .medium, accessibilityLabel: "Favorite") { }
                DSIconButton(icon: "ellipsis", size: 36, accessibilityLabel: "More options") { }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `icon` | `String` | required | SF Symbol name. |
| `size` | `CGFloat` | `44` | Width and height of the square tappable area in points. The symbol is drawn at 40% of it. |
| `color` | `Color?` | `nil` | Icon color. Defaults to the palette's primary text color. |
| `haptic` | `DSHapticStyle` | `.light` | Haptic fired on tap. |
| `accessibilityLabel` | `String?` | `nil` | What VoiceOver reads, e.g. "Share". When nil, VoiceOver falls back to the SF Symbol's own description. |
| `action` | `() -> Void` | required | Called on tap (trailing closure). |

`DSIconButton` lives in `DSButton.swift`.

## Variants

There are no style variants; adjust `size`, `color` and `haptic`:

```swift
DSIconButton(icon: "trash", size: 52, color: Color.red, haptic: .warning, accessibilityLabel: "Delete") { }
```

## Behavior

- Press uses the stronger icon press scale (shrinks more than a text button) with the shared press spring.
- A `.light` haptic fires on tap by default.

## Accessibility

- The button has no visible text, so always pass `accessibilityLabel:` (e.g. "Share"). Without it VoiceOver falls back to the SF Symbol's own description, which is often unhelpful (for example "ellipsis").
- You can also set it from outside with `.accessibilityLabel("Share")`.
- Keep `size` at 44pt or more for a comfortable touch target.

## See also

- [DSButton](DSButton.md)
- [DSToggle](DSToggle.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
