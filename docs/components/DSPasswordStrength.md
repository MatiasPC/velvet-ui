# DSPasswordStrength

A strength meter for a new password: sign-up, change password, a vault or backup phrase. Four segments fill and change colour as the password gets stronger, with the level ("Weak", "Fair", "Good", "Strong") and the one change that would help most ("Add a number", "Avoid common passwords"). Reaching Strong lands with one haptic.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSPasswordStrength.swift`](../../Sources/VelvetUI/Components/DSPasswordStrength.swift)

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

struct SignUpPasswordDemo: View {
    @State private var password = ""

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSTextField(label: "New password", placeholder: "At least 8 characters", icon: "lock",
                            text: $password, isSecure: true)
                DSPasswordStrength(password: password)
                DSButton("Create account", isFullWidth: true) {
                    // create the account
                }
                .disabled(DSPasswordStrength.level(of: password) < .good)
            }
        }
    }
}
```

Put the meter under the field and pass the same text. `DSPasswordStrength.level(of:)` runs the same rules, so a submit button can wait for `.good` without a second set of rules. The meter is advisory: enforce your real policy on the server.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `password` | `String` | required | The password being typed. Pass the field's text. |
| `minLength` | `Int` | `8` | Characters needed before it can be more than Weak. Values under 1 count as 1. |
| `haptic` | `DSHapticStyle` | `.light` | Fired once when the password becomes Strong. Not fired on other steps. |
| `accessibilityLabel` | `String` | `"Password strength"` | What VoiceOver reads before the level. |

`DSPasswordStrength.level(of:minLength:)` returns a `DSPasswordStrengthLevel` (also spelled `DSPasswordStrength.Level`): `.empty`, `.weak`, `.fair`, `.good`, `.strong`. It is `Comparable`, and `title` is the word the meter shows.

## Variants

```swift
struct VaultPhraseDemo: View {
    @State private var phrase = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            DSTextField(label: "Vault phrase", placeholder: "Four or more words", text: $phrase, isSecure: true)
            DSPasswordStrength(password: phrase, minLength: 12, haptic: .success,
                               accessibilityLabel: "Phrase strength")
        }
    }
}
```

A longer minimum for a phrase that guards more, with a `.success` haptic for the moment it's strong enough.

## The rules

They follow current guidance (NIST SP 800-63B): length counts most, and a common password is weak however it's decorated.

- **Empty:** nothing typed. The hint reads "Use at least 8 characters".
- **Weak:** shorter than `minLength`, a common password (one of the most-used passwords or keyboard walks, also with digits and symbols around it: "Password1!", "qwerty123"), or three distinct characters or fewer.
- **Otherwise a score:** one point for each kind of character used (lowercase, capital, digit, symbol; a space counts as a symbol), one more at `minLength + 4` characters, at twice `minLength` and at three times `minLength`, minus one for a straight run of four ("1234", "dcba", "aaaa"). 2 or less is **Fair**, 3–4 **Good**, 5 or more **Strong**.

So "sunflower" is Fair, "sunflower7!" Good, "Sunflower7!x" Strong, and the passphrase "correct horse battery staple" Strong with no symbol soup. The hint names one change at a time: avoid a common password, reach the minimum, avoid repeats, avoid sequences, then add a number, a symbol or a capital, then "Make it longer". A Strong password has no hint.

## Behavior

- Four flat `theme.subtleFill` capsules, 4 pt tall. Filled segments grow from the leading edge on `DSAnimation.springSnappy` and cross-fade to the level's colour: `palette.error` (Weak), `palette.warning` (Fair), `palette.success` (Good, Strong).
- Below them, the level in `.footnote` and the hint in `.caption1`, both in text colours, so they stay readable on every theme. Changes fade.
- `haptic` fires once, when the level becomes Strong (also when a strong password is pasted). Typing within a level, or dropping back, fires nothing.
- No borders: put it in a `DSCard` under the field, or on the backdrop.
- **Reduce Motion:** segments fade in place instead of growing.

## Accessibility

- VoiceOver reads the meter as one element: the `accessibilityLabel`, then the level and the hint ("Fair. Add a number"; "Strong" alone).
- A change of level is announced ("Password strength: Good"), so a VoiceOver user typing in the field hears it without moving focus. Clearing the field isn't announced.
- Text uses `.ds(_:)` styles, so it scales with Dynamic Type.

## See also

- [DSTextField](DSTextField.md): the secure field the meter sits under.
- [DSCodeField](DSCodeField.md): one-time codes, which need no meter.
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
