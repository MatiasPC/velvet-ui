# DSToast

A transient, glass-backed message with a status icon for success, error, warning and info, and `.dsToast(_:edge:)` to present it: it slides in, taps out a haptic, leaves by itself and can be flicked away.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSToast.swift`](../../Sources/VelvetUI/Components/DSToast.swift) · [`DSToastPresenter.swift`](../../Sources/VelvetUI/Components/DSToastPresenter.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(style: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

Bind an optional `DSToastValue` to the screen with `.dsToast(_:edge:)`. Assigning a value presents it; there is no `withAnimation`, timer or haptic to write at the call site.

```swift
import VelvetUI

struct ToastDemo: View {
    @State private var toast: DSToastValue?

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.sm) {
                DSButton("Save", isFullWidth: true) {
                    toast = DSToastValue("Saved to your library", type: .success)
                }
                DSButton("Simulate failure", variant: .secondary, isFullWidth: true) {
                    toast = DSToastValue("Couldn't connect", type: .error)
                }
            }
            .dsScreenPadding()
        }
        .dsToast($toast)
    }
}
```

A toast with `duration: 0` is sticky: it stays until you set the binding to `nil` (or the user flicks it away). Put the toast on the bottom edge with `edge: .bottom`:

```swift
import VelvetUI

struct ToastStickyDemo: View {
    @State private var toast: DSToastValue?

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.sm) {
                DSButton("Start upload", isFullWidth: true) {
                    // duration: 0 keeps it up until you clear the binding
                    toast = DSToastValue("Uploading…", type: .info, duration: 0)
                }
                DSButton("Finish", variant: .secondary, isFullWidth: true) {
                    toast = DSToastValue("Upload complete", type: .success, duration: 4)
                }
                DSButton("Cancel", variant: .ghost, isFullWidth: true) {
                    toast = nil
                }
            }
            .dsScreenPadding()
        }
        .dsToast($toast, edge: .bottom)
    }
}
```

### The bare banner

`DSToast(_:type:)` is just the view: no timer, no animation, no haptic. Use it when you need full control over presentation (for example inside your own overlay). You then decide when it appears, fire the haptic and dismiss it:

```swift
import VelvetUI

struct ToastManualDemo: View {
    @State private var showsToast = false

    var body: some View {
        DSScreen(backdrop: true) {
            DSButton("Save", isFullWidth: true) {
                withAnimation(DSAnimation.springSmooth) { showsToast = true }
                DSHapticEngine.shared.fire(.success)
            }
            .dsScreenPadding()
        }
        .overlay(alignment: .bottom) {
            if showsToast {
                DSToast("Saved to your library", type: .success)
                    .padding(.bottom, DSSpacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation(DSAnimation.springSmooth) { showsToast = false }
                    }
            }
        }
    }
}
```

## Parameters

`DSToast`:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_ message` | `String` | required | The message text. |
| `type` | `DSToastType` | `.info` | `.success`, `.error`, `.warning` or `.info`. |

`DSToastValue(_:type:duration:)`, one toast to present:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_ message` | `String` | required | The message text. |
| `type` | `DSToastType` | `.info` | Icon, color, haptic and VoiceOver prefix. |
| `duration` | `Double` | `2.5` | Seconds on screen. `0` or less (or not finite) is sticky. |

`.dsToast(_:edge:)`, apply it once at the screen root:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_ toast` | `Binding<DSToastValue?>` | required | Set a value to present, a new value to replace, `nil` to dismiss. |
| `edge` | `DSToastEdge` | `.top` | `.top` (banner below the safe area) or `.bottom` (snackbar above it). |

## Variants

| `DSToastType` | Icon | Color | Haptic the presenter fires |
|---|---|---|---|
| `.success` | `checkmark.circle.fill` | `palette.success` | `.success` |
| `.error` | `xmark.circle.fill` | `palette.error` | `.error` |
| `.warning` | `exclamationmark.triangle.fill` | `palette.warning` | `.warning` |
| `.info` (default) | `info.circle.fill` | `palette.info` | `.light` |

## Behavior

- The toast sits on `.ultraThinMaterial` (a solid fill under Reduce Transparency) with a `.lg` shadow, rounded to `DSRadius.md`, and spans the width with the standard screen margin.
- **Replace.** Assigning a new `DSToastValue` swaps the toast on screen in place: the old banner is removed at once, never faded out beneath the new one, so two toasts never overlap. The timer restarts with the new toast's own `duration`, and the haptic and VoiceOver announcement fire again. Two values with the same text are still two presentations.
- **Auto-dismiss.** One timer per presentation, cancelled by a replacement, a manual dismissal (`toast = nil`) or a flick, so a stale timer never clears a newer toast.
- **Flick to dismiss.** Drag the toast toward its edge: past `DSSpacing.xl`, or with enough speed to project past `DSSpacing.massive`, and it leaves from where you let go; otherwise it springs back (`springSnappy`). Dragging it into the screen resists. It slides in and out on `springGentle`.
- **Haptic.** The presenter fires the type's haptic as the toast appears. `DSToast` on its own fires none.
- Under Reduce Motion the slide becomes a short fade (`DSAnimation.fast`) and a snap-back is a short curve rather than a spring. Dragging still follows your finger.
- The modifier draws in an overlay on the view it modifies. Apply it at the screen root so the banner lands inside the safe area. To run a top and a bottom toast independently, stack two `.dsToast` modifiers, each with its own binding.

## Accessibility

- One element: VoiceOver reads it as "<Type>: <message>" with the types "Success", "Error", "Warning" and "Info" (for example "Success: Saved to your library").
- It is announced when it appears (and again for a replacement), so users hear it without moving focus. Keep it on screen long enough to be useful, and consider longer timeouts for errors.
- The presenter adds a "Dismiss" accessibility action, so a sticky toast can be cleared without a drag.
- The icon is decorative; the type is spoken as the prefix.
- The text uses `.ds(.callout)`, which scales with Dynamic Type.

## See also

- [DSEmptyState](DSEmptyState.md)
- [Progress](Progress.md) for long-running work
- [DSButton](DSButton.md) as the typical trigger
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
