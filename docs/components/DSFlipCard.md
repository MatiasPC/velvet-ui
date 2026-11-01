# DSFlipCard

A two-sided card that turns over in 3D when tapped: the front rotates away, the back arrives un-mirrored, and a rigid haptic lands on the turn. For flashcards, tap-to-reveal, and stat cards with detail on the back.

![DSFlipCard](../media/DSFlipCard.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSFlipCard.swift`](../../Sources/VelvetUI/Components/DSFlipCard.swift)

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

struct FlashcardDemo: View {
    var body: some View {
        DSScreen(backdrop: true) {
            DSFlipCard {
                DSCard {
                    Text("Capital of France?")
                        .ds(.title2)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
            } back: {
                DSCard {
                    Text("Paris")
                        .ds(.displayMedium)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
            }
            .dsScreenPadding()
        }
    }
}
```

The card manages its own state and flips on tap. To drive it from the outside — a "Reveal" button, a quiz that advances — pass a binding:

```swift
@State private var revealed = false

DSFlipCard(isShowingBack: $revealed, axis: .vertical) {
    DSCard { Text("Tap to reveal balance").ds(.title3) }
} back: {
    DSCard { Text("$1,248.00").ds(.displayMedium) }
}

DSButton(revealed ? "Hide" : "Reveal") {
    withAnimation(DSAnimation.springSmooth) { revealed.toggle() }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `isShowingBack` | `Binding<Bool>` | — | Binding variant only: whether the back face is showing. Omit it to let the card own its state. |
| `axis` | `DSFlipAxis` | `.horizontal` | `.horizontal` turns left-to-right (around the vertical axis), `.vertical` turns top-to-bottom. |
| `showsBackFirst` | `Bool` | `false` | Self-managed variant only: start showing the back. |
| `haptic` | `DSHapticStyle?` | `.rigid` | Fired on each turn. `nil` for none. |
| `front` | `() -> Front` | required | The face shown at rest. |
| `back` | `() -> Back` | required | The face shown after a turn. |

## Variants

```swift
// Self-managed, horizontal (default)
DSFlipCard { front } back: { back }

// Bound, vertical turn
DSFlipCard(isShowingBack: $revealed, axis: .vertical) { front } back: { back }

// No haptic
DSFlipCard(haptic: nil) { front } back: { back }
```

Both faces are your own views — wrap each in a `DSCard` for the glass look, or put an image, a chart or a stat on either side.

## Behavior

- Tapping anywhere on the card turns it over. With a binding, the tap flips the binding; the parent can also set it directly.
- The turn uses `DSAnimation.springSmooth`, so it settles with a slight, premium overshoot.
- Both faces live in the same space; the one facing away is hidden. The swap happens exactly as a face passes edge-on (90°), where its width is zero — so the back never flashes mirrored across the front.
- Give the two faces a similar size: the card sizes to the union of both.
- Reduce Motion: the faces swap instantly, with no 3D spin. The haptic still fires.

## Accessibility

- The card is a button containing its visible face's content; the hidden face is removed from VoiceOver.
- It exposes a "Flip" custom action, so VoiceOver users can turn it over without the tap.
- Label the content of each face as you normally would; it is read in place.

## See also

- [DSCard](DSCard.md) for the glass surface to put on each face
- [DSCarousel](DSCarousel.md) for paging between cards
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
