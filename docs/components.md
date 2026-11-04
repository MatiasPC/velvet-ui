# Components reference

> Looking for usage? Each component has a page with a copyable snippet, parameters and accessibility notes in [`docs/components/`](components/). This file is the maintainers' reference: status, restyle backlog and implementation notes.

One section per component: what it is for, the public API, variants and states, motion and haptics, theming notes, and anything known to be missing. Keep this file in sync with the code — a component change without a doc change is not done.

Conventions that apply to every component:
- Colors come from `@DSThemed`. Parameters typed `Color? = nil` follow the theme when nil.
- Press states use `DSPress.scale` (0.96) or `DSPress.iconScale` (0.88) with `DSPress.animation`.
- Haptics fire inside the component; don't add another on the call site. The exception is the bare `DSToast` view, which fires none; `.dsToast` fires it for you.
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

## DSFlipCard  🧪

`Components/DSFlipCard.swift`. A two-sided glass card that turns over in 3D.

```swift
DSFlipCard(axis: DSFlipAxis = .horizontal,       // .horizontal (y) · .vertical (x)
           style: DSCardStyle = .elevated,
           padding: CGFloat = DSSpacing.md,
           cornerRadius: CGFloat = DSRadius.card,
           flipOnTap: Bool = true,
           haptic: DSHapticStyle? = .rigid) { front } back: { back }

// Controlled: same params plus a leading `isFlipped: Binding<Bool>`.
DSFlipCard(isFlipped: $revealed, axis: .vertical) { front } back: { back }
```

Each face is a `DSCard` (depends on it). The turn is one `DSAnimation.springSmooth` about `axis` with `perspective` 0.5. A single animated angle runs through an inner `Animatable` container (`DSFlipFaces`); the faces swap on the `angle >= 90` threshold, so the hand-off lands at the edge for any animation, spring included — no opacity cross-fade, no ghosting. The back face is pre-rotated 180° about the same axis so it reads correctly once flipped. The haptic (`.rigid`, `nil` for none) fires from `onChange(of: isFlipped)`, so tap and binding-driven flips both get it as the turn starts. Both faces are laid out by a small `Layout` at the larger face's size (they fill it), and the face that is not showing has hit testing off.

Motion: under Reduce Motion the card never turns (the back face is not pre-rotated) and the faces crossfade with `DSAnimation.fast`. No `compositingGroup()`: it is unnecessary once the faces never overlap, and it risks changing how the glass material samples the backdrop.

Accessibility: with `flipOnTap` the card is one combined element with `.isButton`, hint "Double tap to flip" and a Front/Back side value; the hidden face is `.accessibilityHidden`. With `flipOnTap: false` no button semantics are added, so faces keep their own hit testing — the documented path for a face with its own controls.

Previews: light and dark on `.dsBackdrop()`, a tap-to-flip stat card and a binding-driven vertical card.

## DSTiltCard  ✅

`Components/DSTiltCard.swift`. A glass card that tips in 3D toward the finger as you drag, with a specular sheen sliding across the surface, then springs back on release.

```swift
DSTiltCard(maxTilt: Angle? = nil,                // peak rotation at the edge of the drag; nil = 12°
           padding: CGFloat = DSSpacing.md,
           cornerRadius: CGFloat = DSRadius.card,
           haptic: DSHapticStyle? = .soft) { content }
```

Drag tilts the card around both axes (clamped at `maxTilt` once the drag passes ~120 pt); the sheen fades in with the tilt and the shadow deepens from `.lg` to `.xl` while held. Tracking is un-animated (1:1 with the finger); release or a cancelled touch springs it flat with `DSAnimation.springGentle`. The gesture is `simultaneousGesture`, so the card never blocks an enclosing `ScrollView` and buttons inside keep their taps; a `@GestureState` flag catches the cancelled case that `onEnded` misses. A `.soft` haptic fires once as the touch begins (`nil` for none). Under Reduce Motion the card never rotates, the shadow does not lift and the sheen stays put, only fading in while held. Decoration only — for a tappable surface use `DSInteractiveCard`.

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

