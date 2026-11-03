# Velvet UI: guide for AI coding agents

This file is for agents (Claude Code, Cursor, Codex, Xcode) writing SwiftUI that **uses** Velvet UI, and for the people reviewing their output. It covers the rules, the token cheat sheet, copyable patterns and the mistakes to avoid.

- Everything an agent needs in one file: [`llms-full.txt`](llms-full.txt). Index: [`llms.txt`](llms.txt).
- Every component as data (source files, dependencies, docs): [`registry.json`](registry.json).
- Contributing to Velvet UI itself? Read [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/engineering-notes.md](docs/engineering-notes.md) too.

**Use it in your app's agent setup.** Add one line to your project's `AGENTS.md`, `CLAUDE.md` or `.cursor/rules`:

```text
UI uses Velvet UI. Follow https://raw.githubusercontent.com/MatiasPC/velvet-ui/main/AGENTS.md
```

## Setup (once per app)

Pick one of the two install paths and don't mix them in one target: the package and copied sources define the same types.

**Swift Package (recommended).** `https://github.com/MatiasPC/velvet-ui.git`, product `VelvetUI`, from `0.2.0`. Then `import VelvetUI` in every file with UI.

**Copy the source.** Velvet ships a small CLI that copies one component, plus the shared core it needs, into your app:

```bash
curl -fsSLO https://raw.githubusercontent.com/MatiasPC/velvet-ui/main/scripts/velvet.swift
swift velvet.swift add DSTabBar --dest MyApp/VelvetUI   # also: list, info <name>
```

Copied files compile in Swift 5 and Swift 6 language mode and need no `import`. Previews aren't copied. Running `add` again updates untouched files and never overwrites your edits without `--force`.

**Theme at the root.** Both paths need exactly one theme injected at the top of the view tree:

```swift
import VelvetUI

@main struct MyApp: App {
    @State private var theme = DSTheme(gradient: .sunset)   // .sunset, .aurora, .lagoon
    var body: some Scene { WindowGroup { RootView().dsTheme(theme) } }
}
```

Velvet targets iOS 18+ and macOS 15+.

## The rules

