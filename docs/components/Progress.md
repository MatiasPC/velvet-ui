# Progress

Progress indicators that animate to their value instead of jumping: ring, bar, gradient bar, step dots, a counting number and a skeleton shimmer.

![Progress](../media/Progress.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSProgressAnimation.swift`](../../Sources/VelvetUI/Animation/DSProgressAnimation.swift)

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

struct ProgressDemo: View {
    @State private var progress = 0.35
    @State private var step = 2

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                DSCircularProgress(progress: progress, size: 96)
                DSAnimatedNumber(value: progress * 100, style: .displayMedium)
                DSLinearProgress(progress: progress)
                DSGradientProgress(progress: progress)
                DSStepProgress(currentStep: step, totalSteps: 4)

                DSButton("Advance", isFullWidth: true) {
                    progress = min(progress + 0.15, 1)
                    step = min(step + 1, 4)
                }

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                        .fill(Color.gray.opacity(0.25))
                        .frame(height: 16)
                        .dsShimmer()
                    RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 160, height: 16)
                        .dsShimmer()
                }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

### DSCircularProgress

| Parameter | Type | Default | Description |
|---|---|---|---|
| `progress` | `Double` | required | 0 to 1, clamped. |
| `lineWidth` | `CGFloat` | `6` | Ring thickness. |
| `size` | `CGFloat` | `80` | Diameter. |
| `primaryColor` | `Color?` | `nil` | Ring color. Defaults to the theme accent. |
| `trackColor` | `Color?` | `nil` | Track color. Defaults to the palette border color. |

### DSLinearProgress

| Parameter | Type | Default | Description |
|---|---|---|---|
| `progress` | `Double` | required | 0 to 1, clamped. |
| `height` | `CGFloat` | `6` | Bar height. |
| `primaryColor` | `Color?` | `nil` | Fill color. Defaults to the theme accent. |
| `trackColor` | `Color?` | `nil` | Track color. Defaults to the palette border color. |

### DSGradientProgress

| Parameter | Type | Default | Description |
|---|---|---|---|
| `progress` | `Double` | required | 0 to 1, clamped. |
| `height` | `CGFloat` | `8` | Bar height. |
| `colors` | `[Color]?` | `nil` | Gradient stops, left to right. Defaults to the theme gradient's stops. |
| `trackColor` | `Color?` | `nil` | Track color. Defaults to the palette border color. |

### DSStepProgress

| Parameter | Type | Default | Description |
|---|---|---|---|
| `currentStep` | `Int` | required | Number of completed steps (segments filled). |
| `totalSteps` | `Int` | required | Number of segments. |
| `activeColor` | `Color?` | `nil` | Completed segments. Defaults to the theme accent. |
| `inactiveColor` | `Color?` | `nil` | Remaining segments. Defaults to the palette border color. |

### DSAnimatedNumber

| Parameter | Type | Default | Description |
|---|---|---|---|
| `value` | `Double` | required | The number to count to. |
| `format` | `String` | `"%.0f"` | `String(format:)` format, for example `"%.1f"`. |
| `style` | `DSTextStyle` | `.displayLarge` | Text style (monospaced digits). |

### `.dsShimmer()`

`func dsShimmer() -> some View`, no parameters. A soft highlight sweeps across the view in a 1.5s linear loop. It is width-independent, so it works on any skeleton shape.

## Variants

- **Determinate**: ring, bar and gradient bar for a known fraction. `DSStepProgress` for a wizard or onboarding (4pt segments).
- **Counting**: `DSAnimatedNumber` with `.numericText` content transition for scores and totals.
- **Skeleton**: `.dsShimmer()` over placeholder shapes while content loads. `DSImageCard` uses it for its image placeholder.
- For indeterminate work with no fraction, use [DSThinkingIndicator](DSThinkingIndicator.md).

## Behavior

- The ring and both bars start at 0 and animate to `progress` on appear (`DSAnimation.progress`, 0.8s ease in-out), then animate again whenever `progress` changes. `DSAnimatedNumber` does the same with `DSAnimation.counting` (1s ease out).
- `DSStepProgress` does not start at 0: it draws `currentStep` filled segments at once and staggers the color change when `currentStep` changes, with `DSAnimation.stagger(index:)`.
- No haptics: these are status displays, not controls.
- `.dsShimmer()` does not start under Reduce Motion: the view simply stays static. The progress and counting animations are plain value transitions.

## Accessibility

- The progress views do not set an accessibility value of their own. Add one from outside so VoiceOver can report it, for example `.accessibilityLabel("Upload").accessibilityValue("\(Int(progress * 100)) percent")`.
- `DSAnimatedNumber` is text, so VoiceOver reads the number as it counts; it uses `.dsTextStyle(_:)` and scales with Dynamic Type.
- Shimmer placeholders are decorative; hide them with `.accessibilityHidden(true)` or label the container ("Loading").

## See also

- [DSThinkingIndicator](DSThinkingIndicator.md) for indeterminate work
- [Motion](Motion.md) for ambient effects
- [DSImageCard](DSCard.md) (shimmer placeholder)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
