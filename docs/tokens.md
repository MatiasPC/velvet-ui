# Tokens reference

Every value a component is allowed to use. If you need something that isn't here, add a token first, then use it. Files live in `Sources/DesignSystem/Tokens/`, `Animation/`, `Haptics/`, `Layout/`.

## Theme

`DSTheme` (`Tokens/DSTheme.swift`) is an `@Observable` class holding `light`, `dark` (`DSColorPalette`) and `gradient` (`DSGradientTheme`). Inject once with `.dsTheme(theme)`. When nothing is injected, a shared default (Sunset) is used.

Inside views, read it with the property wrapper:

```swift
@DSThemed private var theme        // DSResolvedTheme for the current color scheme
theme.palette.textPrimary          // neutrals & status colors
theme.accent / theme.onAccent      // fills and their text
theme.ink                          // text / icons / focus on glass, resolved light/dark
theme.subtleFill                   // wash on a backdrop, backgroundSecondary otherwise
theme.washSurface / theme.washEdge // raw wash values
theme.isDark / theme.onBackdrop
```

`DSResolvedTheme` is a value type; `DSTheme.resolved(for:onBackdrop:)` builds one without a view.

## Gradient themes

`DSGradientTheme` (`Tokens/DSGradientTheme.swift`). Four derived colors, each with one job. Contrast is verified by `DesignSystemTests.testGradientThemesMeetAAContrast`.

| Theme | Stops | `accent` | `onAccent` | `ink` | `inkDark` |
|---|---|---|---|---|---|
| `.sunset` (default) | `#FF7E5F → #FEB47B` | `#FF7E5F` | `#2B1510` | `#C2361A` | `#FFA98F` |
| `.aurora` | `#7F5AF0 → #E84393` | `#7F5AF0` | `#FFFFFF` | `#6D47E6` | `#B9A3FF` |
| `.lagoon` | `#16F2B3 → #0DB4F7` | `#16F2B3` | `#06231D` | `#0B7D8C` | `#5EF5CB` |

| Slot | Use it for | Contrast rule |
|---|---|---|
| `stops` | `DSBackdrop`, `DSGradientProgress`, decorative fills | — |
| `accent` | Primary CTA fill, toggle on, active page dot, rating, filled badge | — |
| `onAccent` | Text and icons on `accent` | ≥ 4.5:1 on accent |
| `ink` | Text, icons, links, focus glow on light glass | ≥ 4.5:1 on white |
| `inkDark` | Same, on dark glass | ≥ 4.5:1 on `#1A1A2E` |
| `lightWash` (0.08) | White overlay on the gradient in light mode | — |
| `darkDim` (0.58) | Black overlay on the gradient in dark mode | — |

Custom themes: `DSGradientTheme(id:name:stops:accent:onAccent:ink:inkDark:)`. Keep the contrast rules or text on glass becomes unreadable. `DSGradientTheme.all` lists the built-ins for pickers.

## Colors

`DSColorPalette` (`Tokens/DSColors.swift`) holds neutrals and status colors. 19 slots, memberwise `init`. Don't add slots (it would break every custom palette); add a new type instead.

| Slot | Light | Dark | Role |
|---|---|---|---|
| `primary` / `primaryVariant` | `#FF7E5F` / `#C2361A` | `#FF7E5F` / `#FFA98F` | Mirrors Sunset accent / ink for raw-token code |
| `secondary` / `secondaryVariant` | `#7F5AF0` / `#6D47E6` | `#7F5AF0` / `#B9A3FF` | Secondary button fill |
| `tertiary` | `#16F2B3` | `#16F2B3` | Accent alternative |
| `success` / `warning` / `error` / `info` | `#22C55E` / `#F59E0B` / `#EF4444` / `#3B82F6` | `#34D399` / `#FBBF24` / `#F87171` / `#60A5FA` | Status |
| `backgroundPrimary` / `Secondary` / `Elevated` | `#FFFFFF` / `#F7F7F7` / `#FFFFFF` | `#0F0F1A` / `#1A1A2E` / `#242440` | Screens, subtle fills, solid surface fallback |
| `textPrimary` / `Secondary` / `Tertiary` | `#1A1A2E` / `#6B7280` / `#9CA3AF` | `#F9FAFB` / `#9CA3AF` / `#6B7280` | Text hierarchy |
| `textOnPrimary` | `#FFFFFF` | `#FFFFFF` | Text on **secondary, status, destructive** fills. On the accent use `onAccent`. |
| `border` / `borderFocused` / `divider` | `#E5E7EB` / `#C2361A` / `#F3F4F6` | `#374151` / `#FFA98F` / `#1F2937` | Legacy separators and inactive tracks. Components should prefer `subtleFill` / `ink`. |

`DSColors.primary`, `DSColors.textPrimary`, … are **adaptive light/dark** static colors built from the two default palettes (`Color.dsDynamic(light:dark:)`). Use them in previews, models, or quick prototypes. They do not follow a custom injected palette — inside views use `@DSThemed`.

