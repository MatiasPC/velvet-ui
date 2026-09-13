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

**A capsule as wide as it is tall is a circle — so the morph is a mask, not a resize.** `DSSlideToConfirm(finish: .morphAndVanish)` collapses its pill into a circle by masking with a `Capsule()` inset from both ends until only `trackHeight` remains. The pill already carries `DSRadius.chip`, so no shape interpolation, no `matchedGeometryEffect` and no second view tree are needed. Masking rather than resizing also keeps the measured `trackWidth` stable through the whole collapse and stops the content underneath reflowing — which matters because at that point the control is one solid gradient and any reflow would show as glyphs jumping. The collapse can travel to the *centre* for the same reason: at 100% the trail fills edge to edge and the knob is filled with the same accent, so the knob is indistinguishable from the fill and never appears to walk backwards.

**Particle simulation is analytic, because a `Canvas` draw closure must be pure.** `DSParticleField` stores each mote's birth state in a fixed ring buffer and *computes* its position at any instant (`v = v₀·e^(-kt)`, so displacement is `(v₀/k)·(1 - e^(-kt))`) instead of accumulating it frame by frame. Mutating state from inside `Canvas { }` is illegal; the only writes happen in an `onChange(of: timeline.date)` beside it. The buffer is also why nothing enters or leaves the view tree while the finger is down — there is no layout work mid-drag, which is exactly when a hitch would be most visible.

**`Canvas` cannot animate a colour, so blend it by hand.** A `Color` passed into a draw closure snaps. `DSParticleField` conforms to `Animatable` over a `tintMix: Double`, resolves both endpoint colours against the environment with `Color.resolve(in:)` and interpolates the components itself. That is what lets one animated step sweep every live mote at once rather than recolouring them individually.

## Gotchas

