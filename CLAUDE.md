# Velvet UI — Design System

## Repo: github.com/MatiasPC/velvet-ui

## Architecture
- `Sources/DesignSystem/Tokens/` — Design primitives (colors, typography, spacing, radius, shadows, theme)
- `Sources/DesignSystem/Components/` — Reusable UI components (buttons, cards, fields, etc.)
- `Sources/DesignSystem/Animation/` — Motion system (springs, curves, progress, shimmer)
- `Sources/DesignSystem/Haptics/` — Tactile feedback engine
- `Sources/DesignSystem/Layout/` — Layout helpers (screen containers, grids, stacks)
- `Sources/DesignSystem/Preview/` — ComponentCatalog for browsing all components

## Rules for adding components
1. Must have been built and tested in a real app first
2. Must use DS tokens internally — never raw Color/Font/CGFloat values
3. Must include haptic feedback where appropriate
4. Must animate with DSAnimation springs
5. Naming: `DS[Name].swift`, all types prefixed with `DS`
6. Must be `public` with a clean, minimal API
7. Update `ComponentCatalog.swift` with a preview section
8. Update the Claude skill references at `~/.claude/skills/design-system/references/`

## Commit convention
- `add: DSBottomSheet — sheet component with drag handle and snap points`
- `improve: DSButton — add icon-only variant`
- `fix: DSTextField — border color in dark mode`
- `tokens: add DSSpacing.custom() helper`
