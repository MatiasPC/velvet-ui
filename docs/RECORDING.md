# Recording clips for X with the simulator

VelvetGallery has a "recording stage" for every component: a chrome-free,
centered view on a clean background, built to be screen-recorded in the iOS
Simulator and posted as a vertical clip (X) or a GIF (README).

## Prerequisites

- Xcode with an iPhone simulator (default: **iPhone 16 Pro**).
- `ffmpeg`: `brew install ffmpeg`.

## One command

```bash
scripts/record-stage.sh <StageID> [seconds=8] [background=neutral] [appearance=light]
scripts/record-stage.sh DSToggle 8 sunset dark
```

It boots the simulator (`$VELVET_SIM`, default `iPhone 16 Pro`), overrides the
status bar (9:41, full battery), builds and installs the Gallery, launches the
stage with autoplay on, records, and writes the X clip to `clips/<StageID>.mp4`
(gitignored) and the README GIF to `docs/media/<StageID>.gif`. Stages that need a
gesture (see the table) don't play themselves: when the script prints
`==> Recording`, perform the gesture in the Simulator window with the mouse, or
use the manual path.

`VELVET_RAW_ONLY=/path/clip.mov` skips ffmpeg and just saves the raw recording.

## Manual path

1. Run the Gallery, open **Recording → Recording stages**.
2. Pick a background (Neutral, Sunset, Aurora, Lagoon), appearance and autoplay.
3. Tap a stage. It fills the screen with no chrome. **Long-press the
   background for 1 second to exit** (on the full-screen example flows,
   long-press the top edge).
4. Record from a terminal:
   ```bash
   xcrun simctl io booted recordVideo --codec=h264 --force raw.mov
   ```
   Stop with Ctrl-C.

Launch arguments open a stage directly (they are also remembered by the
in-app pickers):

```bash
xcrun simctl launch booted com.matiasperaltacharro.VelvetGallery \
  -VelvetStage Hero -VelvetStageBackground sunset \
  -VelvetAppearance dark -VelvetStageAutoplay NO \
  -AppleLanguages "(en)" -AppleLocale en_US
```

Invalid values fall back to defaults. The last two arguments force English and US formatting, so prices read "$115.00" whatever the Mac's region is; `scripts/record-stage.sh` passes them too.

### Gesture stages

Use the mouse in the Simulator window: click and drag to slide the
`DSSlideToConfirm` knob, click to press buttons. Start recording first, then
interact; trim the head and tail afterwards. The Simulator has no haptics.

## Status bar

Stages hide the app's status bar. If you record the whole Simulator screen
anyway, set a clean one:

```bash
xcrun simctl status_bar booted override --time 9:41 --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3
xcrun simctl status_bar booted clear   # restore
```

## ffmpeg by hand

The simulator frame is taller than 9:16, so crop the center first.

```bash
CROP="crop=iw:trunc(iw*16/9/2)*2:0:(ih-trunc(iw*16/9/2)*2)/2"

# MP4 for X
ffmpeg -i raw.mov -vf "$CROP,scale=1080:1920:flags=lanczos,fps=30" \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart -an clips/DSToggle.mp4

# GIF for the README
ffmpeg -i raw.mov -vf "$CROP,fps=20,scale=480:-2:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" \
  -loop 0 docs/media/DSToggle.gif
```

## Specs

| Target | Format |
| --- | --- |
| X | vertical 9:16 MP4, 1080x1920, H.264, 30 fps, 5-10 s, no audio, at most 512 MB. The full-screen example flows keep the device height instead (1080x2348), which X also accepts. |
| README GIF | 480 px wide, 20 fps, loops forever, at most 5 MB |

Name files after the stage ID. GIFs go in `docs/media/<StageID>.gif` and are
committed: they replace the placeholders the README and component pages show.
MP4s go in `clips/<StageID>.mp4`, which is gitignored. Post them, don't commit them.

## Stages

