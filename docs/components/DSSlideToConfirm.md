# DSSlideToConfirm

A slide-to-confirm gate for irreversible actions like payments. The label dissolves under your finger, motes trail the knob, and the result lands with a success or refusal haptic.

![DSSlideToConfirm](../media/DSSlideToConfirm.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSSlideToConfirm.swift`](../../Sources/VelvetUI/Components/DSSlideToConfirm.swift)

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

struct SlideToConfirmDemo: View {
    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                Text("Pay $24.00").ds(.title2)
                DSSlideToConfirm("Slide to pay", confirmedLabel: "Paid") {
                    try await chargeCard(amountCents: 2400)
                }
            }
            .dsScreenPadding()
        }
    }

    // Stand-in for your payment call. Throwing re-opens the slider for a retry.
    private func chargeCard(amountCents: Int) async throws {
        try await Task.sleep(for: .seconds(1))
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `label` | `String` | required | Text on the track (unlabeled first argument). |
| `icon` | `String` | `"chevron.right"` | SF Symbol on the knob. |
| `confirmedLabel` | `String` | `"Confirmed"` | Text shown once the action succeeds. |
| `accent` | `Color?` | `nil` | Knob fill. Defaults to the theme accent. The trail is always the theme gradient. |
| `finish` | `DSSlideFinish` | `.settle` | What happens after success: `.settle` or `.morphAndVanish`. |
| `onConfirm` | `() async throws -> Void` | required | Runs when the slide commits. Throwing counts as a refusal. |

A plain synchronous `() -> Void` closure also compiles, since it is a subtype of `() async throws -> Void`.

## Variants

- `.settle` (default): the control stays in place showing a check and `confirmedLabel`. Right for destructive confirmations where the screen doesn't change.
- `.morphAndVanish`: the pill collapses to a circle, resolves, then dissolves. It keeps its slot so your layout doesn't jump; swap in your own success state.

```swift
struct SlideToConfirmVanishDemo: View {
    @State private var paid = false

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                if paid {
                    Text("Payment received").ds(.title2)
                } else {
                    DSSlideToConfirm("Slide to pay", finish: .morphAndVanish) {
                        try await Task.sleep(for: .seconds(1))
                        paid = true
                    }
                }
            }
            .dsScreenPadding()
        }
    }
}
```

There is no reset API; re-mount with `.id(attempt)` to run it again.

## Behavior

- The knob follows your finger 1:1, with soft detent ticks along the track. Crossing 75% of the travel fires a rigid haptic once.
- Release before the threshold and the knob springs back with a light haptic.
- While `onConfirm` runs a spinner shows for at least half a second (applied after the closure returns, never padding a slow call). Success fires a success haptic.
- If `onConfirm` throws, an error haptic fires and the control re-opens for a retry. It never words the failure; telling the user why is your job.
- Reduce Motion: the per-letter label stagger becomes a single fade. Reduce Motion or Reduce Transparency removes the motes.

## Accessibility

- One element, read as a button with the `label` you passed and the hint "Double-tap to confirm". VoiceOver users confirm with a double-tap, no dragging.
- Value is "Processing" while `onConfirm` runs, then the `confirmedLabel` once done.
- Override the label with `.accessibilityLabel("Pay 24 dollars")` on the outside.
- Dynamic Type: the label uses `.ds(.button)` and scales, but the track is a fixed 56pt tall, so long labels at large sizes will clip.

## See also

- [DSButton](DSButton.md)
- [DSToggle](DSToggle.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
