# DSThinkingIndicator

An "the assistant is working" indicator: an animated SF Symbol next to a phrase that cycles and assembles letter by letter, for states where a spinner reads as frozen and a progress bar would be a lie.

![DSThinkingIndicator](../media/DSThinkingIndicator.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSThinkingIndicator.swift`](../../Sources/VelvetUI/Components/DSThinkingIndicator.swift)

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

struct ThinkingDemo: View {
    @State private var isWorking = true

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                DSCard {
                    if isWorking {
                        DSThinkingIndicator(
                            phrases: ["Reading your notes", "Drafting a summary", "Almost there"]
                        )
                    } else {
                        Text("Summary ready").ds(.body)
                    }
                }
                .dsEdgeSweep(isActive: isWorking)

                DSButton(isWorking ? "Stop" : "Run again", variant: .secondary) {
                    isWorking.toggle()
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
| `phrases` | `[String]` | `["Thinking", "Weighing options", "Almost there"]` | Cycled in order, looping. A single phrase disables cycling but still assembles once on appear. |
| `symbol` | `String` | `"sparkles"` | SF Symbol for the leading animated glyph. |
| `interval` | `TimeInterval` | `2.6` | Seconds each phrase stays before the next one assembles. |
| `tint` | `Color?` | `nil` | Letter color. Defaults to `theme.ink`. The symbol always uses the theme gradient. |

## Variants

- **Default**: sparkles plus three phrases.
- **Custom copy**: pass your own phrases, for example `["Reading your notes", "Drafting a summary"]`.
- **Custom symbol**: any SF Symbol with layers, such as `"wand.and.stars"`.
- **With an edge sweep**: put it in a `DSCard` with `.dsEdgeSweep(isActive:)` as in the snippet, so the surface itself looks busy.

## Behavior

- The symbol uses the system's `.breathe.byLayer` and `.variableColor.iterative` effects, filled with the theme gradient.
- The phrase follows a wall-clock schedule, so it never desyncs when the view is re-created, and assembles letter by letter using `DSAnimation.stagger(index:)`.
- The row reserves the width of the widest phrase, so nothing around it shifts.
- No haptics: it is a status indicator, not an interaction.
- Reduce Motion: the symbol effects turn off and letters stop staggering, but phrases keep cycling as a plain cross-fade, because the phrase is information, not decoration.

## Accessibility

- The row is one element whose label is the whole current phrase, never a half-assembled fragment. The symbol is hidden from VoiceOver.
- It carries the `.updatesFrequently` trait, so VoiceOver does not interrupt the user with every change.
- Override from outside with `.accessibilityLabel("Generating summary")` if the phrases are too playful.
- Text uses `.dsTextStyle(.footnote)` and scales with Dynamic Type.

## See also

- [Progress](Progress.md) for known fractions
- [DSTypewriterText](DSTypewriterText.md)
- [Motion](Motion.md) (`.dsEdgeSweep`)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
