// MARK: - Velvet UI — Design System
// A SwiftUI design system for iOS 17+ / macOS 14+: frosted glass over a
// selectable gradient theme, spring motion, haptics, no borders.
// Import this single module to access all tokens, components, and utilities.
//
// Usage:
//   import DesignSystem
//
// Quick start:
//   ContentView().dsTheme(DSTheme(gradient: .sunset))   // at the root
//   DSScreen(backdrop: true) { ... }                     // themed gradient background
//   Text("Hello").ds(.title1)
//   DSButton("Continue", variant: .primary) { }
//   DSCard { Text("Content") }
//   dsHaptic(.success)
//
// Inside your own views:
//   @DSThemed private var theme
//   theme.accent / theme.onAccent / theme.ink / theme.palette.textPrimary
//
// Docs: README.md, docs/tokens.md, docs/components.md, docs/engineering-notes.md

// All public types are automatically exported from their respective files.
// No additional re-exports needed — Swift Package modules export all public symbols.
