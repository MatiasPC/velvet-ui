# Velvet UI

**Glassy SwiftUI components with spring motion and haptics, for iOS 18+ and macOS 15+.**

[![CI](https://github.com/MatiasPC/velvet-ui/actions/workflows/ci.yml/badge.svg)](https://github.com/MatiasPC/velvet-ui/actions/workflows/ci.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2018%2B%20%C2%B7%20macOS%2015%2B-0A84FF)](#requirements)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-34C759)](#install)
[![License: MIT](https://img.shields.io/badge/license-MIT-8E8E93)](LICENSE)

<p align="center">
  <img src="docs/media/Hero.gif" alt="Velvet UI components: a glass card with a toggle, a stepper and a slide-to-pay control" width="320">
</p>

Frosted glass over a gradient theme you pick (Sunset, Aurora or Lagoon). Every control has spring motion and a haptic on the beat, and there are no borders. You get one `import`, no dependencies, and VoiceOver, Reduce Motion and Dynamic Type support built in.

## Install

**Xcode:** File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git` → add the **VelvetUI** library to your app target.

**Package.swift:**

```swift
dependencies: [
    .package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "VelvetUI", package: "velvet-ui")
    ])
]
```

## Quick start

Inject a theme once at the root:

```swift
import VelvetUI

@main struct MyApp: App {
    @State private var theme = DSTheme(gradient: .sunset)
    var body: some Scene { WindowGroup { ContentView().dsTheme(theme) } }
}
```

Then use any component, anywhere below it:

```swift
struct ContentView: View {
    var body: some View {
        DSScreen(backdrop: true) {                  // the theme's gradient behind everything
            DSCard {
                DSSlideToConfirm("Slide to pay") {
                    try await checkout()             // throw to refuse; the control re-opens
                }
            }
            .dsScreenPadding()
        }
    }

    func checkout() async throws { /* charge the card */ }
}
```

## Components

Each component has its own page with a copyable snippet, every parameter, its variants and accessibility notes.

| Preview | Component | What it does |
|:---:|---|---|
| <img src="docs/media/DSButton.gif" width="120" alt="DSButton"> | [DSButton](docs/components/DSButton.md) | Text button with five variants, three sizes, an icon and a loading state. |
| <img src="docs/media/DSIconButton.gif" width="120" alt="DSIconButton"> | [DSIconButton](docs/components/DSIconButton.md) | Icon-only button with press scale, a haptic and a VoiceOver label. |
| <img src="docs/media/DSSlideToConfirm.gif" width="120" alt="DSSlideToConfirm"> | [DSSlideToConfirm](docs/components/DSSlideToConfirm.md) | Slide-to-confirm for payments and destructive actions, with an async result. |
| <img src="docs/media/DSToggle.gif" width="120" alt="DSToggle"> | [DSToggle](docs/components/DSToggle.md) | Switch with a spring knob and a rigid haptic. |
| <img src="docs/media/DSStepper.gif" width="120" alt="DSStepper"> | [DSStepper](docs/components/DSStepper.md) | −/+ stepper that ticks on every step and jiggles at its bounds. |
| <img src="docs/media/DSRating.gif" width="120" alt="DSRating"> | [DSRating](docs/components/DSRating.md) | Drag-to-rate stars, with half steps and a read-only mode. |
| <img src="docs/media/DSSegmentedControl.gif" width="120" alt="DSSegmentedControl"> | [DSSegmentedControl](docs/components/DSSegmentedControl.md) | Pill or underline picker with a sliding indicator. |
| <img src="docs/media/DSTextField.gif" width="120" alt="DSTextField"> | [DSTextField](docs/components/DSTextField.md) | Text field with label, icon and validation states, plus `DSSearchBar`. |
| <img src="docs/media/DSCodeField.gif" width="120" alt="DSCodeField"> | [DSCodeField](docs/components/DSCodeField.md) | One-time-code input with SMS autofill, a shake on error and success feedback. |
| <img src="docs/media/DSPageControl.gif" width="120" alt="DSPageControl"> | [DSPageControl](docs/components/DSPageControl.md) | Page dots whose active dot stretches into a capsule. |
| <img src="docs/media/DSCard.gif" width="120" alt="DSCard"> | [DSCard](docs/components/DSCard.md) | The glass surface everything sits on: elevated, outlined, flat, tappable or with an image. |
| <img src="docs/media/DSListCell.gif" width="120" alt="DSListCell"> | [DSListCell](docs/components/DSListCell.md) | List rows, section headers and dividers. |
| <img src="docs/media/DSBadge.gif" width="120" alt="DSBadge"> | [DSBadge](docs/components/DSBadge.md) | Status pills and count badges. |
| <img src="docs/media/DSAvatar.gif" width="120" alt="DSAvatar"> | [DSAvatar](docs/components/DSAvatar.md) | Remote image with an initials fallback. |
| <img src="docs/media/DSToast.gif" width="120" alt="DSToast"> | [DSToast](docs/components/DSToast.md) | Success, error, warning and info toasts that VoiceOver announces. |
| <img src="docs/media/DSEmptyState.gif" width="120" alt="DSEmptyState"> | [DSEmptyState](docs/components/DSEmptyState.md) | Icon, title, message and an optional call to action. |
| <img src="docs/media/Progress.gif" width="120" alt="Progress"> | [Progress](docs/components/Progress.md) | Circular, linear, gradient and step progress, animated numbers, shimmer skeletons. |
| <img src="docs/media/DSThinkingIndicator.gif" width="120" alt="DSThinkingIndicator"> | [DSThinkingIndicator](docs/components/DSThinkingIndicator.md) | Ambient "thinking" state for AI and background work. |
| <img src="docs/media/DSTypewriterText.gif" width="120" alt="DSTypewriterText"> | [DSTypewriterText](docs/components/DSTypewriterText.md) | Types phrases out character by character, with a blinking caret. |
| <img src="docs/media/Motion.gif" width="120" alt="Motion"> | [Motion](docs/components/Motion.md) | `.dsBreathe`, `.dsJiggle`, `.dsPopIn`, `.dsEdgeSweep` and `.dsHueDrift` modifiers for any view. |

Layout helpers: `DSScreen`, `DSVStack`, `DSHStack`, `DSGrid`, `DSHorizontalScroll`. The maintainers' reference for every component, with status and backlog, is in [docs/components.md](docs/components.md).

## Theming

A theme is a gradient plus four derived colors: `accent` for fills, `onAccent` for text on the accent, and `ink` / `inkDark` for text and icons on glass in light and dark mode. Three themes ship built in:

| Theme | Gradient | Use it as |
|---|---|---|
| `.sunset` (default) | peach → coral | `DSTheme(gradient: .sunset)` |
| `.aurora` | violet → fuchsia | `DSTheme(gradient: .aurora)` |
| `.lagoon` | mint → cyan | `DSTheme(gradient: .lagoon)` |

- **Backdrop.** Glass needs something to blur. Wrap a screen in `DSScreen(backdrop: true) { … }` or add `.dsBackdrop()`. Without a backdrop, components still work and read as plain surfaces.
- **Switch at runtime.** Every component re-renders, and animating the change crossfades them:
  ```swift
  withAnimation(DSAnimation.normal) { theme.gradient = .lagoon }
  ```
- **Light and dark** are automatic. Dark mode is the same gradient under a dim, so the hue is preserved.
- **Your own theme.** `DSGradientTheme(id:name:stops:accent:onAccent:ink:inkDark:)`. The built-in themes pass a WCAG AA contrast test, and yours should too.
- **Your own views.** Read the resolved theme instead of hard-coding colors:
  ```swift
  struct PriceTag: View {
      @DSThemed private var theme

      var body: some View {
          Text("$120").ds(.numeric, color: theme.ink)
              .padding(.horizontal, DSSpacing.sm)
              .background(theme.subtleFill)
              .clipShape(Capsule())
      }
  }
  ```

Under the components sit the tokens: glass surfaces (`DSSurface`), the wash that replaces borders (`DSWash`), soft shadows, radius by role, a 4 pt spacing grid, 17 text styles, motion curves and springs, and haptics. Every value is in [docs/tokens.md](docs/tokens.md).

## Accessibility

- **VoiceOver.** Interactive controls expose a label, a value and the right traits. `DSStepper`, `DSRating` and `DSPageControl` are adjustable (swipe up and down). `DSSlideToConfirm` confirms with a double-tap, so nobody has to drag. `DSToast` announces itself. Icon-only buttons take an `accessibilityLabel:`. Each component page lists exactly what VoiceOver reads.
- **Dynamic Type.** Text styled with `.ds(_:)`, `.dsTextStyle(_:)` or `.dsFont(_:)` scales with the user's text size, and looks identical at the default size. Fixed-height controls (buttons, fields, the segmented control, stepper, code field, slide-to-confirm and badges) keep a fixed label size for now.
- **Reduce Motion** puts ambient effects in a resting state instead of cutting them mid-animation. Gesture feedback stays, and decorative particles are removed.
- **Reduce Transparency** swaps glass for solid surfaces.
- **Contrast.** Each built-in theme is tested for WCAG AA (4.5:1) on its accent, on white and on dark glass.
- **Haptics** support visual feedback and never replace it. They are a no-op on macOS.

## Requirements

| | |
|---|---|
| Platforms | iOS 18.0+, macOS 15.0+ |
| Toolchain | Swift 6.0+ (swift-tools 6.0; the package builds in Swift 5 language mode) |
| Xcode | A version with the iOS 18 / macOS 15 SDKs; CI uses the latest stable release |
| Dependencies | None |

## Demo app

[`Examples/VelvetGallery`](Examples/VelvetGallery) is a runnable iOS app with one screen per component and a clean full-screen recording stage for each. Open `Examples/VelvetGallery/VelvetGallery.xcodeproj` and press Run. [docs/RECORDING.md](docs/RECORDING.md) shows how to record clips from the simulator.

## Documentation

- [Component pages](docs/components/): one per component
- [Tokens](docs/tokens.md): every color, surface, type style, spacing, radius, motion and haptic value
- [Engineering notes](docs/engineering-notes.md): architecture decisions and gotchas
- [Proposals](docs/proposals/): design proposals behind each version
- [Changelog](CHANGELOG.md)

## Contributing

Bug reports, fixes and component proposals are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) for the rules every component follows and the definition of done. This project follows a [Code of Conduct](CODE_OF_CONDUCT.md).

## License

Velvet UI is released under the [MIT License](LICENSE). Copyright © 2026 Matias Peralta.
