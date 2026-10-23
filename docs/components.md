# Components reference

> Looking for usage? Each component has a page with a copyable snippet, parameters and accessibility notes in [`docs/components/`](components/). This file is the maintainers' reference: status, restyle backlog and implementation notes.

One section per component: what it is for, the public API, variants and states, motion and haptics, theming notes, and anything known to be missing. Keep this file in sync with the code — a component change without a doc change is not done.

Conventions that apply to every component:
- Colors come from `@DSThemed`. Parameters typed `Color? = nil` follow the theme when nil.
- Press states use `DSPress.scale` (0.96) or `DSPress.iconScale` (0.88) with `DSPress.animation`.
- Haptics fire inside the component; don't add another on the call site. The exception is `DSToast`, which fires none: the caller does.
- Status: ✅ complete · 🧪 v0.2 glass restyle applied · ⏳ restyle pending (works, still v0.1 look).

---

## DSButton  🧪 (colors) ⏳ (glass secondary/outline)

`Components/DSButton.swift`. Text button with icon, loading state, full-width option.

```swift
DSButton(_ title: String,
         variant: DSButtonVariant = .primary,   // .primary .secondary .outline .ghost .destructive
         size: DSButtonSize = .medium,          // .small 36pt pill · .medium 44pt · .large 52pt
         icon: String? = nil, iconPosition: IconPosition = .leading,
         isFullWidth: Bool = false, isLoading: Bool = false,
         haptic: DSHapticStyle = .medium,
         action: @escaping () -> Void)
```

| Variant | Fill | Text |
|---|---|---|
| `.primary` | `theme.accent` + (pending) `.glow` | `theme.onAccent` |
| `.secondary` | `palette.secondary` (pending: `.glassThin`) | `palette.textOnPrimary` |
| `.outline` | clear + 1.5pt `ink` stroke (pending: wash + edge) | `theme.ink` |
| `.ghost` | none | `theme.ink` |
| `.destructive` | `palette.error` | `palette.textOnPrimary` |

Motion: press → `DSPress.scale`; loading dims to 0.8 and disables. Haptic on tap (configurable).
Radius: `.small` → `DSRadius.chip`, others → `DSRadius.control`.

**DSIconButton**: `DSIconButton(icon:size: 44,color: Color? = nil,haptic: .light,accessibilityLabel: String? = nil,action:)`. Color defaults to `palette.textPrimary`; press uses `DSPress.iconScale`. Icon-only, so pass `accessibilityLabel` ("Share"); when nil VoiceOver falls back to the SF Symbol's own description.

Notes: icon font sizes (12 / 14) are still literals — candidate for a `DSIconSize` token when a third component needs it.

---

## DSCard  🧪

`Components/DSCard.swift`. The reference glass surface.

```swift
DSCard(style: DSCardStyle = .elevated,          // .flat .elevated .outlined
       padding: CGFloat = DSSpacing.md,
       cornerRadius: CGFloat = DSRadius.card) { content }
```

| Style | Surface | Edge | Shadow |
|---|---|---|---|
| `.elevated` | `.glass` (thinMaterial) | yes | `.md` |
| `.outlined` | `.glassThick` (regularMaterial) | yes | none |
| `.flat` | `theme.subtleFill` (wash on backdrop, `backgroundSecondary` otherwise) | no | none |

**DSInteractiveCard**: same params + `haptic: .light` + `action`. Press → `DSPress.scale`.

**DSImageCard**: `DSImageCard(imageURL: URL? = nil, imageName: String? = nil, title:, subtitle: String? = nil, badge: String? = nil, cornerRadius: DSRadius.card)`. Loads `imageURL` with `AsyncImage`, shimmer placeholder, badge in `accent`/`onAccent`, edge highlight on the image.

Previews: light, dark, and a no-backdrop fallback. Theming notes: put the screen on `.dsBackdrop()` (or `DSScreen(backdrop: true)`) — without it, `.elevated` still works but reads as a plain elevated card.