`Color(hex:)` accepts `RRGGBB` or `AARRGGBB`, with or without `#`.

## Surfaces

`DSSurface` (`Tokens/DSSurface.swift`) + `.dsSurface(_ level, radius:, edge:)`.

| Level | Material | Use |
|---|---|---|
| `.glassThin` | `ultraThinMaterial` | Chips, badges, toolbars, toast, page-control track |
| `.glass` | `thinMaterial` | **Cards (default)**, list groups, inputs, segmented track |
| `.glassThick` | `regularMaterial` | Sheets, modals, popovers, outlined cards |
| `.solid` | `backgroundElevated` | Fallback; also what every level becomes under Reduce Transparency |

The modifier fills, clips to a continuous rounded rect and draws `DSWash.edge` inside the shape. Default radius `DSRadius.card`.

## Wash

`DSWash` (`Tokens/DSWash.swift`). Velvet never calls `.stroke()` with a border color.

| Token | Light | Dark | Use |
|---|---|---|---|
| `surface(for:)` | white 0.45 | white 0.10 | Flat translucent fill: input inside a card, toggle track off, flat card. Read via `theme.washSurface`, or `theme.subtleFill` for the no-backdrop fallback. |
| `edge(for:)` | white 0.55 → 0.05, top → bottom | white 0.18 → 0.02 | 1pt specular highlight (`edgeWidth`), drawn with `strokeBorder`. `.dsWashEdge(radius:)` |
| focus | opacity 0.35, width 2, blur 1.5 | same | `.dsFocusGlow(color, radius:, isActive:)` — pass `theme.ink` or a status color |

## Backdrop

`DSBackdrop` (`Layout/DSBackdrop.swift`) draws the active gradient topLeading → bottomTrailing, a radial white light (0.18) at the top-leading corner, the `lightWash` in light mode and `darkDim` in dark mode. Wrap theme changes in `withAnimation(DSAnimation.normal)` for a crossfade.

`.dsBackdrop()` puts it behind a view **and** sets `EnvironmentValues.dsOnBackdrop = true`, which is how `theme.subtleFill` knows to use the wash. `DSScreen(backdrop: true)` does this for a whole screen.

## Shadows

`DSShadow` (`Tokens/DSShadow.swift`) + `.dsShadow(_:)`. Radius / opacity / y-offset.

| Level | Values | Use |
|---|---|---|
| `.sm` | 8 / 0.04 / 2 | Toggle knob, active segment |
| `.md` | 16 / 0.06 / 4 | Cards at rest |
| `.lg` | 24 / 0.08 / 8 | Interactive cards, toast, popovers |
| `.xl` | 32 / 0.10 / 12 | Sheets, modals |
| `.glow(tint)` | 20 / 0.28 light · 0.40 dark / 8 | Primary CTA, toggle on. Pass `theme.accent`. |

Shadow color is black except for `.glow`. `color(for:)` is scheme-aware; the modifier uses it.

## Radius

`DSRadius` (`Tokens/DSRadius.swift`). Always continuous corners.

| Numeric | Value | Semantic alias | Where |
|---|---|---|---|
| `xs` | 4 | | |
| `sm` | 8 | | |
| `md` | 12 | `control` | Buttons medium/large, inputs, code-field boxes |
| `lg` | 16 | `surface` | Nested surfaces: toast, list group, empty state |
| `xl` | 20 | `card` | DSCard, DSInteractiveCard, DSImageCard, sheets |
| `xxl` | 24 | | Hero cards |
| `pill` | 9999 | `chip` | Badges, tags, small buttons, search bar, segmented pill |

`.dsCornerRadius(_:)` clips. The stroke overload is deprecated.

## Spacing

`DSSpacing` (`Tokens/DSSpacing.swift`), 4pt grid: `xxxs` 2 · `xxs` 4 · `xs` 8 · `sm` 12 · `md` 16 · `lg` 20 · `xl` 24 · `xxl` 32 · `xxxl` 40 · `huge` 48 · `massive` 64. Screen margins: `screenHorizontal` 20, `screenHorizontalCompact` 16, `screenTop` 16, `screenBottom` 24. Helpers: `.dsScreenPadding()`, `.dsPadding(_:)`, `.dsPadding(horizontal:vertical:)`.

## Typography

`DSTextStyle` (`Tokens/DSTypography.swift`). Apply with `Text("…").ds(.title1)` or `.dsTextStyle(.body, color:)`. Color defaults to `theme.palette.textPrimary`.

