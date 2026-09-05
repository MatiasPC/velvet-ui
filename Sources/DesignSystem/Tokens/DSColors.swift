import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Design System Colors
// Neutrals and status colors live here (`DSColorPalette`). The accent lives in
// the active `DSGradientTheme` — components read it through `@DSThemed`.
// The static accessors below are adaptive (light/dark) convenience colors for
// code that has no environment (models, previews, quick prototypes). They do
// NOT follow an injected custom palette; use `@DSThemed` inside views for that.

public struct DSColors {

    // MARK: - Semantic Accessors (adaptive light/dark, default palettes)

    public static var primary: Color { dynamic(\.primary) }
    public static var primaryVariant: Color { dynamic(\.primaryVariant) }
    public static var secondary: Color { dynamic(\.secondary) }
    public static var secondaryVariant: Color { dynamic(\.secondaryVariant) }
    public static var tertiary: Color { dynamic(\.tertiary) }

    public static var success: Color { dynamic(\.success) }
    public static var warning: Color { dynamic(\.warning) }
    public static var error: Color { dynamic(\.error) }
    public static var info: Color { dynamic(\.info) }

    public static var backgroundPrimary: Color { dynamic(\.backgroundPrimary) }
    public static var backgroundSecondary: Color { dynamic(\.backgroundSecondary) }
    public static var backgroundElevated: Color { dynamic(\.backgroundElevated) }

    public static var textPrimary: Color { dynamic(\.textPrimary) }
    public static var textSecondary: Color { dynamic(\.textSecondary) }
    public static var textTertiary: Color { dynamic(\.textTertiary) }
    public static var textOnPrimary: Color { dynamic(\.textOnPrimary) }

    public static var border: Color { dynamic(\.border) }
    public static var borderFocused: Color { dynamic(\.borderFocused) }
    public static var divider: Color { dynamic(\.divider) }

    // MARK: - Overlay

    public static let overlay = Color.black.opacity(0.4)
    public static let overlayLight = Color.black.opacity(0.15)

    private static func dynamic(_ keyPath: KeyPath<DSColorPalette, Color>) -> Color {
        Color.dsDynamic(
            light: defaultPalette[keyPath: keyPath],
            dark: defaultDarkPalette[keyPath: keyPath]
        )
    }
}

// MARK: - Default Palettes

public extension DSColors {
    /// Velvet defaults. `primary` matches the Sunset accent so raw-token usage
    /// lines up with the default gradient theme. `textOnPrimary` is white: it is
    /// the text color on *secondary, status and destructive* fills. On the
    /// accent itself use the theme's `onAccent`.
    static let defaultPalette = DSColorPalette(
        primary:             Color(hex: "FF7E5F"),   // Sunset accent
        primaryVariant:      Color(hex: "C2361A"),   // Sunset ink
        secondary:           Color(hex: "7F5AF0"),   // Aurora accent
        secondaryVariant:    Color(hex: "6D47E6"),   // Aurora ink
        tertiary:            Color(hex: "16F2B3"),   // Lagoon accent
        success:             Color(hex: "22C55E"),
        warning:             Color(hex: "F59E0B"),
        error:               Color(hex: "EF4444"),
        info:                Color(hex: "3B82F6"),
        backgroundPrimary:   Color(hex: "FFFFFF"),
        backgroundSecondary: Color(hex: "F7F7F7"),
        backgroundElevated:  Color(hex: "FFFFFF"),
        textPrimary:         Color(hex: "1A1A2E"),
        textSecondary:       Color(hex: "6B7280"),
        textTertiary:        Color(hex: "9CA3AF"),
        textOnPrimary:       Color(hex: "FFFFFF"),
        border:              Color(hex: "E5E7EB"),
        borderFocused:       Color(hex: "C2361A"),
        divider:             Color(hex: "F3F4F6")
    )

    static let defaultDarkPalette = DSColorPalette(
        primary:             Color(hex: "FF7E5F"),
        primaryVariant:      Color(hex: "FFA98F"),   // Sunset inkDark
        secondary:           Color(hex: "7F5AF0"),
        secondaryVariant:    Color(hex: "B9A3FF"),   // Aurora inkDark
        tertiary:            Color(hex: "16F2B3"),
        success:             Color(hex: "34D399"),
        warning:             Color(hex: "FBBF24"),
        error:               Color(hex: "F87171"),
        info:                Color(hex: "60A5FA"),
        backgroundPrimary:   Color(hex: "0F0F1A"),
        backgroundSecondary: Color(hex: "1A1A2E"),
        backgroundElevated:  Color(hex: "242440"),
        textPrimary:         Color(hex: "F9FAFB"),
        textSecondary:       Color(hex: "9CA3AF"),
        textTertiary:        Color(hex: "6B7280"),
        textOnPrimary:       Color(hex: "FFFFFF"),
        border:              Color(hex: "374151"),
        borderFocused:       Color(hex: "FFA98F"),
        divider:             Color(hex: "1F2937")
    )
}

// MARK: - Color Palette Model

public struct DSColorPalette: Sendable {
    public let primary: Color
    public let primaryVariant: Color
    public let secondary: Color
    public let secondaryVariant: Color
    public let tertiary: Color
    public let success: Color
    public let warning: Color
    public let error: Color
    public let info: Color
    public let backgroundPrimary: Color
    public let backgroundSecondary: Color
    public let backgroundElevated: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let textTertiary: Color
    public let textOnPrimary: Color
    public let border: Color
    public let borderFocused: Color
    public let divider: Color

    public init(
        primary: Color, primaryVariant: Color,
        secondary: Color, secondaryVariant: Color,
        tertiary: Color,
        success: Color, warning: Color, error: Color, info: Color,
        backgroundPrimary: Color, backgroundSecondary: Color, backgroundElevated: Color,
        textPrimary: Color, textSecondary: Color, textTertiary: Color, textOnPrimary: Color,
        border: Color, borderFocused: Color, divider: Color
    ) {
        self.primary = primary
        self.primaryVariant = primaryVariant
        self.secondary = secondary
        self.secondaryVariant = secondaryVariant
        self.tertiary = tertiary
        self.success = success
        self.warning = warning
        self.error = error
        self.info = info
        self.backgroundPrimary = backgroundPrimary
        self.backgroundSecondary = backgroundSecondary
        self.backgroundElevated = backgroundElevated
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.textOnPrimary = textOnPrimary
        self.border = border
        self.borderFocused = borderFocused
        self.divider = divider
    }
}

// MARK: - Hex Color Extension

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// A color that resolves to `light` or `dark` with the system appearance,
    /// without needing a SwiftUI environment. Works on iOS and macOS.
    static func dsDynamic(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
        #else
        return light
        #endif
    }
}
