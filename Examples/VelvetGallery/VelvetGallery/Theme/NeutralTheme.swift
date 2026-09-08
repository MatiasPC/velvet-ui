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
