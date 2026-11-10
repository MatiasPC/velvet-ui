# dsScrollReveal

A scroll-coupled reveal for any repeated view: it sits at full presence inside the scroll view, recedes (a little smaller, a little dimmer) as it crosses the leading or trailing edge, and comes back when you scroll back.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSScrollEffects.swift`](../../Sources/VelvetUI/Animation/DSScrollEffects.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(style: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

Put `.dsScrollReveal(_:)` on each repeated item, inside the `ScrollView`:

```swift
import VelvetUI

struct ScrollRevealDemo: View {
    private let items = ["Weekly summary", "New follower", "Backup complete", "Battery full", "Trip reminder", "Goal reached"]

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.sm) {
                ForEach(items, id: \.self) { title in
                    DSCard {
                        Text(title)
                            .ds(.title3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .dsScrollReveal()
                }
            }
            .dsScreenPadding()
        }
    }
}
```

For a horizontal carousel, size each card with `containerRelativeFrame`, leave margins with `contentMargins` so the neighbours peek, and use `.strong`:

```swift
ScrollView(.horizontal) {
    HStack(spacing: DSSpacing.sm) {
        ForEach(0..<5, id: \.self) { index in
            DSCard { Text("Card \(index + 1)").ds(.title3) }
                .containerRelativeFrame(.horizontal)
                .dsScrollReveal(.strong)
        }
    }
    .scrollTargetLayout()
}
.contentMargins(.horizontal, DSSpacing.xxxl, for: .scrollContent)
.scrollTargetBehavior(.viewAligned)
```

## Parameters

`func dsScrollReveal(_ intensity: DSScrollRevealIntensity = .medium) -> some View`

| Intensity | Scale at the edge | Opacity at the edge | Use for |
|---|---|---|---|
| `.subtle` | `DSMotion.scrollRevealSubtleScale` (0.96) | `scrollRevealSubtleOpacity` (0.65) | Text rows and list cells. |
| `.medium` (default) | `scrollRevealMediumScale` (0.90) | `scrollRevealMediumOpacity` (0.40) | Cards in a feed. |
| `.strong` | `scrollRevealStrongScale` (0.80) | `scrollRevealStrongOpacity` (0.15) | Carousel cards. |

## Behavior

- Built on `scrollTransition(.interactive)`: the amount follows the scroll position continuously, in both directions, so it is not an entrance that fires once (that is `dsPopIn` / `dsStaggerIn`).
- It reacts at the edges of the scroll view's visible area, not at its centre. A row fully inside is at full presence; in a carousel with peeking neighbours that reads as centre emphasis. If several cards are fully visible at once, they all stay at full presence.
- The axis is inferred from the enclosing scroll view. Only scale and opacity change (render transforms), so nothing reflows and neighbours never shift.
- Ambient, so it fires no haptic.

## Accessibility

- Under Reduce Motion every item rests at full presence: no scaling and no dimming, so contrast is never reduced for the people the setting protects.
- It does not change what VoiceOver reads or the order of the elements.

## See also

- [Motion](Motion.md) for the other ambient modifiers
- [DSCarousel](DSCarousel.md) for a ready-made snapping carousel with its own depth effect
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
