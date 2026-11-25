# DSStoryProgress

The row of segments across the top of a story: one per page, the pages before the current one full, the current one filling as its time runs, the ones after it empty. When the current segment fills, the binding moves to the next page by itself; after the last page it calls `onFinish`. Use it for stories and status updates, auto-advancing onboarding and product tours, a rotating promo banner, workout intervals.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSStoryProgress.swift`](../../Sources/VelvetUI/Components/DSStoryProgress.swift)

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

struct StoryViewer: View {
    let stories: [String]
    var onClose: () -> Void = {}
    @State private var page = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            DSStoryProgress(
                currentPage: $page,
                numberOfPages: stories.count,
                isPaused: scenePhase != .active
            ) {
                onClose()
            }
            Text(stories[page]).ds(.largeTitle)
            Spacer()
        }
        .dsScreenPadding()
        .overlay {
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { page = max(page - 1, 0) }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if page < stories.count - 1 { page += 1 } else { onClose() }
                    }
            }
            .accessibilityHidden(true)
        }
        .dsBackdrop()
    }
}
```

The control owns the timing; you own the navigation. A tap on the left or right half changes `page`, and the new page starts from zero. Pausing while the app isn't active keeps a story from running out in the background. The tap halves are hidden from VoiceOver because the progress itself is adjustable (see Accessibility).

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `currentPage` | `Binding<Int>` | required | The page showing, from 0. The control moves it on when a page's time runs out; set it yourself to skip. Out-of-range values show as the nearest page. |
| `numberOfPages` | `Int` | required | How many segments. 0 draws nothing and hides it from VoiceOver. |
| `duration` | `TimeInterval` | `5` | Seconds each page stays up. Change it per page (a video's length) and it applies to the page showing. Not positive or not finite falls back to 5. |
| `isPaused` | `Bool` | `false` | Holds the current segment where it is. Resuming continues from there, not from zero. |
| `accent` | `Color?` | `nil` | The segments' fill. `nil` follows the theme accent. |
| `accessibilityLabel` | `String` | `"Story"` | What VoiceOver reads before "2 of 5". |
| `onFinish` | `(() -> Void)?` | `nil` | Called once when the last page's time runs out. Close the viewer, open the next person's stories, or set `currentPage` back to 0 to loop. |

## Variants

```swift
struct HoldToPauseTips: View {
    @State private var page = 0
    @State private var isHolding = false
    @DSThemed private var theme

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                DSStoryProgress(
                    currentPage: $page,
                    numberOfPages: 4,
                    duration: 6,
                    isPaused: isHolding,
                    accent: theme.ink,
                    accessibilityLabel: "Tip"
                ) {
                    page = 0
                }
                Text("Tip \(page + 1) of 4").ds(.title3)
            }
        }
        .onLongPressGesture(minimumDuration: 0.2, perform: {}, onPressingChanged: { isHolding = $0 })
    }
}
```

Hold the card to pause, let go to carry on. `onFinish` sets the page back to 0, so the tips loop. A custom `accent` (here `theme.ink`) suits a quieter surface than the accent fill.

## Behavior

- Segments before `currentPage` are full, the current one fills linearly over `duration`, the ones after it are empty.
- The fill is drawn from a `TimelineView` clock, so it is smooth at any frame rate and draws nothing while paused, finished or off screen.
- Time is read from the clock, not counted: a pause banks the time run so far, and resuming picks up from there. A new page (from you or from the control) starts from zero.
- When a page's time runs out the control sets `currentPage` to the next page. After the last page it calls `onFinish` once and holds the last segment full until `currentPage` changes.
- Skipping springs the segments it passes to full or empty (`DSAnimation.springSnappy`); the segment that becomes current starts empty at once.
- An automatic advance is silent. A VoiceOver step fires a `.selection` haptic.
- It takes the full width it's given and is 4 pt tall, with 4 pt between segments. Segments are `theme.subtleFill` capsules filled with `accent`. No borders.
- It doesn't pause on its own when the app goes to the background: pass `isPaused: scenePhase != .active`, as in the usage example.
- **Reduce Motion:** skipped segments change in place instead of springing. The current segment still fills: it is the time left, not decoration.

## Accessibility

- VoiceOver reads one adjustable element: the `accessibilityLabel`, then the page ("Story, 2 of 5"). Swipe up or down to move one page.
- Pages still advance on their own under VoiceOver. For long reading, pause while VoiceOver is running (`@Environment(\.accessibilityVoiceOverEnabled)`) or give the page a longer `duration`.

## See also

- [DSPageControl](DSPageControl.md): where you are in a set of pages, with no timer.
- [Progress](Progress.md): one value, linear, circular or in steps.
- [DSCarousel](DSCarousel.md): horizontal paging content you swipe through.
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
