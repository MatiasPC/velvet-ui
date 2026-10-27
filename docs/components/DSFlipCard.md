# DSFlipCard

A two-sided glass card that turns over in 3D to reveal its back — tap it, or drive it from a binding. The flip is a single spring about one axis with a touch of perspective, and it fires a haptic on the turn.

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

struct FlipDemo: View {
    var body: some View {
        DSScreen(backdrop: true) {
            // Tap anywhere on the card to turn it over.
            DSFlipCard {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("This month").ds(.footnote)
                    Text("1 248").ds(.displayMedium)
                    Text("Tap to see the trend").ds(.callout)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } back: {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("vs. last month").ds(.footnote)
                    Text("+12%").ds(.displayMedium)
                    Text("Tap to flip back").ds(.callout)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .dsScreenPadding()
        }
    }
}
```

Glass looks best over `.dsBackdrop()` or `DSScreen(backdrop: true)`. Keep the two faces a similar size — the card sizes to the larger one and centers the other.

### Drive it from a binding

Pass `isFlipped` to turn the card over from code (a button, a gesture, a result) as well as by tapping. Animate your own mutations with a `DSAnimation` spring; tap flips are animated for you.

```swift
struct CardFace: View {
    @State private var revealed = false

    var body: some View {
        VStack(spacing: DSSpacing.md) {
            DSFlipCard(isFlipped: $revealed, axis: .vertical) {
                Text("•••• 4242").ds(.numeric)
            } back: {
                Text("CVC 123 · 09/28").ds(.numeric)
            }

            DSButton(revealed ? "Hide" : "Reveal", variant: .secondary, size: .small) {
                withAnimation(DSAnimation.springSmooth) { revealed.toggle() }
            }
        }
    }
}
```

When a face holds its own controls, set `flipOnTap: false` so taps reach them and the card flips only from the binding.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `isFlipped` | `Binding<Bool>` | — | Only on the bound initializer: `false` shows `front`, `true` shows `back`. Omit it for a self-managing, tap-to-flip card. |
| `axis` | `DSFlipAxis` | `.horizontal` | Which way the card swings: `.horizontal` (left-to-right) or `.vertical` (top-to-bottom). |
| `style` | `DSCardStyle` | `.elevated` | Glass treatment of each face, same as `DSCard`: `.flat`, `.elevated`, `.outlined`. |
| `padding` | `CGFloat` | `DSSpacing.md` | Inner padding of each face. |
| `cornerRadius` | `CGFloat` | `DSRadius.card` | Corner radius of each face (20). |
| `flipOnTap` | `Bool` | `true` | Turn the card over when it is tapped. Set `false` when a face has its own controls. |
| `haptic` | `DSHapticStyle` | `.rigid` | Haptic fired on the turn. |
| `front` | `@ViewBuilder () -> Front` | required | The face shown at rest. |
| `back` | `@ViewBuilder () -> Back` | required | The face revealed after the turn. |

## Behavior

- The turn is one `DSAnimation.springSmooth` about `axis`, with a subtle perspective so the card reads as lifting off the glass.
- A single animated angle drives the turn through an `Animatable` container, so the two faces swap exactly at the 90° edge — no ghosting and no mirrored text. The back face is pre-rotated a half turn so it reads the right way round once flipped.
- Each face is a `DSCard`, so it inherits the glass, the 1pt edge highlight and the soft shadow. Under Reduce Transparency the glass becomes a solid elevated background.
- The turn fires `haptic` (default `.rigid`) on both tap and programmatic flips.
- **Reduce Motion:** the card swaps faces instantly instead of spinning in 3D.

## Accessibility

- With `flipOnTap` on, the card gains the `.isButton` trait and the hint "Double tap to flip"; the visible face's content is read as the label.
- The hidden face is marked `.accessibilityHidden`, so VoiceOver never reads both sides at once.
- With `flipOnTap: false`, no button semantics are added and each face keeps its own hit testing and VoiceOver — label the flip control yourself.
- Text uses `.ds(_:)` styles, which scale with Dynamic Type; give both faces room to grow.

## See also

- [DSCard](DSCard.md) for the glass surface each face is built on
- [DSSuccessCheck](DSSuccessCheck.md) and [DSConfetti](DSConfetti.md) for other reveal moments
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