| Topic | What to know |
|---|---|
| `swift build` only builds macOS | The package targets iOS 18 + macOS 15. `swift build` / `swift test` compile the macOS slice. iOS-only modifiers (`keyboardType`, `textContentType`, `navigationBarTitleDisplayMode`, …) must be inside `#if os(iOS)`. Always also run `xcodebuild build -scheme DesignSystem -destination 'generic/platform=iOS Simulator'`. |
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
| Reduce Motion is a resting state, not a skip | `DSMotion.loop` returns `nil` when Reduce Motion is on, so `withAnimation(nil)` applies changes instantly and every ambient effect settles at its resting state. Never wrap an effect in a bare `guard !reduceMotion else { return }` that leaves it mid-transition. |
| Decaying motion → `keyframeAnimator`, not `phaseAnimator` | `phaseAnimator` runs a fresh animation per phase and each one *settles* before the next fires, so a multi-swing shake reads as separate twitches. `dsJiggle` uses one `keyframeAnimator` track (`DSMotion.jiggleSwings`) whose Cubic keyframes carry velocity across the whole timeline. The `DSAnimation` springs are frozen and none is damped low enough to ring, so the decay is a hand-shaped envelope rather than an underdamped spring. |
| `swift-tools-version: 6.0` does not mean Swift 6 | The tools version is pinned to 6.0 for iOS 18 / macOS 15 symbol access, but language mode is explicitly `.v5` via `swiftSettings`. Raising it to Swift 6 language mode is a separate migration. |
| Animated text must reserve its layout | Any component whose text changes length mid-animation (`DSTypewriterText`, `DSThinkingIndicator`, `DSStepper`) stacks every candidate string invisibly in a `ZStack` and sizes to that. Picking the longest by `count` is not enough — `WWW` is wider than `iiiiii` — and under-reserving makes the surrounding layout jitter on every character. |
| `dsEdgeSweep` animates a Double that builds an AngularGradient | The view body re-evaluates per frame while the sweep runs. Keep it on small, leaf-ish surfaces; on a large subtree, put the sweep on a thin overlay shape rather than on the container itself. |
| A knob that fills a `dsSurface` track must be an overlay, not a child | `dsSurface` ends in `.clipShape`, so anything inside it (including a `.dsShadow`) is cropped to the pill. `DSSlideToConfirm` draws its knob in an `.overlay(alignment: .leading)` applied *after* `.dsSurface`: the circle is exactly `trackHeight` tall, nests into the pill's rounded ends, and its shadow renders outside the clip. Travel and the trail width then measure from a flush leading edge (no inset term). |
| A drag-paced dissolve still needs a phase gate | `DSSlideToConfirm`'s label fades letter by letter as a function of `progress`, with `DSAnimation.stagger` delays up to `count × 0.05s` and a `letterOpacity` curve that only reaches 0 when the drag is taken slowly to the end. On a fast flick past the 0.75 threshold the commit fires with letters still lit and the stagger outlasts the ~350ms collapse to a circle. Fix: gate the label on `phase` (`showsInstructionLabel` — `.idle`/`.dragging` only) exactly like `showsKnobGlyph` and `resolution`, so it clears on `DSAnimation.fast` the instant the choreography starts. Any progress-driven reveal that a commit can interrupt needs the same gate. |
| Carousel peek = `containerRelativeFrame` + `contentMargins`, not a manual width | `DSCarousel` sizes each card with `.containerRelativeFrame(.horizontal)` (one page per container width) and creates the neighbour peek with `.contentMargins(.horizontal, peek, for: .scrollContent)`, which narrows the page the card is measured against. Don't reach for a `GeometryReader` + fractional width: `GeometryReader` has no intrinsic height, so it would force the carousel to a fixed height. `containerRelativeFrame` sets width only and lets the height come from the card content, which is what a design-system component wants. `peek: 0` is a full-width pager. |
| `scrollPosition(id:)` fires on the initial layout | The bound id starts `nil` and becomes the first item's id on first layout — a change `.onChange` sees. `DSCarousel` guards its `.selection` haptic with `oldValue != nil && newValue != nil` so it ticks only when the user actually moves a new card into the centre, never once on appear. On the iOS 18 deployment target `scrollPosition(id:)` may show a deprecation notice (superseded by the `ScrollPosition` value type); it still compiles and behaves correctly on iOS 17+ and is kept for that range. |
| `scrollTransition(.interactive)` tracks the drag; `.animated` lags it | The focus effect in `DSCarousel` (scale + opacity by `phase.value`) uses the `.interactive` configuration so it follows the finger 1:1. The default `.animated` config animates the effect *after* the scroll settles, which reads as the neighbours popping rather than easing. `phase.value` is `0` at centre and `±1` at the edges, so `abs(phase.value)` is a clean 0→1 distance term. |

## Known issues / backlog

Tracked here until they become issues or PRs.

- **Seven legacy remote branches** (`add/ds-checkbox`, `add/ds-chip`, `add/ds-chipgroup`, `add/ds-confetti`, `add/ds-flipcard`, `add/ds-odometer`, `add/ds-slider`) predate the v0.2 merge and would revert the token layer if merged as-is. Each needs a rebase onto main before it can land. `DSConfetti` overlaps with the planned wave-2 particle work.
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
  untouched. `project.yml` is the source of truth (XcodeGen), but the generated
  `VelvetGallery.xcodeproj` **is committed** so the app opens and runs with no
  commands — `.gitignore` keeps the blanket `*.xcodeproj/` rule and negates just
  this one path. Re-run `xcodegen generate` and commit the result only after
  changing the file list or target settings. `xcuserdata/` stays ignored.
- **Consumes the package** as a local SPM dependency at `../..`.
- **Covers every component**, motion included: `MotionScreen` (the five
  `DSMotion` primitives), `SlideToConfirmScreen` (with the async slide-to-pay
  and a "next charge fails" toggle), `StepperScreen`, `ThinkingIndicatorScreen`,
  `TypewriterTextScreen`. The Simulator shows the animation; haptics need a
  device (Signing & Capabilities → set your Team, then run on the phone).
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
