# DSCodeField

A one-time-code input of separate digit boxes with a blinking caret, a springy active box, and a shake on a wrong code.

![DSCodeField](../media/DSCodeField.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSCodeField.swift`](../../Sources/VelvetUI/Components/DSCodeField.swift)

## Install

```swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
.product(name: "VelvetUI", package: "velvet-ui")   // add to your target's dependencies
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(gradient: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

```swift
import VelvetUI

struct CodeFieldDemo: View {
    @State private var code = ""
    @State private var state = DSCodeFieldState.normal

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.md) {
                Text("Enter the 6-digit code we texted you").ds(.callout)
                DSCodeField(code: $code, state: state) { entered in
                    state = (entered == "123456") ? .success : .error
                }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `length` | `Int` | `6` | Number of digit boxes. |
| `code` | `Binding<String>` | required | The digits entered so far. Digits only, clamped to `length`. |
| `state` | `DSCodeFieldState` | `.normal` | `.normal`, `.error` or `.success`. |
| `boxHeight` | `CGFloat` | `56` | Height of each box. |
| `onComplete` | `((String) -> Void)?` | `nil` | Called with the full code once `length` digits are entered. |



## Variants

- `.normal`: neutral boxes.
- `.error`: red boxes, a shake and an error haptic. Clear `code` and reset `state` to retry.
- `.success`: green boxes and a success haptic.

## Behavior

- Tap anywhere on the field to focus a hidden text field that owns the keyboard (number pad on iOS).
- On iOS the field supports SMS one-time-code autofill.
- The active box scales up with a snappy spring, a caret blinks in it, and each digit fires a light haptic.

## Accessibility

- One element labelled "Verification code" that accepts typing.
- Its value spells the digits and progress, for example "1 2 3, 3 of 6 digits", plus ", incorrect code" for `.error` or ", verified" for `.success`.
- Label text doesn't scale with Dynamic Type yet: the control has a fixed height, so its label keeps a fixed size. Text elsewhere on your screen that uses `.ds(_:)` / `.dsTextStyle(_:)` does scale.

## See also

- [DSTextField](DSTextField.md)
- [DSButton](DSButton.md)
- [DSSlideToConfirm](DSSlideToConfirm.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
