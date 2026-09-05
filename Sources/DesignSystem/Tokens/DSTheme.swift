import SwiftUI
import Observation

// MARK: - Design System Theme
// Central theme object: a light palette, a dark palette and the active gradient
// theme. Inject once at the root with `.dsTheme(theme)`; every component reads
// it through `@DSThemed` and re-renders when any part changes (Observation).
//
// `DSTheme` is `@Observable` *and* `ObservableObject` on purpose: `@Observable`
// gives live updates to any view that reads a property in `body`, even through
// `@Environment`; `ObservableObject` keeps `@StateObject` / `@EnvironmentObject`
// call sites from v0.1 compiling.

@Observable
@MainActor
public final class DSTheme: ObservableObject {
    public var light: DSColorPalette
    public var dark: DSColorPalette
    /// The active gradient theme. Change it at runtime to re-theme the whole tree.
    public var gradient: DSGradientTheme

    public init(
        light: DSColorPalette = DSColors.defaultPalette,
        dark: DSColorPalette = DSColors.defaultDarkPalette,
        gradient: DSGradientTheme = .sunset
    ) {
        self.light = light
        self.dark = dark
        self.gradient = gradient
    }

    /// Resolve the correct palette for the current color scheme.
    public func palette(for colorScheme: ColorScheme) -> DSColorPalette {
        colorScheme == .dark ? dark : light
    }

    /// Everything a component needs to paint itself, resolved for a color scheme.
    /// - Parameter onBackdrop: whether the view sits on a `DSBackdrop` (see `dsBackdrop()`).
    public func resolved(for colorScheme: ColorScheme, onBackdrop: Bool = false) -> DSResolvedTheme {
        DSResolvedTheme(
            palette: palette(for: colorScheme),
            gradient: gradient,
            colorScheme: colorScheme,
            onBackdrop: onBackdrop
        )
    }
}

// MARK: - Resolved Theme

/// A snapshot of the theme for one color scheme. Value type, cheap to build.
public struct DSResolvedTheme {
    public let palette: DSColorPalette
    public let gradient: DSGradientTheme
    public let colorScheme: ColorScheme
    /// True when the view sits on a `DSBackdrop` — washes make sense; otherwise solid fills do.
    public let onBackdrop: Bool

    public init(
        palette: DSColorPalette,
        gradient: DSGradientTheme,
        colorScheme: ColorScheme,
        onBackdrop: Bool = false
    ) {
        self.palette = palette
        self.gradient = gradient
        self.colorScheme = colorScheme
        self.onBackdrop = onBackdrop
    }

    public var isDark: Bool { colorScheme == .dark }

    /// Fill for primary CTAs, toggles on, active indicators.
    public var accent: Color { gradient.accent }
    /// Text and icons on top of `accent`.
    public var onAccent: Color { gradient.onAccent }
    /// Text, icons, links and focus glows on glass — already resolved for the scheme.
    public var ink: Color { gradient.ink(for: colorScheme) }
    /// Translucent flat fill used to separate a surface inside another.
    public var washSurface: Color { DSWash.surface(for: colorScheme) }
    /// Specular 1pt edge highlight for glass surfaces.
    public var washEdge: LinearGradient { DSWash.edge(for: colorScheme) }
    /// Flat fill for a surface nested inside another: the wash when on a backdrop,
    /// `backgroundSecondary` otherwise (so it stays visible on a plain screen).
    public var subtleFill: Color { onBackdrop ? washSurface : palette.backgroundSecondary }
}

// MARK: - @DSThemed

/// Reads the injected `DSTheme` and the current color scheme, and hands the
/// component a `DSResolvedTheme`. This is how every component gets its colors:
///
///     @DSThemed private var theme
///     ...
///     .foregroundStyle(theme.palette.textPrimary)
///     .background(theme.accent)
@propertyWrapper
@MainActor
public struct DSThemed: DynamicProperty {
    @Environment(\.dsTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dsOnBackdrop) private var onBackdrop

    public init() {}

    public var wrappedValue: DSResolvedTheme {
        theme.resolved(for: colorScheme, onBackdrop: onBackdrop)
    }
}

// MARK: - Environment Key

private struct DSThemeKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue = DSTheme()
}

public extension EnvironmentValues {
    /// The injected theme. Falls back to a shared default (Sunset) when none was injected.
    var dsTheme: DSTheme {
        get { self[DSThemeKey.self] }
        set { self[DSThemeKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// Inject a Design System theme into the view hierarchy.
    func dsTheme(_ theme: DSTheme) -> some View {
        self.environment(\.dsTheme, theme)
            .environmentObject(theme)
    }
}