---

## DSTextField / DSSearchBar  🧪 (colors) ⏳ (wash + focus glow)

`Components/DSTextField.swift`.

```swift
DSTextField(label: String = "", placeholder: String, icon: String? = nil,
            text: Binding<String>,
            state: DSTextFieldState = .normal,   // .normal .focused .error(String) .success .disabled
            isSecure: Bool = false)
DSSearchBar(placeholder: String = "Search", text: Binding<String>)
```

States: real focus (not `.focused`, which looks like `.normal`) tints icon and border with `theme.ink`; `.error` shows message + red icon; `.success` shows a check; `.disabled` at 0.5 opacity. Height 48 (search 44) — literal, candidate for a control-height token. Clear button in the search bar fires `.light`.

Pending restyle: background `subtleFill`, focus → `.dsFocusGlow(theme.ink)`, no stroke.

---

## DSCodeField  🧪 (colors) ⏳ (wash boxes)

`Components/DSCodeField.swift`. OTP / verification input.

**Accessibility:** VoiceOver lands on the hidden field that owns the keyboard: "Verification code", value like "1 2 3, 3 of 6 digits" (+ ", incorrect code" / ", verified"). Boxes and caret are hidden. Override with `.accessibilityLabel(...)`.

```swift
DSCodeField(length: Int = 6, code: Binding<String>,
            state: DSCodeFieldState = .normal,   // .normal .error .success
            boxHeight: CGFloat = 56,
            onComplete: ((String) -> Void)? = nil)
```

Hidden `TextField` owns the keyboard and SMS autofill (`.oneTimeCode`, iOS only). Active box scales 1.04 with `springSnappy`, blinking caret in `theme.ink`, per-digit `.light` haptic, `.error` shakes + `.error` haptic, `.success` fires `.success`. Digits only, clamped to `length`.

---

## DSBadge / DSCountBadge / DSAvatar  🧪 (colors) ⏳ (glass outline)

`Components/DSBadge.swift`.

```swift
DSBadge(_ text: String, color: Color? = nil, variant: DSBadgeVariant = .soft)  // .filled .soft .outline
DSCountBadge(count: Int, color: Color? = nil)      // hides at 0, "99+" cap; color defaults to palette.error
DSAvatar(name: String, imageURL: URL? = nil, size: CGFloat = 40)
```

Badge with default color: `.filled` = `accent`/`onAccent`, `.soft` = accent 12 % + `ink`, `.outline` = `ink` stroke (pending: `.glassThin` + edge). With a custom color the color itself is used for text on soft/outline and `textOnPrimary` on filled.
Avatar: `AsyncImage` when `imageURL` is set, initials on `accent` 15 % otherwise; initials in `theme.ink`.

---

## DSListCell / DSSectionHeader / DSDivider  ✅

`Components/DSList.swift`.

```swift
DSListCell(title:, subtitle: String? = nil, leading: { }, trailing: { }, action: (() -> Void)? = nil)
DSSectionHeader(_ title: String, action: String? = nil, onAction: (() -> Void)? = nil)
DSDivider(inset: CGFloat = 0)
```

A cell with an `action` becomes a button with a chevron and a `.light` haptic. Section header action text uses `theme.ink`. Wrap groups of cells in a `DSCard` for the glass look.

---

## DSToast / DSEmptyState  🧪 (colors) ⏳ (edge + radius 16)

`Components/DSToast.swift`.

**Accessibility:** One element reading "Success: <message>" (Success/Error/Warning/Info); icon hidden. The toast is announced on appear without moving focus. Override with `.accessibilityLabel(...)`.

```swift
DSToast(_ message: String, type: DSToastType = .info)   // .success .error .warning .info
DSEmptyState(icon:, title:, message:, actionTitle: String? = nil, action: (() -> Void)? = nil)
```

