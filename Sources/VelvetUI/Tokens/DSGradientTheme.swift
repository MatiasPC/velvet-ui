import SwiftUI

// MARK: - Design System Gradient Theme
// The surface language of Velvet UI since v0.2: frosted glass over a saturated,
// user-selectable gradient (Arc-inspired, translated to native SwiftUI).
// A theme is a background gradient plus four derived colors. Each slot has a
// fixed job so components never have to guess which one to use:
//
//   accent    → fills: primary CTA, toggle on, active page dot, rating
//   onAccent  → text/icons on top of `accent`               (≥ 4.5:1 on accent)
//   ink       → text, icons, links, focus glow on light glass (≥ 4.5:1 on white)
//   inkDark   → same role on dark glass                      (≥ 4.5:1 on #1A1A2E)
//
// Dark mode is NOT a second palette: `DSBackdrop` draws the same gradient and
// dims it with `darkDim` black on top. One knob, hue preserved.

public struct DSGradientTheme: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    /// Background gradient stops, drawn topLeading → bottomTrailing by `DSBackdrop`.
    public let stops: [Color]
    /// Fill for primary CTAs, toggles on, active indicators. Usually the vivid first stop.
    public let accent: Color
    /// Text and icons on top of `accent`.
    public let onAccent: Color
    /// Text, icons, links and focus glows on light glass.
    public let ink: Color
    /// Same role as `ink`, for dark glass.
    public let inkDark: Color
    /// White overlay on the gradient in light mode (0 = raw gradient).
    public let lightWash: Double
    /// Black overlay on the gradient in dark mode.
    public let darkDim: Double

    public init(
        id: String,
        name: String,
        stops: [Color],
        accent: Color,
        onAccent: Color,
        ink: Color,
        inkDark: Color,
        lightWash: Double = 0.08,
        darkDim: Double = 0.58
    ) {
        self.id = id
        self.name = name
        self.stops = stops
        self.accent = accent
        self.onAccent = onAccent
        self.ink = ink
        self.inkDark = inkDark
        self.lightWash = lightWash
        self.darkDim = darkDim
    }

    /// Ink resolved for a color scheme.
    public func ink(for scheme: ColorScheme) -> Color {
        scheme == .dark ? inkDark : ink
    }

    /// The background gradient, topLeading → bottomTrailing.
    public var linearGradient: LinearGradient {
        LinearGradient(colors: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Horizontal version of the gradient — progress bars, decorative fills.
    public var horizontalGradient: LinearGradient {
        LinearGradient(colors: stops, startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Built-in Themes

public extension DSGradientTheme {
    /// Peach → coral. The default: continuity with Velvet's original coral.
    static let sunset = DSGradientTheme(
        id: "sunset",
        name: "Sunset",
        stops: [Color(hex: "FF7E5F"), Color(hex: "FEB47B")],
        accent: Color(hex: "FF7E5F"),
        onAccent: Color(hex: "2B1510"),
        ink: Color(hex: "C2361A"),
        inkDark: Color(hex: "FFA98F")
    )

    /// Violet → fuchsia.
    static let aurora = DSGradientTheme(
        id: "aurora",
        name: "Aurora",
        stops: [Color(hex: "7F5AF0"), Color(hex: "E84393")],
        accent: Color(hex: "7F5AF0"),
        onAccent: Color(hex: "FFFFFF"),
        ink: Color(hex: "6D47E6"),
        inkDark: Color(hex: "B9A3FF")
    )

    /// Mint → cyan.
    static let lagoon = DSGradientTheme(
        id: "lagoon",
        name: "Lagoon",
        stops: [Color(hex: "16F2B3"), Color(hex: "0DB4F7")],
        accent: Color(hex: "16F2B3"),
        onAccent: Color(hex: "06231D"),
        ink: Color(hex: "0B7D8C"),
        inkDark: Color(hex: "5EF5CB")
    )

    /// All built-in themes, in picker order.
    static let all: [DSGradientTheme] = [.sunset, .aurora, .lagoon]
}
