# DSHoldToConfirm

A press-and-hold confirmation. A ring charges around a glass pill while you keep your finger down; when it closes the pill fills with the accent, runs your action and settles on a check. Let go early and it springs back without running anything.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSHoldToConfirm.swift`](../../Sources/VelvetUI/Components/DSHoldToConfirm.swift)

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

struct HoldToConfirmDemo: View {
    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                Text("Delete account").ds(.title2)
                DSHoldToConfirm(
                    "Hold to delete",
                    icon: "trash",
                    confirmedLabel: "Deleted",
                    accent: DSColors.error
                ) {
                    try await deleteAccount()
                }
            }
            .dsScreenPadding()
        }
    }

    // Stand-in for your call. Throwing re-opens the control for a retry.
    private func deleteAccount() async throws {
        try await Task.sleep(for: .seconds(1))
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `label` | `String` | required | Text on the pill (unlabeled first argument). |
| `icon` | `String?` | `nil` | SF Symbol before the label while idle. |
| `confirmedLabel` | `String` | `"Confirmed"` | Text shown once the action succeeds. |
| `duration` | `Double` | `1.2` | Seconds the finger must stay down. Anything under 0.2 is raised to 0.2. |
| `accent` | `Color?` | `nil` | Ring and fill color. Defaults to the theme accent; pass a status color for a destructive hold. |
| `isFullWidth` | `Bool` | `true` | Stretch to the available width. |
| `onConfirm` | `() async throws -> Void` | required | Runs once the ring closes. Throwing counts as a refusal. |

`onConfirm` works exactly as it does on [DSSlideToConfirm](DSSlideToConfirm.md): a plain synchronous closure also compiles, the control spins for at least half a second while it runs, and the closure carries the latency and the outcome.

## Variants

There is one look; what changes is how long you hold and what the accent says.

```swift
struct HoldToConfirmVariantsDemo: View {
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            // A quick, compact hold.
            DSHoldToConfirm("Hold to send", icon: "paperplane.fill", confirmedLabel: "Sent", duration: 0.6, isFullWidth: false) { }
            // A slow, deliberate one.
            DSHoldToConfirm("Hold to power off", icon: "power", confirmedLabel: "Off", duration: 2.5) { }
        }
    }
}
```

Pick a hold when the risk is sustained intent (power off, hold-to-record) or when one hand is all the user has. Pick a slide when the risk is an accidental touch (a payment, a button a thumb could brush).

## Behavior

- Touch down: the pill dips (`DSPress.scale`), the ring starts to charge and a soft detent fires. Detents tick six times across the hold, each a little stronger.
- The action is decided by a timer that only completes if the finger stayed down, not by the ring animation, so a lift can never let a confirmation slip through.
- Ring closes: a pill-wide fill in the accent, a spinner while `onConfirm` runs, then a success haptic, a check and `confirmedLabel`.
- `onConfirm` throws: an error haptic, a short beat, then the ring clears and the control is ready for another try. It never words the failure; telling the user why is your job.
- Release early: a light haptic and the ring springs back. `onConfirm` is not called.
- There is no reset API. Re-mount with `.id(attempt)` to run it again.
- `.disabled(true)` dims it to 50% and ignores touches.
- Reduce Motion: the ring still charges, since it is the progress feedback itself, but the spring-back and the fill land with a plain fast ease instead of a bounce.
- Reduce Transparency: the glass pill becomes a solid elevated background.

## Accessibility

- One element, read as a button with the `label` you passed and the hint "Double-tap to confirm". VoiceOver users cannot hold a press, so a double-tap confirms straight away, with no timed hold.
- Value is "Processing" while `onConfirm` runs, then the `confirmedLabel` once done.
- Override the label with `.accessibilityLabel("Delete account")` on the outside.
- Dynamic Type: the label uses `.ds(.button)` and scales; the pill grows with it.

## See also

- [DSSlideToConfirm](DSSlideToConfirm.md)
- [DSButton](DSButton.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
