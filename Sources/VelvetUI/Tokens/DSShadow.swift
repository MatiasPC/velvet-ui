import SwiftUI

// MARK: - Design System Shadows & Elevation
// Soft, ambient shadows: large radius, low opacity. Depth without "windows".
// `.glow(tint)` is a colored shadow reserved for the primary CTA and toggles on —
// it makes the control feel like it emits light over the gradient backdrop.

public enum DSShadow: Equatable {
    case none
    /// Subtle lift — toggle knob, active segment
    case sm
    /// Default elevation — cards at rest
    case md
    /// Prominent elevation — interactive cards, toast, popovers
    case lg
    /// Maximum elevation — sheets, modals
    case xl
    /// Tinted glow — primary CTA, toggle on. Pass the theme accent.
    case glow(Color)

    /// Shadow color for light mode. Use `color(for:)` inside views.
    public var color: Color { color(for: .light) }

    public func color(for scheme: ColorScheme) -> Color {
        switch self {
        case .none: return .clear
        case .sm:   return .black.opacity(0.04)
        case .md:   return .black.opacity(0.06)
        case .lg:   return .black.opacity(0.08)
        case .xl:   return .black.opacity(0.10)
        case .glow(let tint): return tint.opacity(scheme == .dark ? 0.40 : 0.28)
        }
    }

    public var radius: CGFloat {
        switch self {
        case .none: return 0
        case .sm:   return 8
        case .md:   return 16
        case .lg:   return 24
        case .xl:   return 32
        case .glow: return 20
        }
    }

    public var y: CGFloat {
        switch self {
        case .none: return 0
        case .sm:   return 2
        case .md:   return 4
        case .lg:   return 8
        case .xl:   return 12
        case .glow: return 8
        }
    }
}

// MARK: - Shadow View Modifier

public struct DSShadowModifier: ViewModifier {
    let shadow: DSShadow
    @Environment(\.colorScheme) private var colorScheme

    public func body(content: Content) -> some View {
        content
            .shadow(color: shadow.color(for: colorScheme), radius: shadow.radius, x: 0, y: shadow.y)
    }
}

public extension View {
    /// Apply a Design System elevation shadow
    func dsShadow(_ shadow: DSShadow) -> some View {
        modifier(DSShadowModifier(shadow: shadow))
    }
}
