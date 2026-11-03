import SwiftUI
import VelvetUI

extension DSThemeStyle {
    /// Gallery-only style: graphite accent that adapts to light/dark, on the
    /// plain snow page tone. The gallery itself paints `backgroundPrimary`;
    /// stages use the style's solid background.
    static let neutral = DSThemeStyle(
        id: "neutral",
        name: "Neutral",
        background: .snow,
        accent: .dsDynamic(light: Color(hex: "1F2225"), dark: Color(hex: "EDEEF0")),
        onAccent: .dsDynamic(light: Color(hex: "FFFFFF"), dark: Color(hex: "16181A")),
        ink: Color(hex: "2A2D30"),
        inkDark: Color(hex: "E6E7E9")
    )
}
