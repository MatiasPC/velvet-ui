# DSEmptyState

A centered empty-list or no-results placeholder: a light icon, a title, a short message and an optional call-to-action button.

![DSEmptyState](../media/DSEmptyState.gif)

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

```swift
import VelvetUI

struct EmptyStateDemo: View {
    @State private var items: [String] = []

    var body: some View {
        DSScreen(backdrop: true) {
            if items.isEmpty {
                DSEmptyState(
                    icon: "tray",
                    title: "Nothing here yet",
                    message: "Saved recipes show up here so you can find them later.",
                    actionTitle: "Add a recipe"
                ) {
                    items.append("Shakshuka")
                }
            } else {
                VStack(spacing: DSSpacing.sm) {
                    ForEach(items, id: \.self) { item in
                        DSCard { Text(item).ds(.body) }
                    }
                }
                .dsScreenPadding()
            }
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `icon` | `String` | required | SF Symbol name, drawn at 48pt light weight in the tertiary text color. |
| `title` | `String` | required | Headline (`.title2`). |
| `message` | `String` | required | Supporting text (`.callout`, secondary color, centered). |
| `actionTitle` | `String?` | `nil` | Label of the call-to-action button. |
| `action` | `(() -> Void)?` | `nil` | Button handler. The button only appears when both `actionTitle` and `action` are set. |

## Variants

- **Informational**: omit `actionTitle` and `action` for a read-only state ("No results for 'xyz'").
- **With a call to action**: pass both and a primary `DSButton` appears under the message (it brings its own `.medium` haptic and press scale).

## Behavior

- Static layout: no entrance animation. Add `.dsPopIn()` to the icon or the whole view if you want one (see [Motion](Motion.md)).
- The view pads itself by `DSSpacing.xxl`; center it in its container yourself, for example inside a `DSScreen` or a `frame(maxHeight: .infinity)`.

## Accessibility

- The icon is an SF Symbol without a label; the title and message are read in order, followed by the button. The title is a normal text element rather than a heading, so add `.accessibilityAddTraits(.isHeader)` from outside if you want heading navigation.
- The button is a labelled `DSButton`.
- Text uses `.ds(_:)` styles and scales with Dynamic Type; the 48pt icon is fixed.

## See also

- [DSListCell](DSListCell.md) for the populated list
- [DSTypewriterText](DSTypewriterText.md) for a livelier headline
- [DSToast](DSToast.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