`Components/DSToast.swift`, `Components/DSToastPresenter.swift`.

**Accessibility:** One element reading "Success: <message>" (Success/Error/Warning/Info); icon hidden. The toast is announced on appear without moving focus. Override with `.accessibilityLabel(...)`. The presenter adds a "Dismiss" action.

```swift
DSToast(_ message: String, type: DSToastType = .info)   // .success .error .warning .info
DSEmptyState(icon:, title:, message:, actionTitle: String? = nil, action: (() -> Void)? = nil)

// Presenter: bind an optional value to the screen
DSToastValue(_ message: String, type: DSToastType = .info, duration: Double = 2.5)  // duration <= 0 = sticky
DSToastEdge { case top, bottom }
func dsToast(_ toast: Binding<DSToastValue?>, edge: DSToastEdge = .top) -> some View
```

Toast already sits on `.ultraThinMaterial` (solid under Reduce Transparency) with `.lg` shadow. `DSToast` is just the banner; `.dsToast` is how you show one (below). `DSToastType.haptic` is internal: the presenter fires it, and a bare `DSToast` leaves it to the caller (mapping in [DSToast.md](components/DSToast.md)). Empty state uses a `DSButton` for the CTA.

### Toast presenter  ✅

`.dsToast($toast, edge:)` overlays the banner on the view it modifies, so apply it at the screen root.

- **Present / replace / dismiss.** Assign a `DSToastValue` to show it, a new one to replace it, `nil` to dismiss. Each value has its own identity, so presenting the same text twice works. A replacement is a cut, never a cross-fade: the old banner is removed instantly (identity transition on the `.id`-keyed `DSToast`) and the animation is keyed on *presence*, so two glass banners never overlap.
- **Auto-dismiss.** A `.task(id: toast?.id)` waits `duration` and clears the binding only if the same toast is still showing. A replacement restarts it, and a dismissal or flick cancels it. `duration <= 0` (or not finite) is sticky.
- **Motion.** Slides from `edge` with `.move` + opacity on `springGentle`. Drag toward the edge to flick it away (past `DSSpacing.xl`, or a flick that projects past `DSSpacing.massive`); otherwise it springs back on `springSnappy`. Dragging inward resists at 0.2×. Under Reduce Motion the slide is a `DSAnimation.fast` fade.
- **Haptics.** `DSToastType.haptic` fires when a toast appears (success/error/warning notification haptics, info `.light`).
- **Accessibility.** The `.id` re-mounts `DSToast` per presentation, so VoiceOver announces replacements too. A "Dismiss" accessibility action clears it without a drag.
- Stack two modifiers (one per edge, each with its own binding) to run a top and a bottom toast independently.

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

## DSChip / DSChipGroup  ✅ 🧪