Toast already sits on `.ultraThinMaterial` with `.lg` shadow; `DSToastType.haptic` is internal; callers fire the matching haptic themselves on presentation (mapping in [DSToast.md](components/DSToast.md)). Empty state uses a `DSButton` for the CTA.

---

## DSSegmentedControl  🧪 (colors) ⏳ (glass track)

`Components/DSSegmentedControl.swift`. Generic over `Hashable`.

**Accessibility:** Container with one button per segment, labelled with its title, `selected` trait on the active one; icons hidden when a title exists. Double-tap selects with the same haptic as tap.

```swift
DSSegmentedControl(selection: Binding<Value>, segments: [DSSegment<Value>],
                   style: DSSegmentedControlStyle = .pill,   // .pill .underline
                   accent: Color? = nil, haptic: DSHapticStyle = .selection)
DSSegmentedControl(selection: Binding<String>, options: [String], style:, accent:, haptic:)
DSSegment(_ title: String, value: Value, icon: String? = nil)
```

Indicator slides with `matchedGeometryEffect` + `springSnappy`. Underline indicator uses `accent ?? theme.accent`; selected label uses `accent ?? theme.ink`. Selecting the current value does nothing (no haptic).

---

## DSToggle  🧪 (colors) ⏳ (wash track + glow)

`Components/DSToggle.swift`.

**Accessibility:** One switch element: label text, value "On"/"Off", toggle trait; dimmed when disabled. Override the label with `.accessibilityLabel(...)`, especially for label-less toggles.

```swift
DSToggle(_ label: String? = nil, isOn: Binding<Bool>,
         size: DSToggleSize = .medium,      // .small 42×26 · .medium 51×31
         onColor: Color? = nil,             // defaults to theme.accent
         haptic: DSHapticStyle = .rigid)
```

Knob springs with `springSnappy`; respects `.disabled` (0.5 opacity, no haptic). Accessibility value On/Off.

---

## DSRating  ✅ 🧪 (colors)

`Components/DSRating.swift`.

**Accessibility:** Label "Rating", value "N out of M stars", adjustable (swipe up/down) when editable. Not a button. Override with `.accessibilityLabel(...)`.

```swift
DSRating(rating: Binding<Double>, count: Int = 5, step: Double = 1,   // 0.5 for half stars
         symbol: "star.fill", emptySymbol: "star", size: 28, spacing: DSSpacing.xs,
         tint: Color? = nil, emptyColor: Color? = nil, haptics: Bool = true)
DSRating(value: Double, count:, symbol:, emptySymbol:, size: 20, spacing: DSSpacing.xxs, tint:, emptyColor:)  // read-only, fractional fills
```

Drag-to-rate with `.selection` tick per star and `.light` on release; active star pops 1.22× with `springBouncy`. `tint` defaults to `palette.warning`, `emptyColor` to `palette.border`. Adjustable action when editable; the read-only init exposes the same label and value but its adjust action does nothing.

---

## DSPageControl  ✅ 🧪 (colors)

`Components/DSPageControl.swift`.

**Accessibility:** One adjustable element: label "Page", value "N of M" (1-based); swipe up/down changes page when `allowsTap` is true, read-only otherwise. Dots hidden. Override with `.accessibilityLabel(...)`.

```swift
DSPageControl(currentPage: Binding<Int>, numberOfPages: Int,
              activeColor: Color? = nil, inactiveColor: Color? = nil,
              dotSize: DSSpacing.xs, activeWidth: DSSpacing.xl, spacing: DSSpacing.xs,
              allowsTap: Bool = true)
```

Active dot expands into a capsule with `springSmooth`; tapping a dot fires `.selection`. Defaults: `accent` / `palette.border`.

---

## Progress  ✅ 🧪 (colors)

`Animation/DSProgressAnimation.swift`.

