import SwiftUI

// MARK: - Design System Theme
// Central theme configuration that can be swapped per-app.
// Each app can define its own palette while keeping all components consistent.

@MainActor
public final class DSTheme: ObservableObject {
    @Published public var light: DSColorPalette
    @Published public var dark: DSColorPalette

    public init(
        light: DSColorPalette = DSColors.defaultPalette,
        dark: DSColorPalette = DSColors.defaultDarkPalette
    ) {
        self.light = light
        self.dark = dark
    }

    /// Resolve the correct palette for the current color scheme
    public func palette(for colorScheme: ColorScheme) -> DSColorPalette {
        colorScheme == .dark ? dark : light
    }
}

// MARK: - Environment Key

private struct DSThemeKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue = DSTheme()
}

public extension EnvironmentValues {
    var dsTheme: DSTheme {
        get { self[DSThemeKey.self] }
        set { self[DSThemeKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// Inject a Design System theme into the view hierarchy
    func dsTheme(_ theme: DSTheme) -> some View {
        self.environment(\.dsTheme, theme)
            .environmentObject(theme)
    }
}