`Components/DSChip.swift`. `DSChipGroup` is generic over `Hashable`: selectable pill chips on [`DSFlowLayout`](#dsflowlayout), single or multiple selection. Built glass-native for v0.2. Depends on `DSFlowLayout`.

**Accessibility:** Container of buttons, each labelled with its title and `selected` when active; a leading icon is decorative and hidden from VoiceOver. Labels use the `buttonSmall` text style (`dsTextStyle`) and scale with Dynamic Type.

```swift
DSChip(_ title: String, icon: String? = nil, isSelected: Bool = false,
       accent: Color? = nil, haptic: DSHapticStyle = .selection, action: () -> Void)
DSChipGroup(_ items: [DSChipItem<Value>], selection: Binding<Set<Value>>,   // multiple
            spacing: CGFloat = DSSpacing.xs, accent: Color? = nil)
DSChipGroup(_ items: [DSChipItem<Value>], selection: Binding<Value?>, ...)  // single: tap selected to clear
DSChipGroup(_ options: [String], selection: Binding<Set<String>>, ...)      // String shortcut (also Binding<String?>)
DSChipItem(_ title: String, value: Value, icon: String? = nil)
```

Selected chips crossfade `theme.subtleFill` → `accent ?? theme.accent` with `springSnappy` (a quick `fast` fade under Reduce Motion) and a `.sm` lift; selecting ticks `.selection`. `DSFlowLayout` wraps chips onto new lines — no borders, no horizontal scroll. Press feedback is a `ButtonStyle` (`DSPress.scale`), not a `DragGesture`, so a touch that turns into a scroll releases the chip. Disabled chips dim to half opacity. The selection toggling is pure and unit-tested (`DSChipGroup.toggled`).

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
DSGradientProgress(progress:, height: 8, colors: [Color]? = nil, trackColor:)   // colors default to a single accent stop (solid)
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

A glass pill track with a knob filled by `accent ?? theme.accent`. The knob is a circle as tall as the track — it nests into the pill's rounded ends (no track surface above or below it) and starts flush with the leading edge; it's layered over the track's glass clip so its shadow isn't cropped. As the knob tracks the drag, an accent trail reveals behind it and the label dissolves letter by letter (paced by the drag — each letter waits its turn). The moment the confirmation commits, the label clears on a fast fade regardless of how far the letter-by-letter dissolve had got, so a quick flick past the threshold never leaves text hanging over the pill as it collapses. Tracking is pure 1:1 — no rubber-banding, no magnetic snap: physics tricks under a payment gesture read as the control second-guessing the user.

Threshold is 0.75 of available travel. The drag itself carries a detent texture — 8 `.soft` ticks across the full travel with intensity ramped 0.2 → 0.6 — and crossing the threshold fires `.rigid` once per drag. Releasing below it snaps the knob back with `springBouncy` and a `.light` haptic.

`onConfirm` is `async throws`, so one closure carries both a payment's latency and its outcome. The control spins while awaiting it, with a 500ms floor so a fast closure never flashes the spinner for a single frame; the floor is applied *after* the closure returns, so a slow charge is never padded. Success fires `.success`. A thrown error is a refusal: `.error` fires, the control re-opens and the knob returns to the start for a retry. The control never words its own failure — saying *why* is the parent's job. Existing synchronous call sites still compile unchanged, because `() -> Void` is a subtype of `() async throws -> Void`.

A cloud of small motes is emitted around the knob — around the finger — from the first touch until the outcome lands, brightening with drag speed. **Their tint is the status channel:** neutral (`palette.textTertiary`) throughout, sweeping to `palette.success` on success and staying neutral on refusal. They keep being emitted through the spinner on purpose: a mote lives under a second, so a cloud that stopped at the end of the drag would already be dead by the time there was anything to turn green.

`finish` decides what happens once the action resolves. `.settle` (default, the original behaviour) rests in place showing the check and `confirmedLabel` — right for a destructive confirmation, where the screen does not change so the control has to be the record that something happened. `.morphAndVanish` collapses the pill into a circle, resolves there, then dissolves while the motes disperse outward. It leaves its 56pt slot behind rather than collapsing it, so the parent's layout does not jump on the exact frame of the payoff; the parent cross-fades its own success state in place, or wraps the control in an `if` to collapse it. There is no reset API — re-mount with `.id(attempt)` to run it again.

Under Reduce Motion the knob and trail still move, but the per-letter label stagger collapses to one fade. Reduce Motion or Reduce Transparency suppresses the motes entirely. VoiceOver gets an `.accessibilityAction` so confirming never requires a drag.

---

## DSHoldToConfirm  ✅

`Components/DSHoldToConfirm.swift`. Press-and-hold confirmation control — the companion to `DSSlideToConfirm`. Where a slide gates an action behind a deliberate *gesture*, a hold gates it behind deliberate *time*.

```swift
DSHoldToConfirm(_ label: String, icon: String? = nil, confirmedLabel: String = "Confirmed", duration: Double = 1.2, accent: Color? = nil, isFullWidth: Bool = true, onConfirm: @escaping () -> Void)
```

A glass pill (`glassThin`, `DSRadius.chip`). While a finger is down, a progress ring charges around the pill over `duration`, drawn as a `trim` of the capsule — so at rest (`progress == 0`) it draws nothing and there is no border. The ring is the theme gradient by default, or a solid `accent` when one is passed. The moment the ring closes, the whole pill fills `accent ?? theme.accent`, the label swaps to a checkmark and `confirmedLabel`, and the action runs. Lifting before the ring closes cancels: the ring springs back and `onConfirm` never runs.

The charge clock is a cancellable `Task`, not the ring animation — a lifted finger cancels it so the confirmation can't slip through on a fractional-second overshoot. A `.soft` detent fires on touch-down and at each of 6 steps, ramped 0.2 → 0.6 so the ring feels like it is tightening; completing fires `.success`, cancelling fires `.light`. The press dips the pill with `DSPress.scale`.

Per the accent-role rules, the filled label uses `theme.onAccent` when the fill is the theme accent and `palette.textOnPrimary` (white) when the caller overrode `accent` with a status color; at rest the label is `theme.ink` on glass. There is no ambient loop to suppress for Reduce Motion — the ring is essential progress feedback — but the spring-back and fill collapse to `DSAnimation.fast` under it. VoiceOver gets an `.accessibilityAction` so a single activation confirms without a timed hold. No reset API — re-mount with `.id(attempt)` to run it again.

Pick a slide when the risk is an accidental touch (a payment, a destructive button a thumb could brush); pick a hold when the risk is sustained intent (power off, hold-to-record) or when one hand is all the user has.

---

## DSHoldToConfirm  ✅

`Components/DSHoldToConfirm.swift`. Press-and-hold confirmation, the companion to `DSSlideToConfirm`: a slide gates an action behind a deliberate *gesture*, a hold behind deliberate *time*. It shares the slide's vocabulary on purpose.

```swift
DSHoldToConfirm(_ label: String, icon: String? = nil, confirmedLabel: String = "Confirmed", duration: Double = 1.2, accent: Color? = nil, isFullWidth: Bool = true, onConfirm: @escaping () async throws -> Void)
```

A glass pill (`glassThin`, `DSRadius.chip`). While a finger is down a ring in `accent ?? theme.accent` charges around it over `duration`, a `trim` of the pill's capsule, so at rest it draws nothing (no border). When it closes the pill fills with the accent, a spinner shows while `onConfirm` runs (500ms floor, applied after the closure returns, as in the slide), then `.success`, a check and `confirmedLabel`. A throw is a refusal: `.error`, a 220ms beat, and the control re-opens. No reset API; re-mount with `.id`. Lifting early cancels: `.light` and the ring springs back, `onConfirm` never runs.

The charge clock is a cancellable `Task` (`chargeSchedule`: six equal steps summing to `duration`), not the ring animation, so a lift can never leak a confirm. The action itself runs in a separate task so a disappearing view cancels the hold but never a payment already in flight. A `.soft` detent fires on touch-down and at each step, ramped 0.2 to 0.6 like the slide's; the press dips with `DSPress.scale`. All labels are stacked in a `ZStack` so the pill doesn't resize between states. Filled label color follows the accent roles: `onAccent` on the theme accent, `textOnPrimary` on a status color. The ring is essential feedback, so Reduce Motion keeps it and only swaps the bounces for `DSAnimation.fast`. VoiceOver gets the slide's hint and value words and a plain activation (`accessibilityAction`) that confirms without holding. `.disabled(true)` dims to 0.5.

Pick a slide when the risk is an accidental touch (a payment, a destructive button a thumb could brush); pick a hold when the risk is sustained intent (power off, hold-to-record) or when one hand is all the user has.

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

## DSExpandableText  ✅

`Components/DSExpandableText.swift`. Clamp-and-reveal for long copy.

```swift
DSExpandableText(_ text: String, lineLimit: Int = 3, expandLabel: String = "Show more", collapseLabel: String = "Show less", style: DSTextStyle = .body, color: Color? = nil, haptic: DSHapticStyle = .light)
```

Collapses `text` to `lineLimit` lines and springs open on tap. Truncation is measured, not guessed: two hidden copies of the text (one clamped to `lineLimit`, one unbounded) sit in the copy's `.background` and report their height with `onGeometryChange` (iOS 18 / macOS 15); the toggle shows only when the unbounded copy is taller by more than half a point, so short copy has no affordance. Neither probe depends on the expanded state, so the toggle never flickers. The rules (`lines(for:)`, `isTruncated`, `revealHeight`) live in an internal `DSExpandableTextLayout` and are unit tested.

The reveal animates a frame, not `lineLimit`: the visible `Text` is `fixedSize(vertical:)`, then `frame(height: revealHeight, alignment: .top)` and `.clipped()`, with `revealHeight` switching between the two measured heights under `DSAnimation.springSmooth`. Animating `lineLimit` directly re-wraps the text on the first frame and centres it in a frame that is still resizing, so lines jump. Two states keep it clean: `isExpanded` is the target (frame, chevron, label), `showsFullCopy` lays the text out without a limit and is set before an expand and cleared in the `withAnimation` completion of a collapse, so the ellipsis only changes while it is clipped away. Chevron rotates 180°, label crossfades (`.contentTransition(.opacity)`), the haptic fires on the tap. Copy color is `color ?? palette.textPrimary` via `.ds(_:)`, so it scales with Dynamic Type and re-measures; the toggle uses `theme.ink`. Reduce Motion skips the animation and sets both states directly. VoiceOver reads the full copy whether collapsed or expanded; the toggle is a button labelled with its visible text with the value Collapsed or Expanded, the chevron and the probes are hidden.

Known gaps: the expansion state is internal (no `isExpanded` binding), so a list cannot expand or collapse rows for you or remember it across reloads; the label strings are English defaults you pass in to localize.

---

## DSStepper  ✅

`Components/DSStepper.swift`. Numeric −/value/+ stepper on a glass track.

```swift
DSStepper(value: Binding<Int>, in range: ClosedRange<Int> = 0...99, step: Int = 1, accent: Color? = nil)   // accent tints the − and + glyphs; defaults to theme.ink
```

Tapping either glyph steps the bound value, clamped into `range`. The number rolls with `.numericText`. Each successful step fires `.selection` haptic; at a bound the value does not move, the whole track fires one `.dsJiggle` refusal wiggle plus a `.warning` haptic. The buttons deliberately stay hit-testable at a bound (never `.disabled`) so refusal can actually be felt — they just dim. Stepping clamps into `range`, so a `step` that does not evenly divide the range lands on the bound instead of overshooting; a non-positive `step` is treated as `1`. Exposes `.accessibilityAdjustableAction` so VoiceOver gets native increment/decrement.

---

## DSSlider  ✅

`Components/DSSlider.swift`. Continuous value control — the input Stepper/Rating/Toggle (all discrete) left uncovered.

```swift
DSSlider(value: Binding<Double>, in bounds: ClosedRange<Double> = 0...1, step: Double? = nil, accent: Color? = nil, haptics: Bool = true)
```

A slim track, an accent fill that trails to the knob's centre, and a white knob (`palette.textOnPrimary`, like DSToggle) that lifts `1.12×` and grows a diffuse accent halo (the focus-glow recipe) while grabbed. The track is `theme.subtleFill` on a `dsBackdrop()` screen and `palette.border` (DSToggle's off track) on a plain one, where `subtleFill` is near-white and the 8pt line would vanish. The knob follows the finger and a tap anywhere jumps to that spot (`minimumDistance: 0`); the touch travel is inset by the knob radius at each end so finger and knob centre agree.

