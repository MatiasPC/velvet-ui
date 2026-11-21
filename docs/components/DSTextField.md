# DSTextField

A labelled text input with leading icon, secure mode and validation states, plus a matching `DSSearchBar` with a clear button.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSTextField.swift`](../../Sources/VelvetUI/Components/DSTextField.swift)

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

- `.normal`: neutral. Real keyboard focus tints the icon and a 1.5pt outline with theme ink. `.focused` is accepted but looks the same as `.normal`; focus is read from the system, not from `state`.
- `.error("message")`: red outline, a red warning icon and the message below the field.
- `.success`: a green check mark appears (the green outline shows only while focused).
- `.disabled`: dimmed to 50%.

## Behavior

- Focusing a field tints it with the theme ink; validation states change color and icon.
- An error message slides in under the field and the status icon scales in, on `DSAnimation.springSnappy`. Under Reduce Motion both fade instead.
- A `.error("")` with a blank message tints the field but shows no message.
- The search bar's clear button fires a light haptic.

## Accessibility

- VoiceOver names the field with its visible `label` ("Email, text field"); the placeholder names it only when there is no label. The caption above the field isn't read twice.
- An error message is announced when it appears or changes, and stays readable as the element after the field. `.success` reads "Valid"; the leading and error icons are decorative and hidden.
- Override the spoken name with `.accessibilityLabel("Email address")`.
- `DSSearchBar` is announced as a search field named by its placeholder. Its clear button reads "Clear text" and has a 44 pt touch target.
- Dynamic Type: the caption, the typed text, the placeholder, the error message and the icons scale. The field keeps its 48 pt height (44 pt for `DSSearchBar`) at the default size and grows with larger text.

## See also

- [DSCodeField](DSCodeField.md)
- [DSButton](DSButton.md)
- [DSSegmentedControl](DSSegmentedControl.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
