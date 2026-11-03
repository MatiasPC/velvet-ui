# DSSkeleton

Loading placeholders: a shimmering block you compose by hand, and a `.dsSkeleton(_:)` modifier that turns a real view into its own placeholder so the loading layout can't drift from the loaded one.

![DSSkeleton](../media/DSSkeleton.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSSkeleton.swift`](../../Sources/VelvetUI/Components/DSSkeleton.swift)

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

struct SkeletonDemo: View {
    @State private var isLoading = true

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                // Hand-built placeholder
                HStack(spacing: DSSpacing.sm) {
                    DSSkeleton.circle(DSSpacing.huge)
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        DSSkeleton(width: 140)
                        DSSkeleton(width: 90)
                    }
                }

                // The real view, shown as its own placeholder while loading
                HStack(spacing: DSSpacing.sm) {
                    DSAvatar(name: "Ada Lovelace", size: DSSpacing.huge)
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text("Ada Lovelace").ds(.title3)
                        Text("Analyst, mathematician").ds(.callout)
                    }
                }
                .dsSkeleton(isLoading)

                DSToggle("Loading", isOn: $isLoading)
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

`DSSkeleton(width:height:cornerRadius:)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `width` | `CGFloat?` | `nil` | Fixed width. `nil` fills the available width. |
| `height` | `CGFloat` | `DSSpacing.sm` | Block height. |
| `cornerRadius` | `CGFloat` | `DSRadius.xs` | Corner radius. |

`DSSkeleton.circle(_ diameter:)` makes a round block, e.g. for an avatar.

`View.dsSkeleton(_ isLoading: Bool)` takes only the loading flag.

## Variants

```swift
VStack(alignment: .leading, spacing: DSSpacing.xs) {
    DSSkeleton(height: 160, cornerRadius: DSRadius.surface)
    DSSkeleton(height: DSSpacing.md)
    DSSkeleton(width: 120)
}
```
A feed-style block: image, title line, short subtitle.

## Behavior

- `DSSkeleton` is a block in the wash colour (on a backdrop) or the palette border colour (elsewhere), with a shimmer sweep.
- `.dsSkeleton(true)` redacts the view as placeholder shapes of its own layout, pulses its opacity gently between full and half (a 3.6 s cycle sampled from a timeline, so it stops the moment loading ends), and blocks touches.
- When `isLoading` goes false the redaction lifts with a short fade.
- The wrapped view keeps its identity when the flag flips: its `@State`, `.task` and `.onAppear` are not reset or run twice. That is why the modifier pulses instead of sweeping: a sweep needs a second copy of the content.
- Reduce Motion: no shimmer and no pulse. Placeholders rest at full opacity.

## Accessibility

- `DSSkeleton` blocks are hidden from VoiceOver.
- While `.dsSkeleton(true)` is active the view reads as one element labelled "Loading". When it ends, the real content is announced normally.

## See also

- [DSEmptyState](DSEmptyState.md)
- [DSCard](DSCard.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