The value mapping is `DSSliderScale` (internal, unit-tested): `clamped` (NaN falls to the lower bound), `snapped` (notches at `lower + k × step`, plus the upper bound even when `step` doesn't divide the span, so the far end is always reachable, like DSStepper), `fraction`/`value(atFraction:)`, `value(atX:trackWidth:knobDiameter:)` (nil until the track is measured) and `adjusted` (VoiceOver: the next notch, or a tenth of the span). A non-positive `step` is continuous. The bound value is clamped and written back on appear and whenever it changes, so it never stays outside `in`.

Haptics: a continuous slider is silent between the ends and fires one `.rigid` detent on *arriving* at either bound; a stepped one also fires `.selection` per notch crossed. Touching down on the notch or end the knob already rests on is silent (the feedback state is seeded from the current value at touch-down). `haptics: false` silences both. Reduce Motion pins the grab lift and drops the spring lag (the halo stays: it is opacity only). `.disabled(true)` dims to 0.5 and drops the gesture. Exposes `.accessibilityAdjustableAction` and a value ("60 percent" for the default `0...1`, otherwise the number, with only the decimals `step` needs). Show your own visible read-out alongside it, the way `DSRating`'s call sites do.

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

Reach for `.dsBreathe()` on any element that should read as "alive and waiting" (loading states, avatars, status indicators). Use `.dsPopIn()` for list entrances, `.dsJiggle(trigger:)` when an input is rejected or something needs shaking attention. `.dsEdgeSweep()` signals processing or recording (pair it with the surface radius). `.dsHueDrift()` is purely decorative — adds life to a solid fill without leaving the theme. All five settle to a resting state under Reduce Motion (breathe at scale 1, drift at 0°) instead of being skipped; `DSMotion.loop(_:unless:)` handles this by returning `nil`.

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

## DSDisclosureGroup  ✅

`Components/DSDisclosureGroup.swift`. Glass accordion / FAQ row — a custom, themed replacement for the stock `DisclosureGroup` (whose open/close animation breaks inside a `ForEach` on iOS 17, whose chevron ignores the tint, and which has no haptics or glass).

```swift
DSDisclosureGroup(_ title: String, subtitle: String? = nil, icon: String? = nil,
                  initiallyExpanded: Bool = false, haptic: DSHapticStyle = .light) { content }
DSDisclosureGroup(_ title: String, subtitle: String? = nil, icon: String? = nil,
                  isExpanded: Binding<Bool>, haptic: DSHapticStyle = .light) { content }
```

Two inits: self-contained (`initiallyExpanded:`) and controlled (`isExpanded:`, for "one open at a time"). On a `.glass` surface at `DSRadius.card`. The body sits in a private `Layout` (`DSDisclosureReveal`) whose `animatableData` is the revealed fraction, so the card grows with the body on `springSmooth`, the body fades with it and the chevron rotates 180° on the same spring; the body is laid out at full height and clipped, so text never re-wraps mid-reveal. The animation hangs off the open state (`.animation(_, value:)`), so it plays for a bound `isExpanded` flipped from outside and retargets on rapid taps. A hairline `palette.divider` splits header from body; the header dips with `DSPress.scale`. `.light` haptic on each toggle. The body stays mounted while collapsed (keeps its state), hidden from touch and VoiceOver. Reduce Motion: a short `DSAnimation.fast` ease instead of the spring, haptic still fires. Reduce Transparency: solid elevated surface. Header is one combined button with value Expanded/Collapsed and a "Shows/Hides the details" hint; the icon and chevron are `accessibilityHidden`.

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

## DSTimeline  ✅

`Components/DSTimeline.swift`. Vertical progress timeline — the content-bearing, vertical complement to `DSStepProgress`.

```swift
DSTimeline(_ items: [DSTimelineItem], currentStep: Int,
           nodeSize: CGFloat = DSSpacing.xxl, lineWidth: CGFloat = DSSpacing.xxxs,
           accent: Color? = nil, haptics: Bool = true)

DSTimelineItem(_ title: String, subtitle: String? = nil, icon: String? = nil)
```

Steps are positional: identity is the enumerated index (`id: \.offset`), so rebuilding `items` keeps nodes animating in place. The rules live in an internal `DSTimelineProgress` (clamp, status, connector fill, `isAdvance`) so they are unit tested: `currentStep` clamps to `0...items.count`, steps before it are complete, the one at it is current, the rest upcoming. Each row is `HStack(alignment: .top)`: node, then a content column whose title is `frame(minHeight: nodeSize)` so it centres on the node at any text size (`nodeSize` is a `@ScaledMetric` relative to `.callout`). The connector is a track capsule with an accent capsule on top at `scaleEffect(y:)` anchored at the top, clipped to the track, and drawn as the row's `.background` offset below the node — not as a flexible child of the rail. The live node's glow sits on its own `dsBreathe(.medium)` layer behind the node and is inserted only while the step is current. The spring (`springSmooth`, or `fast` under Reduce Motion) and the single `.success` haptic are keyed on the clamped step through `animation(value:)` and `onChange` (no `initial:`), and the haptic additionally requires `isAdvance`. One accessibility element per step: title and subtitle as label, status as value.

Known gaps: vertical only; no branching; a jump of several steps fills all connectors at once rather than in sequence.

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

## DSLikeButton  ✅

`Components/DSLikeButton.swift`.

```swift
DSLikeButton(isLiked: Binding<Bool>, count: Int? = nil, size: CGFloat = DSSpacing.xl,
             symbol: String = "heart.fill", emptySymbol: String = "heart",
             tint: Color? = nil, haptic: DSHapticStyle = .soft,
             accessibilityLabel: String = "Like")
```

Favorite / like / bookmark toggle. Liking swaps the symbol with `contentTransition(.symbolEffect(.replace))`, pops the glyph on a `keyframeAnimator` track (`SpringKeyframe` matching `springBouncy`) and radiates one filled halo in the tint, the same halo mechanism as `DSSuccessCheck`, so there's no border. The haptic fires on the peak of the pop (0.13 s after the tap); unliking is quiet (no pop, no halo, haptic on the tap), and rapid taps restart the one track instead of stacking. The beat belongs to the tap: setting `isLiked` from code swaps the symbol without a pop or a haptic. An optional `count` rolls with `.numericText`. Tap target is at least 44 pt, press dips with `DSPress.iconScale`, disabled dims. Reduce Motion: no pop or halo, crossfades instead of morphs, haptic on the tap. Tint defaults to `theme.accent`, the rest color to `palette.textSecondary`. VoiceOver: toggle button, value "Liked, 129" / "Not liked".

---

## dsConfetti  ✅

`Animation/DSConfetti.swift`.

```swift
.dsConfetti(trigger: some Equatable, origin: UnitPoint = .center, count: Int = 80, haptic: DSHapticStyle? = nil)
```

Pure `Canvas` in a `TimelineView` that pauses when the last burst ends. Closed-form physics (gravity + exponential drag, spin, flutter) from a seeded SplitMix64, so it's testable; count clamped to 150. Colors: the accent, the theme ink, a lighter tint of each and the ink again for weight (for contrast on every page tone). Draws inside the view it's attached to, so attach it to a container that covers the area. Removed under Reduce Motion; no haptic by default because the triggering action usually has one.

---

## dsScrollReveal  ✅

`Animation/DSScrollEffects.swift`. The scroll-coupled member of the motion vocabulary, built on `scrollTransition(.interactive)`: a view is at full presence inside the scroll view's visible area and recedes (scale + opacity) as it crosses the leading or trailing edge, and returns when the user scrolls back. Unlike `dsPopIn` / `dsStaggerIn` (one-shot, `onAppear`) it is bidirectional and reversible.

```swift
func dsScrollReveal(_ intensity: DSScrollRevealIntensity = .medium) -> some View
// .subtle / .medium / .strong -> DSMotion.scrollReveal{Subtle,Medium,Strong}{Scale,Opacity}
```

The edge values are `DSMotion` tokens (0.96/0.65, 0.90/0.40, 0.80/0.15 for scale/opacity). The amount is `DSScrollRevealMath.effect(for:phaseValue:reduceMotion:)` (interpolated by `|phase.value|`, clamped, unit-tested). Axis is inferred from the scroll view. Only render transforms are touched, so nothing reflows. Centre emphasis needs a peeking carousel (`contentMargins` + `containerRelativeFrame`), because the effect keys off the visible-area edge. No haptics. Under Reduce Motion every item rests at scale 1 / opacity 1. Docs: [DSScrollReveal.md](components/DSScrollReveal.md).
## DSMarquee  ✅

`Components/DSMarquee.swift`.

```swift
DSMarquee(velocity: CGFloat = 40,          // points/second; 0 disables scrolling
          spacing: CGFloat = DSSpacing.xxxl, // gap between the looping copies
          fade: CGFloat = DSSpacing.lg) {    // edge-fade width per side; 0 = hard edges
    content
}
```

Generic over any single-line content. Scrolls only when the content overflows its width; otherwise static and left-aligned with no fade. The loop is two copies laid end to end with `spacing`, translated by one copy's width + gap and wrapped, so the seam never shows. Width is measured with `onGeometryChange` (iOS 18 / macOS 15); the scrolling layer samples its offset from a `TimelineView(.animation)` (pure `DSMarqueeMath.offset`), so it stops ticking off-screen and needs no remount when the measurement changes. Edges are softened with a gradient `.mask` (never a border). No haptics (ambient, not interactive). Reduce Motion: shown static from the start with a trailing fade, not frozen mid-scroll. Accessibility: content exposed as one combined element; the looping and measuring copies are hidden.
## DSFlowLayout  ✅

`Layout/DSFlowLayout.swift`. A `Layout`, not a container view, so it is called like a stack: `DSFlowLayout { … }`.

```swift
DSFlowLayout(spacing: CGFloat = DSSpacing.xs, lineSpacing: CGFloat = DSSpacing.xs,
             alignment: HorizontalAlignment = .leading) { content }
```

Greedy first-fit row packing for tag clouds, filter chips and keyword lists: items fill a row until the next would overflow the proposed width, then wrap. It fills a finite proposed width (so `.center` / `.trailing` have room) and shrinks to its widest row when offered none; an infinite proposal is never echoed back as its size. An item wider than the container is measured again at the container width, so text wraps instead of overflowing. Shorter items sit centred in their row, and right-to-left mirrors the rows. Pure SwiftUI: no `GeometryReader`, no preference keys. No color, fill or haptics of its own (a layout positions, it never paints); style the chips inside it. Reflow animates on-system when the caller wraps content changes in `withAnimation`, which SwiftUI does not turn off under Reduce Motion, so pass `nil` there (the docs snippet does). The packing is pure and unit-tested (`DSFlowLayout.pack`), plus a test that runs it through SwiftUI's own sizing. Full page: [docs/components/DSFlowLayout.md](components/DSFlowLayout.md).

---

## Layout  ✅

`DSScreen(backgroundColor: Color? = nil, backdrop: Bool = false) { }` · `DSHorizontalScroll(spacing:)` · `DSVStack(spacing: .md, alignment: .leading)` · `DSHStack(spacing: .sm, alignment: .center)` · `DSGrid(minItemWidth: 160, spacing: .md)`. For wrapping rows of chips and tags, see [DSFlowLayout](#dsflowlayout).

---

## ComponentCatalog (internal)

`Preview/ComponentCatalog.swift`. Not part of the public API: an Xcode `#Preview` that lists every component with variants, theme dots and a backdrop toggle. Use it for the manual walkthrough. `Preview/DSPreviewSupport.swift` holds the shared `DSPreviewThemeDots`.
