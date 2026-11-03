# DSBadge

Compact pill labels for status and categories, plus a notification count badge that hides itself at zero and caps at 99+.

![DSBadge](../media/DSBadge.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSBadge.swift`](../../Sources/VelvetUI/Components/DSBadge.swift)

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

struct BadgeDemo: View {
    @State private var unread = 3

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                HStack(spacing: DSSpacing.xs) {
                    DSBadge("Beta")
                    DSBadge("Pro", variant: .filled)
                    DSBadge("Draft", variant: .outline)
                    DSBadge("Live", color: .green)
                }

                HStack(spacing: DSSpacing.md) {
                    Image(systemName: "bell.fill")
                        .font(.title)
                        .overlay(alignment: .topTrailing) {
                            DSCountBadge(count: unread)
                                .offset(x: DSSpacing.xs, y: -DSSpacing.xs)
                        }
                    DSBadge("Mark all read", variant: .soft)
                        .onTapGesture { unread = 0 }
                }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

### DSBadge

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_ text` | `String` | required | The label (unlabeled first argument). |
| `color` | `Color?` | `nil` | Fill for `.filled`, tint for `.soft` and `.outline`. Defaults to the theme accent. |
| `variant` | `DSBadgeVariant` | `.soft` | `.filled`, `.soft` or `.outline`. |

### DSCountBadge

| Parameter | Type | Default | Description |
|---|---|---|---|
| `count` | `Int` | required | Number to show. Renders nothing at 0 or below; shows `99+` above 99. |
| `color` | `Color?` | `nil` | Fill color. Defaults to the palette's error color. |

## Variants

| Variant | Default look | With a custom `color` |
|---|---|---|
| `.soft` (default) | Accent at 12% fill, `theme.ink` text | Color at 12% fill, color text |
| `.filled` | Accent fill, `theme.onAccent` text | Color fill, `textOnPrimary` text |
| `.outline` | No fill, 1pt `theme.ink` outline and text | Color outline and text |

`DSCountBadge` is always a filled capsule with `textOnPrimary` text, at least `DSSpacing.lg` square.

## Behavior

- Static components: no motion and no haptics. Pair them with `.dsPopIn()` or `.dsBreathe(.subtle)` (see [Motion](Motion.md)) if you want life.
- `DSCountBadge` removes itself from the layout when `count` is 0, so you can bind it straight to a model value.

## Accessibility

- `DSBadge` and `DSCountBadge` are plain text, so VoiceOver reads the label or the number as shown (`99+` is read as written). Add context from outside, for example `.accessibilityLabel("3 unread notifications")` on the count badge or on the view it decorates.
- Dynamic Type: both badges keep a fixed size for now (fixed-size fonts from the `.buttonSmall` / `.badge` text styles); they do not grow with the user's text size. Keep badge text short.

## See also

- [DSAvatar](DSAvatar.md) for identity
- [DSListCell](DSListCell.md) for badges in trailing slots
- [DSCard](DSCard.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
