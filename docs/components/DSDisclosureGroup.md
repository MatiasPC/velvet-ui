# DSDisclosureGroup

A glass "show more" section. Tap the header and the body springs open while the chevron rotates and a light haptic fires — the Velvet reading of an accordion / FAQ row, for settings detail, filters, long descriptions, anything that should stay out of the way until asked for.

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSDisclosureGroup.swift`](../../Sources/VelvetUI/Components/DSDisclosureGroup.swift)

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

struct FAQDemo: View {
    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.sm) {
                DSDisclosureGroup("Can I cancel anytime?") {
                    Text("Yes — cancel from Settings and keep access until the end of the period.")
                        .ds(.callout, color: DSColors.textSecondary)
                }
                DSDisclosureGroup("What's included", subtitle: "3 items", icon: "shippingbox") {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("• Unlimited projects").ds(.callout)
                        Text("• Priority support").ds(.callout)
                        Text("• Early access to betas").ds(.callout)
                    }
                }
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `title` | `String` | required | The header label, always visible. Passed as the first, unlabeled argument. |
| `subtitle` | `String?` | `nil` | Optional secondary line under the title. |
| `icon` | `String?` | `nil` | Optional SF Symbol before the title, tinted with `theme.accent`. |
| `initiallyExpanded` | `Bool` | `false` | Open state on first appearance (self-contained init only). |
| `isExpanded` | `Binding<Bool>` | — | Drive the open state yourself (bound init). Use it for an "only one open at a time" accordion. |
| `haptic` | `DSHapticStyle` | `.light` | Feedback fired on each toggle. |
| `content` | `() -> Content` | required | The body revealed when expanded. |

There are two initializers: one that tracks its own state (`initiallyExpanded:`) and one you drive with a `Binding` (`isExpanded:`). Everything else is shared.

## Variants

```swift
// Self-contained, starts open, softer haptic
DSDisclosureGroup("Details", initiallyExpanded: true, haptic: .soft) {
    Text("Open on first appearance, with a softer tap.").ds(.callout)
}

// Controlled: one open at a time
@State private var open: Int? = 0

ForEach(0..<3, id: \.self) { index in
    DSDisclosureGroup("Section \(index + 1)", isExpanded: Binding(
        get: { open == index },
        set: { open = $0 ? index : nil }
    )) {
        Text("Only one section is open at a time.").ds(.callout)
    }
}
```

## Behavior

- Toggling springs the body open and closed with `DSAnimation.springSmooth`. The card grows with the body instead of the body popping in, the body fades with it, and the chevron rotates 180° on the same spring.
- The body is always laid out at its full height and clipped to the revealed part, so text never re-wraps or jumps while it opens.
- The motion is driven by the open state itself, so it also plays when you flip a bound `isExpanded` from outside (a toggle, a "collapse all" button) and when taps arrive in quick succession: the spring retargets instead of restarting.
- A `.light` haptic fires on every toggle (configurable via `haptic:`).
- A hairline `theme.palette.divider` separates the header from the body when open.
- The header dips with `DSPress.scale` while pressed.
- The body stays in the view tree while collapsed, so it keeps its `@State`. It is hidden from touch and VoiceOver, but it is still built: keep it light, or gate expensive content on your own state.
- Reduce Motion: the spring is replaced by a short ease (`DSAnimation.fast`), so the body reaches the same state without bounce. The haptic still fires.
- Reduce Transparency: the glass surface becomes a solid elevated background.

## Accessibility

- The header is one combined button element: VoiceOver reads the title (and subtitle), the trait "Button", and the value "Expanded" or "Collapsed". It updates when the state changes.
- The hint says what activating the header does: "Shows the details" or "Hides the details".
- The leading icon and the chevron are decorative and hidden from VoiceOver.
- While collapsed, the body is hidden from VoiceOver and cannot be tapped.
- Dynamic Type: the title uses `.ds(.title3)` and the subtitle `.ds(.footnote)`, the icon and chevron scale with them; body text scales with whatever `.ds(_:)` style you pass.

## See also

- [DSCard](DSCard.md)
- [DSListCell](DSListCell.md)
- [DSSheet](DSSheet.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
