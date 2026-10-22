# DSTextField

A labelled text input with leading icon, secure mode and validation states, plus a matching `DSSearchBar` with a clear button.

![DSTextField](../media/DSTextField.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSTextField.swift`](../../Sources/VelvetUI/Components/DSTextField.swift)

## Install

```swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
.product(name: "VelvetUI", package: "velvet-ui")   // add to your target's dependencies
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`.dsTheme(DSTheme(gradient: .sunset))`); see [the README](../../README.md#install) and its [quick start](../../README.md#quick-start) for the full theming setup.

## Usage

```swift
import VelvetUI

struct TextFieldDemo: View {
    @State private var email = ""
    @State private var password = ""
    @State private var query = ""

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.md) {
                DSSearchBar(placeholder: "Search destinations", text: $query)
                DSTextField(
                    label: "Email",
                    placeholder: "you@example.com",
                    icon: "envelope",
                    text: $email,
                    state: email.isEmpty || email.contains("@") ? .normal : .error("Enter a valid email")
                )
                DSTextField(
                    label: "Password",
                    placeholder: "At least 8 characters",
                    icon: "lock",
                    text: $password,
                    isSecure: true
                )
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `label` | `String` | `""` | Caption above the field; hidden when empty. |
| `placeholder` | `String` | required | Placeholder text. |
| `icon` | `String?` | `nil` | Leading SF Symbol. |
| `text` | `Binding<String>` | required | The field's text. |
| `state` | `DSTextFieldState` | `.normal` | `.normal`, `.focused`, `.error(String)`, `.success` or `.disabled`. |
| `isSecure` | `Bool` | `false` | Use a secure (password) field. |

**DSSearchBar:** `DSSearchBar(placeholder: String = "Search", text: Binding<String>)`. A pill-shaped search field with a magnifier and a clear button that appears once there is text.

## Variants

- `.normal` / `.focused`: focus tints the icon and outline with the theme ink.
- `.error("message")`: red icon and the message below the field.
- `.success`: a check mark appears.
- `.disabled`: dimmed to 50%.

## Behavior

- Focusing a field tints it with the theme ink; validation states change color and icon.
- The search bar's clear button fires a light haptic.

## Accessibility

- The field is a standard SwiftUI `TextField` (or `SecureField`); VoiceOver uses its placeholder as the field name, and `label` is shown as visible text above it.
- Override the spoken name with `.accessibilityLabel("Email address")`.
- Label text doesn't scale with Dynamic Type yet: the control has a fixed height, so its label keeps a fixed size. Text elsewhere on your screen that uses `.ds(_:)` / `.dsTextStyle(_:)` does scale. The same applies to `DSSearchBar`.

## See also

- [DSCodeField](DSCodeField.md)
- [DSButton](DSButton.md)
- [DSSegmentedControl](DSSegmentedControl.md)
- [All components](../components.md) · [Theming](../../README.md#quick-start)
