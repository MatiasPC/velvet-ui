# DSSwipeDeck

A stack of cards to decide on one at a time. Drag the top card right or left past the line, or flick it, and it flies off that way; let go short of the line and it springs back. Use it for recipe or match pickers, flashcards ("Again" / "Got it"), photo or inbox triage ("Keep" / "Archive") and onboarding interests.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSSwipeDeck.swift`](../../Sources/VelvetUI/Components/DSSwipeDeck.swift)

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

struct Recipe: Identifiable {
    let id: String
    let minutes: Int
}

struct RecipePicker: View {
    @State private var recipes = [
        Recipe(id: "Shakshuka", minutes: 25),
        Recipe(id: "Pad thai", minutes: 30),
        Recipe(id: "Risotto", minutes: 40),
    ]
    @State private var saved: [Recipe] = []

    var body: some View {
        DSSwipeDeck($recipes, leftLabel: "Skip", rightLabel: "Save", onSwipe: { recipe, direction in
            if direction == .right { saved.append(recipe) }
        }) { recipe in
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Spacer()
                Text(recipe.id).ds(.title1)
                Text("\(recipe.minutes) min").ds(.callout)
            }
            .padding(DSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .dsScreenPadding()
    }
}
```

The first element of the array is the top card. When a card leaves, the deck removes it from the binding and then calls `onSwipe` with the card and the direction, so you only record the decision. Give the deck a size (an aspect ratio or a frame): every card fills it.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `items` | `Binding<[Item]>` | required | The cards, top card first. `Item` is `Identifiable`. A swiped card is removed from it. |
| `leftLabel` | `String` | `"Pass"` | The left swipe's name: its chip on the card and its VoiceOver action. |
| `rightLabel` | `String` | `"Like"` | The right swipe's name: its chip on the card and its VoiceOver action. |
| `haptic` | `DSHapticStyle` | `.medium` | Fired when a card leaves. |
| `onSwipe` | `(Item, DSSwipeDirection) -> Void` | does nothing | Called after the card has left and been removed. `DSSwipeDirection` is `.left` or `.right`. |
| `content` | `(Item) -> Content` | required | One card's content. It fills the card; pad it yourself. |

## Variants

```swift
struct Flashcard: Identifiable {
    let id: String
}

struct FlashcardReview: View {
    @State private var deck = ["bonjour", "merci", "à bientôt"].map(Flashcard.init)
    @State private var history: [Flashcard] = []

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            DSSwipeDeck($deck, leftLabel: "Again", rightLabel: "Got it", haptic: .light, onSwipe: { card, direction in
                history.append(card)
                if direction == .left { deck.append(card) }   // see it again at the end
            }) { card in
                Text(card.id)
                    .ds(.title2)
                    .padding(DSSpacing.xl)
            }
            .aspectRatio(4 / 3, contentMode: .fit)

            DSButton("Undo", variant: .ghost, icon: "arrow.uturn.backward") {
                guard let last = history.popLast() else { return }
                deck.removeAll { $0.id == last.id }
                deck.insert(last, at: 0)
            }
            .disabled(history.isEmpty)
        }
        .dsScreenPadding()
    }
}
```

Flashcards: "Again" sends the card to the back of the deck, and Undo puts the last card back on top. Changes you make to the array yourself animate too: a card inserted or removed scales and fades.

## Behavior

- **The line** is 40% of the deck's width. Let go past it and the card leaves that way. A flick also counts: if the card has moved at least 10% of the width and the drag would carry it a full width, it leaves. Otherwise it springs back on `DSAnimation.springSnappy`.
- **Tracking:** the top card follows the finger 1:1 with no animation (a quarter of the vertical drag), and leans up to 12° around its bottom edge.
- **The stack:** two cards wait behind the top one, each 5% smaller and `DSSpacing.sm` lower, so their bottom edges fan out below it. The deck keeps room for them under the top card. As the top card nears the line, the card behind grows into its place, so nothing jumps when the top card leaves.
- **Chips:** the direction's label fades and grows in at the top of the card, on the side it's leaving from: `rightLabel` on `theme.accent` at the top left, `leftLabel` on `theme.ink` at the top right. They're placed by the physical drag, so they don't flip in right-to-left layouts.
- **Leaving:** the card flies out on `springSnappy`, then the deck removes it and settles on `springSmooth`, and `onSwipe` runs. No new drag starts until it's gone.
- **Haptics:** one `.selection` tick when the card crosses the line (again only after it comes back), and `haptic` when a card leaves.
- **Surfaces:** cards are `.solid` (`backgroundElevated`), clipped to `DSRadius.card`, with a `.lg` shadow on the top card and `.sm` behind. Not glass: stacked glass shows each card through the one above and turns muddy.
- **Scrolling:** keep the deck out of a vertical `ScrollView`, or the scroll and the drag fight over the same touch. Buttons inside a card still get their taps: a drag starts after `DSSpacing.xs` of movement.
- **Reduce Motion:** the card follows the finger but doesn't lean. A commit fades it out where it is instead of flying it out.

## Accessibility

- VoiceOver reads the top card's content as one element, with the cards left as its value ("4 cards left"). Hide decorative images in your content with `.accessibilityHidden(true)`.
- The two directions are actions named by the labels ("Like", "Pass"): swipe up or down to pick one, double-tap to run it. Nobody has to drag.
- After a card leaves, VoiceOver announces the action and what's left ("Like. 3 cards left", "Pass. No cards left").
- Cards behind the top one are hidden from VoiceOver.
- The chips use `.ds(.buttonSmall)`, so they scale with Dynamic Type.

## See also

- [DSCarousel](DSCarousel.md): browse cards side by side without deciding on each one.
- [DSLikeButton](DSLikeButton.md): a like toggle for content that stays put.
- [DSTiltCard](DSTiltCard.md): a single card that tips toward the finger.
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
