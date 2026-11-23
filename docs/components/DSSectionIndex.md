# DSSectionIndex

The column of letters along the edge of a long list. Touch a letter to jump to that section, or slide along the column to keep jumping, one tick per letter. While the finger is down, the letters near it fan out toward the list and a bubble beside it shows the current letter in large type.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSSectionIndex.swift`](../../Sources/VelvetUI/Components/DSSectionIndex.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(style: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

Give each section header an `.id` equal to its title, overlay the index on the trailing edge of the scroll view, and scroll in `action`:

```swift
import VelvetUI

struct Contacts: View {
    let sections: [(letter: String, names: [String])] = [
        ("A", ["Ada", "Alan"]), ("B", ["Barbara"]), ("G", ["Grace", "Guido"]),
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DSSpacing.xs) {
                    ForEach(sections, id: \.letter) { section in
                        Text(section.letter).ds(.overline).id(section.letter)
                        ForEach(section.names, id: \.self) { Text($0).ds(.body) }
                    }
                }
                .dsScreenPadding()
            }
            .overlay(alignment: .trailing) {
                DSSectionIndex(sections.map(\.letter)) { letter in
                    proxy.scrollTo(letter, anchor: .top)
                }
            }
        }
        .dsBackdrop()
    }
}
```

Scroll without animation, as the system index does: the list should be on the section before the next tick.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `titles` | `[String]` | required | The section titles, top to bottom, usually single letters. Pass only the sections the list has, so every jump lands somewhere. |
| `accent` | `Color?` | `nil` | Color of the title under the finger and of the bubble. Defaults to the theme accent. |
| `accessibilityLabel` | `String` | `"Section index"` | What VoiceOver calls the index. |
| `action` | `(String) -> Void` | required | Called with the title to jump to: on the first touch, and each time the finger reaches another title. |

## Variants

A custom VoiceOver name, with room above and below the column:

```swift
struct Countries: View {
    let letters: [String]
    let onJump: (String) -> Void

    var body: some View {
        DSSectionIndex(letters, accessibilityLabel: "Country index") { letter in
            onJump(letter)
        }
        .padding(.vertical, DSSpacing.xl)
    }
}
```

## Behavior

- The column is 44 pt wide, with a 16 pt row per title that scales with Dynamic Type. It takes the height it is offered, up to one row per title, and centres its titles in it.
- The first touch jumps to the title under it. Sliding keeps jumping: each new title under the finger calls `action` and fires a `.selection` tick. Staying on a title doesn't repeat either.
- A finger above or below the column holds the first or last title, so a fast slide past an end still lands there.
- While the finger is down, a thin glass track fades in behind the letters. The letters within about two and a half rows of the finger move toward the list and grow, most of all the one under it (20 pt and 1.5×), and that one turns accent. An accent bubble beside the finger shows the title in large type, so the thumb never hides it. The fan follows the finger on `DSAnimation.interactive` and springs back on release.
- When the column is too short for every title, it collapses like the system index: an odd number of rows, title and dot alternating, with the first and last titles always shown and the others spread evenly. Sliding over a dot walks through the titles it hides, so every section stays reachable.
- The fan and the bubble follow the layout direction: in a right-to-left list, put the index on the trailing edge (the left) and it fans to the right.
- Disabled, the index dims and ignores touches.
- Reduce Motion: no fan or growth. The title under the finger still turns accent and the bubble fades in and out. The ticks are unchanged.

## Accessibility

- The index is one adjustable element named by `accessibilityLabel` ("Section index"). Its value is the last title jumped to, or the first title before any jump.
- Swipe up to jump to the next section, down for the previous one; each step calls `action` and ticks. The ends stay put.
- VoiceOver users can also move through the list itself; the index is a shortcut, not the only way to a section.

## See also

- [DSListCell](DSListCell.md) for the rows of the list
- [DSScrollReveal](DSScrollReveal.md) for rows that recede at the scroll edges
- [DSDayStrip](DSDayStrip.md) to pick a day from a strip
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
