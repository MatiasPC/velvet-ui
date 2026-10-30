# DSMarquee

Content that scrolls horizontally in a seamless loop — but only when it is too wide to fit. A "now playing" line, a long title, a ticker of stats: text that would otherwise truncate keeps moving so all of it can be read. Content that already fits stays put.

![DSMarquee](../media/DSMarquee.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSMarquee.swift`](../../Sources/VelvetUI/Components/DSMarquee.swift)

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

struct NowPlaying: View {
    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Now playing").ds(.overline, color: DSColors.textSecondary)

                DSMarquee {
                    Text("Midnight City · M83 · Hurry Up, We're Dreaming").ds(.callout)
                }

                // Any content, not just text — it scrolls as one line.
                DSMarquee(velocity: 28) {
                    HStack(spacing: DSSpacing.xs) {
                        DSBadge("LIVE", variant: .filled)
                        Text("Breaking news scrolls by, in full").ds(.footnote)
                    }
                }
            }
            .dsScreenPadding()
        }
    }
}
```

Keep the content to a single line (text, a badge, a small row). The marquee measures that line and scrolls it only when it is wider than the space it has.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `velocity` | `CGFloat` | `40` | Scroll speed in points per second. Linear, so the pace reads constant for any length. `0` disables scrolling. |
| `spacing` | `CGFloat` | `DSSpacing.xxxl` (40) | Gap between the end of one copy and the start of the next in the loop. |
| `fade` | `CGFloat` | `DSSpacing.lg` (20) | Width of the soft edge fade on each side. Pass `0` for hard edges. |
| `content` | `() -> Content` | required | The content to scroll, as a trailing `@ViewBuilder` closure. |

## Behavior

- **Scrolls only on overflow.** If the content fits the available width it is shown static and left-aligned, with no motion and no fade.
- **Seamless loop.** Two copies of the content are laid end to end with `spacing` between them, translated left by exactly one copy's width plus the gap, then wrapped — so the join never shows.
- **Edge fades.** A gradient mask (not a border) softens both edges while scrolling, hinting that the line continues past them. A static overflow fades only the trailing edge.
- **No haptics.** The marquee is ambient, not interactive.
- **Reduce Motion:** no scrolling. The content is shown static from its start with a trailing fade, so it is clearly truncated rather than frozen mid-scroll.

## Accessibility

- The content is exposed as a single combined element, so VoiceOver reads the whole line at once regardless of where the scroll happens to be. The second, looping copy and the hidden measuring copy are excluded from accessibility.
- Text styled with `.ds(_:)` scales with Dynamic Type; the line simply grows wider and scrolls further.
- Prefer a marquee for supplementary, glanceable copy (a track title, a status line). Don't put text a user must act on only inside a moving line.

## See also

- [DSTypewriterText](DSTypewriterText.md)
- [DSNumberTicker](DSNumberTicker.md)
- [Motion](Motion.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
