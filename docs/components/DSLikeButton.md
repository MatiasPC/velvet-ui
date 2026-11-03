# DSLikeButton

A favorite / like / bookmark toggle with a satisfying beat: the symbol swaps to its filled variant with a designed SF Symbols transition, springs up in a quick pop, and a single soft halo radiates out and fades. An optional count rolls when it changes. Turning it off is quiet.

<!-- GIF pending: ![DSLikeButton](../media/DSLikeButton.gif) -->

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSLikeButton.swift`](../../Sources/VelvetUI/Components/DSLikeButton.swift)

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

struct LikeDemo: View {
    @State private var isLiked = false
    @State private var likes = 128

    var body: some View {
        DSScreen(backdrop: true) {
            DSLikeButton(isLiked: $isLiked, count: likes, accessibilityLabel: "Like post")
                .onChange(of: isLiked) { _, liked in
                    likes += liked ? 1 : -1
                }
                .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `isLiked` | `Binding<Bool>` | required | The liked state. Tapping toggles it. |
| `count` | `Int?` | `nil` | A value shown beside the symbol; rolls with `.numericText` when it changes. `nil` hides it. |
| `size` | `CGFloat` | `DSSpacing.xl` (24) | Point size of the symbol. The tap target is at least 44 pt whatever the size. |
| `symbol` | `String` | `"heart.fill"` | The filled symbol shown while liked. |
| `emptySymbol` | `String` | `"heart"` | The outline symbol shown while not liked. |
| `tint` | `Color?` | `nil` | Color while liked, and of the halo. Defaults to the theme accent. |
| `haptic` | `DSHapticStyle` | `.soft` | Fired on every tap, on the peak of the pop when liking. |
| `accessibilityLabel` | `String` | `"Like"` | What VoiceOver reads for the control. Pass one that matches the symbol (`"Favorite"`, `"Save"`). |

## Variants

```swift
HStack(spacing: DSSpacing.xl) {
    DSLikeButton(isLiked: .constant(true))                              // heart
    DSLikeButton(isLiked: .constant(true), symbol: "star.fill",
                 emptySymbol: "star", tint: DSColors.warning,
                 accessibilityLabel: "Favorite")                        // star
    DSLikeButton(isLiked: .constant(false), symbol: "bookmark.fill",
                 emptySymbol: "bookmark", accessibilityLabel: "Save")   // bookmark
}
```

Any filled/outline SF Symbol pair works — the replace transition morphs between them.

## Behavior

- Tapping flips the binding. Liking (off → on) plays the beat: the symbol swaps with `contentTransition(.symbolEffect(.replace))`, the glyph pops to 1.28× and springs back, and one filled halo in the tint radiates out and fades. The symbol and color ride a `DSAnimation.springSnappy`; the pop and halo run on a `keyframeAnimator` track, the same split as `DSSuccessCheck`.
- The haptic (`.soft` by default) fires on the peak of the pop, 0.13 s after the tap, so the buzz and the visual climax land together.
- Unliking (on → off) is quiet: the symbol swaps back and the color fades, with no pop and no halo. The haptic fires on the tap, since there is no beat to wait for. Unliking while a quick like is still popping ends the pop on the spot.
- Rapid taps never stack. Each like restarts the one keyframe track (and replaces the pending haptic), so there is never more than one pop or one halo on screen.
- The beat belongs to the tap. Setting `isLiked` from code (restoring saved state when a feed loads, a double-tap on a photo) swaps the symbol quietly, with no pop and no haptic.
- A `count` rolls with `.numericText` whenever it changes; drive it from the same state with `.onChange`.
- The tap target is at least 44 × 44 pt, whatever the `size`, and the button dips with `DSPress.iconScale` while pressed. Disabled, it dims.
- Reduce Motion: no pop and no halo, and the symbol swap and the count crossfade instead of morphing and rolling. The symbol and color still change and the haptic still fires, on the tap.
- The halo extends past `size`, so leave a little room around the button.

## Accessibility

- Exposed as a toggle button with your `accessibilityLabel` and a value of "Liked" or "Not liked" (with the count appended when present, e.g. "Liked, 129"). The value updates when the state changes.
- The visible count is hidden from VoiceOver to avoid reading it twice; it is carried in the value instead.
- The tap target is at least 44 pt even when the symbol is small.

## See also

- [DSSuccessCheck](DSSuccessCheck.md) for a one-shot success seal with the same halo mechanism
- [DSToggle](DSToggle.md) for an on/off setting switch
- [DSRating](DSRating.md) for a multi-step star rating
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
