# VelvetGallery — runnable component demo app

**Date:** 2026-09-08
**Status:** approved design, pending spec review → implementation plan
**Branch:** `feat/gallery-app` → PR to `main`

## Goal

A real iOS app that runs in the Simulator and shows every Velvet UI component,
**one component per screen**, so each can be filmed in isolation for a
presentation video. Not a `#Preview`. Not a single scrolling catalog.

## Non-goals

- No replacement for the internal `ComponentCatalog.swift` `#Preview` — it stays
  as the quick dev walkthrough.
- No changes to `Package.swift`, `Sources/`, or any component.
- No gradient-theme switching (Sunset/Aurora/Lagoon). See "Neutral look".
- No macOS target. The gallery is iOS-only; the package still builds both.
- No App Store metadata, no CI wiring, no localization.

## Context (what exists today)

- Swift Package `DesignSystem` (module name `DesignSystem`), `iOS 17 / macOS 14`.
- ~20 components in `Sources/DesignSystem/{Components,Animation,Layout}/`.
- `Sources/DesignSystem/Preview/ComponentCatalog.swift` — an **internal**
  `#Preview` that already renders every component with its variants in one
  `ScrollView`, grouped by `section(...)`. This is the content we decompose.
- Theme API: `.dsTheme(DSTheme(gradient:))`, `.dsBackdrop()`, `DSScreen`,
  `@DSThemed`. `DSTheme.gradient` is a plain `var` (not `@Published`), so runtime
  re-theming is done by injecting a **fresh `DSTheme` instance**.
- Helpers we reuse: `Color.dsDynamic(light:dark:)` (public, adaptive color with no
  environment), `Color(hex:)`, `.ds(_ style:color:)` typography modifier,
  `.dsScreenPadding()`, `DSHapticEngine.shared.fire(_:)`, `DSColors.*` statics
  (allowed outside the package).
- Tooling present: XcodeGen `/opt/homebrew/bin/xcodegen`, Xcode 26, Swift 6.2.

## Approach — A: decompose `ComponentCatalog` into an app

Lift each `section(...)` of `ComponentCatalog` into its own screen `View` file.
Wrap them in a `NavigationStack` + grouped `List`. Add an app-level appearance
control. Each screen is self-contained, built on a shared `GalleryScreen`
wrapper. Content already compiles against the real API, so risk is low; each
screen also gets a one-line caption (a light touch of the "from scratch"
alternative).

## Neutral look (hard constraint)

The user's requirement, verbatim intent: **the background of every screen that
contains components must be a neutral colour, and the components themselves must
render in neutral colours.** Neutral is the *only* mode — no switch to the
gradient themes.

Precise definition:

1. **Screen background** — `DSColors.backgroundPrimary` (solid neutral,
   near-white in light / near-black in dark). **No `.dsBackdrop()` anywhere.**
   The `List` and nav bar use the same neutral.

2. **Component colours** — a gallery-local neutral theme injected once at the
   app root:

   ```swift
   // Examples/VelvetGallery/VelvetGallery/Theme/NeutralTheme.swift
   extension DSGradientTheme {
       static let neutral = DSGradientTheme(
           id: "neutral",
           name: "Neutral",
           stops: [Color(hex: "9AA0A6"), Color(hex: "6B7178")], // never drawn (no backdrop)
           accent:   .dsDynamic(light: Color(hex: "1F2225"), dark: Color(hex: "EDEEF0")), // graphite fill
           onAccent: .dsDynamic(light: Color(hex: "FFFFFF"), dark: Color(hex: "16181A")), // text on the fill
           ink:      Color(hex: "2A2D30"),   // ink(for: .light) — text/icons/focus on surfaces
           inkDark:  Color(hex: "E6E7E9")    // ink(for: .dark)
       )
   }
   ```

   Injected: `ContentView().dsTheme(DSTheme(gradient: .neutral))`.
   With this, everything driven by `theme.accent` / `theme.onAccent` /
   `theme.ink` (DSButton `.primary`, DSToggle on-state, DSSegmentedControl
   indicator, DSPageControl active dot, DSBadge `.filled`/`.soft`, DSCircular/
   Linear progress, focus glows, DSImageCard badge…) renders graphite/neutral in
   both appearances.

3. **Semantic status colours stay** — `palette.error` / `.success` / `.warning`
   / `.info` keep their meaning (error text field, `DSToast(.error)`,
   `DSCodeField(state: .error)`). A red error with no red is confusing.

