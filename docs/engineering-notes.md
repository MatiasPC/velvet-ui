# Engineering notes

Decisions, gotchas and open issues that aren't obvious from the code. Read before adding a component or integrating Velvet into an app. Add to it whenever you hit something that cost you more than ten minutes.

## Architecture decisions

**Theme resolution goes through `@DSThemed`, never through statics.** Components used to read `DSColors.defaultPalette` directly, which meant dark mode and live theming never reached them (v0.1 bug). Every view now declares `@DSThemed private var theme` and paints from the `DSResolvedTheme` it returns. The static `DSColors.x` accessors exist only for code without an environment (previews, models).

**`DSTheme` is `@Observable` and `ObservableObject` at the same time.** `@Observable` (iOS 17 / macOS 14) is what makes reads inside `body` re-render on change, even through `@Environment`. `ObservableObject` stays so v0.1 call sites using `@StateObject` / `@EnvironmentObject` compile. There is no `@Published`: those wrappers would not fire `objectWillChange`, but Observation tracking still updates their views. Don't rely on `objectWillChange` for `DSTheme`.

**`Color? = nil` defaults.** A public init can't read the environment, so the only way a default can "follow the theme" is to be nil and resolve in `body`. Keep labels and positions identical when converting a parameter; that keeps every existing call site compiling.

**Accent vs palette.** The gradient theme owns `accent`, `onAccent`, `ink`, `inkDark`. `DSColorPalette` owns neutrals and status colors. The palette's `primary` mirrors the Sunset accent only so raw-token code lines up with the default theme; components must not use `palette.primary` for the accent role.

**Dark mode is the same gradient plus a black dim (`darkDim`)**, not a second gradient palette. One number to tune, hue preserved, half the maintenance.

