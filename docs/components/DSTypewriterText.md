# DSTypewriterText

Text that types a phrase out character by character, holds it, erases it and moves on to the next, with a blinking caret. For hero headlines and empty states that need a little life.

![DSTypewriterText](../media/DSTypewriterText.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSTypewriterText.swift`](../../Sources/VelvetUI/Components/DSTypewriterText.swift)

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

struct TypewriterDemo: View {
    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Build something").ds(.largeTitle)
                DSTypewriterText(
                    ["that feels alive.", "with glass and springs.", "in an afternoon."],
                    style: .title1
                )

                DSTypewriterText(["Ready when you are."], style: .callout, loops: false)
            }
            .dsScreenPadding()
        }
    }
}
```

Keep phrases short enough to fit on one line: the view is single line and reserves the width of the widest phrase.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_ phrases` | `[String]` | required | Phrases to cycle through, in order. An empty array renders nothing. |
| `style` | `DSTextStyle` | `.title1` | Text style for the phrases. |
| `typingSpeed` | `TimeInterval` | `0.06` | Seconds per character while typing. |
| `erasingSpeed` | `TimeInterval` | `0.03` | Seconds per character while erasing. Should be faster than typing. |
| `holdDuration` | `TimeInterval` | `1.4` | Seconds a fully typed phrase stays before erasing. |
| `loops` | `Bool` | `true` | When `false`, stops on the last phrase fully typed (the caret keeps blinking). |
| `caretColor` | `Color?` | `nil` | Caret fill. Defaults to the theme accent. |

## Variants

- **Rotating headline**: several phrases with `loops: true`.
- **Type once**: `loops: false` types the last phrase and stays (the snippet's second view).
- **Speed**: raise `typingSpeed` for a calmer feel; the defaults are about 16 characters per second.

## Behavior

- Steps through grapheme clusters, so emoji and accented characters are never split.
- Driven by a cancellable `Task`: cancelled on disappear and restarted when `phrases` or Reduce Motion changes.
- The caret blinks in `caretColor`; it is a thin capsule sized to the text style.
- No haptics.
- Reduce Motion: no typing or erasing; the full phrase is shown, still cycling through the list, and the caret stays solid.

## Accessibility

- The view is one element labelled with the whole current phrase, so VoiceOver never reads a half-typed fragment. The caret is decorative.
- Because the label changes when the phrase changes, avoid putting it where VoiceOver users need stable text, such as the only copy of an instruction.
- The text style applied through `.ds(_:)` scales with Dynamic Type. Check that your widest phrase still fits on one line at large sizes.

## See also

- [DSThinkingIndicator](DSThinkingIndicator.md)
- [DSEmptyState](DSEmptyState.md)
- [Motion](Motion.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