```swift
DSCircularProgress(progress:, lineWidth: 6, size: 80, primaryColor: Color? = nil, trackColor: Color? = nil)
DSLinearProgress(progress:, height: 6, primaryColor:, trackColor:)
DSGradientProgress(progress:, height: 8, colors: [Color]? = nil, trackColor:)   // colors default to theme.gradient.stops
DSStepProgress(currentStep:, totalSteps:, activeColor:, inactiveColor:)
DSAnimatedNumber(value:, format: "%.0f", style: .displayLarge)
```

Ring and bars start at 0 and animate with `DSAnimation.progress` on appear and on change; `DSStepProgress` draws `currentStep` segments at once and staggers color changes; the number uses `.counting` + `numericText` content transition.

Modifiers: `.dsShimmer()` (skeletons — width-independent, respects Reduce Motion), `.dsPulse()` (deprecated — use `.dsBreathe(_:)` instead).

---

## DSSlideToConfirm  ✅

`Components/DSSlideToConfirm.swift`. Slide-to-confirm gate for irreversible actions, including payments.

**Accessibility:** Button with the label, hint "Double-tap to confirm", and a value: empty at rest, "Processing" while `onConfirm` runs, the `confirmedLabel` once confirmed. Activation is ignored while processing/confirmed.

```swift
DSSlideToConfirm(_ label: String, icon: String = "chevron.right", confirmedLabel: String = "Confirmed", accent: Color? = nil, finish: DSSlideFinish = .settle, onConfirm: @escaping () async throws -> Void)

enum DSSlideFinish { case settle, morphAndVanish }
```

A glass pill track with a knob filled by `accent ?? theme.accent`. The knob is a circle as tall as the track — it nests into the pill's rounded ends (no track surface above or below it) and starts flush with the leading edge; it's layered over the track's glass clip so its shadow isn't cropped. As the knob tracks the drag, a gradient trail reveals behind it and the label dissolves letter by letter (paced by the drag — each letter waits its turn). The moment the confirmation commits, the label clears on a fast fade regardless of how far the letter-by-letter dissolve had got, so a quick flick past the threshold never leaves text hanging over the pill as it collapses. Tracking is pure 1:1 — no rubber-banding, no magnetic snap: physics tricks under a payment gesture read as the control second-guessing the user.

Threshold is 0.75 of available travel. The drag itself carries a detent texture — 8 `.soft` ticks across the full travel with intensity ramped 0.2 → 0.6 — and crossing the threshold fires `.rigid` once per drag. Releasing below it snaps the knob back with `springBouncy` and a `.light` haptic.

`onConfirm` is `async throws`, so one closure carries both a payment's latency and its outcome. The control spins while awaiting it, with a 500ms floor so a fast closure never flashes the spinner for a single frame; the floor is applied *after* the closure returns, so a slow charge is never padded. Success fires `.success`. A thrown error is a refusal: `.error` fires, the control re-opens and the knob returns to the start for a retry. The control never words its own failure — saying *why* is the parent's job. Existing synchronous call sites still compile unchanged, because `() -> Void` is a subtype of `() async throws -> Void`.

A cloud of small motes is emitted around the knob — around the finger — from the first touch until the outcome lands, brightening with drag speed. **Their tint is the status channel:** neutral (`palette.textTertiary`) throughout, sweeping to `palette.success` on success and staying neutral on refusal. They keep being emitted through the spinner on purpose: a mote lives under a second, so a cloud that stopped at the end of the drag would already be dead by the time there was anything to turn green.

`finish` decides what happens once the action resolves. `.settle` (default, the original behaviour) rests in place showing the check and `confirmedLabel` — right for a destructive confirmation, where the screen does not change so the control has to be the record that something happened. `.morphAndVanish` collapses the pill into a circle, resolves there, then dissolves while the motes disperse outward. It leaves its 56pt slot behind rather than collapsing it, so the parent's layout does not jump on the exact frame of the payoff; the parent cross-fades its own success state in place, or wraps the control in an `if` to collapse it. There is no reset API — re-mount with `.id(attempt)` to run it again.