**`DSColorPalette` is frozen at 19 slots.** Its memberwise init is public; adding a slot breaks every custom palette. Put new color concepts in a new type (that's why `DSGradientTheme` exists).

**No borders.** Separation = material density + `DSWash.edge` + shadow. The `.outline` / `.outlined` variants stay in the API and will render as wash (pending restyle). `dsCornerRadius(_:strokeColor:)` is deprecated.

## Gotchas

| Topic | What to know |
|---|---|
| `swift build` only builds macOS | The package targets iOS 17 + macOS 14. `swift build` / `swift test` compile the macOS slice. iOS-only modifiers (`keyboardType`, `textContentType`, `navigationBarTitleDisplayMode`, …) must be inside `#if os(iOS)`. Always also run `xcodebuild build -scheme DesignSystem -destination 'generic/platform=iOS Simulator'`. |
| Haptics are a no-op on macOS | `DSHapticEngine` is guarded with `#if canImport(UIKit)`. Fine, just don't expect feedback in macOS previews. |
| `@DSThemed` is `@MainActor` | It works in any `View` / `ViewModifier` body. It cannot live in an enum or a non-view struct; pass `theme.palette` into helpers instead (see `DSToastType.color(in:)`). |
| Material over a saturated gradient | `.ultraThinMaterial` lets too much color through and secondary text loses contrast. Cards use `.thinMaterial` (`.glass`); reserve `.glassThin` for small floating elements. |
| Shadows show through glass | A shadow under a translucent view is visible through it as a darker rim. With the v0.2 opacities it reads as a soft halo. If a specific layout looks muddy, add `.compositingGroup()` before `.dsShadow`. |
| `subtleFill` depends on the backdrop flag | `theme.subtleFill` is the wash only inside `.dsBackdrop()` / `DSScreen(backdrop: true)` (they set `dsOnBackdrop`). Elsewhere it's `backgroundSecondary`, otherwise the wash would be invisible on white. |
| Theme crossfade | `DSBackdrop` animates the gradient swap with `DSAnimation.normal` keyed on the theme id. Change the theme inside `withAnimation(DSAnimation.normal)` so components crossfade too. |
| Reduce Transparency / Reduce Motion | `dsSurface` falls back to `.solid`; `dsStaggerIn` and `dsShimmer` skip their animation. Keep honoring both in new components. |
| `Color` equality | `Color` is `Equatable`, so `DSGradientTheme` is `Equatable`/`Sendable` for free. Compare themes by `id` when you only care about identity (cheaper, and what `DSBackdrop` does). |
| Contrast is tested | `DesignSystemTests.testGradientThemesMeetAAContrast` resolves colors via `NSColor`/`UIColor` and asserts ≥ 4.5:1 for onAccent/accent, ink/white, inkDark/`#1A1A2E`. A new theme that fails this is not shippable. |
| One checkout only: `~/Documents/velvet-ui` | The stale `~/Documents/DesignSystem` clone was removed on 2026-09-06. Global CLAUDE.md and the `design-system` skill now point here. Apps add the package as `relativePath = ../velvet-ui`; the SwiftPM product stays named `DesignSystem`. Apps created before that date still reference `../DesignSystem` and must be repointed to `../velvet-ui` when next opened (MindBite, Tic-tac-toe, AquaSync, Tetris-Silver, Tetris-game, PowderRush, snake). |

## Known issues / backlog

Tracked here until they become issues or PRs.

- **Glass restyle pending** on DSButton (secondary/outline as glass/wash, glow on primary), DSTextField/DSSearchBar (wash + focus glow), DSCodeField (wash boxes), DSBadge `.outline`, DSToggle track, DSSegmentedControl track, DSToast (edge + radius 16), progress tracks. Colors are already theme-driven; only surfaces remain. Do it component by component after the manual walkthrough.
- **Literals still in components**: control heights (48 text field, 44 search bar), icon sizes (12/14/16/18). Introduce `DSControlSize` / `DSIconSize` tokens when the third consumer appears, not before.
- **`DSAnimatedValue`** deprecated, remove in 0.3.
- **ComponentCatalog is internal**; the showcase app (separate target, next milestone) will need its own views built on public API.
- **No snapshot tests.** Visual regressions are caught by the manual walkthrough only. Consider swift-snapshot-testing once the showcase app exists.
- **`DSTheme` default instance** (`DSThemeKey.defaultValue`) is a separate object from any theme an app creates. Always inject with `.dsTheme()` at the root or you'll be theming the default and wondering why nothing changes.

## VelvetGallery example app

`Examples/VelvetGallery/` is a runnable iOS app for demoing components one per
screen (the internal `ComponentCatalog` `#Preview` stays for quick dev checks).

- **Neutral by design.** The design system is gradient-first; the gallery is not.
  It injects a gallery-local `DSGradientTheme.neutral` (graphite accent via
  `Color.dsDynamic`) and never calls `.dsBackdrop()`, so components are shown on
  a plain `DSColors.backgroundPrimary`. Semantic status colours are kept;
  decorative defaults (e.g. `DSRating` amber tint, `DSGradientProgress` stops)
  are shown neutral with one labelled colourful example each.
- **Not in `swift build`.** It lives outside `Sources/`; `Package.swift` is
  untouched. The project is XcodeGen-generated from `project.yml`; the
  `.xcodeproj` is not committed (repo ignores `*.xcodeproj/`) — run
  `xcodegen generate` after cloning or after changing its file list.
- **Consumes the package** as a local SPM dependency at `../..`.
- Spec: `docs/superpowers/specs/2026-09-08-velvet-gallery-app-design.md`.

## Roadmap

1. ✅ v0.2 foundations: tokens, theme plumbing, DSCard as the glass reference.
2. Manual walkthrough of every component and variant in the catalog (owner: Mati).
3. Apply the glass restyle to the remaining components, one PR each, with before/after previews.
4. ✅ **Velvet UI Showcase** app — see "VelvetGallery example app" above (`Examples/VelvetGallery/`, neutral theme, one screen per component). Does not modify the package.
5. New components on top of the base: carousels, sheets, animated transitions.

## How to add a component (checklist)

1. Build it in a real app first; only reusable, polished, non-duplicate work gets in.
2. `Sources/DesignSystem/Components/DS<Name>.swift`, types prefixed `DS`, public with a minimal API.
3. Tokens only. `@DSThemed` for colors, `Color? = nil` for overridable ones, `DSPress` for press, `DSAnimation` springs, `DSHapticEngine` on primary actions, `#if os(iOS)` around iOS-only modifiers.
4. `#Preview` in light and dark, on `.dsBackdrop()`.
5. Section in `ComponentCatalog`.
6. Entry in `docs/components.md`, line in `CHANGELOG.md` under Unreleased.
7. `swift build`, `swift test`, iOS `xcodebuild`.
8. Commit `add: DS<Name> — one line`, PR, update the `design-system` skill references.
