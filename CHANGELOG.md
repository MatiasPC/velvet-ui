# Changelog

All notable changes to Velvet UI. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer. Until 1.0, minor versions may change visual output; public API changes are always listed here.

## [Unreleased]

### Added
- `DSChip` and `DSChipGroup`: selectable pill chips for filters, tags and category pickers, laid out with a wrapping flow `Layout` and managing single (`Binding<Value?>`) or multiple (`Binding<Set<Value>>`) selection. Generic over any `Hashable` value, with a `String` convenience. Selection springs the fill into the accent and ticks a selection haptic.

## [0.2.0] — 2026-10-23

The first tagged release, and the first you can install by version with SwiftPM. It folds together the v0.2 glass surface language (logged earlier as an untagged "0.2.0 — 2026-09-05") and everything since: the motion library, slide-to-confirm with async results, an accessibility pass, and the rename to `VelvetUI`.

### Highlights
- **Glass over a gradient theme.** Three built-in themes (Sunset, Aurora, Lagoon), every component reads its colors through `@DSThemed`, dark mode everywhere, no borders. Proposal: [docs/proposals/0001-glass-tokens.md](docs/proposals/0001-glass-tokens.md).
- **Motion.** Five ambient modifiers (`dsBreathe`, `dsJiggle`, `dsPopIn`, `dsEdgeSweep`, `dsHueDrift`) and four motion components: `DSSlideToConfirm`, `DSStepper`, `DSThinkingIndicator`, `DSTypewriterText`. Proposal: [docs/proposals/0002-motion-library.md](docs/proposals/0002-motion-library.md).
- **Accessibility.** VoiceOver labels, values and traits on every interactive control; text styles scale with Dynamic Type; Reduce Motion and Reduce Transparency honored.
- **Ready to share.** MIT license, CI, a docs page per component, and a demo app with recording stages.

### Breaking changes — migrating from 0.1
- The SwiftPM package, product and target are renamed from `DesignSystem` to **`VelvetUI`** (sources now live in `Sources/VelvetUI/`, tests in `Tests/VelvetUITests/`). Migrate with `import DesignSystem` → `import VelvetUI`, and in `Package.swift` depend on `.product(name: "VelvetUI", package: "velvet-ui")`. Xcode projects that added the package locally need the `DesignSystem` framework removed and `VelvetUI` added under the target's *Frameworks, Libraries, and Embedded Content*. Every type keeps its `DS` prefix; no symbol was renamed. The iOS build scheme is now `VelvetUI`.
- Package now targets **iOS 18 / macOS 15** (was iOS 17 / macOS 14). Apps must update their deployment targets.

