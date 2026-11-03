# DSButton

A themed text button with optional icon and loading state. It presses down with a spring and taps out a haptic, so every action feels acknowledged.

![DSButton](../media/DSButton.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSButton.swift`](../../Sources/VelvetUI/Components/DSButton.swift)

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

struct ButtonDemo: View {
    @State private var isSaving = false

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.md) {
                DSButton("Save changes", icon: "checkmark", isFullWidth: true, isLoading: isSaving) {
                    isSaving = true
                }
                DSButton("Cancel", variant: .ghost) { }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `title` | `String` | required | Button text (unlabeled first argument). |
| `variant` | `DSButtonVariant` | `.primary` | `.primary`, `.secondary`, `.outline`, `.ghost` or `.destructive`. |
| `size` | `DSButtonSize` | `.medium` | `.small` (36pt pill), `.medium` (44pt), `.large` (52pt). |
| `icon` | `String?` | `nil` | SF Symbol name shown beside the title. |
| `iconPosition` | `IconPosition` | `.leading` | `.leading` or `.trailing`. |
| `isFullWidth` | `Bool` | `false` | Stretch to the available width. |
| `isLoading` | `Bool` | `false` | Shows a spinner, dims the button and disables taps. |
| `haptic` | `DSHapticStyle` | `.medium` | Haptic fired on tap. |
| `action` | `() -> Void` | required | Called on tap (trailing closure). |

Icon-only buttons use [`DSIconButton`](DSIconButton.md).

## Variants

| Variant | Look |
|---|---|
| `.primary` | Theme accent fill, `onAccent` text. |
| `.secondary` | Palette secondary fill. |
| `.outline` | Clear fill with an ink outline. |
| `.ghost` | Text only, no fill. |
| `.destructive` | Error-red fill for irreversible actions. |

```swift
struct ButtonVariantsDemo: View {
    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            DSButton("Primary") { }
            DSButton("Secondary", variant: .secondary) { }
            DSButton("Outline", variant: .outline) { }
            DSButton("Ghost", variant: .ghost) { }
            DSButton("Delete account", variant: .destructive, icon: "trash") { }
            DSButton("Next", size: .large, icon: "arrow.right", iconPosition: .trailing) { }
            DSButton("Tag", size: .small) { }
        }
    }
}
```

`.small` is a pill; `.medium` and `.large` use the control corner radius.

## Behavior

- Pressing scales the button down with the shared press spring and releases back on lift.
- A haptic fires on tap (`.medium` by default; pass `haptic:` to change it). Don't add another at the call site.
- While `isLoading` is true the button shows a spinner, dims to 80% and ignores taps.

## Accessibility

- VoiceOver reads the button as a standard SwiftUI `Button` whose label is `title`; the icon is decorative. While loading it is disabled and read as dimmed.
- Override the spoken label from outside with `.accessibilityLabel("Save your changes")`.
- Label text doesn't scale with Dynamic Type yet: the control has a fixed height, so its label keeps a fixed size. Text elsewhere on your screen that uses `.ds(_:)` / `.dsTextStyle(_:)` does scale.

## See also

- [DSIconButton](DSIconButton.md)
- [DSSlideToConfirm](DSSlideToConfirm.md)
- [DSToggle](DSToggle.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
