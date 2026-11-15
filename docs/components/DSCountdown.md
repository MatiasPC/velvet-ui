# DSCountdown

A live countdown to a date: the flash sale that ends tonight, the "resend the code in 0:42" under a one-time-code field, the event that starts in two days, the auction's last minute. Time left sits in a row of tiles (days, hours, minutes, seconds) whose digits roll down each second. The last ten seconds turn the seconds tile accent, and reaching zero lands with a haptic and calls `onFinish`.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSCountdown.swift`](../../Sources/VelvetUI/Components/DSCountdown.swift)

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

struct FlashSaleDemo: View {
    let endsAt: Date

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Sale ends in").ds(.title3)
                DSCountdown(to: endsAt, accessibilityLabel: "Sale ends in")
            }
        }
    }
}
```

Pass the moment it ends, not a duration: the countdown recomputes from the clock every second, so it never drifts and survives the view being rebuilt.

`Text(timerInterval:)` is still the right tool for a running clock inside a sentence. Use `DSCountdown` when the time left is the point of the screen, or when something has to happen at zero.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `target` (`to:`) | `Date` | required | The moment the countdown reaches zero. Change it to restart. |
| `accent` | `Color?` | `nil` | The seconds tile's fill in the last ten seconds. `nil` follows the theme accent (digits in `theme.onAccent`). |
| `haptic` | `DSHapticStyle` | `.success` | Fired once when the countdown reaches zero on screen. Not fired for a target that had already passed when it appeared. |
| `accessibilityLabel` | `String` | `"Time remaining"` | What VoiceOver reads before the time left. Name what ends: "Sale ends in", "Resend code in". |
| `onFinish` | `(() -> Void)?` | `nil` | Called once when the countdown reaches zero, or as soon as it appears if `target` has already passed. Called again after `target` changes. |

## Variants

```swift
struct ResendCodeDemo: View {
    @State private var resendAt = Date.now.addingTimeInterval(30)
    @State private var canResend = false

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            DSCountdown(to: resendAt, haptic: .light, accessibilityLabel: "Resend code in") {
                canResend = true
            }
            DSButton("Resend code", variant: .secondary, size: .small) {
                canResend = false
                resendAt = .now.addingTimeInterval(30)
            }
            .disabled(!canResend)
        }
    }
}
```

A short countdown that gates an action: `onFinish` enables the button, and the button restarts the countdown by moving its target. A `.light` haptic suits a minor beat like this better than the default `.success`.

## Behavior

- Seconds left are rounded **up**: with 59.3 s to go it reads 1:00, so 00:00 only shows once the target has passed.
- Minutes and seconds always show. Hours appear from one hour left and days from one day left; as a larger unit runs out its tile shrinks away with `DSAnimation.springSmooth`. Tiles show at least two digits ("05"); 100+ days show them all.
- Digits roll down with `.numericText(countsDown: true)` on `DSAnimation.springSnappy`.
- It wakes on each whole-second boundary before the target (no `Timer`, no drift), and stops ticking at zero or when it leaves the screen. Coming back on screen picks up from the clock.
- In the last ten seconds the seconds tile fills with `accent` and its text turns `theme.onAccent`. At zero it returns to rest.
- At zero it fires `haptic` once and calls `onFinish` once. A target already in the past calls `onFinish` on appear with no haptic.
- Tiles are flat `theme.subtleFill` rounded rectangles (`DSRadius.control`), at least 64 pt wide, and grow with Dynamic Type. No borders: put it on a `DSCard` or the backdrop.
- **Reduce Motion:** digits change in place instead of rolling, and tiles and the accent fade instead of scaling.

## Accessibility

- VoiceOver reads the countdown as one element: the `accessibilityLabel`, then the time left in words ("1 day, 2 hours, 5 seconds"; zero units are skipped; "0 seconds" at the end). It carries the "updates frequently" trait, so VoiceOver re-reads it periodically instead of on every second.
- Digits and captions use `.ds(_:)` styles, so they scale with Dynamic Type.

## See also

- [DSNumberTicker](DSNumberTicker.md): any number that rolls like an odometer.
- [DSCodeField](DSCodeField.md): the one-time-code field a resend countdown usually sits under.
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
