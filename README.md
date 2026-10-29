# Velvet UI

**Glassy SwiftUI components with spring motion and haptics, for iOS 18+ and macOS 15+.**

[![CI](https://github.com/MatiasPC/velvet-ui/actions/workflows/ci.yml/badge.svg)](https://github.com/MatiasPC/velvet-ui/actions/workflows/ci.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2018%2B%20%C2%B7%20macOS%2015%2B-0A84FF)](#requirements)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-34C759)](#install)
[![License: MIT](https://img.shields.io/badge/license-MIT-8E8E93)](LICENSE)

<p align="center">
  <img src="docs/media/Hero.gif" alt="Velvet UI components: a glass card with a toggle, a stepper and a slide-to-pay control over a peach gradient" width="300">
</p>

<p align="center">
  <a href="#install"><b>Install</b></a> ·
  <a href="#components"><b>Components</b></a> ·
  <a href="#examples"><b>Examples</b></a> ·
  <a href="#use-it-with-ai-agents"><b>AI agents</b></a> ·
  <a href="#documentation"><b>Docs</b></a>
</p>

Frosted glass over a gradient theme you pick (Sunset, Aurora or Lagoon). Every control springs when you touch it and lands a haptic on the beat, and there are no borders anywhere.

- **One look, three themes.** Change `theme.gradient` and the whole app crossfades. Dark mode is the same gradient, dimmed.
- **Motion with intent.** Springs for touch, eased curves for ambience, and Reduce Motion treated as a resting state, never as a cut.
- **Accessible by default.** VoiceOver labels, values and traits, Dynamic Type, Reduce Transparency, and AA contrast tested on every theme.
- **Agent-ready.** [`AGENTS.md`](AGENTS.md), [`llms.txt`](llms.txt) and a [registry](registry.json) let Claude Code, Cursor and Codex use the library correctly on the first try.
- **Take all of it or one piece.** Add the Swift package, or copy a single component into your app with one command. No dependencies, MIT.

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

**Or copy one component.** Prefer owning the code? A small Swift script copies a component and the shared core it needs into your app, with no package dependency:

```bash
curl -fsSLO https://raw.githubusercontent.com/MatiasPC/velvet-ui/main/scripts/velvet.swift
swift velvet.swift list                                  # every component, by category
swift velvet.swift add DSSlideToConfirm --dest MyApp/VelvetUI
```

Copied files compile in Swift 5 and Swift 6 language mode, in Debug and Release. `#Preview`s aren't copied, because they use other components. Re-running `add` updates the files you haven't edited and skips the ones you have. Use one install path per target, not both. `--ref` pins a tag or commit (the default is `main`).

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

Each component has its own page with a copyable snippet, every parameter, its variants and accessibility notes. 28 components, every one with a Gallery stage.

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
| <img src="docs/media/DSTabBar.gif" width="120" alt="DSTabBar"> | [DSTabBar](docs/components/DSTabBar.md) | Floating glass tab bar with a sliding accent capsule, a symbol swap and count badges. |
| <img src="docs/media/DSCard.gif" width="120" alt="DSCard"> | [DSCard](docs/components/DSCard.md) | The glass surface everything sits on: elevated, outlined, flat, tappable or with an image. |
| <img src="docs/media/DSListCell.gif" width="120" alt="DSListCell"> | [DSListCell](docs/components/DSListCell.md) | List rows, section headers and dividers. |
| <img src="docs/media/DSCarousel.gif" width="120" alt="DSCarousel"> | [DSCarousel](docs/components/DSCarousel.md) | Snapping carousel with peeking neighbors and depth; pairs with `DSPageControl`. |
| <img src="docs/media/DSSheet.gif" width="120" alt="dsSheet"> | [dsSheet](docs/components/DSSheet.md) | Native sheet with Velvet chrome: detents, a grabber, a glass background, the theme carried in. |
| <img src="docs/media/DSBadge.gif" width="120" alt="DSBadge"> | [DSBadge](docs/components/DSBadge.md) | Status pills and count badges. |
| <img src="docs/media/DSAvatar.gif" width="120" alt="DSAvatar"> | [DSAvatar](docs/components/DSAvatar.md) | Remote image with an initials fallback. |
| <img src="docs/media/DSNumberTicker.gif" width="120" alt="DSNumberTicker"> | [DSNumberTicker](docs/components/DSNumberTicker.md) | Digits that roll like an odometer, for currency, percentages or counts. |
| <img src="docs/media/Charts.gif" width="120" alt="Charts"> | [Charts](docs/components/Charts.md) | A sparkline that draws and morphs, and a bar chart you can scrub. No Swift Charts needed. |
| <img src="docs/media/DSToast.gif" width="120" alt="DSToast"> | [DSToast](docs/components/DSToast.md) | Success, error, warning and info toasts that VoiceOver announces. |
| <img src="docs/media/DSEmptyState.gif" width="120" alt="DSEmptyState"> | [DSEmptyState](docs/components/DSEmptyState.md) | Icon, title, message and an optional call to action. |
| <img src="docs/media/Progress.gif" width="120" alt="Progress"> | [Progress](docs/components/Progress.md) | Circular, linear, gradient and step progress, animated numbers, shimmer skeletons. |
| <img src="docs/media/DSSkeleton.gif" width="120" alt="DSSkeleton"> | [DSSkeleton](docs/components/DSSkeleton.md) | Loading placeholders, plus `.dsSkeleton(_:)` to redact a real view in place. |
| <img src="docs/media/DSSuccessCheck.gif" width="120" alt="DSSuccessCheck"> | [DSSuccessCheck](docs/components/DSSuccessCheck.md) | A success seal that draws itself and pops, with a haptic on the beat. |
| <img src="docs/media/DSThinkingIndicator.gif" width="120" alt="DSThinkingIndicator"> | [DSThinkingIndicator](docs/components/DSThinkingIndicator.md) | Ambient "thinking" state for AI and background work. |
| <img src="docs/media/DSTypewriterText.gif" width="120" alt="DSTypewriterText"> | [DSTypewriterText](docs/components/DSTypewriterText.md) | Types phrases out character by character, with a blinking caret. |
| <img src="docs/media/DSExpandableText.gif" width="120" alt="DSExpandableText"> | [DSExpandableText](docs/components/DSExpandableText.md) | Long copy that collapses to a few lines and springs open, with a Show more / Show less toggle. |
| <img src="docs/media/Motion.gif" width="120" alt="Motion"> | [Motion](docs/components/Motion.md) | `.dsBreathe`, `.dsJiggle`, `.dsPopIn`, `.dsEdgeSweep` and `.dsHueDrift` modifiers for any view. |
| <img src="docs/media/DSConfetti.gif" width="120" alt="dsConfetti"> | [dsConfetti](docs/components/DSConfetti.md) | A themed confetti burst from any point, fired when a trigger changes. |

Layout helpers: `DSScreen`, `DSVStack`, `DSHStack`, `DSGrid`, `DSHorizontalScroll`. The maintainers' reference for every component, with status and backlog, is in [docs/components.md](docs/components.md).

## Examples

Three small flows built only from the components above. They're examples, not components: open them in the Gallery, then copy one and adapt it.

| Example | What it shows |
|---|---|
| [Onboarding](docs/examples/Onboarding.md) | Paged welcome with a typed headline, a live theme picker that re-themes the screen, notification toggles, and a success seal with confetti. |
| [Settings](docs/examples/Settings.md) | Grouped glass rows with toggles and a segmented control, a "Saved" toast, and account deletion behind a sheet with slide-to-confirm. |
| [Checkout](docs/examples/Checkout.md) | Quantity steppers, a promo code, a total that rolls as it changes, slide-to-pay with a declined-card path, and a success moment. |

```bash
swift velvet.swift add Checkout --dest MyApp/VelvetUI   # copies the flow and every component it uses
```

## Use it with AI agents

Velvet is written to be used by coding agents as well as people.

- **[`AGENTS.md`](AGENTS.md)** has the rules, a component chooser, a token cheat sheet, copyable patterns and the anti-patterns to avoid. Point your agent at it with one line in your project's `AGENTS.md`, `CLAUDE.md` or `.cursor/rules`:
  ```text
  UI uses Velvet UI. Follow https://raw.githubusercontent.com/MatiasPC/velvet-ui/main/AGENTS.md
  ```
- **[`llms.txt`](llms.txt)** is the index and **[`llms-full.txt`](llms-full.txt)** holds every doc page in one file, so an agent can load the whole API at once.
- **[`registry.json`](registry.json)** lists every component with its source files, dependencies, docs page and Gallery stage. `scripts/velvet.swift` reads it to copy components.
- Every snippet in the README, `AGENTS.md` and the component pages is compiled by the test suite, so what an agent copies matches the current API.

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
- **Dynamic Type.** Text styled with `.ds(_:)`, `.dsTextStyle(_:)` or `.dsFont(_:)` scales with the user's text size, and looks identical at the default size. Buttons, text field input, the segmented control and badges keep a fixed label size for now. The stepper, code field and slide-to-confirm scale their text inside a fixed-height control.
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

[`Examples/VelvetGallery`](Examples/VelvetGallery) is a runnable iOS app with one screen per component, the example flows, and a clean full-screen recording stage for each. Open `Examples/VelvetGallery/VelvetGallery.xcodeproj` and press Run. [docs/RECORDING.md](docs/RECORDING.md) shows how to record clips from the simulator.

## Documentation

- [Component pages](docs/components/): one per component
- [Examples](docs/examples/): onboarding, settings and checkout flows
- [AGENTS.md](AGENTS.md): rules, patterns and anti-patterns for agents (and people)
- [Tokens](docs/tokens.md): every color, surface, type style, spacing, radius, motion and haptic value
- [Engineering notes](docs/engineering-notes.md): architecture decisions and gotchas
- [Proposals](docs/proposals/): design proposals behind each version
- [Changelog](CHANGELOG.md)

## Velvet UI Pro (coming soon)

Complete screens, flows and an app starter built on this free core, in a separate package. The core stays MIT and complete: nothing here moves behind Pro. [What's planned](docs/PRO.md), and [tell us what you'd want in it](https://github.com/MatiasPC/velvet-ui/discussions).

## Contributing

Bug reports, fixes and component proposals are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) for the rules every component follows and the definition of done. This project follows a [Code of Conduct](CODE_OF_CONDUCT.md).

## License

Velvet UI is released under the [MIT License](LICENSE). Copyright © 2026 Matias Peralta.
