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
   background for 1 second to exit.**
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
  -VelvetAppearance dark -VelvetStageAutoplay NO
```

Invalid values fall back to defaults.

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
| X | vertical 9:16 MP4, 1080x1920, H.264, 30 fps, 5-10 s, no audio, at most 512 MB |
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
| `DSTextField` | Click a field and type an email; type a password. Manual. |
| `DSCodeField` | Autoplay: types a 6-digit code, then shows success. |
| `DSBadge` | Nothing moves; record a still moment or screenshot. |
| `DSAvatar` | Nothing moves; record a still moment or screenshot. |
| `DSListCell` | Click rows to show the press. Manual. |
| `DSToast` | Autoplay: cycles success, error, warning, info. |
| `DSEmptyState` | Click "Compose". Manual. |
| `DSSegmentedControl` | Autoplay: walks Day, Week, Month. |
| `DSToggle` | Autoplay: flips the switch. |
| `DSRating` | Autoplay: fills the five stars. |
| `DSPageControl` | Autoplay: advances the pages. |
| `DSStepper` | Autoplay: steps up, then down. |
| `DSSlideToConfirm` | Drag the knob to the end, release. Manual. |
| `DSThinkingIndicator` | Runs on its own. |
| `DSTypewriterText` | Runs on its own. |
| `Progress` | Autoplay: fills 0 to 100 %. |
| `Motion` | Runs on its own (breathe, edge sweep, hue drift; jiggle and pop-in repeat). |