4. **Decorative (non-status) default colours are overridden to neutral** — where
   a component defaults to a colour that is decoration, not status, the screen
   passes a neutral explicitly for the primary example and shows the colourful
   variant only as a clearly-secondary example:
   - `DSRating` — default `tint` is `palette.warning` (amber). Primary example
     passes `tint: DSColors.textPrimary`; a secondary row shows the amber
     `heart.fill` variant.
   - `DSGradientProgress` — default `colors` is `theme.gradient.stops`. Pass an
     explicit neutral `[Color]` (two greys).
   - `DSToggle` / `DSPageControl` / `DSSegmentedControl` custom-colour examples
     in the catalog that use `DSColors.secondary/.success` are re-pointed to
     neutral greys, except where the point of the example is "you can tint it",
     which is kept as one labelled secondary row.

## Project setup

```
Examples/VelvetGallery/
├── project.yml                     # XcodeGen source of truth
├── VelvetGallery.xcodeproj/        # generated, COMMITTED (zero-friction open)
├── README.md                       # "open the xcodeproj, or `xcodegen generate`"
└── VelvetGallery/
    ├── VelvetGalleryApp.swift
    ├── GallerySettings.swift
    ├── ComponentListView.swift
    ├── Theme/
    │   └── NeutralTheme.swift
    ├── Support/
    │   ├── GalleryScreen.swift     # shared screen chrome
    │   └── ComponentEntry.swift    # list model: id, title, caption, category, destination
    └── Screens/
        ├── ThemeScreen.swift
        ├── TypographyScreen.swift
        ├── ButtonsScreen.swift
        └── … (one file per entry below)
```

- `project.yml`: single app target `VelvetGallery`, `platform: iOS`,
  `deploymentTarget: "17.0"`, devices iPhone + iPad, bundle id
  `com.matiasperaltacharro.VelvetGallery`, `SwiftUI` lifecycle.
- Package dependency: local, `path: ../..` (repo root), target links product
  `DesignSystem`.
- `.gitignore` (repo root): add
  `Examples/VelvetGallery/VelvetGallery.xcodeproj/xcuserdata/` and
  `Examples/VelvetGallery/VelvetGallery.xcodeproj/project.xcworkspace/xcuserdata/`.
  The `project.pbxproj` itself is committed.
- Regenerate rule: run `xcodegen generate` from `Examples/VelvetGallery/` only
  when the file list or target settings change; commit the result.

## App architecture

### `GallerySettings` (ObservableObject)
- `@AppStorage("gallery.appearance")` → `Appearance` enum `{ system, light, dark }`.
  Persists between launches (handy when filming across sessions).
- That is the only setting. No theme, no backdrop.

### `VelvetGalleryApp`
```swift
@main struct VelvetGalleryApp: App {
    @StateObject private var settings = GallerySettings()
    private let theme = DSTheme(gradient: .neutral)
    var body: some Scene {
        WindowGroup {
            NavigationStack { ComponentListView() }
                .environmentObject(settings)
                .dsTheme(theme)
                .preferredColorScheme(settings.appearance.colorScheme) // nil = system
                .tint(DSColors.textPrimary)                            // neutral nav tint
        }
    }
}
```

### `ComponentListView`
- `List` with `Section`s by category, in this order:
  **Foundations** — Theme, Typography, Layout  *(Surfaces is folded into Theme)*
  **Actions** — Buttons
  **Containers** — Cards
  **Inputs** — Text Field, Code Field, Toggle, Segmented Control, Rating, Page Control
  **Data Display** — Badges & Avatars, Lists
  **Feedback** — Toast, Empty State, Progress & Loading
- Each row: title + caption (`.ds(.footnote, color: DSColors.textSecondary)`),
  `NavigationLink` to the screen.
- `.listStyle(.insetGrouped)`, `.scrollContentBackground(.hidden)`,
  background `DSColors.backgroundPrimary`.
- Toolbar: one `Menu` (`"circle.lefthalf.filled"` icon) → `Picker` bound to
  `settings.appearance` (System / Light / Dark). Present on the list; child
  screens inherit the app-level `preferredColorScheme`, so no per-screen toolbar
  is needed, but `GalleryScreen` re-exposes the same menu for filming
  convenience.

