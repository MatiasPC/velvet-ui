# dsStretchyHeader

A hero header for the top of a detail screen (a profile, a trip, an album, a recipe). Pull the page down past the top and the header grows to fill the gap instead of leaving an empty band; scroll up and it trails at half speed inside its own frame, so the content below seems to slide over it.

<!-- GIF pending: ![dsStretchyHeader](../media/DSStretchyHeader.gif) -->

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSStretchyHeader.swift`](../../Sources/VelvetUI/Animation/DSStretchyHeader.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(style: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

Put `.dsStretchyHeader()` on the **first** view inside a vertical `ScrollView`, give it a fixed height, and let the scroll view run under the status bar:

```swift
import VelvetUI

struct TripScreen: View {
    @DSThemed private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Rectangle().fill(theme.accent)
                    Text("Weekend in Lisbon")
                        .ds(.title1, color: theme.onAccent)
                        .padding(DSSpacing.lg)
                }
                .frame(height: 320)
                .dsStretchyHeader()

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    DSCard { Text("Check-in · Friday, from 15:00").ds(.body) }
                    DSCard { Text("Check-out · Monday, until 11:00").ds(.body) }
                }
                .dsScreenPadding()
                .padding(.vertical, DSSpacing.xl)
            }
        }
        .ignoresSafeArea(edges: .top)
        .dsBackdrop()
    }
}
```

A photo works the same way: `Image("lisbon").resizable().scaledToFill().frame(height: 320).dsStretchyHeader()`. Anything that should overhang the header, such as an avatar half over its bottom edge, goes in an `.overlay` **after** the modifier, because the header clips to its frame:

```swift
Rectangle()
    .fill(theme.accent)
    .frame(height: 240)
    .dsStretchyHeader(parallax: false)
    .overlay(alignment: .bottomLeading) {
        DSAvatar(name: "Ada Lovelace", size: 72)
            .offset(y: DSSpacing.xxxl)
            .padding(.leading, DSSpacing.lg)
    }
```

## Parameters

`func dsStretchyHeader(parallax: Bool = true) -> some View`

| Parameter | Default | What it does |
|---|---|---|
| `parallax` | `true` | While scrolling up, the header travels at `1 - DSMotion.stretchyHeaderParallax` (0.5) of the scroll speed inside its frame. `false` scrolls it normally; the stretch stays. |

## Behavior

- **Stretch:** on overscroll the header scales by `(height + pull) / height`, anchored at the bottom, so it grows by exactly the pull and its top edge stays pinned to the top of the scroll view.
- **Parallax:** a downward offset of half the scrolled distance, applied inside a clip, so the header never slides out of its frame and under the content that follows.
- Both are render-only `visualEffect` transforms computed from the header's frame in the scroll view: no state, no `GeometryReader`, nothing reflows and the content below never moves.
- The effect is measured from the top of the scroll view. A header further down the page, or in a scroll view that keeps a top inset, would read as "pulled" and sit enlarged; keep it first and use `.ignoresSafeArea(edges: .top)`. For that reason it doesn't go inside `DSScreen`, which adds top padding: use a `ScrollView` with `.dsBackdrop()`.
- Scroll-coupled and ambient, so it fires no haptic.

## Accessibility

- Under Reduce Motion the parallax rests (the header scrolls with the page). The stretch stays: it follows the finger 1:1 and replaces the empty rubber-band gap, rather than adding motion of its own.
- It does not change what VoiceOver reads or the order of the elements. Give a decorative hero image `.accessibilityHidden(true)`, or a real `accessibilityLabel` when it carries meaning.
- Keep title text on the header at a size and color that stay legible when it scales (`theme.onAccent` on an accent fill, or a scrim behind text on a photo).

## See also

- [dsScrollReveal](DSScrollReveal.md) for scroll-coupled rows and cards
- [Motion](Motion.md) for the other ambient modifiers
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
