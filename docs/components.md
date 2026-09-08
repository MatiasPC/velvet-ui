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

## DSStepper  ✅ 🧪

`Components/DSStepper.swift`. Compact −/＋ integer counter for quantities, guest counts, portions.

```swift
DSStepper(_ label: String? = nil, value: Binding<Int>,
          in range: ClosedRange<Int> = 0...99,
          step: Int = 1, haptics: Bool = true)
```

The value rolls with `.contentTransition(.numericText(value:))` inside a `springSnappy` transaction (skipped under Reduce Motion). Each step fires `.selection`; pushing against a bound fires `.rigid` and dims that button (0.35) without changing the value. `−`/`＋` glyphs use `theme.ink` on a `.glassThin` pill (`DSRadius.chip`); press uses `DSPress.iconScale`. `.disabled` dims the control to 0.5. Accessibility: single adjustable element (increment/decrement by `step`), value reads the number.

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

Modifiers: `.dsShimmer()` (skeletons — width-independent, respects Reduce Motion), `.dsPulse()` (attention).

---

## Layout  ✅

`DSScreen(backgroundColor: Color? = nil, backdrop: Bool = false) { }` · `DSHorizontalScroll(spacing:)` · `DSVStack(spacing: .md, alignment: .leading)` · `DSHStack(spacing: .sm, alignment: .center)` · `DSGrid(minItemWidth: 160, spacing: .md)`.

---

## ComponentCatalog (internal)

`Preview/ComponentCatalog.swift`. Not part of the public API: an Xcode `#Preview` that lists every component with variants, theme dots and a backdrop toggle. Use it for the manual walkthrough. `Preview/DSPreviewSupport.swift` holds the shared `DSPreviewThemeDots`.
