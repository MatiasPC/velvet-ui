# DSCard

A glass surface for grouping content: thin material, a 1pt specular edge and a soft shadow, with a press-to-scale interactive variant and an image card for media.

![DSCard](../media/DSCard.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSCard.swift`](../../Sources/VelvetUI/Components/DSCard.swift)

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

struct CardDemo: View {
    @State private var opened = false

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.md) {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("This week").ds(.title2)
                        Text("4 sessions · 2 h 35 min").ds(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSInteractiveCard(action: { opened.toggle() }) {
                    HStack {
                        Text(opened ? "Opened" : "Open plan").ds(.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }

                DSImageCard(
                    title: "Cabin in the woods",
                    subtitle: "$120 / night",
                    badge: "New"
                )
            }
            .dsScreenPadding()
        }
    }
}
```

Glass looks best over `.dsBackdrop()` or `DSScreen(backdrop: true)`. Without a backdrop `.elevated` still reads as a plain elevated card.

## Parameters

### DSCard

| Parameter | Type | Default | Description |
|---|---|---|---|
| `style` | `DSCardStyle` | `.elevated` | Surface treatment: `.flat`, `.elevated`, `.outlined`. |
| `padding` | `CGFloat` | `DSSpacing.md` | Inner padding around the content. |
| `cornerRadius` | `CGFloat` | `DSRadius.card` | Corner radius (20). Use `DSRadius.surface` for nested cards. |
| `content` | `@ViewBuilder () -> Content` | required | The card's content (trailing closure). |

### DSInteractiveCard

Same as `DSCard`, plus a haptic and an action. Parameters in order:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `style` | `DSCardStyle` | `.elevated` | Surface treatment. |
| `padding` | `CGFloat` | `DSSpacing.md` | Inner padding. |
| `cornerRadius` | `CGFloat` | `DSRadius.card` | Corner radius. |
| `haptic` | `DSHapticStyle` | `.light` | Haptic fired on tap. |
| `action` | `() -> Void` | required | Called on tap, after the haptic. |
| `content` | `@ViewBuilder () -> Content` | required | The card's content. |

### DSImageCard

| Parameter | Type | Default | Description |
|---|---|---|---|
| `imageURL` | `URL?` | `nil` | Remote image, loaded with `AsyncImage`. |
| `imageName` | `String?` | `nil` | Asset-catalog image. Wins over `imageURL` when both are set. |
| `title` | `String` | required | Up to two lines, `.title3`. |
| `subtitle` | `String?` | `nil` | One line, `.callout`, secondary color. |
| `badge` | `String?` | `nil` | Pill drawn on the image's top-leading corner (accent fill). |
| `cornerRadius` | `CGFloat` | `DSRadius.card` | Corner radius of the image area. |

## Variants

| `DSCardStyle` | Surface | Edge | Shadow |
|---|---|---|---|
| `.elevated` (default) | Thin glass | yes | `.md` |
| `.outlined` | Thicker, denser glass | yes | none |
| `.flat` | Translucent wash (`theme.subtleFill`) | no | none |

`.flat` is for grouping inside another surface. There are no borders: separation comes from material density, the edge highlight and shadow.

```swift
import VelvetUI

struct CardStylesDemo: View {
    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.md) {
                DSCard(style: .outlined) {
                    Text("Denser glass, no shadow").ds(.body)
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Nested").ds(.title3)
                        DSCard(style: .flat, cornerRadius: DSRadius.surface) {
                            Text("Flat card inside an elevated one").ds(.callout)
                        }
                    }
                }
            }
            .dsScreenPadding()
        }
    }
}
```

## Behavior

- `DSInteractiveCard` scales to `DSPress.scale` (0.96) while pressed using `DSPress.animation`, and fires `haptic` (default `.light`) on tap.
- `DSImageCard` shows a shimmering placeholder until the image loads; the image gets the glass edge highlight.
- The shimmer placeholder stays still under Reduce Motion. Glass falls back to the plain background if there is no backdrop.

## Accessibility

- `DSCard` adds no accessibility semantics of its own: its content is read as written.
- `DSInteractiveCard` is a real `Button` (plain style), so VoiceOver reads the card's text content as the button label. Add `.accessibilityLabel("…")` or `.accessibilityHint("…")` on the outside when the visible text is not enough.
- `DSImageCard` has no built-in image description. Label it from outside, for example `.accessibilityLabel("Cabin in the woods, $120 per night")`.
- Text uses `.ds(_:)` styles, which scale with Dynamic Type; give card content room to grow.

## See also

- [DSListCell](DSListCell.md) for rows inside a card
- [DSBadge](DSBadge.md) for status labels
- [DSButton](../components.md#dsbutton) for actions
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
