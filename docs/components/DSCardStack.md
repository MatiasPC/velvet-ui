# DSCardStack

A pile of related cards that fans out into a column when tapped. Collapsed, the first card is on top and the next two peek out under it; tap the pile and every card springs to its place in a column. Use it for grouped notifications, a wallet of passes or tickets, a thread of messages from one sender, or several updates about the same order.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSCardStack.swift`](../../Sources/VelvetUI/Components/DSCardStack.swift)

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

struct OrderUpdate: Identifiable {
    let id: String
    let detail: String
}

struct OrderUpdates: View {
    @State private var isExpanded = false
    let updates = [
        OrderUpdate(id: "Your order shipped", detail: "Arrives Thursday"),
        OrderUpdate(id: "Out for delivery", detail: "4 stops away"),
        OrderUpdate(id: "Delivered", detail: "Left at the front door"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Text("Orders").ds(.title3)
                Spacer()
                if isExpanded {
                    DSButton("Show less", variant: .ghost, size: .small) { isExpanded = false }
                }
            }
            DSCardStack(updates, isExpanded: $isExpanded, accessibilityLabel: "Order updates") { update in
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(update.id).ds(.body)
                    Text(update.detail).ds(.callout)
                }
            }
        }
        .dsScreenPadding()
    }
}
```

The first element is the top card. A tap on the pile sets `isExpanded` to `true`; collapse it yourself by setting it back to `false`, usually from a "Show less" button above the stack. Each card is padded with `DSSpacing.md` and drawn on a solid surface, so pass only the content.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `items` | `[Item]` | required | The cards, top card first. `Item` is `Identifiable`. |
| `isExpanded` | `Binding<Bool>` | required | Whether the cards stand in a column. A tap on the pile sets it to `true`. |
| `haptic` | `DSHapticStyle` | `.light` | Fired when a tap expands the pile. |
| `accessibilityLabel` | `String` | `"Stack"` | What VoiceOver calls the pile, such as "Notifications" or "Boarding passes". |
| `content` | `(Item) -> Content` | required | One card's content. The stack pads it and puts it on a solid surface. |

## Variants

```swift
struct BoardingPass: Identifiable {
    let id: String
    let gate: String
}

struct BoardingPasses: View {
    @State private var showAll = false
    let passes = [
        BoardingPass(id: "LIS → AMS", gate: "Gate 14"),
        BoardingPass(id: "AMS → OSL", gate: "Gate D7"),
    ]

    var body: some View {
        VStack(spacing: DSSpacing.md) {
            DSCardStack(passes, isExpanded: $showAll, haptic: .medium, accessibilityLabel: "Boarding passes") { pass in
                HStack {
                    Text(pass.id).ds(.title3)
                    Spacer()
                    Text(pass.gate).ds(.callout)
                }
            }
            if showAll {
                DSButton("Done", variant: .secondary, isFullWidth: true) { showAll = false }
            }
        }
        .dsScreenPadding()
    }
}
```

Two passes: one peeks under the other. A single card is shown on its own and the tap does nothing, since there is nothing more to show.

## Behavior

- **The pile:** the top card is full size. The next two sit behind it, each 5% smaller (anchored at their bottom edge) with their bottom edge `DSSpacing.sm` lower, so a strip of each shows. Cards after the third wait behind the last peeking one, invisible, and fade in as the stack opens. A card behind that is taller than the top one never rises above the top of the pile; it just shows more of itself. Cards of similar height stack best.
- **The column:** expanded, the cards stand full size with `DSSpacing.sm` between them.
- **Motion:** one progress value moves every card from the pile to the column, and the stack's height follows it frame by frame, so whatever sits below the stack moves with the cards instead of jumping. It animates on `DSAnimation.springSmooth` from the state, not the tap, so setting `isExpanded` yourself animates the same way.
- **Touch:** collapsed, the whole pile is one tap target that dips on press (`DSPress`), and controls inside the cards don't take touches. Expanded, every card's content is live.
- **Haptics:** `haptic` when a tap expands the pile. Collapsing is your control's job, and a `DSButton` already fires its own haptic.
- **Surfaces:** cards are `.solid` (`backgroundElevated`), clipped to `DSRadius.card`, with an `.md` shadow on the top card and `.sm` behind. Not glass: stacked glass shows each card through the one above it and turns muddy.
- **Reduce Motion:** the change runs on `DSAnimation.fast`, a short eased curve with no spring, to the same end state.

## Accessibility

- Collapsed, the pile is one button named by `accessibilityLabel`, with the count and state as its value ("Order updates, 3 cards, collapsed"). Double-tap expands it. The cards inside are not read until then.
- Expanded, each card's content is its own element, in order.
- Give your collapse control a clear name ("Show less"); VoiceOver users need it as much as anyone.
- A single card is read as "1 card", without a state, and isn't a button.

## See also

- [DSSwipeDeck](DSSwipeDeck.md): a stack of cards to decide on one at a time.
- [DSDisclosureGroup](DSDisclosureGroup.md): a titled section that springs open to reveal its body.
- [DSCard](DSCard.md) · [All components](../../README.md#components) · [Theming](../../README.md#theming)
