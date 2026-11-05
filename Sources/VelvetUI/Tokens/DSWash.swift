import SwiftUI

// MARK: - Design System Wash
// Velvet UI never draws borders. When two surfaces need separating, use a
// translucent white *wash*; when glass needs definition, use the *edge*
// highlight; when an input needs focus, use a diffuse *glow* of the theme ink.

public enum DSWash {
    /// Width of the specular edge highlight.
    public static let edgeWidth: CGFloat = 1

    /// Flat translucent fill (no blur — cheap). Separates a surface inside another:
    /// input inside a card, toggle track off, selected cell, flat card.
    public static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.45)
    }

    /// Specular edge: top-lit 1pt highlight that fades toward the bottom.
    /// Drawn inside the shape with `strokeBorder`, so it never changes layout.
    public static func edge(for scheme: ColorScheme) -> LinearGradient {
        let top: Double = scheme == .dark ? 0.18 : 0.55
        let bottom: Double = scheme == .dark ? 0.02 : 0.05
        return LinearGradient(
            colors: [Color.white.opacity(top), Color.white.opacity(bottom)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: Focus glow

    public static let focusOpacity: Double = 0.35
    public static let focusWidth: CGFloat = 2
    public static let focusBlur: CGFloat = 1.5
}

// MARK: - Modifiers

public struct DSWashEdgeModifier: ViewModifier {
    let corner: DSCorner
    @DSThemed private var theme

    public func body(content: Content) -> some View {
        content.overlay(
            DSInsideStroke(style: theme.washEdge, corner: corner, lineWidth: DSWash.edgeWidth)
        )
    }
}

public struct DSFocusGlowModifier: ViewModifier {
    let color: Color
    let corner: DSCorner
    let isActive: Bool

    public func body(content: Content) -> some View {
        content.overlay(
            DSInsideStroke(style: color.opacity(isActive ? DSWash.focusOpacity : 0), corner: corner, lineWidth: DSWash.focusWidth)
                .blur(radius: DSWash.focusBlur)
                .allowsHitTesting(false)
        )
        .animation(DSAnimation.micro, value: isActive)
    }
}

public extension View {
    /// Specular edge highlight on a rounded surface (the border replacement).
    func dsWashEdge(radius: CGFloat) -> some View {
        modifier(DSWashEdgeModifier(corner: .fixed(radius)))
    }

    /// Specular edge highlight that follows `corner` (fixed or concentric).
    func dsWashEdge(corner: DSCorner) -> some View {
        modifier(DSWashEdgeModifier(corner: corner))
    }

    /// Diffuse focus glow in the given color (the focus-ring replacement).
    /// Pass the theme ink (`theme.ink`) or a status color (error/success).
    func dsFocusGlow(_ color: Color, radius: CGFloat, isActive: Bool) -> some View {
        modifier(DSFocusGlowModifier(color: color, corner: .fixed(radius), isActive: isActive))
    }

    /// Diffuse focus glow that follows `corner` (fixed or concentric).
    func dsFocusGlow(_ color: Color, corner: DSCorner, isActive: Bool) -> some View {
        modifier(DSFocusGlowModifier(color: color, corner: corner, isActive: isActive))
    }
}