| Style | Size / weight | Design | Tracking | Use |
|---|---|---|---|---|
| `hero` | 34 bold | SF Pro | −0.8 | Onboarding headlines |
| `largeTitle` | 28 bold | SF Pro | −0.6 | Screen titles |
| `title1` | 22 semibold | SF Pro | −0.4 | Section headers |
| `title2` | 20 semibold | SF Pro | −0.3 | Card titles |
| `title3` | 17 semibold | SF Pro | −0.2 | Subsection headers |
| `body` | 17 regular | SF Pro | 0 | Body text |
| `callout` | 15 regular | SF Pro | 0 | Secondary content |
| `footnote` | 13 medium | SF Pro | 0 | Labels, metadata |
| `caption1` / `caption2` | 12 / 11 regular | SF Pro | 0 | Timestamps / fine print |
| `button` / `buttonSmall` | 15 / 13 semibold | Rounded | 0 | Button labels |
| `overline` | 11 bold, uppercase | SF Pro | +1.2 | Section overlines |
| `displayLarge` / `displayMedium` | 60 / 40 bold | Rounded, monospaced digits | −1.2 / −0.6 | Stats, timers |
| `numeric` | 17 semibold | Rounded, monospaced digits | 0 | Prices, counters inline |
| `badge` | 11 bold | Rounded | 0 | Count badges |

Rule: numbers are always Rounded; titles are never Rounded. Max three styles per visual section.

## Motion

`DSAnimation` (`Animation/DSAnimation.swift`).

| Token | Value | Use |
|---|---|---|
| `micro` | 0.20s, curve (0.25, 0.10, 0.25, 1) | Toggles, highlights, color changes |
| `fast` | 0.24s, curve (0.20, 0, 0, 1) | State changes, button feedback |
| `normal` | 0.32s, curve (0.20, 0, 0, 1) | View transitions, card reveals, theme crossfade |
| `slow` | 0.48s, curve (0.30, 0, 0.10, 1) | Large layout shifts |
| `springSnappy` | response 0.3, damping 0.7 | Buttons, toggles, press states |
| `springSmooth` | 0.45 / 0.75 | Cards, panels |
| `springGentle` | 0.6 / 0.8 | Sheets, full-screen |
| `springBouncy` | 0.5 / 0.5 | Celebrations, rating pop |
| `interactive` | 0.3 / 0.7, blend 0.05 | Gesture-driven |
| `progress` / `counting` | easeInOut 0.8 / easeOut 1.0 | Progress fills / number count-up |
| `ambient` | easeInOut 1.8s | Base curve for ambient loops (breathe, drift, sweep) |
| `stagger(index:base:)` | springSmooth + index × 0.05s | List entrances |

`DSPress`: `scale` 0.96, `iconScale` 0.88, `animation` = springSnappy. Every pressable component uses these.

Transitions: `.dsSlideUp`, `.dsScale`, `.dsFade`, `.dsPush`. Modifiers: `.dsAnimate(_:value:)`, `.dsStaggerIn(index:)` (fade + 8pt rise, respects Reduce Motion), `.dsShimmer()`, `.dsPulse()` (deprecated — use `.dsBreathe()`).

### Motion primitives

These live in `Animation/DSMotion.swift` and are the ambient layer above `DSAnimation`, composing constant motion effects for decorative and attention-holding purposes.

| Modifier | What it does | Reduce Motion |
|---|---|---|
| `.dsBreathe(_ intensity:)` | Slow swell in scale and dip in opacity at `breatheDuration` | Rests at scale 1 |
| `.dsJiggle(trigger:)` | One decaying wiggle (two full swings that shrink to rest) on trigger change | Not applied at all |
| `.dsPopIn(delay:)` | Entrance with springBouncy overshoot and fade | Fades only, no scale |
| `.dsEdgeSweep(radius:isActive:)` | Specular highlight travelling the surface edge | Highlight stays static |
| `.dsHueDrift(isActive:)` | Slow, bounded hue rotation over the gradient (decorative) | Stays at 0° |

`DSMotion.loop(_:autoreverses:unless:)` wraps an animation in `repeatForever`, or returns `nil` when Reduce Motion is on. Passing nil to `.animation(_:value:)` applies the change instantly, so every ambient effect settles at its resting state instead of being skipped.

| Constant | Value | Purpose |
|---|---|---|
| `breatheDuration` | 2.4s | Breathing swell. Slow enough to read as alive, not as a spinner. |
| `sweepDuration` | 2.0s | One full trip of the edge sweep. |
| `driftDuration` | 8.0s | Hue drift. Deliberately slow: notice it only on a second look. |
| `driftDegrees` | 12 | Maximum hue rotation. Small to keep the gradient recognisable. |
| `jiggleDegrees` | 7 | Peak rotation of one jiggle swing. |

## Haptics

`DSHapticStyle` (`Haptics/DSHaptics.swift`): `light`, `medium`, `heavy`, `soft`, `rigid`, `selection`, `success`, `warning`, `error`. Fire with `dsHaptic(.success)`, `DSHapticEngine.shared.fire(.medium, intensity: 0.7)`, or `.dsHapticTap(.light) { }`. No-op on macOS. Components fire their own haptics — don't double up.

## Layout

`DSScreen(backgroundColor:backdrop:)`, `DSHorizontalScroll`, `DSVStack`, `DSHStack`, `DSGrid(minItemWidth:)` in `Layout/DSLayout.swift`.
