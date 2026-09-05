# Velvet UI

SwiftUI design system for iOS 17+ and macOS 14+. Frosted glass over a selectable gradient theme, spring motion, haptics on every primary action, no borders. One `import DesignSystem`.

| | |
|---|---|
| **Repo** | github.com/MatiasPC/velvet-ui |
| **Version** | 0.2.0 (unreleased) — see [CHANGELOG](CHANGELOG.md) |
| **Docs** | [Tokens](docs/tokens.md) · [Components](docs/components.md) · [Engineering notes](docs/engineering-notes.md) · [Proposals](docs/proposals/) |

## Install

- **Local package**: Xcode → File → Add Package Dependencies → Add Local → this folder.
- **Remote**: `.package(url: "https://github.com/MatiasPC/velvet-ui.git", from: "0.2.0")`, product `DesignSystem`.

## Quick start

```swift
import DesignSystem

@main
struct MyApp: App {
    @State private var theme = DSTheme(gradient: .sunset)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .dsTheme(theme)          // inject once at the root
        }
    }
}

struct ContentView: View {
    var body: some View {
        DSScreen(backdrop: true) {       // themed gradient behind everything
            VStack(spacing: DSSpacing.lg) {
                Text("Tu semana").ds(.title1)
                DSCard {                 // glass + edge highlight + soft shadow
                    Text("4 sesiones · 2 h 35 min").ds(.callout)
                }
                DSButton("Continuar", isFullWidth: true) { }
            }
            .dsScreenPadding()
        }
    }
}
```

Switch the theme at runtime and everything re-renders:

```swift
withAnimation(DSAnimation.normal) { theme.gradient = .lagoon }
```

## The system in one screen

| Layer | What it gives you | Reference |
|---|---|---|
| `DSGradientTheme` | Sunset / Aurora / Lagoon: background gradient + `accent`, `onAccent`, `ink`, `inkDark` | [tokens.md#gradient-themes](docs/tokens.md#gradient-themes) |
| `DSSurface` / `.dsSurface()` | Glass levels: `.glassThin`, `.glass`, `.glassThick`, `.solid` | [tokens.md#surfaces](docs/tokens.md#surfaces) |
| `DSWash` | The border replacement: translucent fill, 1pt specular edge, focus glow | [tokens.md#wash](docs/tokens.md#wash) |
| `DSShadow` | Soft ambient shadows + `.glow(accent)` | [tokens.md#shadows](docs/tokens.md#shadows) |
| `DSRadius` | 4…24, pill; semantic `card` 20 / `surface` 16 / `control` 12 / `chip` | [tokens.md#radius](docs/tokens.md#radius) |
| `DSSpacing` | 4pt grid, 2…64, screen margins | [tokens.md#spacing](docs/tokens.md#spacing) |
| `DSTextStyle` | 17 styles; SF Pro titles with tight tracking, rounded numbers | [tokens.md#typography](docs/tokens.md#typography) |
| `DSAnimation` / `DSPress` | 200/240/320/480ms curves, 5 springs, press scale 0.96 | [tokens.md#motion](docs/tokens.md#motion) |
| `DSHaptics` | 9 styles, pre-warmed engine, `dsHaptic(.success)` | [tokens.md#haptics](docs/tokens.md#haptics) |

Components: buttons, cards, inputs, code field, badges, avatar, list cells, toggle, segmented control, rating, page control, toast, empty state, progress ×4, shimmer, pulse. Full API in [components.md](docs/components.md).

## Building on Velvet

Inside any view, read the theme with the property wrapper and never touch raw colors:

```swift
struct PriceTag: View {
    @DSThemed private var theme

    var body: some View {
        Text("$120").ds(.numeric, color: theme.ink)
            .padding(.horizontal, DSSpacing.sm)
            .background(theme.subtleFill)
            .clipShape(Capsule())
    }
}
```

Rules for anything that lands in `Sources/DesignSystem/Components/` are in [CLAUDE.md](CLAUDE.md). The short version: tokens only, `@DSThemed` for colors, `DSPress` for press states, `DSAnimation` springs, haptics on primary actions, `Color? = nil` defaults that follow the theme, a `#Preview` in light and dark, a section in the catalog, an entry in `docs/components.md` and `CHANGELOG.md`.

## Verify before you push

```bash
swift build                                   # macOS build
swift test                                    # tokens, theme resolution, AA contrast
xcodebuild build -scheme DesignSystem \
  -destination 'generic/platform=iOS Simulator' | tail -3   # iOS build
```

`swift build` alone only compiles for macOS. iOS-only modifiers must be guarded with `#if os(iOS)`; see [engineering notes](docs/engineering-notes.md).

## Browsing the catalog

Open the package in Xcode and run the `#Preview` on `Sources/DesignSystem/Preview/ComponentCatalog.swift`. It has theme dots, a backdrop toggle and every component with its variants. The standalone showcase app is the next milestone (see the roadmap in the engineering notes).
