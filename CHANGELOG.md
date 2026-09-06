# Changelog

All notable changes to Velvet UI. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer. Until 1.0, minor versions may change visual output; public API changes are always listed here.

## [Unreleased]

### Changed
- **DSToggle** — the knob now fills the full track height (was inset 2pt), nesting into the capsule ends so no track color shows above or below the circle. Horizontal travel adjusted to `(trackWidth − trackHeight) / 2`; track dimensions and public API unchanged.

## [0.2.0] — 2026-09-05

The Arc-inspired surface language: glass over a selectable gradient theme. Proposal and decisions in [docs/proposals/0001-arc-tokens.md](docs/proposals/0001-arc-tokens.md).

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
- Docs: README, `docs/tokens.md`, `docs/components.md`, `docs/engineering-notes.md`.

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

### Fixed
- `dsStaggerIn` was a no-op (animated a constant). It now fades and rises with the stagger delay and respects Reduce Motion.
- `DSShimmer` used a fixed 200pt offset and broke on wide views; the sweep is now width-independent and scheme-aware.
- `DSImageCard` and `DSAvatar` accepted `imageURL` and ignored it; both load it with `AsyncImage` and fall back to the placeholder / initials.
- `DSCard(style: .flat)` was invisible on a white screen.
- Dark palette was never applied to components.

### Deprecated
- `dsCornerRadius(_:strokeColor:strokeWidth:)` — Velvet doesn't draw borders; use `dsSurface` or `dsWashEdge`.
- `DSAnimatedValue` — unused; removal planned for 0.3.

## [0.1.0] — 2026-03-11

Initial release: tokens (colors, typography, spacing, radius, shadow, animation, haptics), components (button, card, text field, search bar, list cell, section header, divider, badge, count badge, avatar, toast, empty state, progress ×4, animated number, shimmer, pulse), layout helpers, ComponentCatalog preview. Later additions before 0.2: `DSSegmentedControl`, `DSToggle`, `DSRating`, `DSPageControl`, `DSCodeField`.
