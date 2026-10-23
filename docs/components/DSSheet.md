# DSSheet

A Velvet-styled native sheet: detents, a visible grabber, a glass background, and your theme carried into the content.

![DSSheet](../media/DSSheet.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSSheet.swift`](../../Sources/VelvetUI/Components/DSSheet.swift)

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

struct SheetDemo: View {
    @State private var showShare = false

    var body: some View {
        DSScreen(backdrop: true) {
            DSButton("Share trip", icon: "square.and.arrow.up") { showShare = true }
                .dsScreenPadding()
        }
        .dsSheet(isPresented: $showShare) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Share trip").ds(.title2)
                DSListCell(title: "Copy link", leading: { Image(systemName: "link") })
                DSListCell(title: "Message", leading: { Image(systemName: "message") })
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `isPresented` | `Binding<Bool>` | required | Whether the sheet is showing. |
| `item` | `Binding<Item?>` | required | The item-driven overload: the sheet shows while non-nil. `Item` is `Identifiable`. |
| `detents` | `Set<PresentationDetent>` | `[.medium, .large]` | Heights the sheet can rest at. |
| `onDismiss` | `(() -> Void)?` | `nil` | Called after dismissal. |
| `content` | `() -> Content` (or `(Item) -> Content`) | required | The sheet body. |

## When to use it

Use `dsSheet` instead of plain `.sheet` when you want the Velvet look without repeating the modifiers: it sets the detents and the visible grabber, picks a glass background, and passes the theme into the sheet (a sheet is a separate view tree, so your presenter's theme would otherwise reset to the default). Keep plain `.sheet` when you need a fully custom background or presentation.

## Variants

Small confirmation sheet with a fixed height:

```swift
.dsSheet(isPresented: $confirming, detents: [.height(220)]) {
    VStack(spacing: DSSpacing.md) {
        Text("Delete this trip?").ds(.title3)
        DSButton("Delete", variant: .destructive, isFullWidth: true) { confirming = false }
    }
    .padding(DSSpacing.xl)
}
```

Maps-style persistent sheet: the content behind stays interactive while the sheet is at its smaller detent.

```swift
.dsSheet(isPresented: $showPlaces, detents: [.height(160), .medium, .large]) {
    PlacesList()
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .interactiveDismissDisabled()
}
```

Item-driven: the sheet shows while the item is non-nil.

```swift
.dsSheet(item: $selectedTrip) { trip in
    Text(trip.name).ds(.title2).padding(DSSpacing.xl)
}
```

## Behavior

- It is the system sheet: interactive dismissal, scroll hand-off and keyboard handling all come from SwiftUI.
- Applies `.presentationDetents` and a visible drag indicator.
- On iOS 26 and macOS 26 the system background (Liquid Glass) is left alone. On earlier systems the background is `.regularMaterial`.
- Reduce Transparency: the background is the solid elevated surface color on every system.
- The content gets the presenter's theme and is marked as not on the gradient backdrop.
- No haptic: presenting a sheet is not an action.

## Accessibility

- VoiceOver treats it as a standard sheet; the grabber supports the standard dismiss gesture.
- Give the sheet content its own heading and labelled controls.
- Honors Reduce Transparency.

## See also

- [DSCard](DSCard.md)
- [DSListCell](DSListCell.md)
- [DSToast](DSToast.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
