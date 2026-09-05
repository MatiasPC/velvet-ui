# Velvet UI — Design System

## Repo: github.com/MatiasPC/velvet-ui

## Docs (read before changing anything)
- `README.md` — install, quick start, verification commands
- `docs/tokens.md` — every token and its value
- `docs/components.md` — every component: API, variants, status, notes
- `docs/engineering-notes.md` — architecture decisions, gotchas, known issues, roadmap
- `docs/proposals/` — design proposals (0001: Arc-inspired v0.2 tokens)
- `CHANGELOG.md` — every user-visible change, Keep a Changelog format

## Architecture
- `Sources/DesignSystem/Tokens/` — colors, gradient themes, theme + `@DSThemed`, surface, wash, typography, spacing, radius, shadow
- `Sources/DesignSystem/Components/` — reusable UI components
- `Sources/DesignSystem/Animation/` — curves, springs, `DSPress`, progress, shimmer
- `Sources/DesignSystem/Haptics/` — tactile feedback engine
- `Sources/DesignSystem/Layout/` — `DSScreen`, `DSBackdrop`, stacks, grid
- `Sources/DesignSystem/Preview/` — `ComponentCatalog` (internal) and preview helpers
- `Tests/DesignSystemTests/` — tokens, theme resolution, AA contrast

## Non-negotiable rules
1. **Tokens only.** No raw `Color`, `Font`, `CGFloat` values in components. Need a value that doesn't exist? Add a token first.
2. **Colors come from `@DSThemed private var theme`**, never from `DSColors.defaultPalette`. `DSColors.x` statics are allowed only inside `#Preview`.
3. **Overridable colors are `Color? = nil`** and resolve to the theme role in `body`. Never change an existing parameter's label or position.
4. **Accent roles:** `theme.accent` for fills, `theme.onAccent` for text on the accent, `theme.ink` for text/icons/focus on surfaces. `palette.textOnPrimary` is for secondary/status/destructive fills only.
5. **No borders.** `dsSurface` (glass + edge), `dsWashEdge`, `dsFocusGlow`, `theme.subtleFill`. Never `.stroke(border)`.
6. **Press = `DSPress.scale` / `DSPress.iconScale` with `DSPress.animation`.** Springs from `DSAnimation` for state changes. Haptics via `DSHapticEngine` on primary actions.
7. **Radius by role:** `DSRadius.card` 20 / `.surface` 16 / `.control` 12 / `.chip` pill.
8. **Both platforms build.** iOS-only modifiers go inside `#if os(iOS)`. Run `swift build`, `swift test` and `xcodebuild build -scheme DesignSystem -destination 'generic/platform=iOS Simulator'` before committing.
9. **Accessibility:** honor Reduce Motion / Reduce Transparency, label controls.

## Definition of done for any change
- Code + `#Preview` (light and dark, on `.dsBackdrop()`)
- Section in `ComponentCatalog.swift`
- Entry in `docs/components.md` (or `docs/tokens.md`)
- Line in `CHANGELOG.md` under `[Unreleased]`
- Gotcha or decision worth remembering → `docs/engineering-notes.md`
- Update the Claude skill references at `~/.claude/skills/design-system/references/`
- Builds and tests pass on both platforms

## Adding a component
1. Must have been built and tested in a real app first
2. `Components/DS[Name].swift`, all types prefixed `DS`, `public` with a minimal API
3. Follow the rules above; check `docs/engineering-notes.md` → "How to add a component"

## Git workflow
- Work on a branch (`feat/…`, `fix/…`, `docs/…`), open a PR to `main`, never push to `main` directly
- One logical change per commit; every commit builds
- Commit convention:
  - `add: DSBottomSheet — sheet component with drag handle and snap points`
  - `improve: DSButton — add icon-only variant`
  - `fix: DSTextField — border color in dark mode`
  - `tokens: add DSSpacing.custom() helper`
  - `docs: …` / `test: …`
