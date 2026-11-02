# DSDisclosureGroup

A glass "show more" section. Tap the header and the body springs open while the chevron rotates and a light haptic fires — the Velvet reading of an accordion / FAQ row, for settings detail, filters, long descriptions, anything that should stay out of the way until asked for.

![DSDisclosureGroup](../media/DSDisclosureGroup.gif)

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
// Self-contained, starts open
DSDisclosureGroup("Details", initiallyExpanded: true) { … }

// Controlled — one open at a time
@State private var open: Int? = 0
DSDisclosureGroup("Section A", isExpanded: Binding(
    get: { open == 0 },
    set: { open = $0 ? 0 : nil }
)) { … }
```

## Behavior

- Toggling springs the body open/closed with `DSAnimation.springSmooth`; the chevron rotates 180°.
- A `.light` haptic fires on every toggle (configurable via `haptic:`).
- A hairline `theme.palette.divider` separates the header from the body when open.
- Reduce Motion: the open/close is applied instantly (no spring, no chevron sweep); the haptic still fires.
- Reduce Transparency: the glass surface becomes a solid elevated background.

## Accessibility

- The header is one combined button element; VoiceOver reads the title (and subtitle), the trait "Button", and the value "Expanded" / "Collapsed".
- A hint ("Double tap to expand/collapse") describes the action.
- The leading icon is decorative and hidden from VoiceOver.
- Dynamic Type: the title uses `.ds(.title3)` and the subtitle `.ds(.footnote)`, both scaling; body text scales with whatever `.ds(_:)` style you pass.

## See also

- [DSCard](DSCard.md)
- [DSListCell](DSListCell.md)
- [DSSheet](DSSheet.md)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
