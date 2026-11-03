# DSListCell

A consistent list row with leading and trailing slots, an optional tap action, a section header and a hairline divider.

![DSListCell](../media/DSListCell.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSList.swift`](../../Sources/VelvetUI/Components/DSList.swift)

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

struct ListDemo: View {
    @State private var selected = "None yet"

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: 0) {
                DSSectionHeader("Account", action: "Edit") { selected = "Edit" }

                DSCard(padding: 0) {
                    VStack(spacing: 0) {
                        DSListCell(
                            title: "Ada Lovelace",
                            subtitle: "ada@example.com",
                            leading: { DSAvatar(name: "Ada Lovelace") },
                            action: { selected = "Profile" }
                        )
                        DSDivider(inset: DSSpacing.screenHorizontal)
                        DSListCell(
                            title: "Notifications",
                            trailing: { DSCountBadge(count: 3) },
                            action: { selected = "Notifications" }
                        )
                        DSDivider(inset: DSSpacing.screenHorizontal)
                        DSListCell(title: "Version", subtitle: "0.2.0")
                    }
                }
                .padding(.horizontal, DSSpacing.screenHorizontal)

                Text("Last tapped: \(selected)")
                    .ds(.caption1)
                    .padding(DSSpacing.screenHorizontal)
            }
        }
    }
}
```

Wrap groups of cells in a `DSCard(padding: 0)` for the glass look. Cells add their own horizontal padding (`DSSpacing.screenHorizontal`), so use `padding: 0` on the card.

## Parameters

### DSListCell

| Parameter | Type | Default | Description |
|---|---|---|---|
| `title` | `String` | required | Primary text (`.body`). |
| `subtitle` | `String?` | `nil` | Secondary text (`.callout`, secondary color). |
| `leading` | `@ViewBuilder () -> Leading` | `{ EmptyView() }` | View before the text, such as an icon or `DSAvatar`. |
| `trailing` | `@ViewBuilder () -> Trailing` | `{ EmptyView() }` | View after the text, such as a `DSCountBadge`. |
| `action` | `(() -> Void)?` | `nil` | When set, the cell is a button with a chevron. |

### DSSectionHeader

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_ title` | `String` | required | Uppercase overline title. |
| `action` | `String?` | `nil` | Label of the trailing text button. |
| `onAction` | `(() -> Void)?` | `nil` | Called when the button is tapped. The button only appears when both `action` and `onAction` are set. |

### DSDivider

| Parameter | Type | Default | Description |
|---|---|---|---|
| `inset` | `CGFloat` | `0` | Leading inset, so the line can start under the text instead of under the icon. |

## Variants

- **Static row**: omit `action` and the cell is plain content without chevron.
- **Tappable row**: pass `action` and the whole row (padding included) becomes the tap target, with a trailing chevron and a `.light` haptic.
- **Divider**: a 1pt `palette.divider` line; it is the only separator, there are no borders.

## Behavior

- Tappable cells use a plain button style: no system highlight, no press animation. Wrap them in `DSInteractiveCard` if you want a scale-on-press card instead.
- The header action fires a `.light` haptic as well.

## Accessibility

- A tappable cell is a `Button`: VoiceOver reads the title, subtitle and any text in the slots as one label, and activating it calls `action`. A static cell is a plain stack whose pieces are read in order.
- The chevron is a decorative SF Symbol; the section header title is read as a normal text element.
- Override with `.accessibilityLabel("…")` or `.accessibilityHint("…")` on the cell.
- Text uses `.ds(_:)` styles, so rows grow with Dynamic Type.

## See also

- [DSCard](DSCard.md) for grouping rows
- [DSAvatar](DSAvatar.md) and [DSBadge](DSBadge.md) for slots
- [DSEmptyState](DSEmptyState.md) for an empty list
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
