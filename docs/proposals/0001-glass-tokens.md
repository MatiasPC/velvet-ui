# 0001 — Glass surface language and gradient themes

**Status:** accepted and shipped in 0.2.0 · **Date:** 2026-09-05

This RFC records why Velvet UI moved from "white cards with shadows" to frosted glass over a selectable gradient theme, and which tokens that change introduced. It is the rationale behind the values in [docs/tokens.md](../tokens.md). Scope: visual layer and tokens only. Public component APIs and structure stay as they were, apart from the additive change in §3.

## 1. Starting point

Before 0.2 the system had a complete token set (colors, type, 4pt spacing, radii, shadows, motion, haptics) and a full component set, with four structural problems:

1. **Theming was disconnected.** `DSTheme` existed, but every component read the static light palette. The dark palette was never applied, and live theme switching was impossible.
2. **Surfaces relied on borders.** `.outline` / `.outlined` variants and focus rings were drawn with strokes, which reads flat on a colorful background.
3. **Shadows were hard and short** (radius 4–24, opacity up to 0.16).
4. **A single `primary` color did every job**: fills, text, focus, links. It could not satisfy contrast for all of them.

## 2. Proposal

**Kept:** springs, haptics on primary actions, the press scale, the 4pt grid, the type scale, layout helpers.

**Changed:** surfaces become glass (`Material`) over a gradient; separation comes from translucent washes and an edge highlight instead of strokes; shadows become soft and ambient; the accent derives from the active theme; curves get shorter durations; headlines use tighter tracking.

### 2.1 `DSGradientTheme`

A theme is a background gradient plus derived colors, each with one job:

| Slot | Use | Contrast rule |
|---|---|---|
| `stops: [Color]` | Screen backdrop, decorative fills, gradient progress | — |
| `accent` | Primary fill, toggle on, active page, active segment, rating | First stop (the vivid color) |
| `onAccent` | Text and icons on `accent` | ≥ 4.5:1 on `accent` |
| `ink` | Text, icons, links and focus on light glass | ≥ 4.5:1 on white |
| `inkDark` | Same, on dark glass | ≥ 4.5:1 on `#1A1A2E` |

| Theme | Stops | `accent` | `onAccent` | `ink` | `inkDark` |
|---|---|---|---|---|---|
| Sunset (default) | `#FF7E5F → #FEB47B` | `#FF7E5F` | `#2B1510` | `#C2361A` | `#FFA98F` |
| Aurora | `#7F5AF0 → #E84393` | `#7F5AF0` | `#FFFFFF` | `#6D47E6` | `#B9A3FF` |
| Lagoon | `#16F2B3 → #0DB4F7` | `#16F2B3` | `#06231D` | `#0B7D8C` | `#5EF5CB` |

- A dark `onAccent` on Sunset and Lagoon is deliberate: it avoids dulling the accent just to pass contrast.
- Dark mode is the same gradient under a black layer (`darkDim = 0.58`), not a second palette. It preserves hue and leaves one knob to maintain. Light mode adds a white wash (`lightWash = 0.08`).
- The gradient runs top-leading to bottom-trailing with a soft white radial light (0.18) near the top-left for depth.
- Sunset is the default for continuity with the previous coral accent.

### 2.2 `DSSurface`

Four levels, most transparent to most opaque, applied with `.dsSurface(_:radius:)` (material, continuous clip and edge highlight):

| Level | Material | For |
|---|---|---|
| `.glassThin` | `.ultraThinMaterial` | Chips, badges, toolbars, toast |
| `.glass` | `.thinMaterial` | Cards (default), list groups, inputs |
| `.glassThick` | `.regularMaterial` | Sheets, modals, popovers |
| `.solid` | elevated background | Reduce Transparency, or screens without `DSBackdrop` |

Cards default to `.glass`, not ultra-thin: over a saturated gradient, ultra-thin lets too much color through and secondary text loses contrast.

### 2.3 `DSWash` (replaces borders)

| Token | Light | Dark | Use |
|---|---|---|---|
| `surface` | white 0.45 | white 0.10 | Flat translucent fill to separate a surface inside another (no blur) |
| `edge` | white 0.55 → 0.05, 1pt | white 0.18 → 0.02 | Specular highlight on the glass edge; drawn inside with `strokeBorder`, so it never changes layout |
| `focus` | `ink` 0.35, 2pt, blur 2 | `inkDark` 0.35 | Diffuse glow replacing the focus ring |

