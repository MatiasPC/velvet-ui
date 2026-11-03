# Discoverability kit

Settings to apply on GitHub by hand, and the spec for the social preview image. Nothing here is applied automatically.

## Repository "About"

**Description** (GitHub allows 350 characters):

> Glassy SwiftUI components with spring motion and haptics. Frosted glass over gradient themes, no borders, VoiceOver and Reduce Motion built in. Swift Package or copy one component with a CLI. Agent-ready with llms.txt and AGENTS.md. iOS 18+ · macOS 15+ · MIT.

**Website:** leave empty until there's a docs site. Don't point it at the Pro placeholder.

**Topics** (GitHub allows 20; lowercase, hyphenated):

```
swiftui  swift  ios  macos  design-system  ui-components  swiftui-components
component-library  ui-kit  glassmorphism  animation  haptics  accessibility
dark-mode  swift-package-manager  spm  ios18  llms-txt  ai-agents  copy-paste
```

Why these: `swiftui`, `ios`, `swiftui-components`, `ui-components`, `design-system` and `component-library` are what people browse on github.com/topics. `glassmorphism`, `animation` and `haptics` describe how Velvet differs. `llms-txt`, `ai-agents` and `copy-paste` reach people choosing libraries their agents can use. Avoid `liquid-glass` until the core adopts the iOS 26 material, so the repo doesn't over-promise.

**Also turn on:** Discussions (for "show your app" and questions, which keeps issues for bugs), and "Include in the home page" for Releases once v0.2.0 is tagged.

## Social preview image

GitHub → Settings → General → Social preview. It's used by X, Slack, Discord, LinkedIn and iMessage link cards.

| | |
|---|---|
| Canvas | **1280 × 640 px** (2:1), PNG, sRGB, under 1 MB |
| Safe area | Keep all text and the phones inside the centered **1160 × 560** box (60 px side margins, 40 px top and bottom). LinkedIn and some Slack clients crop toward 1.91:1. |
| Background | The Sunset backdrop as `DSBackdrop` draws it: linear gradient `#FF7E5F` → `#FEB47B`, top-leading to bottom-trailing, plus a radial white light (18 % opacity, radius about 560 px) centered at 14 % / 8 % of the canvas. No noise, no texture. |
| Left column (about 560 px wide) | **Wordmark** "Velvet UI", SF Pro Display Bold, 104 px, tracking −2 px, color `#2B1510` (Sunset `onAccent`, AA on the gradient). **Tagline** on two lines, SF Pro Text Medium 36 px, `#2B1510` at 85 %: "Glassy SwiftUI components / with spring motion and haptics." **Meta line**, SF Pro Rounded Semibold 24 px, `#2B1510` at 70 %: "iOS 18+ · macOS 15+ · Swift Package · MIT". |
| Right column | Two iPhone screens, frameless, corner radius 56 px, a soft shadow (black 18 %, blur 40, y 20). **Front:** the `Hero` stage on Sunset, light mode (glass card with a toggle, a stepper and slide-to-pay). **Back,** offset up-right by about 80 px and scaled to 92 %: the `DSTabBar` or `Charts` stage on Aurora, dark mode. No device bezels, no rotation. |
| Don'ts | No more than one typeface family, no emoji, no "#1" or "best" claims, no GitHub star counts, no screenshot of code. |

**Making the screenshots:**

```bash
xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100
xcrun simctl launch booted com.matiasperaltacharro.VelvetGallery \
  -VelvetStage Hero -VelvetStageBackground sunset -VelvetAppearance light -VelvetStageAutoplay NO
xcrun simctl io booted screenshot hero-sunset-light.png
```

Use an iPhone 16 Pro simulator, so the screenshots are 1206 × 2622.

**Alt text** (for the README hero and wherever the image is posted): "Velvet UI: two iPhone screens with frosted-glass SwiftUI components (a toggle, a stepper, a slide-to-pay control and a tab bar) over a peach-to-coral gradient."

**Variants worth exporting from the same file:** an X header (1500 × 500, wordmark plus one phone) and a square avatar (400 × 400, a glass "V" on the Sunset gradient).
