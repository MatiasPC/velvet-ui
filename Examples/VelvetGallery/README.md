# VelvetGallery

A runnable iOS app that shows every Velvet UI component on its own screen, for
demos and video capture. Not part of `swift build` / `swift test`.

## Run

Open `VelvetGallery.xcodeproj`, pick an iPhone simulator, press Run. The project
is committed, so there are no commands to run first.

```bash
open Examples/VelvetGallery/VelvetGallery.xcodeproj
```

Headless build:

```bash
xcodebuild build -project Examples/VelvetGallery/VelvetGallery.xcodeproj \
  -scheme VelvetGallery \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0'
```

### Haptics

The Simulator has no Taptic Engine. To feel the haptics — `DSSlideToConfirm`
(soft detent texture, rigid tick at the 75 % threshold, success / error on the
outcome) and `DSStepper` (tick per step, warning + jiggle at a bound) — run on a
device: select the **VelvetGallery** target → Signing & Capabilities → set your
Team, then pick the phone as the run destination.

## Regenerate the project

`project.yml` is the source of truth ([XcodeGen](https://github.com/yonwoo9/XcodeGen)).
After changing the file list or target settings, re-run `xcodegen generate` and
**commit** the updated `.xcodeproj` (`.gitignore` negates it out of the blanket
`*.xcodeproj/` rule; `xcuserdata/` stays ignored).

## Layout

- `VelvetGalleryApp.swift` — entry point; injects the neutral theme and the appearance binding.
- `ComponentListView.swift` — grouped `List`, one row per component.
- `Screens/` — one screen per component, each built on `GalleryScreen`. Includes
  the motion set: `MotionScreen` (the five `DSMotion` primitives),
  `SlideToConfirmScreen` (async slide-to-pay + "next charge fails" toggle),
  `StepperScreen`, `ThinkingIndicatorScreen`, `TypewriterTextScreen`.
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