The public `.outline` / `.outlined` variants stay as API but render as a denser wash with an edge, with no colored stroke.

### 2.4 `DSShadow`

Same API, larger radius and lower opacity:

| Level | Before (radius / opacity / y) | After |
|---|---|---|
| `.sm` | 4 / 0.04 / 1 | 8 / 0.04 / 2 |
| `.md` | 8 / 0.08 / 4 | 16 / 0.06 / 4 |
| `.lg` | 16 / 0.12 / 8 | 24 / 0.08 / 8 |
| `.xl` | 24 / 0.16 / 12 | 32 / 0.10 / 12 |

New `DSShadow.glow(accent)`: an accent-colored shadow (radius 20, opacity 0.28 light / 0.40 dark, y 8) reserved for the primary action and a toggle that is on. A shadow under a `Material` shows through as a halo; at these opacities it is acceptable, and `compositingGroup()` fixes it if not.

### 2.5 `DSRadius` roles

The numeric scale is unchanged. Semantic aliases make the hierarchy a rule instead of a convention:

| Alias | Value | For |
|---|---|---|
| `card` | 20 | First-level cards, sheets |
| `surface` | 16 | Nested surfaces: toast, list group, empty state |
| `control` | 12 | Medium and large buttons, inputs, code boxes |
| `chip` | pill | Badges, tags, small buttons, search bar, segmented pill |

`DSCard` defaults to 20 (was 16) and small buttons become pills. `.dsCornerRadius(strokeColor:)` is kept but deprecated in favor of `.dsSurface()`.

### 2.6 `DSAnimation`

Names stay; durations and curves change. Springs are untouched.

| Token | Before | After |
|---|---|---|
| `.micro` | 0.20 easeOut | 0.20, `timingCurve(0.25, 0.10, 0.25, 1.0)` |
| `.fast` | 0.30 easeInOut | 0.24, `timingCurve(0.20, 0, 0, 1.0)` |
| `.normal` | 0.40 easeInOut | 0.32, `timingCurve(0.20, 0, 0, 1.0)` |
| `.slow` | 0.60 easeInOut | 0.48, `timingCurve(0.30, 0, 0.10, 1.0)` |

New `DSPress` holds the shared press constants (`scale = 0.96`, `iconScale = 0.88`, `animation = springSnappy`). Side fixes: `dsStaggerIn` now actually animates, and `DSShimmer` measures its width instead of using a fixed offset.

### 2.7 `DSTypography`

Headlines move from the rounded design to the default design with negative tracking (hero −0.8, largeTitle −0.6, title1 −0.4, title2 −0.3, title3 −0.2). Buttons stay rounded. Display styles stay rounded and gain `monospacedDigit`. New `DSTextStyle.numeric` (17 semibold rounded, monospaced digits) for prices, counters and timers.

### 2.8 `DSBackdrop`

A public view that paints the active theme's gradient with the light/dark layer and radial light. `DSScreen` gains `backdrop: Bool = false`. Without a backdrop everything falls back to `.solid`, so adoption is opt-in per screen.

## 3. Plumbing required for theming

1. `DSTheme` gains `@Published var gradient: DSGradientTheme` (default `.sunset`), so changing it re-renders live.
2. Components resolve their palette from the environment (`colorScheme` and `dsTheme`) instead of reading a static palette. No signature change.
3. Color parameters change from `Color = <static default>` to `Color? = nil`, where `nil` means "follow the theme". This is source-compatible and the only touch to public signatures.
4. `DSColors` statics become adaptive light/dark, so raw token use in apps also respects dark mode.

## 4. Decisions recorded

| # | Decision | Outcome |
|---|---|---|
| A | Default theme | Sunset |
| B | Card radius | 20 first-level, 16 nested, 12 controls |
| C | `.outline` / `.outlined` | Keep the API, render as wash with no colored stroke |
| D | Headlines | Default design with negative tracking; rounded only for numbers and buttons |
| E | Dark mode | Same gradient plus a 0.58 black dim |
| F | `Color` → `Color?` defaults | Adopted |
| G | First component to prove the system | `DSCard` |
| H | Adaptive `DSColors` statics | Adopted |

## 5. Out of scope

Public API changes beyond §3, component internals, gestures, and the half-finished items found in the inventory (`imageURL` on `DSImageCard` / `DSAvatar` was addressed separately in the changelog).
