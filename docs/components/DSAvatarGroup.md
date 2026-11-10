# DSAvatarGroup

A facepile: overlapping avatars that show who is on a thread, in a space or going to an event, with a "+N" bubble when there are more than fit.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSAvatarGroup.swift`](../../Sources/VelvetUI/Components/DSAvatarGroup.swift)

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

struct EventRow: View {
    @State private var showsGuests = false

    var body: some View {
        DSScreen(backdrop: true) {
            DSCard {
                HStack(spacing: DSSpacing.md) {
                    DSAvatarGroup(
                        names: ["Ana Ruiz", "Ben Cole", "Cy Park", "Di Sol", "Eli Wu"],
                        maxVisible: 3
                    ) { showsGuests = true }

                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text("Design Review").ds(.title3)
                        Text("5 people going").ds(.callout)
                    }
                    Spacer(minLength: 0)
                }
            }
            .dsScreenPadding()
        }
        .dsSheet(isPresented: $showsGuests) {
            Text("Guest list").ds(.title2).padding(DSSpacing.xl)
        }
    }
}
```

## Parameters

`DSAvatarGroup(members:maxVisible:size:overlap:haptic:action:)` and `DSAvatarGroup(names:…)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `members` / `names` | `[DSAvatarGroup.Member]` / `[String]` | required | The people, first on top. `names` makes initials-only avatars. |
| `maxVisible` | `Int` | `4` | Most circles to show, the "+N" bubble included. At least 2. |
| `size` | `CGFloat` | `DSSpacing.xxxl` | Diameter of each avatar. |
| `overlap` | `CGFloat` | `0.25` | How much each avatar is covered by the next, as a fraction of its width (`0...0.9`). |
| `haptic` | `DSHapticStyle?` | `.light` | Fired when the group is tapped (with `action`). `nil` for none. |
| `action` | `(() -> Void)?` | `nil` | Makes the whole group a button. |

`DSAvatarGroup.Member(id:name:imageURL:)`: `id` defaults to `name` and must be unique within the group; `imageURL` loads a photo with an initials fallback, like [DSAvatar](DSAvatar.md).

## Variants

```swift
VStack(alignment: .leading, spacing: DSSpacing.lg) {
    // Photos where you have them, initials where you don't
    DSAvatarGroup(members: [
        .init(name: "Ada Lovelace", imageURL: URL(string: "https://picsum.photos/seed/ada/96")),
        .init(name: "Grace Hopper")
    ])

    // Small and tight
    DSAvatarGroup(names: ["Ana Ruiz", "Ben Cole", "Cy Park"], size: DSSpacing.xxl, overlap: 0.3)
}
```

## Behavior

- Built from `DSAvatar`, so it themes and scales with it.
- With more people than `maxVisible`, the last slot becomes a "+N" bubble counting everyone not shown.
- The gap between neighbours is a cut-out of the avatar in front, not a ring: nothing is stroked and there is no background colour to match, so the group looks right on a card, a plain page or a photo.
- Avatars pop in one after another. Adding a person pops in only the new one.
- With `action`, the group dips on press and fires a light haptic, then calls `action`. Keep the group at 32 pt or more if it is tappable.
- Reduce Motion: avatars fade in, nothing scales.
- Right-to-left layouts mirror the pile.

## Accessibility

- The group is one VoiceOver element. It names the people shown and counts the rest: "Ana, Ben and 3 others". With no overflow it names everyone ("Ana, Ben and Cy"); with nobody it reads "No people".
- With `action` it also has the button trait.
- Individual avatars and the "+N" bubble are not separately focusable.

## See also

- [DSAvatar](DSAvatar.md) for a single avatar
- [DSBadge](DSBadge.md) for counts and status marks
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
