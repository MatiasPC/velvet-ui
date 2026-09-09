# 0002 — Motion library: adapting open-swiftui-animations to Velvet UI

**Status:** proposed · **Date:** 2026-09-05 · **Depends on:** [0001 — Arc tokens](0001-arc-tokens.md)

## Why

v0.2 gave Velvet UI a surface language (glass over a gradient theme). What it does not
have yet is a *motion* language beyond press-and-spring. `DSAnimation` holds the curves,
but the catalog has only two decorative effects (`dsShimmer`, `dsPulse`) and no
motion-first components.

[amosgyamfi/open-swiftui-animations](https://github.com/amosgyamfi/open-swiftui-animations)
is the best public collection of pure-SwiftUI motion techniques (75 files, iOS 17+
`PhaseAnimator` / `KeyframeAnimator` / symbol effects). We mine it for **techniques**, not
code, and rebuild each one on our tokens.

### Licensing / attribution

The upstream repo ships **no LICENSE file**, so it is all-rights-reserved by default.
We therefore **do not copy any of its source**. Every file we add is written from scratch
against the Velvet API; what we take is the technique (which SwiftUI API composes the
effect), which is not itself protectable. Each adapted component carries a
`// Technique inspired by: <upstream file>` comment and the reference is credited once in
`docs/components.md`. A vendored copy of the upstream repo is never committed.

## What makes an animation "Velvet"

The upstream demos are gorgeous and completely un-shippable: hardcoded `.systemPink`,
`repeatForever` with no Reduce Motion escape, magic numbers, UIKit layers, no haptics.
Our version of any of them must satisfy all six:

1. **Springs, not ramps.** Anything the finger drives uses `DSAnimation.spring*`.
   `easeInOut` is reserved for ambient loops (shimmer, breathing) where a spring reads wrong.
2. **Color from the theme.** Bursts, particles and sweeps pull from `theme.gradient.stops`
   / `theme.accent` / `theme.ink`. Never a literal `Color`.
3. **Reduce Motion is a first-class state,** not a bail-out. Every looping effect has a
   legible static end-state; every transition degrades to a cross-fade.
4. **Glass, not fills.** Tracks, pills and containers are `dsSurface` + `washEdge`. No strokes.
5. **Haptics land on the beat.** The tactile hit and the visual peak are the same moment
   (`DSHapticEngine`), on threshold crossings and completions — not on every frame.
6. **Both platforms.** Pure SwiftUI only. No `CAEmitterLayer` / `UIViewRepresentable`;
   particles are `Canvas` + `TimelineView`. iOS-only bits go inside `#if os(iOS)`.

## Inventory of the source (75 files)

| Cluster | Files | Verdict |
|---|---|---|
| Slide to cancel / unlock | 9 variants + `LockAnimationView` | **Adopt** → `DSSlideToConfirm` |
| AI thinking | `Thinking`, `Thinking2`, `CombinedSymbolEffects` | **Adopt** → `DSThinkingIndicator` |
| Typing / erasing | `TypingErasing` | **Adopt (rewrite)** → `DSTypewriterText` |
| Reactions — X like | `XLike1`, `XLike2`, `SplashView` | **Adopt** → `DSReactionButton` |
| Reactions — messenger | `EmotionalReactions`, `ReactionsView`, `JumpAndFall*`, `ScaleUp` | **Wave 2** → `DSReactionBar` |
| Duolingo loading | `DuoLoading`, `DuoGetStarted`, `SpringyDuoGetStarted`, `MusicNotes` | **Technique only** → `DSLoadingDots` (mascot art is theirs) |
| Increase / decrease | `IncreaseDecrease` | **Adopt** → `DSStepper` |
| Stacked spring | `StackedSpring` | **Wave 2** → `DSCardStack` |
| Bookmark fly | `AddToBookmark` | **Wave 2** → `.dsFlyTo()` |
| Flip X/Y/Z | `FlipXYZ`, `FlipCharactersXYZ` | **Defer** — `add/ds-flipcard` branch already covers it |
| Marching ants / moving border | `StreamLogoMarchingAnts`, dashPhase gist | **Reinterpret** → `.dsEdgeSweep()` (rule 5: no borders) |
| Pulsing hearts, heart rate, sun & wind | `PulsingHearts`, `MeasuringHeartRate`, `SunAndWind` | **Fold into** `.dsBreathe()` |
| Tutorials (3 ways to animate, completion criteria, eased curves) | 8 files | **Reference only** — no component |
| Christmas tree, fireworks, Mickey Mouse, handwritten Hello | 20 files | **Skip** — seasonal, asset-bound, or third-party IP |
| `EmitterParticles` | 1 | **Skip as written** — `CAEmitterLayer` breaks the macOS build |

## Proposed additions

### A. Motion primitives → `Sources/DesignSystem/Animation/DSMotion.swift`

Composable modifiers, each honoring Reduce Motion, each tokenised.

| API | What it does | Replaces / from |
|---|---|---|
| `.dsBreathe(_ intensity:)` | Scale + opacity swell on an ambient loop | Supersedes `dsPulse` (kept, deprecated) |
| `.dsJiggle(active:)` | Short attention wiggle, decays to rest | `wiggle` symbol effect, iOS 17-safe |
| `.dsPopIn(delay:)` | Entrance with `springBouncy` overshoot | Complements `dsStaggerIn` |
| `.dsEdgeSweep(radius:)` | A specular highlight travelling the surface edge | Marching ants, re-read as glass |
| `.dsHueDrift(active:)` | Slow hue rotation bounded to the active gradient | Hue-rotation slide variants |
| `DSMotion.loop(_:)` | One helper that returns `nil` under Reduce Motion | New — kills the repeated guard boilerplate |

`DSAnimation` also gains `ambient` (the 1.5–2s `easeInOut` used by every loop) so
looping durations stop being magic numbers.

### B. Components — wave 1

**`DSSlideToConfirm`** — the flagship. Glass track (`.dsSurface(.glassThin, radius: .chip)`),
knob filled with `theme.accent`, gradient wash revealed behind the knob as it travels, label
letters flowing toward the chevron with a per-letter stagger, `.rigid` haptic on threshold
crossing and `.success` on commit, spring snap-back on release below threshold.
API: `DSSlideToConfirm(label:icon:onConfirm:)`.

**`DSThinkingIndicator`** — AI/processing state. Symbol with layered effects (iOS 18
`.wiggle`/`.breathe` behind `#available`, `.pulse`/`.bounce` fallback on 17), plus optional
cycling phrases whose letters shimmer in `theme.ink`. Reduce Motion → static symbol + phrase.
API: `DSThinkingIndicator(phrases:symbol:)`.

**`DSTypewriterText`** — types and erases through a `[String]`, blinking caret in `theme.accent`.
The upstream version hardcodes 26 enum phases for one word; ours is data-driven and works on
any strings. API: `DSTypewriterText(_ phrases:typing:pause:)`.

**`DSStepper`** — `−` / value / `+` with `.contentTransition(.numericText())`, `DSTextStyle.numeric`,
`.selection` haptic per step, `.warning` at the bounds, glass track. Fills a real gap in the catalog.
API: `DSStepper(value:in:step:)`.

### C. Components — wave 2 (after the walkthrough)

`DSReactionButton` (heart + ring + Canvas particle burst in gradient stops),
`DSReactionBar` (long-press emoji picker, jump-and-fall), `DSLoadingDots`,
`DSCardStack`, `.dsFlyTo()`.

## Ordering, and what this does not touch

Wave 1 lands as **two PRs**: primitives first (`DSMotion` + `DSAnimation.ambient`, no
component depends on anything unreviewed), then the four components on top. Nothing here
changes an existing public API — `dsPulse` stays and is only marked deprecated.

Unrelated but worth recording: the seven `add/ds-*` branches (checkbox, chip, chipgroup,
confetti, flipcard, odometer, slider) all predate the v0.2 merge and would revert the token
layer if merged as-is. They need a rebase before any of them lands, and `DSConfetti` there
overlaps with wave 2's particle work — decide that one before building both.

## Open questions for review

1. Wave 1 scope — all four components, or `DSSlideToConfirm` alone as the proof of concept?
2. `dsPulse` — deprecate in favour of `dsBreathe`, or keep both as distinct effects?
3. iOS 18 symbol effects — accept `#available` branching, or stay on the iOS 17 subset only?
