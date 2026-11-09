# Velvet UI

**Glassy SwiftUI components with spring motion and haptics, for iOS 18+ and macOS 15+.**

[![CI](https://github.com/MatiasPC/velvet-ui/actions/workflows/ci.yml/badge.svg)](https://github.com/MatiasPC/velvet-ui/actions/workflows/ci.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2018%2B%20%C2%B7%20macOS%2015%2B-0A84FF)](#requirements)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-34C759)](#install)
[![License: MIT](https://img.shields.io/badge/license-MIT-8E8E93)](LICENSE)

<p align="center">
  <img src="docs/media/showcase.png" alt="A selection of Velvet UI components on a light page: a checkout card with a toggle, a stepper and slide-to-pay, a one-time-code field, a toast, a tab bar, a segmented control, revenue charts, a slider, activity rings, filter chips and a rating with avatars">
</p>

<p align="center">
  <a href="#install"><b>Install</b></a> ·
  <a href="#components"><b>Components</b></a> ·
  <a href="#examples"><b>Examples</b></a> ·
  <a href="#use-it-with-ai-agents"><b>AI agents</b></a> ·
  <a href="#documentation"><b>Docs</b></a>
</p>

Frosted glass over a solid, neutral page tone you pick (Snow, Paper or Graphite). Every control springs when you touch it and lands a haptic on the beat, and there are no borders anywhere.

- **One look, three styles.** Change `theme.style` and the whole app crossfades. Each style pairs a flat page tone with an accent, and light and dark are two curated tones — never a gradient.
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
    @State private var theme = DSTheme(style: .sunset)
    var body: some Scene { WindowGroup { ContentView().dsTheme(theme) } }
}
```

Then use any component, anywhere below it:

```swift
struct ContentView: View {
    var body: some View {
        DSScreen(backdrop: true) {                  // the theme's solid page tone behind everything
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

A few of what's in the box:

| | |
|---|---|
| **Actions** | [DSButton](docs/components/DSButton.md) · [DSIconButton](docs/components/DSIconButton.md) · [DSSlideToConfirm](docs/components/DSSlideToConfirm.md) · [DSHoldToConfirm](docs/components/DSHoldToConfirm.md) |
| **Inputs** | [DSToggle](docs/components/DSToggle.md) · [DSStepper](docs/components/DSStepper.md) · [DSSlider](docs/components/DSSlider.md) · [DSSegmentedControl](docs/components/DSSegmentedControl.md) · [DSTextField](docs/components/DSTextField.md) · [DSCodeField](docs/components/DSCodeField.md) · [DSChip](docs/components/DSChip.md) |
| **Surfaces** | [DSCard](docs/components/DSCard.md) · [DSListCell](docs/components/DSListCell.md) · [DSCarousel](docs/components/DSCarousel.md) · [DSTabBar](docs/components/DSTabBar.md) · [dsSheet](docs/components/DSSheet.md) |
| **Data** | [DSBadge](docs/components/DSBadge.md) · [DSAvatar](docs/components/DSAvatar.md) · [DSNumberTicker](docs/components/DSNumberTicker.md) · [Charts](docs/components/Charts.md) · [DSActivityRings](docs/components/DSActivityRings.md) |
| **Feedback** | [DSToast](docs/components/DSToast.md) · [Progress](docs/components/Progress.md) · [DSSkeleton](docs/components/DSSkeleton.md) · [DSSuccessCheck](docs/components/DSSuccessCheck.md) · [Motion](docs/components/Motion.md) |

The rest are in [docs/components](docs/components/), one page each with a copyable snippet, every parameter, its variants and accessibility notes. `swift velvet.swift list` prints them all by category, and the [Demo app](#demo-app) has a screen for each.

Layout helpers: `DSScreen`, `DSVStack`, `DSHStack`, `DSGrid`, `DSHorizontalScroll`. The maintainers' reference for every component, with status and backlog, is in [docs/components.md](docs/components.md).

## Examples

Three small flows built only from Velvet components. They're examples, not components: open them in the Gallery, then copy one and adapt it.

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

A style is a flat page tone plus four derived colors: `accent` for fills, `onAccent` for text on the accent, and `ink` / `inkDark` for text and icons on glass in light and dark mode. Three styles ship built in, each on its own neutral background:

| Style | Background | Accent | Use it as |
|---|---|---|---|
| `.sunset` (default) | Paper: warm off-white / warm black | coral | `DSTheme(style: .sunset)` |
| `.aurora` | Snow: white / true black | violet | `DSTheme(style: .aurora)` |
| `.lagoon` | Graphite: cool grey / deep graphite | teal | `DSTheme(style: .lagoon)` |

- **Backdrop.** Glass needs something to blur. Wrap a screen in `DSScreen(backdrop: true) { … }` or add `.dsBackdrop()`. Without a backdrop, components still work and read as plain surfaces.
- **Switch at runtime.** Every component re-renders, and animating the change crossfades them:
  ```swift
  withAnimation(DSAnimation.normal) { theme.style = .lagoon }
  ```
- **Light and dark** are automatic. Every background carries one curated tone per scheme; there is no dim layer and no gradient to recolor.
- **Your own style.** `DSThemeStyle(id:name:background:accent:onAccent:ink:inkDark:)`, with a background from `DSBackground.all` or your own `DSBackground(id:name:light:dark:)`. The built-in styles pass a WCAG AA contrast test, and yours should too.
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

- **VoiceOver.** Interactive controls expose a label, a value and the right traits. `DSStepper`, `DSRating` and `DSPageControl` are adjustable (swipe up and down). `DSSlideToConfirm` confirms with a double-tap, so nobody has to drag. `DSToast` announces itself, and `.dsToast` adds a Dismiss action. Icon-only buttons take an `accessibilityLabel:`. Each component page lists exactly what VoiceOver reads.
- **VoiceOver.** Interactive controls expose a label, a value and the right traits. `DSStepper`, `DSRating` and `DSPageControl` are adjustable (swipe up and down). `DSSlideToConfirm` and `DSHoldToConfirm` confirm with a double-tap, so nobody has to drag or hold. `DSToast` announces itself. Icon-only buttons take an `accessibilityLabel:`. Each component page lists exactly what VoiceOver reads.
- **VoiceOver.** Interactive controls expose a label, a value and the right traits. `DSStepper`, `DSSlider`, `DSRating` and `DSPageControl` are adjustable (swipe up and down). `DSSlideToConfirm` confirms with a double-tap, so nobody has to drag. `DSToast` announces itself. Icon-only buttons take an `accessibilityLabel:`. Each component page lists exactly what VoiceOver reads.
- **Dynamic Type.** Text styled with `.ds(_:)`, `.dsTextStyle(_:)` or `.dsFont(_:)` scales with the user's text size, and looks identical at the default size. Buttons, text field input, the segmented control and badges keep a fixed label size for now. The stepper, code field and slide-to-confirm scale their text inside a fixed-height control.
- **Reduce Motion** puts ambient effects in a resting state instead of cutting them mid-animation. Gesture feedback stays, and decorative particles are removed.
- **Reduce Transparency** swaps glass for solid surfaces.
- **Contrast.** Each built-in style is tested for WCAG AA (4.5:1) on its accent and on both of its page tones.
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
