# DSReactionBar

A glass capsule of emoji reactions. Press and slide across it: the emoji under the finger swells and rises with its neighbours, a tick lands on each new emoji, and letting go picks it. The pick jumps and falls back, and an accent dot slides under it. Picking it again takes the reaction back.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSReactionBar.swift`](../../Sources/VelvetUI/Components/DSReactionBar.swift)

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

struct MessageReactions: View {
    @State private var reaction: String?

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                DSReactionBar(selection: $reaction)
                Text("Dinner at eight?")
                    .ds(.body)
                    .padding(DSSpacing.md)
                    .dsSurface(.glass, radius: DSRadius.card)
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `selection` | `Binding<String?>` | required | The picked emoji, or `nil` for none. A pick sets it; picking the same emoji again sets it back to `nil`. |
| `reactions` | `[String]` | `DSReactionBar.defaultReactions` (👍 ❤️ 😂 😮 😢 🙏) | The emoji to offer, in order. Keep it to about seven so it fits a phone at large text sizes. |
| `accent` | `Color?` | `nil` | Color of the dot under the picked emoji. Defaults to the theme accent. |
| `accessibilityLabel` | `String` | `"Reaction"` | What VoiceOver calls the bar. |

## Variants

A feedback card with your own scale:

```swift
struct RideFeedback: View {
    @State private var mood: String?

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.md) {
                Text("How was your ride?").ds(.title3)
                DSReactionBar(selection: $mood, reactions: ["😡", "🙁", "😐", "🙂", "😍"],
                              accessibilityLabel: "Ride rating")
            }
            .frame(maxWidth: .infinity)
        }
    }
}
```

Showing it over a long-pressed message is your app's job, so the bar works wherever you place it: an overlay, a popover, a row under a post.

## Behavior

- Press anywhere on the bar and slide. The emoji under the finger grows to 1.6× and rises, and its neighbours grow less the further away they are (a dock-style falloff over about two emoji). The swell follows the finger on `DSAnimation.interactive` and springs home when it lifts.
- A `.selection` tick lands each time the finger crosses into a different emoji. The first touch doesn't tick; the pick on release confirms it.
- Letting go over an emoji picks it, with a `.soft` haptic. The emoji jumps up and falls back with a bounce (a `keyframeAnimator` track), and the accent dot springs over to it on `springSnappy`.
- Picking the selected emoji again takes the reaction back: `selection` becomes `nil`, the dot fades and a `.light` haptic fires. No jump.
- A finger past either end is held on the end emoji. More than about one and a half emoji away from the bar (above, below or past an end), it hovers nothing: everything rests, and letting go there changes nothing. A touch the system cancels (a scroll view taking it) also changes nothing.
- The beat belongs to the gesture. Setting `selection` from code moves the dot quietly, with no jump and no haptic.
- Each emoji sits in a 44 pt cell that scales with Dynamic Type. The swollen emoji rise above the capsule, so leave a little room over the bar.
- Disabled, the bar dims and ignores touches.
- Reduce Motion: nothing swells, rises or jumps. A flat wash marks the emoji under the finger instead, and the dot moves with a short fade. The ticks and the haptics are unchanged.
- Reduce Transparency: the capsule falls back to a solid surface, like every `dsSurface`.

## Accessibility

- The bar is one adjustable element named by `accessibilityLabel` ("Reaction"), whose value is the picked emoji (VoiceOver speaks its name, such as "red heart") or "None".
- Swipe up to move to the next reaction (from none, the first). Swipe down to move to the previous one; down from the first takes the reaction back. Each step ticks.

## See also

- [DSLikeButton](DSLikeButton.md) for a single like / favorite toggle with a pop
- [DSRating](DSRating.md) for a star rating you drag across
- [DSSegmentedControl](DSSegmentedControl.md) to pick one of a few labelled options
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