### Added
- `DSGradientTheme` with three built-in themes (`.sunset` default, `.aurora`, `.lagoon`), each with `accent`, `onAccent`, `ink`, `inkDark`, `lightWash`, `darkDim`.
- `DSTheme.gradient` and `@DSThemed` property wrapper: components resolve palette + gradient for the current color scheme and re-render on theme changes.
- `DSResolvedTheme` (`accent`, `onAccent`, `ink`, `washSurface`, `washEdge`, `subtleFill`, `onBackdrop`).
- `DSSurface` glass levels and `.dsSurface(_:radius:edge:)`; falls back to solid under Reduce Transparency.
- `DSWash`: `surface(for:)`, `edge(for:)`, focus constants; `.dsWashEdge(radius:)`, `.dsFocusGlow(_:radius:isActive:)`.
- `DSBackdrop` view, `.dsBackdrop()` modifier, `EnvironmentValues.dsOnBackdrop`, `DSScreen(backdrop:)`.
- `DSShadow.glow(Color)` and `DSShadow.color(for:)`.
- `DSRadius.card` (20), `.surface` (16), `.control` (12), `.chip` (pill).
- `DSPress` (`scale` 0.96, `iconScale` 0.88, `animation`).
- `DSTextStyle.numeric` (17 semibold rounded, monospaced digits) and `.badge` (11 bold rounded).
- `Color.dsDynamic(light:dark:)`.
- `DSCard` previews over the backdrop in light and dark, plus a no-backdrop fallback preview.
- Tests: gradient theme AA contrast (onAccent/accent, ink/white, inkDark/dark glass), theme resolution, press constants, radius aliases.
- `View.dsFont(_:)`: applies a text style's font scaled with Dynamic Type.
- `DSTextStyle.size`, `.weight`, `.design`, `.textStyle` (the Dynamic Type curve) are now public.
- `Examples/VelvetGallery/` — a runnable per-component demo app: one screen per component, neutral non-gradient theme, System/Light/Dark toggle. For demos and video capture. XcodeGen project consuming the package as a local dependency; `Package.swift` untouched and not part of `swift build` / `swift test`. The generated `.xcodeproj` is committed (open and Run, no commands) and now covers the motion set too — `MotionScreen`, `SlideToConfirmScreen` (async slide-to-pay), `StepperScreen`, `ThinkingIndicatorScreen`, `TypewriterTextScreen`.
- `DSAnimation.ambient`: easeInOut 1.8s, the base curve for ambient loops.
- `DSMotion` enum: constants `breatheDuration` 2.4s, `sweepDuration` 2.0s, `driftDuration` 8.0s, `driftDegrees` 12, `jiggleDegrees` 7, `jiggleDuration` 0.45s, `jiggleSwings` (the five-point decay envelope).
- `DSMotion.loop(_:autoreverses:unless:)` — wraps an animation in `repeatForever`, or returns `nil` when Reduce Motion is on, so ambient effects settle at rest instead of being skipped.
- `DSBreatheIntensity` enum: `.subtle` (scale 1.02), `.medium` (1.05, default), `.strong` (1.10).
- View modifiers: `.dsBreathe(_ intensity:)` (ambient swell), `.dsJiggle(trigger:)` (one decaying shake), `.dsPopIn(delay:)` (springBouncy entrance), `.dsEdgeSweep(radius:isActive:)` (specular highlight on edge), `.dsHueDrift(isActive:)` (slow hue rotation).
- `DSSlideToConfirm`: slide-to-confirm gate for destructive actions; rigid haptic on threshold, success on confirm, light on snap-back.
- `DSSlideFinish` enum: `.settle` (default, rests in place) and `.morphAndVanish` (pill collapses to a circle, resolves, then dissolves leaving its layout slot).
- `DSThinkingIndicator`: ambient processing indicator with animated symbol and phrase cycling.
- `DSTypewriterText`: character-by-character typing with blinking caret and phrase looping.
- `DSStepper`: numeric stepper with selection haptic per step, warning haptic and jiggle at bounds.
- `DSIconButton(accessibilityLabel:)`: optional VoiceOver label for icon-only buttons, placed before `action` so existing call sites compile unchanged.
- `ComponentCatalog` — Motion section demoing all five modifiers, plus a section for each of the four new components.
- Tests: 8 new tests for DSMotion covering Reduce Motion nil contract, drift/jiggle bounds, breathe intensities, ambient curve timing, jiggle-envelope decay and jiggle duration.
- `LICENSE`: Velvet UI is MIT-licensed.
- CI on GitHub Actions: `swift build` + `swift test` on macOS, `xcodebuild test` on an iOS Simulator and a VelvetGallery build, on pushes to `main` and on pull requests.
- A page per component in `docs/components/` (usage snippet, parameters, variants, behavior, accessibility). Every snippet in those pages and in the README is compiled by the test suite (`DocSnippets*Tests`).
- VelvetGallery recording stages: a clean full-screen stage per component (neutral or gradient background, light or dark, optional autoplay), launch arguments to open one directly, and `scripts/record-stage.sh` to record a clip and GIF from the simulator. See `docs/RECORDING.md`.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), issue forms for bugs and component requests, a pull request template, and `docs/RELEASING.md`.
- Tests: Dynamic Type mapping and fixed-font equality for every text style, VoiceOver string builders.
- **New components**, each with a docs page, a Gallery screen and recording stage, light and dark previews, a `ComponentCatalog` section and tests:
  - `DSTabBar` / `DSTabItem`: floating glass tab bar with a sliding accent capsule, a selected-symbol swap with one bounce, and count badges.
  - `DSCarousel`: snapping carousel with peeking neighbors and scroll-driven depth; index-based so it pairs with `DSPageControl`.
  - `View.dsSheet(isPresented:detents:onDismiss:content:)` and `dsSheet(item:…)`: the native sheet with Velvet chrome (detents, grabber, glass background before iOS 26, the theme carried in).
  - `DSNumberTicker`: odometer-style rolling digits for any `FormatStyle` (currency, percent, grouped integers).
  - `DSSparkline` and `DSBarChart`: light animated charts without Swift Charts (monotone curve that draws and morphs, staggered bars, drag to scrub, VoiceOver Audio Graphs).
  - `DSSkeleton` and `View.dsSkeleton(_:)`: shimmering placeholder blocks, and an in-place redaction that keeps the wrapped view's identity and state.
  - `DSSuccessCheck`: success seal whose ring, disc and check draw on, then pop with a haptic on the beat.
  - `View.dsConfetti(trigger:origin:count:haptic:)`: themed confetti burst with closed-form `Canvas` physics; its timeline sleeps when idle; removed under Reduce Motion.
