import SwiftUI

// MARK: - Design System Colors
// Inspired by Airbnb's warmth and Opal's calm sophistication.
// Semantic naming ensures consistency across any app type.
// Uses programmatic colors — no asset catalog needed. Works everywhere.

public struct DSColors {

    // MARK: - Semantic Accessors (use defaultPalette)
    // These are convenience accessors. For themed apps, use DSTheme's palette instead.

    public static var primary: Color { defaultPalette.primary }
    public static var primaryVariant: Color { defaultPalette.primaryVariant }
    public static var secondary: Color { defaultPalette.secondary }
    public static var secondaryVariant: Color { defaultPalette.secondaryVariant }
    public static var tertiary: Color { defaultPalette.tertiary }

    public static var success: Color { defaultPalette.success }
    public static var warning: Color { defaultPalette.warning }
    public static var error: Color { defaultPalette.error }
    public static var info: Color { defaultPalette.info }

    public static var backgroundPrimary: Color { defaultPalette.backgroundPrimary }
    public static var backgroundSecondary: Color { defaultPalette.backgroundSecondary }
    public static var backgroundElevated: Color { defaultPalette.backgroundElevated }

    public static var textPrimary: Color { defaultPalette.textPrimary }
    public static var textSecondary: Color { defaultPalette.textSecondary }
    public static var textTertiary: Color { defaultPalette.textTertiary }
    public static var textOnPrimary: Color { defaultPalette.textOnPrimary }

    public static var border: Color { defaultPalette.border }
    public static var borderFocused: Color { defaultPalette.borderFocused }
    public static var divider: Color { defaultPalette.divider }

    // MARK: - Overlay

    public static let overlay = Color.black.opacity(0.4)
    public static let overlayLight = Color.black.opacity(0.15)
}

// MARK: - Default Palettes

public extension DSColors {
    /// Beautiful defaults out of the box — warm, professional, Airbnb-inspired
    static let defaultPalette = DSColorPalette(
        primary:             Color(hex: "FF385C"),   // Warm coral
        primaryVariant:      Color(hex: "E0294D"),
        secondary:           Color(hex: "5B5FEF"),   // Calm indigo
        secondaryVariant:    Color(hex: "4A4ED4"),
        tertiary:            Color(hex: "00BFA6"),   // Fresh teal
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
        borderFocused:       Color(hex: "FF385C"),
        divider:             Color(hex: "F3F4F6")
    )

    static let defaultDarkPalette = DSColorPalette(
        primary:             Color(hex: "FF6B81"),
        primaryVariant:      Color(hex: "FF385C"),
        secondary:           Color(hex: "818CF8"),
        secondaryVariant:    Color(hex: "5B5FEF"),
        tertiary:            Color(hex: "34D399"),
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
        borderFocused:       Color(hex: "FF6B81"),
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
}