### `GalleryScreen` (shared wrapper)
```swift
GalleryScreen(title: String, caption: String) { content }
```
- `ScrollView` → `VStack(alignment: .leading, spacing: DSSpacing.xxl)`.
- Header: `Text(title).ds(.title1)` + `Text(caption).ds(.callout, color: .textSecondary)`.
- `.dsScreenPadding()` + vertical padding.
- Background `DSColors.backgroundPrimary.ignoresSafeArea()`. **No backdrop.**
- `.navigationTitle(title)`, `.navigationBarTitleDisplayMode(.inline)`.
- Appearance `Menu` in `.toolbar`.
- A small `Group("label") { ... }` sub-helper for titled example blocks within a
  screen.

## Screen inventory (~16)

Each screen shows the component's full surface area with **live `@State`** so it
works on camera. Source of truth for variants is `docs/components.md` +
`ComponentCatalog.swift`.

| # | Screen | Caption | Content |
|---|--------|---------|---------|
| 1 | Theme | "Neutral palette & glass surfaces" | Neutral swatches (bg primary/secondary/elevated, textPrimary/secondary/tertiary, border, divider); the four `dsSurface` levels glassThin→solid as labelled rows; the 3 built-in gradients (`DSGradientTheme.all`) as **static reference swatches** with a note "not used in this gallery". |
| 2 | Typography | "Every text style" | One line per `DSTextStyle`: hero, largeTitle, title1–3, body, callout, footnote, caption1, overline, numeric, displayLarge/Medium. |
| 3 | Buttons | "Variants, sizes, states" | `DSButton` × {primary, secondary, outline, ghost, destructive}; sizes small/medium/large; `isFullWidth`; `isLoading`; `icon` leading/trailing; `DSIconButton` row. |
| 4 | Cards | "Glass containers" | `DSCard` flat / elevated / outlined; nested card; `DSInteractiveCard` (tap → console + haptic); `DSImageCard` (remote `imageURL`, shimmer placeholder, neutral badge). |
| 5 | Text Field | "Inputs & validation" | `DSTextField` states normal / focused / error / success / disabled; `isSecure`; `DSSearchBar` bound to state with clear button. |
| 6 | Code Field | "OTP entry" | `DSCodeField` length 6 (live, `onComplete` shows a `DSToast(.success)` overlay); length 4 `.error`; length 4 `.success`. |
| 7 | Toggle | "Switches" | `DSToggle` sizes small/medium; with label / without; `disabled`; one labelled "custom tint" row using a neutral grey `onColor`. |
| 8 | Segmented Control | "Pick one" | pill style (3 options, live); underline style (3 options, live); a variant with `icon` per segment. |
| 9 | Rating | "Star input" | interactive `DSRating` (`tint: DSColors.textPrimary`); half-step; read-only fractional `DSRating(value:)`; one secondary row: amber `heart.fill` to show `tint`/`symbol`. |
| 10 | Page Control | "Paged content" | `DSPageControl` driven by a swipeable `TabView` of 4 neutral cards; second instance with `allowsTap` and neutral `activeColor`. |
| 11 | Badges & Avatars | "Status marks & identity" | `DSBadge` filled / soft / outline (neutral); `DSBadge` with a semantic colour (success) as one labelled row; `DSCountBadge` 5 / 120 / 0 (hidden); `DSAvatar` initials at sizes 32/40/48 and one with `imageURL`. |
| 12 | Lists | "Rows & sections" | `DSCard(padding: 0)` wrapping `DSListCell` (leading icon, subtitle, `action` → chevron + haptic), `DSListCell` with `trailing: DSCountBadge`, plain cell; `DSDivider(inset:)` between; a `DSSectionHeader` with an action. |
| 13 | Toast | "Transient feedback" | Four buttons (success / error / warning / info). Each **presents** the toast via an overlay with the DS spring animation and fires `DSToastType.haptic`; auto-dismiss after ~2.5s. This is the filmable moment the catalog can't show. |
| 14 | Empty State | "Nothing here yet" | `DSEmptyState` with icon, title, message, working CTA that toggles to a "filled" state and back. |
| 15 | Progress & Loading | "Determinate & skeletons" | `DSCircularProgress`, `DSLinearProgress`, `DSGradientProgress` (neutral `colors:`), `DSStepProgress`; `DSAnimatedNumber` with a "Randomize" button; `.dsShimmer()` skeleton rows; `.dsPulse()` badge. A slider drives all `progress` values. |
| 16 | Layout | "Stacks & grids" | Live demos of `DSVStack`, `DSHStack`, `DSGrid(minItemWidth:)`, `DSHorizontalScroll`, and `DSScreen` (shown as a labelled inset), each filled with neutral placeholder tiles. |