| Stage ID | While recording |
| --- | --- |
| `Hero` | Toggle, step the quantity, then drag the knob to the end and release. Manual. |
| `DSButton` | Click each button (press feedback). Manual. |
| `DSIconButton` | Click the three icon buttons in turn. Manual. |
| `DSCard` | Click the card to show its press. Manual. |
| `DSTiltCard` | Click and drag across the card, then release (tilt, sheen, spring back). Manual. |
| `DSTextField` | Click a field and type an email; type a password. Manual. |
| `DSCodeField` | Autoplay: types a 6-digit code, then shows success. |
| `DSBadge` | Nothing moves; record a still moment or screenshot. |
| `DSAvatar` | Nothing moves; record a still moment or screenshot. |
| `DSListCell` | Click rows to show the press. Manual. |
| `DSToast` | Autoplay: toasts ride in from the bottom, one replaces another, the rest leave by themselves. Manual: tap a button, then flick the toast away. |
| `DSEmptyState` | Click "Compose". Manual. |
| `DSSegmentedControl` | Autoplay: walks Day, Week, Month. |
| `DSToggle` | Autoplay: flips the switch. |
| `DSRating` | Autoplay: fills the five stars. |
| `DSPageControl` | Autoplay: advances the pages. |
| `DSStepper` | Autoplay: steps up, then down. |
| `DSSlider` | Autoplay: the volume and price knobs glide to new values, the price one stepping through its notches. Drag either by hand. |
| `DSSlideToConfirm` | Drag the knob to the end, release. Manual. |
| `DSHoldToConfirm` | Press and hold until the ring closes; release early once to show the spring back. Manual; it re-arms itself after 2.5 s. |
| `DSThinkingIndicator` | Runs on its own. |
| `DSTypewriterText` | Runs on its own. |
| `DSExpandableText` | Tap Show more, then Show less. Manual. |
| `Progress` | Autoplay: fills 0 to 100 %. |
| `Motion` | Runs on its own (breathe, edge sweep, hue drift; jiggle and pop-in repeat). |
| `DSActivityRings` | Autoplay: drains the rings, refills them part way, then closes them one at a time (glow and haptic). |
| `DSTabBar` | Autoplay: walks the four tabs (capsule slide, symbol swap, bounce). |
| `DSCarousel` | Autoplay: advances a page every 1.6 s and wraps. Swipe it by hand for the depth effect. |
| `DSSheet` | Autoplay: presents the sheet, holds, dismisses. |
| `DSTimeline` | Autoplay: an order moves through four steps (connector fills, node lights, haptic), then cuts back to the start. |
| `DSNumberTicker` | Autoplay: rolls a balance through a sequence (including 99.99 → 100.05). |
| `Charts` | Autoplay: shuffles the data every 2 s (line morph, bars regrow). Drag across the bars to scrub. |
| `DSSkeleton` | Autoplay: loading → loaded → loading. |
| `DSSuccessCheck` | Autoplay: replays the seal every 2.5 s. |
| `DSRadioGroup` | Autoplay: selects Free, Pro, Team in turn (highlight slides, indicator pops). |
| `DSScrollReveal` | Autoplay: the feed scrolls down and back up. Manual: scroll it yourself. |
| `DSConfetti` | Autoplay: a burst every 2.5 s. Looks best on Aurora or Lagoon, dark. |
| `DSDisclosureGroup` | Autoplay: opens the three FAQ rows in turn (one open at a time), then closes them all. Tap a row by hand to see the press and the spring. |
| `DSLikeButton` | Tap the heart (pop, halo, count rolls), tap it again (quiet), then the star and the bookmark. Manual: the beat belongs to the tap. |
| `OnboardingFlow` | Full screen. Swipe through the pages; pick a theme on page 2 to re-theme everything. Manual. |
| `SettingsFlow` | Full screen. Flip a toggle (toast), open Delete account and slide. Manual. |
| `CheckoutFlow` | Full screen. Step a quantity (total rolls), apply `VELVET`, slide to pay. Manual. |
