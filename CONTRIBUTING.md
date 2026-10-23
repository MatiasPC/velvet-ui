# Contributing to Velvet UI

Thanks for helping. Velvet UI is a small, opinionated library: every component has to feel right (motion, haptics, glass) and stay out of the way of the app using it. These rules keep it that way.

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## What gets in

- **Bug fixes**: always welcome. Open an issue with the [bug template](https://github.com/MatiasPC/velvet-ui/issues/new?template=bug_report.yml) first, unless the fix is obvious.
- **Docs and examples**: welcome, as PRs.
- **New components**: open a [component request](https://github.com/MatiasPC/velvet-ui/issues/new?template=component_request.yml) before you write code. A component lands only if it is:
  - **reusable**: useful beyond one app or screen,
  - **polished**: animations, haptics and tokens done properly,
  - **unique**: not a duplicate of an existing component, and
  - **proven**: already built and used in a real app.

We don't accept one-off layouts for a single screen, components that try to do too much, or anything that hasn't been tried in a real app.

## Setup

```bash
git clone https://github.com/MatiasPC/velvet-ui.git
cd velvet-ui
open Package.swift                                   # the library, with #Previews
open Examples/VelvetGallery/VelvetGallery.xcodeproj  # the demo app, one screen per component
```

Requirements: Xcode with the iOS 18 and macOS 15 SDKs or newer. CI uses the latest stable Xcode.

## Rules for library code

1. **Tokens only.** No raw `Color`, `Font` or `CGFloat` values in components. If you need a value that doesn't exist, add a token first ([docs/tokens.md](docs/tokens.md)).
2. **Colors come from `@DSThemed private var theme`**, never from `DSColors.defaultPalette`. The `DSColors.x` statics are allowed only inside `#Preview`.
3. **Overridable colors are `Color? = nil`** and resolve to the theme role in `body`. Never change an existing public parameter's label or position. Add new parameters with defaults, before any trailing closure.
4. **Accent roles:** `theme.accent` for fills, `theme.onAccent` for text on the accent, `theme.ink` for text, icons and focus on surfaces.
5. **No borders.** Use `dsSurface`, `dsWashEdge`, `dsFocusGlow` or `theme.subtleFill`, never `.stroke(border)`.
6. **Motion and touch:** press states use `DSPress.scale` / `DSPress.iconScale` with `DSPress.animation`; state changes use `DSAnimation` springs; primary actions fire a haptic through `DSHapticEngine`.
7. **Radius by role:** `DSRadius.card` 20, `.surface` 16, `.control` 12, `.chip` pill.
8. **Both platforms build.** iOS-only modifiers go inside `#if os(iOS)`.
9. **Accessibility:** honor Reduce Motion and Reduce Transparency, give every control a VoiceOver label, value and traits, and use `.ds(_:)` / `.dsFont(_:)` for text so it scales with Dynamic Type.

[docs/engineering-notes.md](docs/engineering-notes.md) explains the decisions behind these rules and lists the gotchas. Read it before adding a component.

## Definition of done

A change is done when it has:

- [ ] Code, plus a `#Preview` in light and dark on `.dsBackdrop()`
- [ ] A section in `Sources/VelvetUI/Preview/ComponentCatalog.swift`
- [ ] For a new component: a page in `docs/components/<Name>.md`, an entry in `docs/components.md`, a row in the README's component table, and a stage in the VelvetGallery (see [docs/RECORDING.md](docs/RECORDING.md))
- [ ] A line in `CHANGELOG.md` under `[Unreleased]`
- [ ] Any gotcha or decision worth remembering, written up in `docs/engineering-notes.md`
- [ ] A green build and green tests on both platforms:

```bash
swift build                                    # macOS
swift test                                     # tokens, theme, contrast, accessibility, doc snippets
xcodebuild build -scheme VelvetUI \
  -destination 'generic/platform=iOS Simulator'  # iOS
```

CI runs the same checks, plus the iOS tests on a simulator and a build of the Gallery, on every pull request.

## Git workflow

- Branch from `main`: `feat/…`, `fix/…`, `docs/…`. Open a pull request to `main`; nobody pushes to `main` directly.
- One logical change per commit, and every commit builds.
- Commit subjects follow this convention:
  - `add: DSBottomSheet — sheet component with drag handle and snap points`
  - `improve: DSButton — add icon-only variant`
  - `fix: DSTextField — border color in dark mode`
  - `tokens: add DSSpacing.custom() helper`
  - `docs: …` / `test: …`
- For visual changes, attach a before/after screenshot or a short clip to the PR.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