- **Example flows** (examples, not components): Onboarding, Settings and Checkout in `Examples/VelvetGallery/VelvetGallery/Flows/`, with an Examples section and full-screen stages in the Gallery and pages in `docs/examples/`.
- **Agent-ready files:**
  - `AGENTS.md`: public guide for AI coding agents with the rules, a component chooser, a token cheat sheet, copyable patterns and anti-patterns. Its snippets are compiled by `DocSnippetsAgentsTests`.
  - `llms.txt` and `llms-full.txt`, generated from the docs.
  - `registry.json`: every component with its source files, dependencies, docs page and Gallery stage.
  - `scripts/velvet.swift`, a dependency-free Swift CLI: `list`, `info`, `add` (copies a component plus the shared core into an app, leaves out previews, updates files you haven't edited and skips the ones you have, writes nothing if a download fails), and the maintainer commands `verify` (typechecks every component on its own in Swift 5 and 6, Debug, for macOS and iOS) and `llms [--check]`.
  - `RegistryTests`: the registry covers every source file, docs page and stage.
- `docs/PRO.md`: proposal for a separate, paid Velvet UI Pro package (screens, flows, app starter, presets) that leaves the free core complete.
- `docs/discoverability.md`: repository description, GitHub topics and the social preview image spec.
- CI runs `velvet.swift verify` and `velvet.swift llms --check`.
- README and component pages show real stills of every stage instead of placeholders. Recordings later replace them with animated GIFs.

### Changed
- **DSTheme is `@Observable`** (still conforms to `ObservableObject`). `@Published` removed; `@StateObject` / `@EnvironmentObject` call sites keep compiling.
- **Components read colors from the theme** instead of `DSColors.defaultPalette`. Dark mode now reaches every component; the accent follows the active gradient theme.
- **Color defaults in public inits are now `Color? = nil`** (nil = follow the theme). Same labels and positions — source-compatible. Affected: `DSIconButton.color`, `DSBadge.color`, `DSCountBadge.color`, `DSSegmentedControl.accent`, `DSToggle.onColor`, `DSRating.tint/emptyColor`, `DSPageControl.activeColor/inactiveColor`, `DSCircularProgress`, `DSLinearProgress`, `DSGradientProgress.colors` (`[Color]?`), `DSStepProgress`, `DSScreen.backgroundColor`.
- `DSColors.primary`, `.textPrimary` and all static accessors are adaptive light/dark (previously always light).
- Default palette: `primary` is the Sunset accent `#FF7E5F`, `primaryVariant` the Sunset ink `#C2361A`, `secondary` the Aurora accent `#7F5AF0`, `tertiary` the Lagoon accent `#16F2B3`; `borderFocused` follows the ink. Dark palette aligned the same way.
- `DSShadow` values softened: sm 8/0.04/2, md 16/0.06/4, lg 24/0.08/8, xl 32/0.10/12 (radius/opacity/y). Modifier is color-scheme aware.
- `DSAnimation` curves: `micro` 0.20s standard, `fast` 0.24s, `normal` 0.32s, `slow` 0.48s, all cubic timing curves. Springs unchanged.
- Typography: `hero`, `largeTitle`, `title1`, `title2` are SF Pro (was Rounded) with tracking −0.8 / −0.6 / −0.4 / −0.3; `title3` −0.2; `overline` +1.2; display styles use monospaced digits with −1.2 / −0.6.
- `DSCard`: default radius 16 → 20; `.elevated` is `.glass` + edge + `.md` shadow, `.outlined` is `.glassThick` + edge (no stroke), `.flat` uses `subtleFill` (visible on plain screens now).
- `DSButton`: `.primary` uses `accent` / `onAccent`; `.outline` and `.ghost` use `ink`; small size is a pill (was 8pt).
- `DSInteractiveCard` press scale 0.97 → 0.96 (`DSPress.scale`).
- `DSCountBadge` uses tokens (`DSTextStyle.badge`, `DSSpacing`, palette) instead of raw values.
- `dsCornerRadius(_:)` no longer takes stroke parameters; the stroking overload is deprecated.
- Text styles (`.ds(_:)`, `.dsTextStyle(_:)`) now scale with Dynamic Type; identical at the default size. `DSTextStyle.font` stays fixed-size. `DSThinkingIndicator` scales; fixed-height controls do not yet.
- VoiceOver: `DSToggle` has the toggle trait; `DSSegmentedControl` exposes one button per segment with selected state; `DSCodeField` is a single "Verification code" element reading the digits; `DSPageControl` is one adjustable "Page N of M" element; `DSToast` reads "<Type>: <message>" and announces on appear.
- `DSSlideToConfirm`: accessibility hint is now "Double-tap to confirm" and it reports a value ("Processing" / confirmed label).
- `DSRating` no longer carries the button trait (adjustable only).
- `DSSlideToConfirm.onConfirm` is now `async throws`, so one closure carries a payment's latency and its outcome. The control spins while awaiting it (500ms floor, applied after the closure returns) and treats a thrown error as a refusal: `.error` haptic, then it re-opens for a retry. **Not source-breaking** — `() -> Void` is a subtype of `() async throws -> Void`, so existing call sites compile unchanged.
- `DSSlideToConfirm` gains a `finish:` parameter, placed after `accent:` so no existing parameter changes label or position.
- `DSSlideToConfirm` emits a cloud of motes around the finger for the whole gesture; their tint is the status channel, sweeping to `palette.success` on success and staying neutral on refusal. Suppressed under Reduce Motion or Reduce Transparency.
- `DSSlideToConfirm` drag haptics went from a single threshold tap to a detent texture: 8 `.soft` ticks across the travel with intensity ramped 0.2 → 0.6, plus the existing `.rigid` at the threshold.
- `.dsJiggle(trigger:)` motion reworked from a stepped `phaseAnimator` (five spring-settled phases, read as robotic) to one continuous `keyframeAnimator` track over `jiggleSwings` / `jiggleDuration`. Same API, same peak, smoother decay.
- `swift-tools-version` raised from 5.9 to 6.0; language mode explicitly pinned to Swift 5 via `swiftSettings` (the tools version does not imply Swift 6 here).
- `.dsPulse()` now respects Reduce Motion. It previously looped regardless of the setting; the guard was added on the way to deprecating it. Its curve is unchanged.
- README: a new hero with the value props and quick links, a "copy one component" install path, Examples, "Use it with AI agents", and a short "Pro (coming soon)" section.
- `AGENTS.md` at the repo root is now published (it was gitignored). `CLAUDE.md`, `.claude/` and `.opencode/` stay local.
- Component pages and `docs/tokens.md` were audited against the source and corrected. For example, `DSStepper` glyphs default to theme ink, `DSSegmentedControl.accent` only tints the underline style, `DSSlideToConfirm.accent` fills only the knob, and several Dynamic Type notes were fixed. The Install block is now identical on every page.
- `scripts/record-stage.sh` forces English and US formatting so prices read "$115.00", and keeps the full height for the full-screen example flows.

### Deprecated
- `dsCornerRadius(_:strokeColor:strokeWidth:)` — Velvet doesn't draw borders; use `dsSurface` or `dsWashEdge`.
- `DSAnimatedValue` — unused; removal planned for 0.3.
- `.dsPulse()` — use `.dsBreathe(_:)` instead.

### Fixed
- `dsStaggerIn` was a no-op (animated a constant). It now fades and rises with the stagger delay and respects Reduce Motion.
- `DSShimmer` used a fixed 200pt offset and broke on wide views; the sweep is now width-independent and scheme-aware.
- `DSImageCard` and `DSAvatar` accepted `imageURL` and ignored it; both load it with `AsyncImage` and fall back to the placeholder / initials.
- `DSCard(style: .flat)` was invisible on a white screen.
- Dark palette was never applied to components.
- `DSSlideToConfirm` knob is now a circle as tall as the track (was inset 4pt top and bottom), so no glass shows above or below it and it travels flush edge-to-edge. It's layered over the track's pill clip so its shadow isn't cropped.
- `DSSlideToConfirm` now fills the track edge-to-edge on confirm. The gradient trail stops at the knob's centre while dragging, so without this the trailing half of the track would stay uncoloured once the knob reaches the end.
- `DSSlideToConfirm` trail now stops at the knob's centre while dragging, so the opaque knob caps it with a true circle instead of the gradient showing square corners past the knob's edge.
- `DSSlideToConfirm` clears its instruction label the instant the confirmation commits. The letter-by-letter dissolve is paced by the drag (stagger up to `count × 0.05s`) and only reaches zero on an unhurried drag; a quick flick past the threshold used to leave lit text over the pill as it masked down to a circle. The label is now `phase`-gated like the knob glyph.
- `DSToast` now uses a solid background under Reduce Transparency. It painted its material directly before.
- `dsBreathe` and `dsHueDrift` now rest at scale 1 and 0° under Reduce Motion. Before, they froze at the peak of the effect.
- Sources compile in Swift 6 language mode when copied into an app target. `DSParticleField`'s `Animatable` conformance crossed actor isolation, and `DSTypewriterText` had a mutable static preference default.

## [0.1.0] — 2026-03-11

Initial release: tokens (colors, typography, spacing, radius, shadow, animation, haptics), components (button, card, text field, search bar, list cell, section header, divider, badge, count badge, avatar, toast, empty state, progress ×4, animated number, shimmer, pulse), layout helpers, ComponentCatalog preview. Later additions before 0.2: `DSSegmentedControl`, `DSToggle`, `DSRating`, `DSPageControl`, `DSCodeField`.

[Unreleased]: https://github.com/MatiasPC/velvet-ui/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/MatiasPC/velvet-ui/releases/tag/v0.2.0
