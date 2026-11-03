import SwiftUI

// MARK: - Design System Background
// A flat page background. Velvet deliberately ships no background gradients:
// every screen sits on one solid tone per color scheme. The tones are neutral
// by design — warm, pure and cool — so the accent is the only color on screen.

public struct DSBackground: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    /// Page tone in light mode.
    public let light: Color
    /// Page tone in dark mode.
    public let dark: Color

    public init(id: String, name: String, light: Color, dark: Color) {
        self.id = id
        self.name = name
        self.light = light
        self.dark = dark
    }

    /// The page tone for a color scheme.
    public func color(for scheme: ColorScheme) -> Color {
        scheme == .dark ? dark : light
    }
}

// MARK: - Built-in Backgrounds

public extension DSBackground {
    /// True white in light mode, true black in dark mode.
    static let snow = DSBackground(
        id: "snow",
        name: "Snow",
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "000000")
    )

    /// Warm off-white and warm black — pairs with coral and amber accents.
    static let paper = DSBackground(
        id: "paper",
        name: "Paper",
        light: Color(hex: "FAF8F4"),
        dark: Color(hex: "121110")
    )

    /// Cool light grey and deep graphite — pairs with violet and teal accents.
    static let graphite = DSBackground(
        id: "graphite",
        name: "Graphite",
        light: Color(hex: "F0F0F2"),
        dark: Color(hex: "1B1C1E")
    )

    /// All built-in backgrounds, in picker order.
    static let all: [DSBackground] = [.snow, .paper, .graphite]
}