Under Reduce Motion the knob and trail still move, but the per-letter label stagger collapses to one fade. Reduce Motion or Reduce Transparency suppresses the motes entirely. VoiceOver gets an `.accessibilityAction` so confirming never requires a drag.

---

## DSThinkingIndicator  ✅

`Components/DSThinkingIndicator.swift`. Ambient indicator for AI and background processing states.

```swift
DSThinkingIndicator(phrases: [String] = ["Thinking", "Weighing options", "Almost there"], symbol: String = "sparkles", interval: TimeInterval = 2.6, tint: Color? = nil)
```

A symbol carries layered `.breathe.byLayer` and `.variableColor.iterative` effects; phrases cycle on a `TimelineView(.periodic)` schedule and assemble letter by letter with `DSAnimation.stagger(index:)`. No haptics — it is a status indicator, not an interaction. Under Reduce Motion the symbol effects turn off and letters stop staggering, but phrases keep cycling as a cross-fade because the phrase is information rather than decoration. Layout reserves width for the widest phrase so nothing reflows.

---

## DSTypewriterText  ✅

`Components/DSTypewriterText.swift`. Character-by-character typing animation with caret and phrase cycling.

```swift
DSTypewriterText(_ phrases: [String], style: DSTextStyle = .title1, typingSpeed: TimeInterval = 0.06, erasingSpeed: TimeInterval = 0.03, holdDuration: TimeInterval = 1.4, loops: Bool = true, caretColor: Color? = nil)
```

Types a phrase out character by character, holds it, erases it, then moves to the next. Works on any `[String]`; steps by `Character` so emoji and accents are never split. Driven by a cancellable `Task`, not a `Timer` — cancelled on disappear and restarted when `phrases` or Reduce Motion changes. `loops: false` stops on the last phrase fully typed. A blinking caret in `caretColor ?? theme.accent` runs throughout. Under Reduce Motion there is no typing or erasing and the caret is static (not hidden), but phrases still cycle in full. VoiceOver always announces the whole phrase, never the half-typed fragment. Layout reserves width for the widest phrase — keep phrases short enough to fit on one line.

---

## DSStepper  ✅

`Components/DSStepper.swift`. Numeric −/value/+ stepper on a glass track.

```swift
DSStepper(value: Binding<Int>, in range: ClosedRange<Int> = 0...99, step: Int = 1, accent: Color? = nil)   // accent tints the − and + glyphs; defaults to theme.ink
```

Tapping either glyph steps the bound value, clamped into `range`. The number rolls with `.numericText`. Each successful step fires `.selection` haptic; at a bound the value does not move, the whole track fires one `.dsJiggle` refusal wiggle plus a `.warning` haptic. The buttons deliberately stay hit-testable at a bound (never `.disabled`) so refusal can actually be felt — they just dim. Stepping clamps into `range`, so a `step` that does not evenly divide the range lands on the bound instead of overshooting; a non-positive `step` is treated as `1`. Exposes `.accessibilityAdjustableAction` so VoiceOver gets native increment/decrement.

---

## Motion primitives  ✅

