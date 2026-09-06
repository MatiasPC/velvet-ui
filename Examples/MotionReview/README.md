# MotionReview

A throwaway harness for reviewing the Velvet UI **motion wave-1** additions
(PRs #80 + #81) before they merge: the five `DSMotion` primitives and the four
motion-first components, on one scrollable screen with a theme switcher and a
light/dark toggle.

## Run in the Simulator (animations)

```sh
cd Examples/MotionReview
xcodegen generate
open MotionReview.xcodeproj
# pick an iPhone simulator, Cmd+R
```

Or headless:

```sh
xcodebuild build -project MotionReview.xcodeproj -scheme MotionReview \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Run on your iPhone (haptics)

The Simulator has no Taptic Engine. To feel the haptics:

1. `open MotionReview.xcodeproj`
2. Select the **MotionReview** target → Signing & Capabilities → set your Team.
3. Plug in the phone, pick it as the run destination, Cmd+R.

The haptic-firing surfaces are **DSSlideToConfirm** (rigid at the 75 % threshold,
success on confirm, light on snap-back) and **DSStepper** (selection tick per
step, warning + jiggle when it refuses at a bound).

## Notes

- Regenerate the `.xcodeproj` with `xcodegen generate` after pulling — it is not
  committed as a source of truth, `project.yml` is.
- Depends on the package at the repo root via a local SwiftPM reference.
- Delete this whole folder once wave-1 has landed and the real showcase app
  exists (roadmap in `docs/engineering-notes.md`).
