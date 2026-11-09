# DSKeypad

An on-screen numeric keypad for the screens where the system keyboard is the wrong tool: an amount to send or tip, a passcode, a quantity at a kiosk. Twelve keys on a 3 × 4 grid: 1–9, then the decimal separator (only for amounts), 0 and delete. Keys dip and tick under your finger; a key that would make the value invalid wiggles and buzzes instead of typing.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSKeypad.swift`](../../Sources/VelvetUI/Components/DSKeypad.swift)

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

struct SendMoneyDemo: View {
    @State private var amount = ""

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.xl) {
                Text(amount.isEmpty ? "$0" : "$" + amount)
                    .ds(.displayMedium)
                    .accessibilityLabel("Amount")
                DSKeypad(text: $amount, maxLength: 7, decimalPlaces: 2)
            }
            .dsScreenPadding()
        }
    }
}
```

The keypad edits a `String`, because what people type is text until they're done: `"12."` and `"0.50"` are valid amounts in progress that no `Double` can hold. Like [DSSlider](DSSlider.md), it draws no value of its own: show your own read-out above it (a currency amount, PIN dots), as above.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `text` | `Binding<String>` | required | The entered text. Keys append to it and delete from its end. |
| `maxLength` | `Int?` | `nil` | The most digits it may hold; the separator doesn't count. `nil` (or less than 1) means no limit. Use `4` or `6` for a PIN. |
| `decimalPlaces` | `Int` | `0` | Digits allowed after the decimal separator. `0` hides the separator key and keeps leading zeros (a PIN, a code, a count). Use `2` for money. |
| `haptic` | `DSHapticStyle` | `.light` | Fired on every accepted key. A refused key always fires `.warning`. |

### The rules

- **Digits** append, up to `maxLength` digits.
- **Amounts** (`decimalPlaces > 0`) never read `"05"` or `"00"`: a lone leading `0` is replaced by the next digit, and a second `0` is refused. Zeros after the separator are kept (`"0.05"`).
- **The separator** is accepted once. Typed first, it becomes `"0."`. After it, at most `decimalPlaces` digits fit.
- **Delete** removes the last character (the separator included) and is refused on empty text.
- **PINs and codes** (`decimalPlaces: 0`) keep every digit as typed, leading zeros included (`"007"`).

## Variants

```swift
struct PasscodeDemo: View {
    @State private var pin = ""
    @DSThemed private var theme

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            HStack(spacing: DSSpacing.md) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? theme.accent : theme.subtleFill)
                        .frame(width: DSSpacing.sm, height: DSSpacing.sm)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Passcode")
            .accessibilityValue("\(pin.count) of 4 digits")
            DSKeypad(text: $pin, maxLength: 4)
                .onChange(of: pin) { _, code in
                    if code.count == 4 { /* verify the code, then clear it */ }
                }
        }
    }
}
```

## Behavior

- Every key dips to `DSPress.scale` on a spring while held, and a faint ink wash deepens it.
- Digit keys sit on `theme.subtleFill` (the frosted wash on a backdrop, a flat nested fill on a card), never glass on glass. The separator and delete keys are bare glyphs, so the digits read as the keyboard.
- An accepted key fires `haptic` (a light tap by default). A refused key leaves the text alone, fires `.warning` and wiggles that key once with `dsJiggle`, the same refusal [DSStepper](DSStepper.md) gives at its bounds.
- **Locale.** The separator follows the `\.locale` environment: `"."` in en_US, `","` in de_DE. The bound text uses that separator, so parse it with the same locale, e.g. `Decimal(string: text, locale: locale)`.
- **Reduce Motion:** the refusal wiggle rests (it's a `DSMotion` effect); the warning haptic still says no. The press dip stays, since it follows your finger.
- **Disabled** (`.disabled(true)`): dimmed to 50%, and the keys ignore touches.
- Keys are 64 pt tall and share the width equally, so they stay well above the 44 pt minimum on every iPhone.

## Accessibility

- The pad is a container labelled "Keypad". Each key is its own button with the keyboard-key trait, read as its digit, "Decimal point" or "Delete", so VoiceOver's typing modes work on it.
- The keypad has no value of its own: give your read-out a label and value (`.accessibilityLabel("Amount")`, or `"Passcode"` with `"2 of 4 digits"` for PIN dots, as above), so people hear what they've typed. Don't speak a PIN's digits.
- Dynamic Type: the key glyphs scale with `.ds(.title1)` / `.dsFont(.title2)`; the 64 pt key height is a minimum, so larger text grows the keys.

## See also

- [DSCodeField](DSCodeField.md): one-time codes with SMS autofill, on the system keyboard.
- [DSStepper](DSStepper.md)
- [DSSlider](DSSlider.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
