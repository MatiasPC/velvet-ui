# DSExpandableText

A block of copy that collapses to a few lines and springs open on tap, with a rotating chevron and a crossfading **Show more** / **Show less** affordance. For product descriptions, reviews, bios and terms — anywhere a long paragraph would otherwise push everything else off the screen or get truncated with no way back.

![DSExpandableText](../media/DSExpandableText.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSExpandableText.swift`](../../Sources/VelvetUI/Components/DSExpandableText.swift)

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

struct AboutCard: View {
    var body: some View {
        DSScreen(backdrop: true) {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("About").ds(.title3)
                    DSExpandableText(
                        "Velvet UI is a small, opinionated SwiftUI library: frosted glass over a gradient theme, spring motion on everything you touch, and haptics that make the interface feel alive.",
                        lineLimit: 3
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .dsScreenPadding()
        }
    }
}
```

The toggle appears only when the copy is actually clipped: pass short text and `DSExpandableText` renders it with no affordance.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_ text` | `String` | required | The copy to show. Read in full by VoiceOver even while clipped. |
| `lineLimit` | `Int` | `3` | Lines shown while collapsed. |
| `expandLabel` | `String` | `"Show more"` | The reveal affordance. |
| `collapseLabel` | `String` | `"Show less"` | The collapse affordance. |
| `style` | `DSTextStyle` | `.body` | Text style for the copy. |
| `color` | `Color?` | `nil` | Copy color. `nil` follows the theme (`textPrimary`). |
| `haptic` | `DSHapticStyle` | `.light` | Feedback fired on toggle. |

## Variants

- **Default**: `DSExpandableText(longCopy)` — three lines, then "Show more".
- **Custom clamp and labels**: `DSExpandableText(longCopy, lineLimit: 2, expandLabel: "Read more", collapseLabel: "Read less")`.
- **Secondary copy**: `DSExpandableText(longCopy, style: .callout, color: theme.palette.textSecondary)`.

## Behavior

- Truncation is measured, not guessed: two off-screen copies of the text (one clamped to `lineLimit`, one unbounded) are laid out at the real text width with `onGeometryChange`, and the toggle shows only when the unbounded copy is taller. The result never flips mid-reveal because neither probe depends on the expanded state.
- Expanding and collapsing animate the height with `DSAnimation.springSmooth`; the chevron rotates 180° and the label crossfades with `.contentTransition(.opacity)`.
- The configurable haptic (`.light` by default) fires on each toggle.
- Reduce Motion: the reveal is instant (no spring, no rotation sweep); the text and toggle still work.
- The text style applied through `.ds(_:)` scales with Dynamic Type, and the measurement re-runs at the new size.

## Accessibility

- The copy is a standard `Text`, so VoiceOver reads it in full whether collapsed or expanded.
- The toggle is a button labelled with its current action ("Show more" / "Show less"); the chevron is decorative.

## See also

- [DSTypewriterText](DSTypewriterText.md)
- [DSCard](DSCard.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
