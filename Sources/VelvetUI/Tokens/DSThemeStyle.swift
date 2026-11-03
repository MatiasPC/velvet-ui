import SwiftUI

// MARK: - Design System Theme Style
// The surface language of Velvet UI: frosted glass over a flat, neutral page
// tone. A style is a solid background plus four derived colors. Each slot has a
// fixed job so components never have to guess which one to use:
//
//   accent    → fills: primary CTA, toggle on, active page dot, rating
//   onAccent  → text/icons on top of `accent`               (≥ 4.5:1 on accent)
//   ink       → text, icons, links, focus glow on light glass (≥ 4.5:1 on the page tone)
//   inkDark   → same role on dark glass                      (≥ 4.5:1 on the dark page tone)
//
// Dark mode is NOT a second palette: the chosen `DSBackground` carries one
// light tone and one dark tone. No gradients, no washes, no dim layers.

public struct DSThemeStyle: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    /// The flat page tone the style sits on.
    public let background: DSBackground
    /// Fill for primary CTAs, toggles on, active indicators.
    public let accent: Color
    /// Text and icons on top of `accent`.
    public let onAccent: Color
    /// Text, icons, links and focus glows on light glass.
    public let ink: Color
    /// Same role as `ink`, for dark glass.
    public let inkDark: Color

    public init(
        id: String,
        name: String,
        background: DSBackground = .snow,
        accent: Color,
        onAccent: Color,
        ink: Color,
        inkDark: Color
    ) {
        self.id = id
        self.name = name
        self.background = background
        self.accent = accent
        self.onAccent = onAccent
        self.ink = ink
        self.inkDark = inkDark
    }

    /// Ink resolved for a color scheme.
    public func ink(for scheme: ColorScheme) -> Color {
        scheme == .dark ? inkDark : ink
    }
}

// MARK: - Built-in Styles

public extension DSThemeStyle {
    /// Coral on warm paper. The default: continuity with Velvet's original coral.
    static let sunset = DSThemeStyle(
        id: "sunset",
        name: "Sunset",
        background: .paper,
        accent: Color(hex: "FF7E5F"),
        onAccent: Color(hex: "2B1510"),
        ink: Color(hex: "C2361A"),
        inkDark: Color(hex: "FFA98F")
    )

    /// Violet on pure white and true black.
    static let aurora = DSThemeStyle(
        id: "aurora",
        name: "Aurora",
        background: .snow,
        accent: Color(hex: "7F5AF0"),
        onAccent: Color(hex: "FFFFFF"),
        ink: Color(hex: "6D47E6"),
        inkDark: Color(hex: "B9A3FF")
    )

    /// Teal on cool graphite.
    static let lagoon = DSThemeStyle(
        id: "lagoon",
        name: "Lagoon",
        background: .graphite,
        accent: Color(hex: "16F2B3"),
        onAccent: Color(hex: "06231D"),
        ink: Color(hex: "0A7382"),
        inkDark: Color(hex: "5EF5CB")
    )

    /// All built-in styles, in picker order.
    static let all: [DSThemeStyle] = [.sunset, .aurora, .lagoon]
}

// MARK: - Deprecated

@available(*, deprecated, renamed: "DSThemeStyle")
public typealias DSGradientTheme = DSThemeStyle
