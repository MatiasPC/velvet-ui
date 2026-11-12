# DSTagField

A text field that collects tags: the skills on a profile, the people on an invite, the labels on a post, the keywords of a saved search. Type a word and press Return or a comma, and it springs into an accent pill inside the field while the caret moves on to the next one. Paste `design, swift, ios` and all three go in at once. Tap a pill to remove it.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSTagField.swift`](../../Sources/VelvetUI/Components/DSTagField.swift)

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

struct ProfileSkillsDemo: View {
    @State private var skills = ["SwiftUI", "Design systems"]

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Skills").ds(.title3)
                DSTagField(tags: $skills, placeholder: "Add a skill")
            }
        }
    }
}
```

[DSChipGroup](DSChip.md) picks from options your app already knows; `DSTagField` collects values people invent. They pair well: chips for suggestions, the field for what's been chosen.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `tags` | `Binding<[String]>` | required | The tags, in the order they were added. New tags are appended. |
| `placeholder` | `String` | `"Add a tag"` | Shown in the empty draft. Also the text field's VoiceOver label. |
| `maxTags` | `Int?` | `nil` | The most tags the field holds. `nil` (or less than 1) means no limit. |
| `accent` | `Color?` | `nil` | The pill fill. `nil` follows the theme accent (text in `theme.onAccent`). |
| `haptic` | `DSHapticStyle` | `.light` | Fired when tags are added. A refusal always fires `.warning`. |

### The rules

- **Return, `,` or `;`** ends a tag. So does leaving the field: a half-typed word isn't lost.
- **Whitespace** is trimmed, and runs of it inside a tag collapse to one space (`"  design   systems "` → `"design systems"`). A blank tag is ignored without any fuss.
- **Duplicates** are refused, ignoring letter case: typing `swiftui` next to `SwiftUI` wiggles the existing pill instead of adding a second one.
- **`maxTags`**: once the field is full, a new tag is refused and the text stays in the draft so you can see what didn't go in.
- **Pasting** a list commits every piece in order, by the same rules, with one haptic for the whole paste.

## Variants

```swift
struct InviteDemo: View {
    @State private var emails: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            DSTagField(tags: $emails, placeholder: "Email address", maxTags: 5)
            Text("\(emails.count) of 5 invites").ds(.footnote)
        }
    }
}
```

The field doesn't validate what a tag *is* (an email address, a known skill). Check the bound array in `.onChange(of:)` and show your own message, or filter it before saving.

## Behavior

- The field is a flat `theme.subtleFill` well at `DSRadius.control`, at least 48 pt tall, with a soft `dsFocusGlow` in `theme.ink` while editing. No borders, and no glass on glass when it sits on a card.
- Pills flow onto as many lines as they need (`DSFlowLayout`); the draft keeps at least 128 pt on its line and wraps below the pills when there isn't room.
- A new pill pops in with `DSAnimation.springSnappy` and fires `haptic`. Tapping a pill dips it (`DSPress.scale`), removes it and fires a `.selection` tick.
- A refusal fires `.warning` and wiggles once with `dsJiggle`: the existing pill for a duplicate, the draft for a full field. The same refusal vocabulary as [DSKeypad](DSKeypad.md) and [DSStepper](DSStepper.md).
- **Hardware keyboard:** Delete on an empty draft highlights the last pill (it lifts), and a second Delete removes it, the way Mail treats recipients. Typing anything clears the highlight.
- Autocapitalization and autocorrection are off, so tags stay as typed.
- **Reduce Motion:** pills fade in and out instead of scaling, state changes use a short ease, and the refusal wiggle rests (the warning haptic still says no).
- **Disabled** (`.disabled(true)`): dimmed to 50%, and neither the field nor the pills respond.

## Accessibility

- Each pill is a button read as "Remove *tag*", so VoiceOver users can find and remove any tag directly.
- The text field reads its `placeholder` as its label, with the hint "Return adds a tag".
- Every change is announced: "Added swift", "Removed design", "SwiftUI is already added", "Tag limit reached".
- Text uses `.ds(_:)` styles, so the pills and the draft scale with Dynamic Type and the pills wrap onto more lines.

## See also

- [DSChip](DSChip.md): pick from a fixed set of options.
- [DSFlowLayout](DSFlowLayout.md): the wrapping layout the pills sit in.
- [DSTextField](DSTextField.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
