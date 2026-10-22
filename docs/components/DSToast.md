# DSToast

A transient, glass-backed message with a status icon for success, error, warning and info.

![DSToast](../media/DSToast.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSToast.swift`](../../Sources/VelvetUI/Components/DSToast.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(gradient: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

`DSToast` is just the view: you decide when it appears, fire the haptic and dismiss it. This is the usual pattern, an overlay driven by state, with the haptic on presentation and a `.task` that dismisses after a moment:

```swift
import VelvetUI

struct ToastDemo: View {
    @State private var toast: (message: String, type: DSToastType)?

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.sm) {
                DSButton("Save", isFullWidth: true) {
                    show("Saved to your library", type: .success)
                }
                DSButton("Simulate failure", variant: .secondary, isFullWidth: true) {
                    show("Couldn't connect", type: .error)
                }
            }
            .dsScreenPadding()
        }
        .overlay(alignment: .bottom) {
            if let toast {
                DSToast(toast.message, type: toast.type)
                    .padding(.bottom, DSSpacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: toast.message) {
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation(DSAnimation.springSmooth) { self.toast = nil }
                    }
            }
        }
    }

    private func show(_ message: String, type: DSToastType) {
        withAnimation(DSAnimation.springSmooth) { toast = (message, type) }
        switch type {
        case .success: DSHapticEngine.shared.fire(.success)
        case .error:   DSHapticEngine.shared.fire(.error)
        case .warning: DSHapticEngine.shared.fire(.warning)
        case .info:    DSHapticEngine.shared.fire(.light)
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_ message` | `String` | required | The message text. |
| `type` | `DSToastType` | `.info` | `.success`, `.error`, `.warning` or `.info`. |

## Variants

| `DSToastType` | Icon | Color | Matching haptic (you fire it) |
|---|---|---|---|
| `.success` | `checkmark.circle.fill` | `palette.success` | `.success` |
| `.error` | `xmark.circle.fill` | `palette.error` | `.error` |
| `.warning` | `exclamationmark.triangle.fill` | `palette.warning` | `.warning` |
| `.info` (default) | `info.circle.fill` | `palette.info` | `.light` |

## Behavior

- The toast sits on `.ultraThinMaterial` with a `.lg` shadow, rounded to `DSRadius.md`, and spans the width with the standard screen margin.
- It has no presentation logic: no timer, no animation, no haptic. The snippet shows the caller's side (a spring from `DSAnimation`, `DSHapticEngine.shared.fire(_:)`, and a delayed dismissal). Use the `Examples/VelvetGallery` Toast screen as a reference.
- `DSToastType` has no public haptic mapping; copy the table above (the `switch` in the snippet).
- Under Reduce Motion, swap the slide transition for `.opacity` in your overlay.

## Accessibility

- One element: VoiceOver reads it as "<Type>: <message>" with the types "Success", "Error", "Warning" and "Info" (for example "Success: Saved to your library").
- It is announced when it appears, so users hear it without moving focus. Keep it on screen long enough to be useful, and consider longer timeouts for errors.
- The icon is decorative; the type is spoken as the prefix.
- The text uses `.ds(.callout)`, which scales with Dynamic Type.

## See also

- [DSEmptyState](DSEmptyState.md)
- [Progress](Progress.md) for long-running work
- [DSButton](../components.md#dsbutton) as the typical trigger
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