"Surfaces" is folded into screen 1 rather than given its own row (it is token
demonstration, not a component).

## Interactivity requirements

- Every stateful component binds to real `@State` on its screen — draggable
  rating, typeable fields, flippable toggles, sliding segmented control,
  swipeable page control, tappable list cells.
- Haptics fire on device only; in the Simulator they're silent — acceptable.
- `DSInteractiveCard` / `DSListCell` actions log via `print` (visible with the
  console MCP if needed) — no alerts/dialogs (they block the automation bridge).
- Remote images (`DSImageCard`, `DSAvatar imageURL`) use small stable
  `picsum.photos` URLs; screens must look correct while the image is still
  loading (shimmer) and if it never loads (offline Simulator).

## Verification

1. `xcodegen generate` in `Examples/VelvetGallery/` — succeeds, project opens.
2. `xcodebuild build -project Examples/VelvetGallery/VelvetGallery.xcodeproj \
   -scheme VelvetGallery -destination 'platform=iOS Simulator,name=iPhone 16'`
   — builds clean (no warnings from gallery code).
3. Boot Simulator, install, launch. Screenshot: the component list, plus
   Buttons, Toast (mid-presentation), and Rating screens.
4. Package regression: `swift build` and `swift test` at the repo root still
   pass (they are untouched — `Examples/` is outside `Sources/`).
5. `xcodebuild build -scheme DesignSystem -destination 'generic/platform=iOS
   Simulator'` still passes.

## Repo housekeeping

- `.gitignore` — add the two `xcuserdata` paths above.
- `CHANGELOG.md` — under `[Unreleased]`:
  `add: VelvetGallery — runnable per-component demo app under Examples/ (neutral theme)`.
- `docs/engineering-notes.md` — short subsection: why the gallery exists, that it
  forces a local neutral `DSGradientTheme`, how to regenerate the project, and
  that it is not part of `swift build`.
- `Examples/VelvetGallery/README.md` — one screen of instructions.
- No `docs/components.md` change (no component changed).
- Git: branch `feat/gallery-app`, one commit per logical chunk (scaffold →
  shell → screens in batches → docs), PR to `main`, never push to `main`.

## Implementation notes for the plan

- Screens are independent → parallelisable across subagents; each subagent gets
  this spec section for its screen + the relevant `docs/components.md` entry +
  the matching `ComponentCatalog` block, and must not touch `Sources/`.
- Build the scaffold + `GalleryScreen` + `NeutralTheme` + `ComponentListView`
  with 2–3 screens first, get it building and running, *then* fan out the rest so
  every subagent works against a known-good shell.
- Integrator (me) wires `ComponentEntry` list, resolves duplicate helper names,
  runs the full verification, writes docs, opens the PR.

## Risks & mitigations

| Risk | Mitigation |
|------|-----------|
| Runtime theme not `@Published` | We never mutate it — one fixed `DSTheme(gradient: .neutral)` instance for the app's life. |
| `theme.accent` is a single (non-scheme) `Color` → graphite unreadable in one appearance | `accent`/`onAccent` built with `Color.dsDynamic(light:dark:)`. |
| Committed `.xcodeproj` drifts from `project.yml` | `project.yml` is the source of truth; regenerate + commit on any structure change; README says so. |
| XcodeGen local-package path wrong when repo moves | Path is repo-relative (`../..`), matches the "one checkout at ~/Documents/velvet-ui" rule. |
| Glass `.elevated` cards still translucent over neutral | Acceptable — reads as a subtle grey card, still neutral; `.flat` used where a hard neutral is wanted. |
| Gallery code accidentally treated as package source | It lives in `Examples/`, excluded from `Sources/`; `Package.swift` untouched; verification step 4 guards it. |

## Out of scope / future

- A "download as video" or automated screen-recording pass.
- Per-screen code snippets / "when to use" copy beyond the one-line caption.
- iPad-optimised `NavigationSplitView` layout.
- Re-enabling gradient themes behind a debug flag.
