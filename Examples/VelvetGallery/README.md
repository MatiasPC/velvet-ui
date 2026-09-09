# VelvetGallery

A runnable iOS app that shows every Velvet UI component on its own screen, for
demos and video capture. Not part of `swift build` / `swift test`.

## Run

The `.xcodeproj` is **not** in git (the repo ignores `*.xcodeproj/`). Generate it first:

```bash
cd Examples/VelvetGallery && xcodegen generate
```

Then open `VelvetGallery.xcodeproj` in Xcode, pick an iPhone simulator, and Run.
Or from the repo root:

```bash
xcodebuild build -project Examples/VelvetGallery/VelvetGallery.xcodeproj \
  -scheme VelvetGallery \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

(Pin `,OS=<version>` on the destination if your Xcode has no matching default runtime.)

## Regenerate the project

`project.yml` is the source of truth ([XcodeGen](https://github.com/yonwoo9/XcodeGen)).
Re-run `xcodegen generate` after changing the file list or target settings.

## Layout

- `VelvetGalleryApp.swift` — entry point; injects the neutral theme and the appearance binding.
- `ComponentListView.swift` — grouped `List`, one row per component, six sections.
- `Screens/` — one screen per component (16), each built on `GalleryScreen`.
- `Support/` — `GalleryScreen` + `LabeledExample` chrome, `Appearance` toggle.
- `Theme/NeutralTheme.swift` — `DSGradientTheme.neutral`.

## Design

Neutral-only: solid `DSColors.backgroundPrimary` background, no `.dsBackdrop()`, a
local `DSGradientTheme.neutral` with a graphite accent. Semantic status colours
(error / success / warning / info) are kept; decorative defaults are shown in
neutral with one labelled colourful example each. Appearance (System / Light /
Dark) is switchable from the toolbar and persisted.

Rationale in `docs/engineering-notes.md` and
`docs/superpowers/specs/2026-09-08-velvet-gallery-app-design.md`.
