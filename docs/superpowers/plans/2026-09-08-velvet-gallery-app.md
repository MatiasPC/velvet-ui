# VelvetGallery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a runnable iOS Simulator app under `Examples/VelvetGallery/` that shows every Velvet UI component on its own screen, in a neutral (non-gradient) theme, for filming a presentation video.

**Architecture:** Decompose the existing internal `ComponentCatalog.swift` `#Preview` into ~16 standalone SwiftUI screens behind a `NavigationStack` + grouped `List`. A gallery-local `DSGradientTheme.neutral` is injected once at the app root; no `.dsBackdrop()` anywhere; screen backgrounds are `DSColors.backgroundPrimary`. The app is an XcodeGen-generated project that consumes the package as a local SPM dependency at `../..`.

**Tech Stack:** SwiftUI (iOS 17), the `DesignSystem` SwiftPM product, XcodeGen, `xcodebuild` + `xcrun simctl` for build/run/screenshot verification.

**Spec:** `docs/superpowers/specs/2026-09-08-velvet-gallery-app-design.md` — read it alongside this plan.

## Global Constraints

- **Module import:** every Swift file with UI code does `import SwiftUI` and `import DesignSystem`.
- **Do NOT touch** `Package.swift`, anything under `Sources/`, or any component. If a screen seems to need a component change, stop and report — it is out of scope.
- **No `.dsBackdrop()`** and no gradient themes anywhere in the app.
- **Screen background** is always `DSColors.backgroundPrimary` (via the `GalleryScreen` wrapper).
- **`DSColors.*` statics are allowed here.** The package rule "only inside `#Preview`" applies to components, not to this consumer app. Do not "fix" `DSColors` usages.
- **Neutral colours:** components driven by `theme.accent` / `theme.ink` render graphite automatically once `DSGradientTheme.neutral` is injected. Semantic status colours (`DSColors.error/.success/.warning/.info`) are kept where they carry meaning. Where a component's *default* colour is decorative, not status (`DSRating` amber tint, `DSGradientProgress` gradient stops), pass a neutral explicitly for the primary example and show the colourful variant only as one clearly-labelled secondary row.
- **Deployment target:** iOS 17.0. Devices: iPhone + iPad (`TARGETED_DEVICE_FAMILY = 1,2`).
- **Bundle id:** `com.matiasperaltacharro.VelvetGallery`. Product/scheme name: `VelvetGallery`.
- **Build command** (used verbatim in every task's verification) — `OS=18.0` is pinned because this machine (Xcode 26) has no iPhone 16 Pro runtime for iOS 26, only iOS 18.0 (controller ruling, Task 1):
  ```bash
  xcodebuild build \
    -project Examples/VelvetGallery/VelvetGallery.xcodeproj \
    -scheme VelvetGallery \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0' \
    -derivedDataPath /tmp/velvetgallery-dd 2>&1 | tail -25
  ```
  Expected: ends with `** BUILD SUCCEEDED **`, no warnings originating from files under `Examples/VelvetGallery/` (a lone `appintentsmetadataprocessor: Metadata extraction skipped` line is benign toolchain noise, not a code warning).
- **Run + screenshot** (used where a task says "screenshot") — targets whatever is `booted` (the iOS 18.0 iPhone 16 Pro), so it is unaffected by the OS pin above:
  ```bash
  xcrun simctl boot "iPhone 16 Pro" 2>/dev/null; sleep 3
  xcrun simctl install booted /tmp/velvetgallery-dd/Build/Products/Debug-iphonesimulator/VelvetGallery.app
  xcrun simctl launch booted com.matiasperaltacharro.VelvetGallery
  sleep 2
  xcrun simctl io booted screenshot /tmp/velvetgallery-<name>.png
  ```
- **Commit convention:** `add:` / `improve:` / `docs:` prefixes (repo style). End every commit message body with:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01W5k6DjWbXpDiP4C5bq44Nm
  ```
- **Branch:** `feat/gallery-app` (already created and checked out; the spec is already committed on it). Never push to `main`.
- **Package regression:** `swift build` and `swift test` at repo root must still pass at the end (they are untouched).

---

## File Structure

All paths relative to repo root `/Users/mati/Documents/velvet-ui/`.

| File | Responsibility | Created in |
|------|----------------|-----------|
| `Examples/VelvetGallery/project.yml` | XcodeGen spec: one app target, local package dep on `../..` | Task 1 |
| `Examples/VelvetGallery/VelvetGallery.xcodeproj/` | Generated locally, **not committed** — repo `.gitignore` already excludes `*.xcodeproj/`. Regenerate with `xcodegen generate`. | Task 1 (generate only) |
| `Examples/VelvetGallery/README.md` | How to open / regenerate | Task 20 |
| `Examples/VelvetGallery/VelvetGallery/VelvetGalleryApp.swift` | `@main`, injects neutral theme, appearance binding, `preferredColorScheme` | Task 1 → Task 2 |
| `.../VelvetGallery/Support/Appearance.swift` | `Appearance` enum + `galleryAppearance` environment key + `AppearanceMenu` view | Task 2 |
| `.../VelvetGallery/Theme/NeutralTheme.swift` | `DSGradientTheme.neutral` | Task 2 |
| `.../VelvetGallery/Support/GalleryScreen.swift` | Shared screen chrome + `LabeledExample` helper | Task 2 |
| `.../VelvetGallery/ComponentListView.swift` | Grouped `List` linking to every screen | Task 3 |
| `.../VelvetGallery/Screens/*.swift` | 16 screen views (stubbed in Task 3, filled in Tasks 4–19) | Task 3 → 4–19 |
| `CHANGELOG.md` | `[Unreleased]` line | Task 20 |
| `docs/engineering-notes.md` | "Why the gallery exists" subsection | Task 20 |

16 screen files: `ThemeScreen`, `TypographyScreen`, `LayoutScreen`, `ButtonsScreen`, `CardsScreen`, `TextFieldScreen`, `CodeFieldScreen`, `ToggleScreen`, `SegmentedControlScreen`, `RatingScreen`, `PageControlScreen`, `BadgesAvatarsScreen`, `ListsScreen`, `ToastScreen`, `EmptyStateScreen`, `ProgressLoadingScreen`.

**Parallelism:** Tasks 4–19 each own exactly one file in `Screens/` and touch nothing else → run them concurrently. Task 20 is last.

---

## Task 1: Scaffold — runnable empty app

**Files:**
- Create: `Examples/VelvetGallery/project.yml`
- Create: `Examples/VelvetGallery/VelvetGallery/VelvetGalleryApp.swift`
- Generate (local only, not committed): `Examples/VelvetGallery/VelvetGallery.xcodeproj/` (via `xcodegen`)

**Interfaces:**
- Produces: an app target `VelvetGallery`, scheme `VelvetGallery`, that launches to a screen reading "VelvetGallery". `VelvetGalleryApp` is `@main`.

**Note (controller ruling):** the repo `.gitignore` already excludes `*.xcodeproj/`; the generated project is intentionally NOT committed. `project.yml` is the committed source of truth. Do not `git add -f` the `.xcodeproj`.

- [ ] **Step 1: Write `Examples/VelvetGallery/project.yml`**

```yaml
name: VelvetGallery
options:
  bundleIdPrefix: com.matiasperaltacharro
  createIntermediateGroups: true
  deploymentTarget:
    iOS: "17.0"
packages:
  DesignSystem:
    path: ../..
targets:
  VelvetGallery:
    type: application
    platform: iOS
    sources:
      - path: VelvetGallery
    dependencies:
      - package: DesignSystem
        product: DesignSystem
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.matiasperaltacharro.VelvetGallery
        GENERATE_INFOPLIST_FILE: YES
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        TARGETED_DEVICE_FAMILY: "1,2"
        SWIFT_VERSION: "5.9"
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UISupportedInterfaceOrientations~ipad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
schemes:
  VelvetGallery:
    build:
      targets:
        VelvetGallery: all
    run:
      config: Debug
```

- [ ] **Step 2: Write `Examples/VelvetGallery/VelvetGallery/VelvetGalleryApp.swift`** (placeholder, replaced in Task 2)

```swift
import SwiftUI
import DesignSystem

@main
struct VelvetGalleryApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Text("VelvetGallery")
                    .ds(.title1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DSColors.backgroundPrimary.ignoresSafeArea())
                    .navigationTitle("Velvet UI")
            }
            .dsTheme(DSTheme())
        }
    }
}
```

- [ ] **Step 3: Generate the Xcode project**

Run: `cd Examples/VelvetGallery && xcodegen generate && cd ../..`
Expected: `Created project at .../VelvetGallery.xcodeproj`.

- [ ] **Step 4: Confirm the project is ignored** — run `git status --porcelain Examples/VelvetGallery/` and verify `VelvetGallery.xcodeproj/` does **not** appear (the repo's existing `*.xcodeproj/` rule covers it). No `.gitignore` edit needed.

- [ ] **Step 5: Build**

Run the **Build command** from Global Constraints.
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Run + screenshot**

Run the **Run + screenshot** block with `<name>` = `01-scaffold`.
Expected: `/tmp/velvetgallery-01-scaffold.png` shows a nav bar "Velvet UI" and centered text "VelvetGallery".

- [ ] **Step 7: Commit**

```bash
git add Examples/VelvetGallery/project.yml Examples/VelvetGallery/VelvetGallery/VelvetGalleryApp.swift
git status   # confirm no .xcodeproj staged
git commit -m "add: VelvetGallery scaffold — XcodeGen project spec, empty runnable app"
```

---

## Task 2: Neutral theme, shared screen chrome, appearance control

**Files:**
- Create: `Examples/VelvetGallery/VelvetGallery/Theme/NeutralTheme.swift`
- Create: `Examples/VelvetGallery/VelvetGallery/Support/Appearance.swift`
- Create: `Examples/VelvetGallery/VelvetGallery/Support/GalleryScreen.swift`
- Modify: `Examples/VelvetGallery/VelvetGallery/VelvetGalleryApp.swift` (full replace)
- Regenerate: `xcodegen generate` (new folders/files)

**Interfaces:**
- Produces:
  - `extension DSGradientTheme { static let neutral: DSGradientTheme }`
  - `enum Appearance: String, CaseIterable, Identifiable { case system, light, dark; var label: String; var colorScheme: ColorScheme? }`
  - `EnvironmentValues.galleryAppearance: Binding<Appearance>`
  - `struct AppearanceMenu: View` — toolbar menu bound to `\.galleryAppearance`
  - `struct GalleryScreen<Content: View>: View` — `init(title: String, caption: String, @ViewBuilder content: () -> Content)`
  - `struct LabeledExample<Content: View>: View` — `init(_ label: String, @ViewBuilder content: () -> Content)`

- [ ] **Step 1: Write `Theme/NeutralTheme.swift`**

```swift
import SwiftUI
import DesignSystem

extension DSGradientTheme {
    /// Gallery-only theme: no gradient, graphite accent that adapts to light/dark.
    /// `stops` is never drawn because the gallery never uses `.dsBackdrop()`.
    static let neutral = DSGradientTheme(
        id: "neutral",
        name: "Neutral",
        stops: [Color(hex: "9AA0A6"), Color(hex: "6B7178")],
        accent: .dsDynamic(light: Color(hex: "1F2225"), dark: Color(hex: "EDEEF0")),
        onAccent: .dsDynamic(light: Color(hex: "FFFFFF"), dark: Color(hex: "16181A")),
        ink: Color(hex: "2A2D30"),
        inkDark: Color(hex: "E6E7E9")
    )
}
```

- [ ] **Step 2: Write `Support/Appearance.swift`**

```swift
import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

private struct GalleryAppearanceKey: EnvironmentKey {
    static let defaultValue: Binding<Appearance> = .constant(.system)
}

extension EnvironmentValues {
    var galleryAppearance: Binding<Appearance> {
        get { self[GalleryAppearanceKey.self] }
        set { self[GalleryAppearanceKey.self] = newValue }
    }
}

struct AppearanceMenu: View {
    @Environment(\.galleryAppearance) private var appearance
    var body: some View {
        Menu {
            Picker("Appearance", selection: appearance) {
                ForEach(Appearance.allCases) { Text($0.label).tag($0) }
            }
        } label: {
            Image(systemName: "circle.lefthalf.filled")
        }
    }
}
```

- [ ] **Step 3: Write `Support/GalleryScreen.swift`**

```swift
import SwiftUI
import DesignSystem

/// Shared chrome for every component screen: neutral background, scroll,
/// screen padding, a header, and the appearance menu in the toolbar. No backdrop.
struct GalleryScreen<Content: View>: View {
    let title: String
    let caption: String
    @ViewBuilder var content: () -> Content

    init(title: String, caption: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.caption = caption
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xxl) {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(title).ds(.title1)
                    Text(caption).ds(.callout, color: DSColors.textSecondary)
                }
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.lg)
        }
        .background(DSColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { AppearanceMenu() } }
    }
}

/// A titled block within a screen.
struct LabeledExample<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    init(_ label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(label).ds(.overline, color: DSColors.textSecondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

- [ ] **Step 4: Replace `VelvetGalleryApp.swift` in full**

```swift
import SwiftUI
import DesignSystem

@main
struct VelvetGalleryApp: App {
    @AppStorage("gallery.appearance") private var appearanceRaw = Appearance.system.rawValue
    private let theme = DSTheme(gradient: .neutral)

    private var appearance: Binding<Appearance> {
        Binding(
            get: { Appearance(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack { ComponentListView() }
                .dsTheme(theme)
                .tint(DSColors.textPrimary)
                .environment(\.galleryAppearance, appearance)
                .preferredColorScheme(appearance.wrappedValue.colorScheme)
        }
    }
}
```

Note: this references `ComponentListView`, created in Task 3. The build in Step 6 will fail until Task 3 lands — that is expected; Task 2 and Task 3 are a pair. If executing strictly one task at a time, temporarily keep the Task 1 placeholder body and swap to `ComponentListView()` at the end of Task 3. Subagent-driven execution should run Task 2 then Task 3 back-to-back before the review gate.

- [ ] **Step 5: Regenerate project**

Run: `cd Examples/VelvetGallery && xcodegen generate && cd ../..`

- [ ] **Step 6: Build** — deferred to Task 3 (see note in Step 4). If running standalone, verify the three new files compile by temporarily keeping the placeholder `body`.

- [ ] **Step 7: Commit**

```bash
git add Examples/VelvetGallery
git commit -m "add: VelvetGallery — neutral theme, GalleryScreen chrome, appearance menu"
```

---

## Task 3: Component list + 16 screen stubs + navigation

**Files:**
- Create: `Examples/VelvetGallery/VelvetGallery/ComponentListView.swift`
- Create: 16 files `Examples/VelvetGallery/VelvetGallery/Screens/<Name>.swift` (stubs)
- Regenerate: `xcodegen generate`

**Interfaces:**
- Consumes: `GalleryScreen`, `AppearanceMenu`, `DSColors`.
- Produces: `struct ComponentListView: View` and 16 screen types, each `struct <Name>: View` with a no-arg init, each rendering `GalleryScreen(title:caption:) { … }`. Tasks 4–19 replace the `content` closure of one stub each. **Type names and the (title, caption) strings are fixed here** — later tasks must not change them.

- [ ] **Step 1: Write `ComponentListView.swift`**

```swift
import SwiftUI
import DesignSystem

struct ComponentListView: View {
    var body: some View {
        List {
            Section("Foundations") {
                row("Theme", "Neutral palette & glass surfaces") { ThemeScreen() }
                row("Typography", "Every text style") { TypographyScreen() }
                row("Layout", "Stacks & grids") { LayoutScreen() }
            }
            Section("Actions") {
                row("Buttons", "Variants, sizes, states") { ButtonsScreen() }
            }
            Section("Containers") {
                row("Cards", "Glass containers") { CardsScreen() }
            }
            Section("Inputs") {
                row("Text Field", "Inputs & validation") { TextFieldScreen() }
                row("Code Field", "OTP entry") { CodeFieldScreen() }
                row("Toggle", "Switches") { ToggleScreen() }
                row("Segmented Control", "Pick one") { SegmentedControlScreen() }
                row("Rating", "Star input") { RatingScreen() }
                row("Page Control", "Paged content") { PageControlScreen() }
            }
            Section("Data Display") {
                row("Badges & Avatars", "Status marks & identity") { BadgesAvatarsScreen() }
                row("Lists", "Rows & sections") { ListsScreen() }
            }
            Section("Feedback") {
                row("Toast", "Transient feedback") { ToastScreen() }
                row("Empty State", "Nothing here yet") { EmptyStateScreen() }
                row("Progress & Loading", "Determinate & skeletons") { ProgressLoadingScreen() }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DSColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Velvet UI")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { AppearanceMenu() } }
    }

    private func row<Destination: View>(
        _ title: String,
        _ caption: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).ds(.body)
                Text(caption).ds(.footnote, color: DSColors.textSecondary)
            }
        }
        .listRowBackground(DSColors.backgroundSecondary)
    }
}
```

- [ ] **Step 2: Write the 16 stub files**

Each file is exactly this shape (substitute the `Name`, `title`, `caption` from the table). **Do not** deviate from these names — `ComponentListView` references them.

```swift
import SwiftUI
import DesignSystem

struct <Name>: View {
    var body: some View {
        GalleryScreen(title: "<title>", caption: "<caption>") {
            Text("TODO").ds(.body)
        }
    }
}
```

| File / type `<Name>` | `<title>` | `<caption>` |
|---|---|---|
| `Screens/ThemeScreen.swift` → `ThemeScreen` | `Theme` | `Neutral palette & glass surfaces` |
| `Screens/TypographyScreen.swift` → `TypographyScreen` | `Typography` | `Every text style` |
| `Screens/LayoutScreen.swift` → `LayoutScreen` | `Layout` | `Stacks & grids` |
| `Screens/ButtonsScreen.swift` → `ButtonsScreen` | `Buttons` | `Variants, sizes, states` |
| `Screens/CardsScreen.swift` → `CardsScreen` | `Cards` | `Glass containers` |
| `Screens/TextFieldScreen.swift` → `TextFieldScreen` | `Text Field` | `Inputs & validation` |
| `Screens/CodeFieldScreen.swift` → `CodeFieldScreen` | `Code Field` | `OTP entry` |
| `Screens/ToggleScreen.swift` → `ToggleScreen` | `Toggle` | `Switches` |
| `Screens/SegmentedControlScreen.swift` → `SegmentedControlScreen` | `Segmented Control` | `Pick one` |
| `Screens/RatingScreen.swift` → `RatingScreen` | `Rating` | `Star input` |
| `Screens/PageControlScreen.swift` → `PageControlScreen` | `Page Control` | `Paged content` |
| `Screens/BadgesAvatarsScreen.swift` → `BadgesAvatarsScreen` | `Badges & Avatars` | `Status marks & identity` |
| `Screens/ListsScreen.swift` → `ListsScreen` | `Lists` | `Rows & sections` |
| `Screens/ToastScreen.swift` → `ToastScreen` | `Toast` | `Transient feedback` |
| `Screens/EmptyStateScreen.swift` → `EmptyStateScreen` | `Empty State` | `Nothing here yet` |
| `Screens/ProgressLoadingScreen.swift` → `ProgressLoadingScreen` | `Progress & Loading` | `Determinate & skeletons` |

- [ ] **Step 3: Regenerate project**

Run: `cd Examples/VelvetGallery && xcodegen generate && cd ../..`

- [ ] **Step 4: Build**

Run the **Build command**. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Run + screenshot (list + one stub)**

Run the **Run + screenshot** block with `<name>` = `03-list`. Then:
```bash
xcrun simctl io booted screenshot /tmp/velvetgallery-03-list.png
```
Manually confirm from the screenshot: six sections in order (Foundations, Actions, Containers, Inputs, Data Display, Feedback), all 16 rows present, neutral background. (Optional: use the simulator MCP `idb_tap` to open "Buttons" and confirm the stub screen shows "Buttons" header + "TODO".)

- [ ] **Step 6: Commit**

```bash
git add Examples/VelvetGallery
git commit -m "add: VelvetGallery — component list and 16 screen stubs, full navigation"
```

---

## Tasks 4–19: fill each screen

**Shared rules for every screen task below:**

- **File:** replace the `content` closure body of the one stub named in the task. Keep `import`s, the `struct <Name>: View`, and the `GalleryScreen(title:caption:)` call with its exact strings. Add `@State` properties on the struct as needed.
- **Structure:** wrap each distinct example in `LabeledExample("…") { … }`. Group related controls in a `DSCard { VStack(spacing: DSSpacing.md) { … } }` where the reference (`ComponentCatalog.swift`) does. Vertical rhythm between examples is handled by `GalleryScreen` (`DSSpacing.xxl`).
- **Reference:** the matching block in `Sources/DesignSystem/Preview/ComponentCatalog.swift` and the matching section of `docs/components.md` show working, correct API usage. Adapt that code; do not invent parameters.
- **Neutral:** follow the Global Constraints neutral rule. Callbacks that would open an alert/dialog must instead use `print(...)`.
- **Verification (every task):** run the **Build command** (expect `BUILD SUCCEEDED`, no warnings from `Examples/VelvetGallery/`), then the **Run + screenshot** block with `<name>` = the task's screen, navigating to that screen first (simulator MCP `idb_tap` on the row, or relaunch and tap). Eyeball the screenshot against the example list. Then commit:
  ```bash
  git add Examples/VelvetGallery/VelvetGallery/Screens/<Name>.swift
  git commit -m "add: VelvetGallery <Name> — <one-line what it shows>"
  ```

---

### Task 4: `ButtonsScreen` (canonical example — full body)

Replace the stub body with:

```swift
GalleryScreen(title: "Buttons", caption: "Variants, sizes, states") {
    LabeledExample("Variants") {
        VStack(spacing: DSSpacing.sm) {
            DSButton("Primary", variant: .primary, isFullWidth: true) { print("primary") }
            DSButton("Secondary", variant: .secondary, isFullWidth: true) { print("secondary") }
            DSButton("Outline", variant: .outline, isFullWidth: true) { print("outline") }
            HStack(spacing: DSSpacing.sm) {
                DSButton("Ghost", variant: .ghost) { print("ghost") }
                DSButton("Delete", variant: .destructive, icon: "trash") { print("destructive") }
            }
        }
    }
    LabeledExample("Sizes") {
        HStack(spacing: DSSpacing.sm) {
            DSButton("Small", size: .small) { }
            DSButton("Medium", size: .medium) { }
            DSButton("Large", size: .large) { }
        }
    }
    LabeledExample("States") {
        VStack(spacing: DSSpacing.sm) {
            DSButton("Loading", isLoading: true, isFullWidth: true) { }
            DSButton("Disabled", isFullWidth: true) { }.disabled(true)
        }
    }
    LabeledExample("Icon position") {
        VStack(spacing: DSSpacing.sm) {
            DSButton("Back", icon: "arrow.left", iconPosition: .leading, isFullWidth: true) { }
            DSButton("Continue", icon: "arrow.right", iconPosition: .trailing, isFullWidth: true) { }
        }
    }
    LabeledExample("Icon buttons") {
        HStack(spacing: DSSpacing.md) {
            DSIconButton(icon: "heart") { print("like") }
            DSIconButton(icon: "square.and.arrow.up") { print("share") }
            DSIconButton(icon: "ellipsis") { print("more") }
        }
    }
}
```

Verify + commit per the shared rules (`<name>` = `buttons`).

---

### Task 5: `CardsScreen`

Examples (each in a `LabeledExample`):
1. **"Styles"** — three `DSCard`s stacked: `DSCard(style: .flat) { cardBody("Flat", "Wash on the backdrop, no shadow") }`, `.elevated` ("Elevated", "Glass, edge highlight, soft shadow"), `.outlined` ("Outlined", "Denser glass, no shadow"). Define a local `@ViewBuilder func cardBody(_ title: String, _ sub: String) -> some View` returning a leading-aligned `VStack(spacing: DSSpacing.xs)` of `Text(title).ds(.title3)` + `Text(sub).ds(.callout, color: DSColors.textSecondary)`, `.frame(maxWidth: .infinity, alignment: .leading)`.
2. **"Nested"** — `DSCard(style: .elevated) { VStack(alignment: .leading, spacing: DSSpacing.sm) { Text("Nested").ds(.title3); DSCard(style: .flat, cornerRadius: DSRadius.surface) { Text("Flat card inside").ds(.callout).frame(maxWidth: .infinity, alignment: .leading) } } }`.
3. **"Interactive"** — `DSInteractiveCard(action: { print("card tap") }) { HStack { Text("Interactive card").ds(.body); Spacer(); Image(systemName: "chevron.right").foregroundStyle(DSColors.textTertiary) } }`.
4. **"Image card"** — `DSImageCard(imageURL: URL(string: "https://picsum.photos/seed/velvet/600/400"), title: "Cabaña en el bosque", subtitle: "$120 / noche", badge: "Nuevo")`.

Neutral: `DSImageCard` badge uses `theme.accent`/`onAccent` → graphite, no override needed. Screen must look right while the image loads (shimmer) and if it never loads.

---

### Task 6: `TextFieldScreen`

`@State private var email = ""`, `@State private var password = ""`, `@State private var search = ""`.

Examples:
1. **"States"** — one `DSCard { VStack(spacing: DSSpacing.md) { … } }` containing:
   - `DSTextField(label: "Email", placeholder: "you@example.com", icon: "envelope", text: $email)`
   - `DSTextField(label: "Password", placeholder: "••••••••", icon: "lock", text: $password, isSecure: true)`
   - `DSTextField(label: "Username", placeholder: "username", text: .constant("m"), state: .error("Too short"))`
   - `DSTextField(label: "Display name", placeholder: "name", text: .constant("Matias"), state: .success)`
   - `DSTextField(label: "Locked", placeholder: "n/a", text: .constant("read only"), state: .disabled)`
2. **"Search bar"** — `DSSearchBar(text: $search)`.

Neutral: focus glow is `theme.ink` (graphite). `.error` red is semantic — keep.

---

### Task 7: `CodeFieldScreen`

`@State private var code = ""`, `@State private var completed = false`.

Examples, all inside one `DSCard { VStack(alignment: .leading, spacing: DSSpacing.lg) { … } }`:
1. **"Live (6 digits)"** — `DSCodeField(length: 6, code: $code, onComplete: { _ in completed = true })`, followed by `Text(completed ? "Completed ✓" : "Enter 6 digits").ds(.footnote, color: completed ? DSColors.success : DSColors.textSecondary)`.
2. **"Error"** — `DSCodeField(length: 4, code: .constant("1234"), state: .error)`.
3. **"Success"** — `DSCodeField(length: 4, code: .constant("5678"), state: .success)`.

Wrap each of the three in its own `LabeledExample` inside the card, or use one card per example — match `ComponentCatalog`'s single-card layout. Neutral: caret is `theme.ink` (graphite).

---

### Task 8: `ToggleScreen`

`@State private var notifications = true`, `@State private var sync = false`, `@State private var focus = false`.

One `DSCard { VStack(spacing: DSSpacing.md) { … } }`, each item in a `LabeledExample`:
1. **"With label"** — `DSToggle("Push notifications", isOn: $notifications)`.
2. **"Sizes"** — `HStack(spacing: DSSpacing.lg) { DSToggle(isOn: $sync, size: .small); DSToggle(isOn: $notifications, size: .medium) }`.
3. **"Disabled"** — `DSToggle("Background sync", isOn: $sync).disabled(true)`.
4. **"Custom tint (neutral)"** — `DSToggle("Focus mode", isOn: $focus, onColor: DSColors.textSecondary)`.

Neutral: default on-state is `theme.accent` (graphite); the custom-tint row deliberately uses a grey per spec §4.

---

### Task 9: `SegmentedControlScreen`

`@State private var period = "Day"`, `@State private var tab = "Overview"`, `@State private var mode = "List"`.

One `DSCard { VStack(spacing: DSSpacing.lg) { … } }`, each in a `LabeledExample`:
1. **"Pill"** — `DSSegmentedControl(selection: $period, options: ["Day", "Week", "Month"])`.
2. **"Underline"** — `DSSegmentedControl(selection: $tab, options: ["Overview", "Details", "Reviews"], style: .underline)`.
3. **"With icons"** — `DSSegmentedControl(selection: $mode, segments: [DSSegment("List", value: "List", icon: "list.bullet"), DSSegment("Grid", value: "Grid", icon: "square.grid.2x2"), DSSegment("Map", value: "Map", icon: "map")])`.

Neutral: indicator/label use `theme.accent`/`theme.ink` (graphite) — no override.

---

### Task 10: `RatingScreen`

`@State private var rating: Double = 3`, `@State private var half: Double = 3.5`.

One `DSCard { VStack(alignment: .leading, spacing: DSSpacing.md) { … } }`, each in a `LabeledExample`:
1. **"Interactive"** — `DSRating(rating: $rating, tint: DSColors.textPrimary)`.
2. **"Half steps"** — `DSRating(rating: $half, step: 0.5, tint: DSColors.textPrimary)`.
3. **"Read-only"** — `DSRating(value: 4.2, size: 20, tint: DSColors.textPrimary)`.
4. **"Custom symbol & tint"** — `DSRating(value: 4, symbol: "heart.fill", emptySymbol: "heart", size: 20, tint: DSColors.error)`. Caption this block as the "you can tint & re-symbol it" example.

Neutral: primary examples pass `tint: DSColors.textPrimary` per spec §4; the last row is the single labelled colourful exception.

---

### Task 11: `PageControlScreen`

`@State private var page = 0`.

Examples:
1. **"Paged content"** — a `TabView(selection: $page) { ForEach(0..<4, id: \.self) { i in DSCard { Text("Page \(i + 1)").ds(.title2).frame(maxWidth: .infinity, minHeight: 120) }.tag(i) } }` with `.tabViewStyle(.page(indexDisplayMode: .never))` and `.frame(height: 180)`, then below it `DSPageControl(currentPage: $page, numberOfPages: 4)`.
2. **"Tap to jump"** — `DSPageControl(currentPage: $page, numberOfPages: 4, activeColor: DSColors.textPrimary)`.

Neutral: default `activeColor` is `theme.accent` (graphite); example 2 passes `DSColors.textPrimary` (also neutral) to demonstrate the parameter.

---

### Task 12: `BadgesAvatarsScreen`

Examples, grouped into two `DSCard`s:

Card A — badges, each in a `LabeledExample`:
1. **"Variants"** — `HStack(spacing: DSSpacing.xs) { DSBadge("New", variant: .filled); DSBadge("Active", variant: .soft); DSBadge("Beta", variant: .outline) }`.
2. **"Semantic colour"** — `DSBadge("Live", color: DSColors.success, variant: .soft)` — the single labelled colourful example.
3. **"Count"** — `HStack(spacing: DSSpacing.sm) { DSCountBadge(count: 5); DSCountBadge(count: 120) }` and a trailing `Text("count: 0 renders nothing").ds(.footnote, color: DSColors.textTertiary)` next to `DSCountBadge(count: 0)`.

Card B — **"Avatars"** — `HStack(spacing: DSSpacing.sm) { DSAvatar(name: "John Doe", size: 32); DSAvatar(name: "Jane Smith", size: 40); DSAvatar(name: "Bob", size: 48); DSAvatar(name: "Ada Lovelace", imageURL: URL(string: "https://picsum.photos/seed/ada/96"), size: 48) }`.

Neutral: filled/soft badges use `theme.accent` (graphite); semantic row explicit green.

---

### Task 13: `ListsScreen`

One `LabeledExample("Settings group")` containing:
- `DSSectionHeader("Settings", action: "Edit", onAction: { print("edit") })`
- `DSCard(padding: 0) { VStack(spacing: 0) { … } }`:
  - `DSListCell(title: "Account", subtitle: "Profile, security") { Image(systemName: "person.circle") } action: { print("account") }`
  - `DSDivider(inset: DSSpacing.screenHorizontal)`
  - `DSListCell(title: "Notifications") { Image(systemName: "bell") } trailing: { DSCountBadge(count: 3) } action: { print("notifications") }`
  - `DSDivider(inset: DSSpacing.screenHorizontal)`
  - `DSListCell(title: "About", subtitle: "Version 0.2.0")`

Neutral: section-header action text is `theme.ink` (graphite) — no override.

---

### Task 14: `ToastScreen`

`@State private var active: DSToastType?`

Local helpers on the struct:
```swift
private func message(for type: DSToastType) -> String {
    switch type {
    case .success: return "Saved to your library"
    case .error:   return "Couldn't connect"
    case .warning: return "Low storage"
    case .info:    return "New version available"
    }
}
private func haptic(for type: DSToastType) -> DSHapticStyle {
    switch type {
    case .success: return .success
    case .error:   return .error
    case .warning: return .warning
    case .info:    return .light
    }
}
private func present(_ type: DSToastType) {
    withAnimation(DSAnimation.springSmooth) { active = type }
    DSHapticEngine.shared.fire(haptic(for: type))
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
        withAnimation(DSAnimation.springSmooth) { if active == type { active = nil } }
    }
}
```
(`DSToastType` is `Equatable` via synthesized conformance since all cases are payload-free; if the compiler disagrees, compare with a raw tag or `String(describing:)`.)

Body:
```swift
GalleryScreen(title: "Toast", caption: "Transient feedback") {
    LabeledExample("Tap to present") {
        VStack(spacing: DSSpacing.sm) {
            DSButton("Show success", variant: .primary, isFullWidth: true) { present(.success) }
            DSButton("Show error", variant: .secondary, isFullWidth: true) { present(.error) }
            DSButton("Show warning", variant: .secondary, isFullWidth: true) { present(.warning) }
            DSButton("Show info", variant: .secondary, isFullWidth: true) { present(.info) }
        }
    }
}
.overlay(alignment: .bottom) {
    if let active {
        DSToast(message(for: active), type: active)
            .padding(DSSpacing.md)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
```

Neutral: `DSToast` keeps its semantic per-type colour (that is the point of the component). Buttons are graphite.

---

### Task 15: `EmptyStateScreen`

`@State private var hasResults = false`.

Body: inside a `LabeledExample("Search results")`:
```swift
if hasResults {
    DSCard {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("3 results").ds(.title3)
            Text("Showing sample data.").ds(.callout, color: DSColors.textSecondary)
            DSButton("Clear", variant: .ghost) { hasResults = false }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
} else {
    DSCard {
        DSEmptyState(
            icon: "magnifyingglass",
            title: "No results",
            message: "Try adjusting your search or filters to find what you're looking for.",
            actionTitle: "Show sample"
        ) { hasResults = true }
    }
}
```

Neutral: CTA is a `DSButton` (graphite). Icon tints follow the theme.

---

### Task 16: `ProgressLoadingScreen`

`@State private var progress: Double = 0.65`, `@State private var number: Double = 1248`.

Examples:
1. **"Driver"** — `Slider(value: $progress, in: 0...1).tint(DSColors.textPrimary)`.
2. **"Determinate"** — one `DSCard { VStack(spacing: DSSpacing.lg) { … } }`:
   - `DSCircularProgress(progress: progress, size: 80)`
   - `DSLinearProgress(progress: progress)`
   - `DSGradientProgress(progress: progress, colors: [DSColors.textTertiary, DSColors.textPrimary])`
   - `DSStepProgress(currentStep: max(1, Int(progress * 5) + (progress >= 1 ? 0 : 1)), totalSteps: 5)`
3. **"Animated number"** — `HStack { DSAnimatedNumber(value: number, style: .displayMedium); Spacer(); DSButton("Randomize", size: .small) { number = Double(Int.random(in: 100...9999)) } }`.
4. **"Skeletons"** — `VStack(alignment: .leading, spacing: DSSpacing.sm) { RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous).fill(DSColors.backgroundSecondary).frame(height: DSSpacing.lg).dsShimmer(); RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous).fill(DSColors.backgroundSecondary).frame(width: 180, height: DSSpacing.md).dsShimmer() }`.
5. **"Pulse"** — `DSBadge("Syncing", variant: .soft).dsPulse()`.

Neutral: `DSGradientProgress` gets explicit neutral `colors:` per spec §4; everything else follows the theme (graphite).

---

### Task 17: `LayoutScreen`

Local helper on the struct:
```swift
private func tile(_ label: String, width: CGFloat? = nil) -> some View {
    Text(label)
        .ds(.footnote, color: DSColors.textSecondary)
        .frame(width: width, height: 64)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .background(DSColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
}
```

Examples, each in a `LabeledExample`:
1. **"DSVStack"** — `DSVStack(spacing: DSSpacing.sm) { tile("A"); tile("B"); tile("C") }`.
2. **"DSHStack"** — `DSHStack(spacing: DSSpacing.sm) { tile("1"); tile("2"); tile("3") }`.
3. **"DSGrid"** — `DSGrid(minItemWidth: 100, spacing: DSSpacing.sm) { ForEach(0..<6, id: \.self) { tile("\($0)") } }`.
4. **"DSHorizontalScroll"** — `DSHorizontalScroll(spacing: DSSpacing.sm) { ForEach(0..<8, id: \.self) { tile("#\($0)", width: 120) } }`.
5. **"DSScreen"** — `DSScreen { VStack(spacing: DSSpacing.sm) { tile("DSScreen"); tile("scroll + padding") } }.frame(height: 220).clipShape(RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous))` with a trailing `Text("DSScreen supplies the scroll container and screen padding.").ds(.footnote, color: DSColors.textTertiary)`.

Neutral: all tiles are `DSColors.backgroundSecondary`.

---

### Task 18: `ThemeScreen`

Local helper:
```swift
private func swatch(_ name: String, _ color: Color) -> some View {
    HStack(spacing: DSSpacing.sm) {
        RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
            .fill(color)
            .frame(width: 44, height: 44)
        Text(name).ds(.footnote)
        Spacer()
    }
}
```

Examples, each in a `LabeledExample`:
1. **"Neutral palette"** — a `DSCard(style: .flat) { VStack(alignment: .leading, spacing: DSSpacing.sm) { … } }` with `swatch` rows for: `("backgroundPrimary", DSColors.backgroundPrimary)`, `("backgroundSecondary", DSColors.backgroundSecondary)`, `("backgroundElevated", DSColors.backgroundElevated)`, `("textPrimary", DSColors.textPrimary)`, `("textSecondary", DSColors.textSecondary)`, `("textTertiary", DSColors.textTertiary)`, `("border", DSColors.border)`, `("divider", DSColors.divider)`.
2. **"Surfaces"** — four rows, each: `HStack { Text(name).ds(.footnote); Spacer(); Text("dsSurface(.\(name))").ds(.caption1, color: DSColors.textTertiary) }.padding(DSSpacing.md).dsSurface(level, radius: DSRadius.surface)` for `("glassThin", .glassThin)`, `("glass", .glass)`, `("glassThick", .glassThick)`, `("solid", .solid)`. Adapt from `ComponentCatalog.surfaceRow`.
3. **"Built-in gradient themes (reference only)"** — `VStack(spacing: DSSpacing.sm) { ForEach(DSGradientTheme.all) { g in HStack(spacing: DSSpacing.sm) { RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous).fill(g.linearGradient).frame(width: 60, height: 44); Text(g.name).ds(.footnote); Spacer() } } }` plus `Text("Not used in this gallery — the app is neutral-only. Shown so the themes are on camera once.").ds(.footnote, color: DSColors.textTertiary)`.

---

### Task 19: `TypographyScreen`

One `DSCard { VStack(alignment: .leading, spacing: DSSpacing.sm) { … } }`, one `Text` per style (label text = the style name, modifier = that style):

```swift
Text("Hero").ds(.hero)
Text("Large Title").ds(.largeTitle)
Text("Title 1").ds(.title1)
Text("Title 2").ds(.title2)
Text("Title 3").ds(.title3)
Text("Body — the quick brown fox jumps over the lazy dog").ds(.body)
Text("Callout").ds(.callout)
Text("Footnote").ds(.footnote)
Text("Caption 1").ds(.caption1)
Text("Caption 2").ds(.caption2)
Text("BUTTON").ds(.button)
Text("OVERLINE").ds(.overline)
Text("$1,248.00").ds(.numeric)
Text("42").ds(.displayLarge)
Text("128").ds(.displayMedium)
```

`.frame(maxWidth: .infinity, alignment: .leading)` on the `VStack`.

---

## Task 20: Docs, final verification, PR

**Files:**
- Create: `Examples/VelvetGallery/README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/engineering-notes.md`

**Interfaces:** none (terminal task).

- [ ] **Step 1: Write `Examples/VelvetGallery/README.md`**

```markdown
# VelvetGallery

A runnable iOS app that shows every Velvet UI component on its own screen, for
demos and video capture. Not part of `swift build` / `swift test`.

## Run

The `.xcodeproj` is **not** in git (the repo ignores `*.xcodeproj/`). Generate it first:

```bash
cd Examples/VelvetGallery && xcodegen generate
```

Then open `VelvetGallery.xcodeproj` in Xcode, pick an iPhone simulator, Run.
Or: `xcodebuild build -scheme VelvetGallery -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`.

## Regenerate the project

`project.yml` is the source of truth ([XcodeGen](https://github.com/yonwoo9/XcodeGen)).
Re-run `xcodegen generate` after changing the file list or target settings.

## Design

Neutral-only: solid `DSColors.backgroundPrimary` background, no `.dsBackdrop()`,
a local `DSGradientTheme.neutral` with a graphite accent. Appearance
(System/Light/Dark) is switchable from the toolbar. Rationale in
`docs/engineering-notes.md` and `docs/superpowers/specs/2026-09-08-velvet-gallery-app-design.md`.
```

- [ ] **Step 2: Add the `CHANGELOG.md` line** under `## [Unreleased]` (create the section if absent, matching Keep a Changelog style already used in the file):

```
### Added
- `VelvetGallery` — runnable per-component demo app under `Examples/`, neutral theme, one screen per component (for demos / video capture). Not part of `swift build`.
```

- [ ] **Step 3: Add a subsection to `docs/engineering-notes.md`** (under a sensible existing heading, or a new `## VelvetGallery example app`):

```markdown
## VelvetGallery example app

`Examples/VelvetGallery/` is a runnable iOS app for demoing components one per
screen (the internal `ComponentCatalog` `#Preview` stays for quick dev checks).

- **Neutral by design.** The design system is gradient-first; the gallery is
  not. It injects a gallery-local `DSGradientTheme.neutral` (graphite accent via
  `Color.dsDynamic`) and never calls `.dsBackdrop()`, so components are shown on
  a plain `DSColors.backgroundPrimary`. Semantic status colours are kept;
  decorative defaults (e.g. `DSRating` amber) are overridden to neutral with one
  labelled colourful example each.
- **Not in `swift build`.** It lives outside `Sources/`; `Package.swift` is
  untouched. The project is XcodeGen-generated from `project.yml` and committed;
  run `xcodegen generate` after changing its file list.
- **Consumes the package** as a local SPM dependency at `../..`.
```

- [ ] **Step 4: Regenerate + full build**

```bash
cd Examples/VelvetGallery && xcodegen generate && cd ../..
```
Then the **Build command**. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Package regression**

```bash
swift build 2>&1 | tail -5
swift test 2>&1 | tail -15
xcodebuild build -scheme DesignSystem -destination 'generic/platform=iOS Simulator' 2>&1 | tail -5
```
Expected: `swift build` compiles, `swift test` all pass, iOS package build succeeds. (These are untouched, but confirm.)

- [ ] **Step 6: Run + screenshot the highlights**

Run the **Run + screenshot** block for `<name>` = `list`, then navigate (simulator MCP `idb_tap`) and screenshot `buttons`, `toast` (after tapping "Show success"), and `rating`. Keep the four PNGs for the PR.

- [ ] **Step 7: Commit docs**

```bash
git add Examples/VelvetGallery/README.md CHANGELOG.md docs/engineering-notes.md
git commit -m "docs: VelvetGallery — README, changelog, engineering notes"
```

- [ ] **Step 8: Push and open the PR**

```bash
git push -u origin feat/gallery-app
gh pr create --base main --title "add: VelvetGallery — runnable per-component demo app" --body "$(cat <<'EOF'
## What

A runnable iOS Simulator app under `Examples/VelvetGallery/` that shows every
Velvet UI component on its own screen, for filming a presentation video.
Replaces nothing — the internal `ComponentCatalog` `#Preview` stays.

## Design

- **Neutral only.** Solid `DSColors.backgroundPrimary` background, no
  `.dsBackdrop()`, a gallery-local `DSGradientTheme.neutral` (graphite accent).
  Semantic status colours kept; decorative defaults overridden to neutral with
  one labelled colourful example each.
- Appearance (System/Light/Dark) switchable from the toolbar, persisted.
- `NavigationStack` + grouped `List` → 16 screens.
- XcodeGen project (`project.yml` committed; `.xcodeproj` generated locally, not
  committed — repo already ignores `*.xcodeproj/`). Package consumed as a local
  SPM dependency at `../..`. `Package.swift` untouched; `swift build` /
  `swift test` unaffected.

## Verification

- `xcodebuild build -scheme VelvetGallery` — succeeds.
- `swift build`, `swift test`, `xcodebuild -scheme DesignSystem` (iOS) — still pass.
- Screenshots attached: component list, Buttons, Toast, Rating.

Spec: `docs/superpowers/specs/2026-09-08-velvet-gallery-app-design.md`
Plan: `docs/superpowers/plans/2026-09-08-velvet-gallery-app.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review

**Spec coverage:**

| Spec section | Task(s) |
|---|---|
| Approach A — decompose `ComponentCatalog` | Task 3 + 4–19 |
| Neutral background (`backgroundPrimary`, no backdrop) | Task 2 (`GalleryScreen`), enforced every screen |
| Neutral components (`DSGradientTheme.neutral`, graphite adaptive accent) | Task 2 |
| Semantic status colours kept | Tasks 6, 7, 12, 14 (error/success/warning/info) |
| Decorative defaults overridden + one labelled colourful example | Tasks 10 (rating), 16 (gradient progress), 12 (badge), 18 (gradients reference) |
| Appearance menu, `@AppStorage`, no gradient switcher | Task 2 (`Appearance`, `AppearanceMenu`, `VelvetGalleryApp`) |
| Project under `Examples/VelvetGallery/`, XcodeGen, local dep `../..` (`.xcodeproj` NOT committed — controller ruling, repo already ignores `*.xcodeproj/`) | Task 1 |
| iOS 17, iPhone+iPad, bundle id | Task 1 (`project.yml`) |
| `Package.swift` untouched, `swift build`/`test` pass | Global Constraints + Task 20 Step 5 |
| 16 screens per the spec table | Tasks 4–19 (Buttons, Cards, TextField, CodeField, Toggle, Segmented, Rating, PageControl, Badges&Avatars, Lists, Toast, EmptyState, Progress&Loading, Layout, Theme incl. Surfaces, Typography) |
| Toast *presents* animated (not static) | Task 14 |
| Live `@State` interactivity | Tasks 6–11, 14–17 |
| Remote images degrade gracefully | Tasks 5, 12 (notes) |
| `print` not alerts | Shared rules for 4–19 |
| CHANGELOG `[Unreleased]` line | Task 20 Step 2 |
| `docs/engineering-notes.md` subsection | Task 20 Step 3 |
| `Examples/VelvetGallery/README.md` | Task 20 Step 1 |
| Branch `feat/gallery-app`, PR to `main` | Global Constraints + Task 20 Step 8 |
| Verification matrix (build, sim run, screenshots, package regression) | Task 20 Steps 4–6 |

No spec requirement is left without a task. "Surfaces" is folded into Task 18 (ThemeScreen), matching the spec.

**Placeholder scan:** The word "TODO" appears only as literal stub screen text in Task 3 Step 2 (intentional — replaced in Tasks 4–19). No "TBD", no "add error handling", no "write tests for the above", no "similar to Task N" (Task 4 is fully written; Tasks 5–19 each carry their own explicit example list with real API calls). Verification steps give exact commands and expected output.

**Type consistency:**
- `GalleryScreen(title:caption:content:)` — defined Task 2, used identically Tasks 3–19.
- `LabeledExample(_:content:)` — defined Task 2, used Tasks 4–19.
- `Appearance` (`.system/.light/.dark`, `.label`, `.colorScheme`) — defined Task 2, used in `VelvetGalleryApp` and `AppearanceMenu` (Task 2).
- `EnvironmentValues.galleryAppearance: Binding<Appearance>` — defined Task 2, read by `AppearanceMenu` (Task 2), written by `VelvetGalleryApp` (Task 2).
- 16 screen type names + their `(title, caption)` strings — fixed in Task 3's table, referenced verbatim by `ComponentListView` (Task 3) and preserved by Tasks 4–19.
- Component APIs (`DSButton`, `DSCard`, `DSTextField`, `DSCodeField`, `DSToggle`, `DSSegmentedControl`, `DSSegment`, `DSRating`, `DSPageControl`, `DSBadge`, `DSCountBadge`, `DSAvatar`, `DSListCell`, `DSSectionHeader`, `DSDivider`, `DSToast`, `DSToastType`, `DSEmptyState`, `DSCircularProgress`, `DSLinearProgress`, `DSGradientProgress`, `DSStepProgress`, `DSAnimatedNumber`, `DSIconButton`, `.dsShimmer()`, `.dsPulse()`, `DSHapticEngine.shared.fire(_:)`, `DSHapticStyle`, `DSAnimation.springSmooth`, `DSGradientTheme(id:name:stops:accent:onAccent:ink:inkDark:)`, `Color.dsDynamic(light:dark:)`, `Color(hex:)`, `.ds(_:color:)`, `.dsScreenPadding()`, `.dsSurface(_:radius:)`, `DSSpacing.*`, `DSRadius.*`, `DSColors.*`) — all verified against `Sources/DesignSystem/` during planning. `DSToastType.haptic` is **not** public → Task 14 defines a local `haptic(for:)` map instead.

Fixes applied inline: none needed beyond the `DSToastType.haptic` note already in Task 14.