1. **Inject one `DSTheme` with `.dsTheme(_:)` at the root.** Without it every view silently uses a shared default, and changing "your" theme does nothing.
2. **Put screens on the backdrop.** Write `DSScreen(backdrop: true) { … }` (it scrolls) or add `.dsBackdrop()` to a container. Glass needs a gradient behind it to read as glass.
3. **Reach for a component before building one.** See [the component chooser](#component-chooser). Velvet components already handle press feel, haptics, VoiceOver and Reduce Motion.
4. **Tokens only.** Use `DSSpacing` for padding and gaps, `DSRadius` for corners, `.ds(_:)` for text, `DSShadow` for elevation and `DSAnimation` for motion. Never write literal numbers, fonts or colors.
5. **Colors come from the theme.** In your own views, declare `@DSThemed private var theme` and paint with its roles (table below). Don't use `DSColors.x` inside a view body; those statics don't follow the injected theme.
6. **No borders.** Separate surfaces with `.dsSurface(_:radius:)`, `DSCard`, `theme.subtleFill` or `.dsWashEdge(radius:)`. Never use `.border` or `.stroke`.
7. **Haptics are built in.** `DSButton`, `DSToggle`, `DSStepper`, `DSTabBar` and the other controls already fire their haptic. Don't add a second one. Call `dsHaptic(_:)` only for your own custom controls.
8. **Springs for touch, eased curves for ambience.** Use `DSAnimation.springSnappy` / `.springSmooth` for state changes caused by a tap or drag, and `withAnimation(DSAnimation.normal)` for theme changes. Loop effects through `.dsBreathe`, `.dsShimmer` or `DSMotion.loop(_:unless:)`, which respect Reduce Motion.
9. **Accessibility is part of the job.** Give icon-only buttons an `accessibilityLabel:`, give bare controls (`DSStepper`, `DSRating`) a `.accessibilityLabel("Guests")`, and keep text on `.ds(_:)` so it scales with Dynamic Type.
10. **Async work goes into the component.** `DSSlideToConfirm`'s `onConfirm` is `async throws`. Await the payment inside it and throw to refuse; the control spins, then succeeds or re-opens by itself.

## Component chooser

| You need | Use | Notes |
|---|---|---|
| Primary / secondary action | `DSButton(_:variant:size:icon:isLoading:action:)` | `.primary` is the accent fill; one per screen. |
| Icon-only action | `DSIconButton(icon:accessibilityLabel:action:)` | Always pass `accessibilityLabel`. |
| Confirm a payment or a destructive action | `DSSlideToConfirm(_:confirmedLabel:finish:onConfirm:)` | `onConfirm` is `async throws`. |
| On/off setting | `DSToggle(_:isOn:)` | |
| Small number (quantity, guests) | `DSStepper(value:in:step:)` | Add `.accessibilityLabel(…)`. |
| Pick one of 2–4 options | `DSSegmentedControl(selection:options:)` | `style: .underline` for a tab-like look. |
| Star rating | `DSRating(rating:)` / `DSRating(value:)` (read-only) | |
| Text input | `DSTextField(label:placeholder:icon:text:state:)` | `DSSearchBar(text:)` for search. |
| One-time code | `DSCodeField(code:state:onComplete:)` | SMS autofill on iOS. |
| App sections at the bottom | `DSTabBar(selection:items:)` | Place with `.safeAreaInset(edge: .bottom)`. |
| Horizontal paging content | `DSCarousel(_:currentPage:content:)` + `DSPageControl` | |
| Page dots | `DSPageControl(currentPage:numberOfPages:)` | |
| Modal panel | `.dsSheet(isPresented:detents:content:)` | Native sheet with Velvet chrome. |
| A surface to group content | `DSCard { … }` | `DSInteractiveCard(action:)` when tappable. |
| Rows in a group | `DSListCell(title:subtitle:leading:trailing:action:)` + `DSDivider` | Inside `DSCard(padding: 0)`. |
| Status label / unread count | `DSBadge(_:variant:)`, `DSCountBadge(count:)` | |
| Person | `DSAvatar(name:imageURL:size:)` | Falls back to initials. |
| Transient message | `DSToast(_:type:)` | Present in an overlay; it announces itself. |
| Nothing to show | `DSEmptyState(icon:title:message:actionTitle:action:)` | |
| Loading layout | `.dsSkeleton(isLoading)` or `DSSkeleton` blocks | |
| Progress | `DSCircularProgress`, `DSLinearProgress`, `DSGradientProgress`, `DSStepProgress` | |
| Animated number | `DSNumberTicker(_:format:)` (rolling digits), `DSAnimatedNumber` (count-up) | |
| Trend / small chart | `DSSparkline(_:)`, `DSBarChart(_:labels:selection:)` | Use Swift Charts for axes, legends, many series. |
| Success moment | `DSSuccessCheck(isComplete:)`, `.dsConfetti(trigger:)` | Confetti is decorative; pair it with a real result. |
| AI / background work | `DSThinkingIndicator(phrases:)` | |
| Typed headline | `DSTypewriterText(_:style:)` | |
| Ambient motion on any view | `.dsBreathe()`, `.dsJiggle(trigger:)`, `.dsPopIn(delay:)`, `.dsEdgeSweep()`, `.dsHueDrift()` | |
| Menu, context menu | SwiftUI `Menu`, `.contextMenu` | Native is right; it inherits the tint. |
| Pull to refresh | `.refreshable { await … }` | Native. |
| Tips, coach marks | TipKit | Native. |
| Alerts, confirmations | `.alert`, `.confirmationDialog` | Native. |
| Date and time input | `DatePicker` | Native, tinted with `.tint(theme.ink)`. |

## Tokens cheat sheet

**Theme roles** (from `@DSThemed private var theme`):

| Role | Use for |
|---|---|
| `theme.accent` | Fills: primary CTA, toggle on, selected tab, active indicator |
| `theme.onAccent` | Text and icons **on** `theme.accent` |
| `theme.ink` | Text, icons, links and focus **on glass or surfaces** |
| `theme.palette.textPrimary` / `.textSecondary` / `.textTertiary` | Body copy hierarchy |
| `theme.palette.success` / `.warning` / `.error` / `.info` | Status; `theme.palette.textOnPrimary` for text on them |
| `theme.subtleFill` | Flat fill for a surface nested in another |
| `theme.gradient.stops`, `.linearGradient`, `.horizontalGradient` | Decoration |

**Spacing** (`DSSpacing`, 4 pt grid): `xxxs` 2 · `xxs` 4 · `xs` 8 · `sm` 12 · `md` 16 · `lg` 20 · `xl` 24 · `xxl` 32 · `xxxl` 40 · `huge` 48 · `massive` 64. Screen margin: `.dsScreenPadding()` (20).

**Radius by role** (`DSRadius`): `.card` 20 (cards, sheets) · `.surface` 16 (nested surfaces) · `.control` 12 (buttons, inputs) · `.chip` pill (badges, small buttons).

**Text** (`Text("…").ds(.style)` or `.dsTextStyle(.style)`): `hero`, `largeTitle`, `title1`, `title2`, `title3`, `body`, `callout`, `footnote`, `caption1`, `caption2`, `button`, `buttonSmall`, `overline`, `displayLarge`, `displayMedium`, `numeric`, `badge`. Pass a color with `.ds(.callout, color: theme.palette.textSecondary)`.

**Surfaces** (`.dsSurface(_:radius:)`): `.glassThin` (chips, toolbars) · `.glass` (cards, default) · `.glassThick` (sheets, popovers) · `.solid`. They fall back to solid under Reduce Transparency.

**Shadows** (`.dsShadow(_:)`): `.sm`, `.md`, `.lg`, `.xl`, `.glow(theme.accent)` (primary CTA only).

**Motion** (`DSAnimation`): `micro` 0.20 s, `fast` 0.24 s, `normal` 0.32 s, `slow` 0.48 s curves; springs `springSnappy`, `springSmooth`, `springGentle`, `springBouncy`; `ambient` for loops. Press feel: `DSPress.scale` (0.96) with `DSPress.animation`.

**Haptics** (`dsHaptic(_:)`): `.light`, `.medium`, `.heavy`, `.soft`, `.rigid`, `.selection`, `.success`, `.warning`, `.error`. No-op on macOS.

All values: [docs/tokens.md](docs/tokens.md).

## Patterns

Every snippet below compiles against the current API (they're mirrored in the test suite).

**A screen**

```swift
struct ProfileScreen: View {
    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                Text("Profile").ds(.largeTitle)
                DSCard {
                    HStack(spacing: DSSpacing.md) {
                        DSAvatar(name: "Ada Lovelace", size: 56)
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text("Ada Lovelace").ds(.title3)
                            Text("Member since 2024").ds(.footnote)
                        }
                        Spacer()
                    }
                }
            }
            .dsScreenPadding()
        }
    }
}
```

**A settings group**

```swift
struct NotificationSettings: View {
    @State private var push = true
    @State private var digest = false

    var body: some View {
        DSCard(padding: 0) {
            VStack(spacing: 0) {
                DSListCell(title: "Push notifications") {
                    Image(systemName: "bell")
                } trailing: {
                    DSToggle(isOn: $push)
                }
                DSDivider(inset: DSSpacing.md)
                DSListCell(title: "Weekly digest", subtitle: "Every Monday") {
                    Image(systemName: "envelope")
                } trailing: {
                    DSToggle(isOn: $digest)
                }
            }
        }
    }
}
```

**A primary action pinned to the bottom**

```swift
struct CheckoutScreen: View {
    @State private var isPaying = false

    var body: some View {
        DSScreen(backdrop: true) {
            Text("Your order").ds(.largeTitle).dsScreenPadding()
        }
        .safeAreaInset(edge: .bottom) {
            DSButton("Pay $24.00", size: .large, isFullWidth: true, isLoading: isPaying) {
                isPaying = true
            }
            .dsScreenPadding()
        }
    }
}
```

**An async confirmation**

```swift
struct PayRow: View {
    var body: some View {
        DSSlideToConfirm("Slide to pay $24.00", confirmedLabel: "Paid", finish: .morphAndVanish) {
            try await PaymentService.charge(cents: 2400)   // throw to refuse; the control re-opens
        }
    }
}

enum PaymentService {
    static func charge(cents: Int) async throws { try await Task.sleep(for: .seconds(1)) }
}
```

**Loading, then content**

```swift
struct ArticleCard: View {
    @State private var isLoading = true

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Weekend in Lisbon").ds(.title3)
                Text("Three nights by the river, two guests.").ds(.callout)
            }
            .dsSkeleton(isLoading)
        }
        .task {
            try? await Task.sleep(for: .seconds(1))
            isLoading = false
        }
    }
}
```

Keep `.task` and `.onAppear` outside the view you pass to `.dsSkeleton`.

**A tab bar shell**

```swift
enum AppTab: Hashable { case home, search, inbox, profile }

struct AppShell: View {
    @State private var tab = AppTab.home

    var body: some View {
        Group {
            switch tab {
            case .home:    Text("Home").ds(.largeTitle)
            case .search:  Text("Search").ds(.largeTitle)
            case .inbox:   Text("Inbox").ds(.largeTitle)
            case .profile: Text("Profile").ds(.largeTitle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsBackdrop()
        .safeAreaInset(edge: .bottom) {
            DSTabBar(selection: $tab, items: [
                DSTabItem("Home", value: .home, icon: "house", selectedIcon: "house.fill"),
                DSTabItem("Search", value: .search, icon: "magnifyingglass"),
                DSTabItem("Inbox", value: .inbox, icon: "tray", selectedIcon: "tray.fill", badge: 3),
                DSTabItem("Profile", value: .profile, icon: "person", selectedIcon: "person.fill"),
            ])
            .dsScreenPadding()
        }
    }
}
```

**A toast**

```swift
struct SaveButton: View {
    @State private var showsToast = false

    var body: some View {
        DSButton("Save") {
            withAnimation(DSAnimation.springSmooth) { showsToast = true }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if showsToast {
                DSToast("Saved to your library", type: .success)
                    .transition(.dsSlideUp)
                    .task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation(DSAnimation.springSmooth) { showsToast = false }
                    }
            }
        }
    }
}
```

**Your own view, on-system**

```swift
struct PriceTag: View {
    let amount: String
    @DSThemed private var theme

    var body: some View {
        Text(amount)
            .ds(.numeric, color: theme.onAccent)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xxs)
            .background(theme.accent, in: Capsule())
    }
}
```

**Switching the theme at runtime**

```swift
struct ThemePicker: View {
    let theme: DSTheme

    var body: some View {
        DSSegmentedControl(
            selection: Binding(
                get: { theme.gradient.id },
                set: { id in
                    withAnimation(DSAnimation.normal) {
                        theme.gradient = DSGradientTheme.all.first { $0.id == id } ?? .sunset
                    }
                }
            ),
            segments: DSGradientTheme.all.map { DSSegment($0.name, value: $0.id) }
        )
    }
}
```

## Anti-patterns

| Don't | Do | Why |
|---|---|---|
| `.foregroundStyle(.blue)`, `Color(hex: "FF7E5F")` in a view | `theme.ink`, `theme.accent`, `theme.palette.textSecondary` | Literals ignore the theme and dark mode. |
| `DSColors.primary` inside `body` | `@DSThemed private var theme` then `theme.accent` | Statics don't follow the injected theme. |
| `.font(.system(size: 17))`, `.font(.headline)` | `.ds(.body)`, `.ds(.title3)` | DS styles carry tracking, line spacing and Dynamic Type. |
| `.padding(15)`, `.cornerRadius(10)` | `.padding(DSSpacing.md)`, `.dsSurface(.glass, radius: DSRadius.control)` | Off-grid values drift from the system. |
| `.border(.gray)`, `.overlay(RoundedRectangle(…).stroke(…))` | `.dsSurface(_:radius:)`, `.dsWashEdge(radius:)`, `theme.subtleFill` | Velvet has no borders. |
| `DSCard { DSCard { … } }` | Inner `DSCard(style: .flat)` or `.background(theme.subtleFill)` | Glass on glass turns muddy. |
| A haptic in the action of a `DSButton` | Nothing. The button already fires one. | Double haptics feel broken. |
| `withAnimation(.easeInOut)` after a tap | `withAnimation(DSAnimation.springSnappy)` | Touch gets springs. |
| `.repeatForever()` on your own loop | `.dsBreathe()` or `DSMotion.loop(_:unless: reduceMotion)` | Loops must rest under Reduce Motion. |
| `ScrollView { DSScreen { … } }` | `DSScreen(backdrop: true) { … }` alone | `DSScreen` already scrolls. |
| Showing `DSToast` without removing it | Remove it after a delay (see the pattern) | It stays on screen otherwise. |
| `Image(systemName: "trash")` as a button with no label | `DSIconButton(icon: "trash", accessibilityLabel: "Delete") { … }` | VoiceOver reads "trash" or nothing. |
| A `DSStepper` with no label | `.accessibilityLabel("Guests")` | It reads "Stepper" otherwise. |
| `DSListCell(title: "Wi-Fi") { Image(systemName: "wifi") }` | `DSListCell(title: "Wi-Fi", leading: { Image(systemName: "wifi") })` | A single trailing closure binds to `action`, so the icon never shows. |
| Adding the package **and** copying sources | Pick one | Duplicate symbols. |
| Glass on a plain white screen, then "it looks flat" | `DSScreen(backdrop: true)` or `.dsBackdrop()` | Glass needs something behind it. |

## Naming

- Types start with `DS` (`DSButton`, `DSTabItem`); modifiers start with `ds` (`.dsSurface`, `.dsConfetti`).
- Bindings: `selection:` for a selected value, `value:` / `isOn:` / `rating:` / `code:` / `text:` for edited values, `currentPage:` for page indices.
- Optional tint parameters are `Color? = nil` (`accent:`, `color:`, `tint:`); `nil` means "follow the theme". Passing `nil` explicitly is fine.
- `haptic:` is the parameter for a configurable haptic, `accessibilityLabel:` for VoiceOver text, and the trailing closure is `action:`, `content:` or `onConfirm:`.

## Before you hand back

- Build for every platform the app targets. `swift build` alone only checks macOS.
- Look at the screen in light and dark mode, with the theme injected, on a backdrop.
- Turn on Reduce Motion and check that the UI still makes sense at rest.
- Search your diff for `Color(`, `.font(.system`, `.stroke(`, `.border(`, `cornerRadius(` and literal numbers in `padding`. Each one is usually a missed token.

## Working on Velvet UI itself

Library code follows the rules in [CONTRIBUTING.md](CONTRIBUTING.md): tokens only, colors from `@DSThemed`, `Color? = nil` for overridable colors, no borders, `DSPress` for press states, both platforms building, and a definition of done that includes docs, a Gallery stage and the registry entry. [docs/engineering-notes.md](docs/engineering-notes.md) records the decisions and gotchas.