`Animation/DSMotion.swift`. Ambient effects for decorative swell, attention-holding jiggles, entrances, edge highlights, and hue shifts. The motion components adapt techniques (not code) from [amosgyamfi/open-swiftui-animations](https://github.com/amosgyamfi/open-swiftui-animations); each file names its upstream inspiration in a header comment.

```swift
func dsBreathe(_ intensity: DSBreatheIntensity = .medium) -> some View
func dsJiggle<T: Equatable>(trigger: T) -> some View
func dsPopIn(delay: Double = 0) -> some View
func dsEdgeSweep(radius: CGFloat = DSRadius.card, isActive: Bool = true) -> some View
func dsHueDrift(isActive: Bool = true) -> some View

DSMotion.loop(_ base: Animation, autoreverses: Bool = true, unless reduceMotion: Bool) -> Animation?
```

Reach for `.dsBreathe()` on any element that should read as "alive and waiting" (loading states, avatars, status indicators). Use `.dsPopIn()` for list entrances, `.dsJiggle(trigger:)` when an input is rejected or something needs shaking attention. `.dsEdgeSweep()` signals processing or recording (pair it with the surface radius). `.dsHueDrift()` is purely decorative — adds life to a static gradient without leaving the theme. All five settle to a resting state under Reduce Motion (breathe at scale 1, drift at 0°) instead of being skipped; `DSMotion.loop(_:unless:)` handles this by returning `nil`.

---

## DSTabBar  ✅

`Components/DSTabBar.swift`. Floating glass tab bar. Depends on `DSCountBadge`.

```swift
DSTabBar(selection: Binding<Value>, items: [DSTabItem<Value>],
         accent: Color? = nil,                    // selected capsule; nil = theme accent
         haptic: DSHapticStyle = .selection)
DSTabItem(_ title: String, value: Value, icon: String, selectedIcon: String? = nil, badge: Int? = nil)
```

Glass capsule (`.glass`, `DSRadius.chip`, `.lg` shadow). The selected tab sits on a solid accent capsule (`onAccent` content) that slides with `matchedGeometryEffect` on `springSnappy` (`fast` under Reduce Motion); the icon swaps to `selectedIcon` and bounces once. The haptic fires only when the selection changes. VoiceOver: tab-bar trait, one button per tab with `.isSelected`, badge read as "3 new". Place with `.safeAreaInset(edge: .bottom)`.

---

## DSCarousel  ✅

`Components/DSCarousel.swift`.

```swift
DSCarousel(_ data: Data, currentPage: Binding<Int>,      // or omit currentPage for a self-managed index
           peek: CGFloat = DSSpacing.xxxl, spacing: CGFloat = DSSpacing.sm,
           haptic: DSHapticStyle? = .selection) { item in … }
```

`.viewAligned` scroll, `contentMargins` peek (`peek - spacing` of each neighbor shows), `containerRelativeFrame` items, `scrollTransition` depth from `DSCarouselMath.depth(for:)` (scale 0.9, opacity 0.6, 4° yaw at ±1, scaled toward the centre item so the peek survives). Identity under Reduce Motion. Haptic once per user-driven page change, not on programmatic ones. Items should fill the carousel's height (`.frame(maxHeight: .infinity)`): the scroll view clips.

---

## DSSheet  ✅

`Components/DSSheet.swift`. Styling wrapper over the native sheet.

```swift
.dsSheet(isPresented: Binding<Bool>, detents: Set<PresentationDetent> = [.medium, .large], onDismiss: (() -> Void)? = nil) { … }
.dsSheet(item: Binding<Item?>, detents:, onDismiss:) { item in … }
```

Detents + visible grabber. Background: `.regularMaterial` before iOS/macOS 26, the system Liquid Glass sheet from 26 on, solid `backgroundElevated` under Reduce Transparency. Re-injects the presenter's `DSTheme` and sets `dsOnBackdrop` to false inside. No haptic.

---

## DSNumberTicker  ✅

`Components/DSNumberTicker.swift`.

```swift
DSNumberTicker(_ value: Double, format: some FormatStyle<Double, String>,
               style: DSTextStyle = .displayMedium, color: Color? = nil)
DSNumberTicker(_ value: Int, style: DSTextStyle = .displayMedium, color: Color? = nil)
```

Odometer digits: each digit is a 0–9 column in a private animatable `Layout` that rolls on `springSmooth`, staggered 0.03 s from the units digit. Slot ids count from the right (`slots(for:)`, tested), so 99 → 100 keeps its digits. The view is `fixedSize()`: it never compresses, because a squeezed static slot ("US$") would clip. Reduce Motion: crossfade. One accessibility element with the formatted string and `.updatesFrequently`. No haptics.

---

## Charts: DSSparkline / DSBarChart  ✅

`Components/DSCharts.swift`. No Swift Charts dependency.

```swift
DSSparkline(_ values: [Double], color: Color? = nil, lineWidth: CGFloat = 2,
            showsFill: Bool = true, showsLastPoint: Bool = true, accessibilityLabel: String = "Trend")
DSBarChart(_ values: [Double], labels: [String]? = nil, selection: Binding<Int?>? = nil,
           color: Color? = nil, accessibilityLabel: String = "Chart")
```

Sparkline: monotone cubic (Fritsch–Carlson) so the curve never overshoots the data, draw-on with `trim`, morph between same-count datasets through an animatable series, breathing last point. Bar chart: staggered spring growth, negative values clamp to 0, tap or drag to scrub with a `.selection` haptic per bar, bars dim only while one is selected. Both provide `AXChartDescriptorRepresentable` (VoiceOver Audio Graphs) and a spoken summary. Reduce Motion: data appears at rest.

---

## DSSkeleton  ✅

`Components/DSSkeleton.swift`.

```swift
DSSkeleton(width: CGFloat? = nil, height: CGFloat = DSSpacing.sm, cornerRadius: CGFloat = DSRadius.xs)
DSSkeleton.circle(_ diameter: CGFloat)
.dsSkeleton(_ isLoading: Bool)
```

Blocks: `washSurface` on a backdrop, `palette.border` elsewhere, with `dsShimmer`; hidden from VoiceOver. The modifier redacts the real view (`.redacted(reason: .placeholder)`), pulses its opacity from a `TimelineView` (1 → 0.5 → 1 over 3.6 s; paused when not loading or under Reduce Motion), disables hit testing and reads "Loading". It never branches on `isLoading` and never duplicates content, so `@State` and `.task` inside survive the toggle. A `repeatForever` animation was avoided on purpose: it can keep running after loading ends.

---

## DSSuccessCheck  ✅

`Components/DSSuccessCheck.swift`.

```swift
DSSuccessCheck(isComplete: Bool, size: CGFloat = 64, color: Color? = nil,
               haptic: DSHapticStyle? = .success, accessibilityLabel: String = "Done")
```

Ring strokes, disc fills, check draws (eased state), then one pop and a fading halo on a `keyframeAnimator` track (`SpringKeyframe` matching `springBouncy`). The haptic and the VoiceOver announcement land at the pop peak (0.65 s of 0.9 s). Fill is `palette.success`, check `palette.textOnPrimary`. Resets quietly; Reduce Motion crossfades the finished seal in.

---

## dsConfetti  ✅

`Animation/DSConfetti.swift`.

```swift
.dsConfetti(trigger: some Equatable, origin: UnitPoint = .center, count: Int = 80, haptic: DSHapticStyle? = nil)
```

Pure `Canvas` in a `TimelineView` that pauses when the last burst ends. Closed-form physics (gravity + exponential drag, spin, flutter) from a seeded SplitMix64, so it's testable; count clamped to 150. Colors: accent, gradient stops, their light tints and the theme ink (for contrast on the backdrop). Draws inside the view it's attached to, so attach it to a container that covers the area. Removed under Reduce Motion; no haptic by default because the triggering action usually has one.

---

## Layout  ✅

`DSScreen(backgroundColor: Color? = nil, backdrop: Bool = false) { }` · `DSHorizontalScroll(spacing:)` · `DSVStack(spacing: .md, alignment: .leading)` · `DSHStack(spacing: .sm, alignment: .center)` · `DSGrid(minItemWidth: 160, spacing: .md)`.

---

## ComponentCatalog (internal)

`Preview/ComponentCatalog.swift`. Not part of the public API: an Xcode `#Preview` that lists every component with variants, theme dots and a backdrop toggle. Use it for the manual walkthrough. `Preview/DSPreviewSupport.swift` holds the shared `DSPreviewThemeDots`.
