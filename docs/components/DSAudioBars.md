# DSAudioBars

An equaliser for live audio: a row of capsule bars that ripple while sound is playing or being recorded, follow an optional live level, and ease down to a flat line when idle.

<!-- GIF pending: ![DSAudioBars](../media/DSAudioBars.gif) -->

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSAudioBars.swift`](../../Sources/VelvetUI/Components/DSAudioBars.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(style: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

```swift
import VelvetUI

struct ListeningDemo: View {
    @State private var isListening = true
    @State private var micLevel = 0.5   // feed this from your recorder's meter

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                DSCard {
                    HStack(spacing: DSSpacing.sm) {
                        DSAudioBars(isActive: isListening, level: micLevel, barCount: 7)
                        Text(isListening ? "Listening…" : "Paused").ds(.callout)
                        Spacer()
                    }
                }
                DSToggle("Listening", isOn: $isListening)
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

`DSAudioBars(isActive:level:barCount:barWidth:spacing:height:color:)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `isActive` | `Bool` | `true` | Ripple while true; ease down to a flat line while false. |
| `level` | `Double?` | `nil` | Live level `0...1`, the amplitude of the ripple. `nil` ripples at full amplitude. Out-of-range values are clamped. |
| `barCount` | `Int` | `5` | Number of bars (at least 1). |
| `barWidth` | `CGFloat` | `DSSpacing.xxs` | Width of each bar. |
| `spacing` | `CGFloat` | `DSSpacing.xxs` | Gap between bars. |
| `height` | `CGFloat` | `DSSpacing.xl` | Height of the tallest bar. |
| `color` | `Color?` | `nil` | Bar fill. Defaults to the theme accent. |

## Variants

```swift
HStack(spacing: DSSpacing.xl) {
    DSAudioBars(barCount: 3)
    DSAudioBars(barCount: 7, height: DSSpacing.xxl)
    DSAudioBars(barCount: 5, color: DSColors.success)
}
```
Few and short for a list row, many and tall for a voice screen.

## Behavior

- Heights come from one clock, with a phase offset per bar, so the row ripples rather than pulses.
- Going between active and idle, and between levels, eases with the system's eased curves (not a spring: nothing was touched). Raw meter readings are fine to pass; a level change is smoothed over about a quarter of a second.
- With a `level`, the bars swell with it and sit at the resting line at `0`. Without one they ripple at full amplitude.
- The clock is paused when the bars are idle, when the view is not on screen (it disappeared, for example behind a pushed screen), when the app is not active, and under Reduce Motion. A paused indicator costs no CPU. In a plain `ScrollView` a row that is only scrolled away may still count as on screen; lists and lazy stacks unload it.
- Reduce Motion: no ripple. Idle bars are a flat line; active bars rest on a symmetric bell, and `level` is ignored.

## Accessibility

- The bars are decorative and hidden from VoiceOver. Put a label next to them ("Listening…") so the state is also announced.

## See also

- [DSThinkingIndicator](DSThinkingIndicator.md) for "the assistant is working"
- [Motion](Motion.md) for ambient effects on any view
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
