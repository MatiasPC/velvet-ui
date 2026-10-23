# DSToggle

A themed on/off switch whose knob springs across a glass track and snaps with a rigid haptic.

![DSToggle](../media/DSToggle.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSToggle.swift`](../../Sources/VelvetUI/Components/DSToggle.swift)

## Install

```swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
.product(name: "VelvetUI", package: "velvet-ui")   // add to your target's dependencies
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(gradient: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

```swift
import VelvetUI

struct ToggleDemo: View {
    @State private var notifications = true
    @State private var compact = false

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                DSToggle("Push notifications", isOn: $notifications)
                DSToggle("Compact layout", isOn: $compact, size: .small)
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `label` | `String?` | `nil` | Text shown beside the switch (unlabeled first argument). |
| `isOn` | `Binding<Bool>` | required | The on/off state. |
| `size` | `DSToggleSize` | `.medium` | `.small` (42x26) or `.medium` (51x31). |
| `onColor` | `Color?` | `nil` | Track color when on. Defaults to the theme accent. |
| `haptic` | `DSHapticStyle` | `.rigid` | Haptic fired on change. |



## Variants

- `.medium` matches the native switch size; `.small` suits dense settings lists.
- Without a label it is just the switch, for use in your own rows:

```swift
DSToggle(isOn: $notifications).accessibilityLabel("Push notifications")
```
- `.disabled(true)` dims it to 50% and suppresses the haptic.

## Behavior

- The knob springs across the track with a snappy spring; the track fills with the accent when on.
- A rigid haptic fires on every change (not when disabled).

## Accessibility

- One accessibility element. Its label is the `label` text; when you use the toggle without a label, add `.accessibilityLabel("…")` yourself.
- Value is "On" or "Off", with the toggle trait, and it reads as dimmed when `.disabled`.
- Dynamic Type: the optional label text scales with the user's text size.

## See also

- [DSSegmentedControl](DSSegmentedControl.md)
- [DSStepper](DSStepper.md)
- [DSButton](DSButton.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
