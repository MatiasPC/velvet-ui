# DSNumberTicker

A number whose digits roll like an odometer. Each digit slides to its new value, staggered from the units digit, while separators and currency symbols stay put.

![DSNumberTicker](../media/DSNumberTicker.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSNumberTicker.swift`](../../Sources/VelvetUI/Components/DSNumberTicker.swift)

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

struct NumberTickerDemo: View {
    @State private var balance = 1_284.50

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Balance").ds(.overline)
                DSNumberTicker(balance, format: .currency(code: "USD"))
                DSButton("Add $100") { balance += 100 }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `value` | `Double` or `Int` | required | The number to show. The `Int` form is grouped with no decimals. |
| `format` | `FormatStyle` (`Double` to `String`) | required for `Double` | `.number`, `.currency(code:)`, `.percent`, `.number.precision(...)`. Follows the user's locale. |
| `style` | `DSTextStyle` | `.displayMedium` | Use a style with monospaced digits (`.displayLarge`, `.displayMedium`, `.numeric`). |
| `color` | `Color?` | `nil` | Text color. Defaults to the theme's primary text color. |

Only ASCII digits (0-9) roll. Anything else the format produces, including other numeral systems, is shown as static text.

## Variants

```swift
VStack(alignment: .leading, spacing: DSSpacing.md) {
    DSNumberTicker(8_432, style: .displayLarge)
    DSNumberTicker(0.42, format: .percent, style: .numeric)
    DSNumberTicker(3.14159, format: .number.precision(.fractionLength(2)))
}
```

## Behavior

- Digits roll with a smooth spring, 0.03 s later for each place to the left of the units digit.
- Digits are counted from the right, so going from 99 to 100 keeps the existing digits and fades in the new leading one.
- Each digit's width and height come from the text style, so the number never changes height as it rolls.
- The ticker never compresses: it always takes the width its formatted value needs. Give it room (or pick a smaller `style`) for long currency strings such as "US$ 12,906.40".
- No haptics: it's a display.
- Reduce Motion: digits don't roll. The new value appears with a short crossfade.

## Accessibility

- One element. VoiceOver reads the full formatted value (for example "$1,384.50"), not individual digits.
- Marked as updating frequently, so VoiceOver doesn't announce every change.
- Text scales with Dynamic Type through the DS text styles.

## See also

- [DSStepper](DSStepper.md)
- [DSCard](DSCard.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
