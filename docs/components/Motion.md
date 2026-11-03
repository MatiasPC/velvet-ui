# Motion

Five composable view modifiers for ambient motion: breathe, jiggle, pop in, edge sweep and hue drift. Springs for touch, eased curves for ambience, and every one has a real Reduce Motion state.

![Motion](../media/Motion.gif)

**Platforms:** iOS 18+ · macOS 15+  ·  **Source:** [`DSMotion.swift`](../../Sources/VelvetUI/Animation/DSMotion.swift)

## Install

```swift
// Package.swift
.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")
// target dependencies
.product(name: "VelvetUI", package: "velvet-ui")
```

In Xcode: File → Add Package Dependencies… → paste `https://github.com/MatiasPC/velvet-ui.git`. Inject the theme once at your app root (`@State private var theme = DSTheme(gradient: .sunset)` + `.dsTheme(theme)`); see [the README](../../README.md#install) for the full setup.

## Usage

```swift
import VelvetUI

struct MotionDemo: View {
    @State private var shakes = 0
    @State private var isSweeping = true

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(spacing: DSSpacing.lg) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 16, height: 16)
                    .dsBreathe(.subtle)

                Image(systemName: "bell.fill")
                    .font(.largeTitle)
                    .dsJiggle(trigger: shakes)
                DSButton("Shake", variant: .secondary, size: .small) { shakes += 1 }

                HStack(spacing: DSSpacing.sm) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                            .fill(Color.blue)
                            .frame(height: DSSpacing.huge)
                            .dsHueDrift()
                            .dsPopIn(delay: Double(index) * 0.08)
                    }
                }

                Text("Processing…")
                    .ds(.body)
                    .padding(DSSpacing.md)
                    .frame(maxWidth: .infinity)
                    .dsSurface(.glass, radius: DSRadius.card)
                    .dsEdgeSweep(radius: DSRadius.card, isActive: isSweeping)
            }
            .dsScreenPadding()
        }
    }
}
```

## Parameters

### `.dsBreathe(_:)`

`func dsBreathe(_ intensity: DSBreatheIntensity = .medium) -> some View`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `_ intensity` | `DSBreatheIntensity` | `.medium` | How far it swells: `.subtle` (1.02), `.medium` (1.05), `.strong` (1.10). |

### `.dsJiggle(trigger:)`

`func dsJiggle<T: Equatable>(trigger: T) -> some View`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `trigger` | `T: Equatable` | required | One decaying wiggle fires every time this value changes. |

### `.dsPopIn(delay:)`

`func dsPopIn(delay: Double = 0) -> some View`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `delay` | `Double` | `0` | Seconds before the entrance starts. Stagger by index: `Double(index) * 0.08`. |

### `.dsEdgeSweep(radius:isActive:)`

`func dsEdgeSweep(radius: CGFloat = DSRadius.card, isActive: Bool = true) -> some View`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `radius` | `CGFloat` | `DSRadius.card` | Corner radius of the surface underneath. Match it. |
| `isActive` | `Bool` | `true` | Fades the highlight in and out. |

### `.dsHueDrift(isActive:)`

`func dsHueDrift(isActive: Bool = true) -> some View`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `isActive` | `Bool` | `true` | Turns the drift on or off. |

### `DSMotion.loop(_:autoreverses:unless:)`

For your own ambient effects: `DSMotion.loop(_ base: Animation, autoreverses: Bool = true, unless reduceMotion: Bool) -> Animation?` wraps an animation in `repeatForever`, or returns `nil` under Reduce Motion, so the change applies instantly and the effect rests instead of being skipped.

## Variants

| Modifier | Use it for | Timing |
|---|---|---|
| `.dsBreathe` | "alive and waiting": loading states, status dots, avatars | 2.4s ease-in-out loop, scale plus a slight opacity dip |
| `.dsJiggle` | a rejected input, an item that needs noticing | 0.45s, peak 7 degrees, decaying counter-swings |
| `.dsPopIn` | entrances and staggered rows | `springBouncy` overshoot from 0.8 scale |
| `.dsEdgeSweep` | processing, recording, "AI is working" | 2.0s linear loop of a specular highlight on the 1pt glass edge |
| `.dsHueDrift` | decorative life on a static gradient | 8.0s loop, at most 12 degrees of hue rotation |

The constants live on `DSMotion` (`breatheDuration`, `sweepDuration`, `driftDuration`, `driftDegrees`, `jiggleDegrees`, `jiggleDuration`).

`.dsPulse()` is deprecated; use `.dsBreathe(_:)` instead.

## Behavior

- All five settle at a resting state under Reduce Motion instead of being skipped: breathe and drift stop looping, the jiggle does not rotate, the edge sweep shows its highlight without travelling, and pop in keeps the fade but drops the scale.
- Colors come from the theme (the edge sweep is light riding the existing glass edge, not a border).
- The loops are ambient, so they do not fire haptics; add a `DSHapticEngine.shared.fire(.error)` next to a jiggle if the event deserves one.

## Accessibility

- These modifiers are purely visual and do not change what VoiceOver reads.
- Because Reduce Motion is a real state, content stays visible and in place when the setting is on.
- Never use motion as the only signal: pair a jiggle with an error message, and a sweep with a status text such as "Processing…".

## See also

- [DSThinkingIndicator](DSThinkingIndicator.md)
- [Progress](Progress.md)
- [DSAvatar](DSAvatar.md) (breathe while waiting)
- [All components](../../README.md#components) · [Theming](../../README.md#theming)
