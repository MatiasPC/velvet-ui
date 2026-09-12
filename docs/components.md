# Components reference

One section per component: what it is for, the public API, variants and states, motion and haptics, theming notes, and anything known to be missing. Keep this file in sync with the code — a component change without a doc change is not done.

Conventions that apply to every component:
- Colors come from `@DSThemed`. Parameters typed `Color? = nil` follow the theme when nil.
- Press states use `DSPress.scale` (0.96) or `DSPress.iconScale` (0.88) with `DSPress.animation`.
- Haptics fire inside the component; don't add another on the call site.
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

**DSIconButton**: `DSIconButton(icon:size: 44,color: Color? = nil,haptic: .light,action:)`. Color defaults to `palette.textPrimary`; press uses `DSPress.iconScale`.

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

States: focus tints icon and border with `theme.ink`; `.error` shows message + red icon; `.success` shows a check; `.disabled` at 0.5 opacity. Height 48 (search 44) — literal, candidate for a control-height token. Clear button in the search bar fires `.light`.

Pending restyle: background `subtleFill`, focus → `.dsFocusGlow(theme.ink)`, no stroke.

---

## DSCodeField  🧪 (colors) ⏳ (wash boxes)

`Components/DSCodeField.swift`. OTP / verification input.

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

```swift
DSToast(_ message: String, type: DSToastType = .info)   // .success .error .warning .info
DSEmptyState(icon:, title:, message:, actionTitle: String? = nil, action: (() -> Void)? = nil)
```

Toast already sits on `.ultraThinMaterial` with `.lg` shadow; `DSToastType.haptic` maps to the matching haptic for the caller to fire on presentation. Empty state uses a `DSButton` for the CTA.

---

## DSSegmentedControl  🧪 (colors) ⏳ (glass track)

`Components/DSSegmentedControl.swift`. Generic over `Hashable`.

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

```swift
DSRating(rating: Binding<Double>, count: Int = 5, step: Double = 1,   // 0.5 for half stars
         symbol: "star.fill", emptySymbol: "star", size: 28, spacing: DSSpacing.xs,
         tint: Color? = nil, emptyColor: Color? = nil, haptics: Bool = true)
DSRating(value: Double, count:, symbol:, emptySymbol:, size: 20, spacing: DSSpacing.xxs, tint:, emptyColor:)  // read-only, fractional fills
```

Drag-to-rate with `.selection` tick per star and `.light` on release; active star pops 1.22× with `springBouncy`. `tint` defaults to `palette.warning`, `emptyColor` to `palette.border`. Full accessibility (adjustable action).

---

## DSPageControl  ✅ 🧪 (colors)

`Components/DSPageControl.swift`.

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

All animate with `DSAnimation.progress` on appear and on change; the number uses `.counting` + `numericText` content transition.

Modifiers: `.dsShimmer()` (skeletons — width-independent, respects Reduce Motion), `.dsPulse()` (deprecated — use `.dsBreathe(_:)` instead).

---

## DSSlideToConfirm  ✅

`Components/DSSlideToConfirm.swift`. Slide-to-confirm gate for irreversible actions, including payments.

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
DSStepper(value: Binding<Int>, in range: ClosedRange<Int> = 0...99, step: Int = 1, accent: Color? = nil)
```

Tapping either glyph steps the bound value, clamped into `range`. The number rolls with `.numericText`. Each successful step fires `.selection` haptic; at a bound the value does not move, the whole track fires one `.dsJiggle` refusal wiggle plus a `.warning` haptic. The buttons deliberately stay hit-testable at a bound (never `.disabled`) so refusal can actually be felt — they just dim. Stepping clamps into `range`, so a `step` that does not evenly divide the range lands on the bound instead of overshooting; a non-positive `step` is treated as `1`. Exposes `.accessibilityAdjustableAction` so VoiceOver gets native increment/decrement.

---

## DSDisclosure  🧪

`Components/DSDisclosure.swift`. Expand/collapse section with a tappable header over springy content — a styled replacement for the stock, chrome-heavy `DisclosureGroup`.

```swift
DSDisclosure(_ title: String, subtitle: String? = nil, icon: String? = nil, initiallyExpanded: Bool = false, showsDivider: Bool = true) { content }
```

Tapping the header toggles open/closed on `DSAnimation.springSmooth`: the chevron rotates 90° and the content grows while fading in, clipped by the container so nothing spills mid-reveal. A `.light` haptic fires on every toggle. Manages its own expanded state (seeded by `initiallyExpanded`) — no binding to wire up. Optional `icon` is an SF Symbol tinted `theme.ink`; `showsDivider` draws a hairline between header and content when open. Under Reduce Motion the toggle is instant (the fade stays, nothing travels). Draws **no surface of its own** — place it inside a `DSCard` (or on a `dsSurface`) so it inherits the glass; stack several in one card, separated by `DSDivider`, for an accordion-style list. VoiceOver reads the title with an expand/collapse hint and an Expanded/Collapsed value.

---

## Motion primitives  ✅

`Animation/DSMotion.swift`. Ambient effects for decorative swell, attention-holding jiggles, entrances, edge highlights, and hue shifts. The four motion components adapt techniques (not code) from [amosgyamfi/open-swiftui-animations](https://github.com/amosgyamfi/open-swiftui-animations); each file names its upstream inspiration in a header comment.

```swift
func dsBreathe(_ intensity: DSBreatheIntensity = .medium) -> some View
func dsJiggle<T: Equatable>(trigger: T) -> some View
func dsPopIn(delay: Double = 0) -> some View
func dsEdgeSweep(radius: CGFloat = DSRadius.card, isActive: Bool = true) -> some View
func dsHueDrift(isActive: Bool = true) -> some View

DSMotion.loop(_ base: Animation, autoreverses: Bool = true, unless reduceMotion: Bool) -> Animation?
```

Reach for `.dsBreathe()` on any element that should read as "alive and waiting" (loading states, avatars, status indicators). Use `.dsPopIn()` for list entrances, `.dsJiggle(trigger:)` when an input is rejected or something needs shaking attention. `.dsEdgeSweep()` signals processing or recording (pair it with the surface radius). `.dsHueDrift()` is purely decorative — adds life to a static gradient without leaving the theme. All five settle to a resting state under Reduce Motion instead of being skipped; `DSMotion.loop(_:unless:)` handles this by returning `nil`.

---

## Layout  ✅

`DSScreen(backgroundColor: Color? = nil, backdrop: Bool = false) { }` · `DSHorizontalScroll(spacing:)` · `DSVStack(spacing: .md, alignment: .leading)` · `DSHStack(spacing: .sm, alignment: .center)` · `DSGrid(minItemWidth: 160, spacing: .md)`.

---

## ComponentCatalog (internal)

`Preview/ComponentCatalog.swift`. Not part of the public API: an Xcode `#Preview` that lists every component with variants, theme dots and a backdrop toggle. Use it for the manual walkthrough. `Preview/DSPreviewSupport.swift` holds the shared `DSPreviewThemeDots`.
