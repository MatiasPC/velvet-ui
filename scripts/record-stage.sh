#!/usr/bin/env bash
# Record a VelvetGallery recording stage in the iOS Simulator and export an
# X-ready MP4 and a README GIF to docs/media/<StageID>.{mp4,gif}.
#
# Usage: scripts/record-stage.sh <StageID> [seconds=8] [background=neutral] [appearance=light]
#   StageID     one of the IDs in docs/RECORDING.md (Hero, DSToggle, Motion, ...)
#   background  neutral | sunset | aurora | lagoon
#   appearance  light | dark | system
# Env: VELVET_SIM       simulator name (default "iPhone 16 Pro")
#      VELVET_RAW_ONLY  path to a .mov: skip ffmpeg, just save the raw recording there
set -euo pipefail

if [ $# -lt 1 ]; then
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 64
fi

STAGE="$1"
SECONDS_TO_RECORD="${2:-8}"
BACKGROUND="${3:-neutral}"
APPEARANCE="${4:-light}"
SIM="${VELVET_SIM:-iPhone 16 Pro}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/Examples/VelvetGallery/VelvetGallery.xcodeproj"
DERIVED="$ROOT/.build/gallery-record"
OUT_DIR="$ROOT/docs/media"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RAW_ONLY="${VELVET_RAW_ONLY:-}"
if [ -z "$RAW_ONLY" ]; then
  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "error: ffmpeg not found. Install it with: brew install ffmpeg" >&2
    exit 1
  fi
  if ! ffmpeg -version >/dev/null 2>&1; then
    echo "error: ffmpeg is installed but does not run (broken Homebrew dylibs?)." >&2
    echo "       Try: brew reinstall ffmpeg" >&2
    exit 1
  fi
fi

# Resolve the simulator UDID (prefer a booted device of that name, else first available).
UDID="$(xcrun simctl list devices booted | grep -F "    $SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' || true)"
if [ -z "$UDID" ]; then
  UDID="$(xcrun simctl list devices available | grep -F "    $SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' || true)"
fi
[ -n "$UDID" ] || { echo "error: no available simulator named '$SIM' (set VELVET_SIM)" >&2; exit 1; }

# Boot the simulator if needed.
if ! xcrun simctl list devices booted | grep -q "$UDID"; then
  echo "==> Booting $SIM ($UDID)"
  xcrun simctl boot "$UDID" || true
fi
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
SIM="$UDID"
open -a Simulator >/dev/null 2>&1 || true

echo "==> Clean status bar (9:41, full battery)"
xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3

echo "==> Building VelvetGallery"
xcodebuild build -project "$PROJECT" -scheme VelvetGallery \
  -destination "platform=iOS Simulator,id=$SIM" \
  -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO -quiet

APP="$(find "$DERIVED/Build/Products" -name VelvetGallery.app -path '*iphonesimulator*' | head -1)"
[ -n "$APP" ] || { echo "error: built VelvetGallery.app not found" >&2; exit 1; }
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")"

echo "==> Installing $BUNDLE_ID"
xcrun simctl install "$SIM" "$APP"
xcrun simctl terminate "$SIM" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl launch "$SIM" "$BUNDLE_ID" \
  -VelvetStage "$STAGE" -VelvetStageBackground "$BACKGROUND" \
  -VelvetAppearance "$APPEARANCE" -VelvetStageAutoplay YES >/dev/null
sleep 4   # let the first frame settle before recording

echo "==> Recording ${SECONDS_TO_RECORD}s"
RAW="$TMP/raw.mov"
xcrun simctl io "$SIM" recordVideo --codec=h264 --force "$RAW" >/dev/null 2>&1 &
REC_PID=$!
sleep "$SECONDS_TO_RECORD"
kill -INT "$REC_PID" 2>/dev/null || true
wait "$REC_PID" 2>/dev/null || true
[ -s "$RAW" ] || { echo "error: recording is empty" >&2; exit 1; }

if [ -n "$RAW_ONLY" ]; then
  cp "$RAW" "$RAW_ONLY"
  xcrun simctl status_bar "$SIM" clear >/dev/null 2>&1 || true
  echo "Raw recording saved to $RAW_ONLY (ffmpeg step skipped)"
  exit 0
fi

mkdir -p "$OUT_DIR"
# Center crop to 9:16 (portrait). Source is taller than 9:16, so keep full width.
CROP="crop=iw:trunc(iw*16/9/2)*2:0:(ih-trunc(iw*16/9/2)*2)/2"

echo "==> Writing $OUT_DIR/$STAGE.mp4"
ffmpeg -y -loglevel error -i "$RAW" \
  -vf "$CROP,scale=1080:1920:flags=lanczos,fps=30" \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart -an "$OUT_DIR/$STAGE.mp4"

echo "==> Writing $OUT_DIR/$STAGE.gif"
ffmpeg -y -loglevel error -i "$RAW" \
  -vf "$CROP,fps=20,scale=480:-2:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" \
  -loop 0 "$OUT_DIR/$STAGE.gif"

GIF_BYTES="$(wc -c < "$OUT_DIR/$STAGE.gif" | tr -d ' ')"
if [ "$GIF_BYTES" -gt 5242880 ]; then
  echo "warning: $STAGE.gif is $((GIF_BYTES / 1024)) KB (> 5 MB). Record fewer seconds or re-encode at lower fps." >&2
fi

xcrun simctl status_bar "$SIM" clear >/dev/null 2>&1 || true
echo "Done:"
ls -lh "$OUT_DIR/$STAGE.mp4" "$OUT_DIR/$STAGE.gif"
