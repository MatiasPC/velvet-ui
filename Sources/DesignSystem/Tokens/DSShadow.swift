import SwiftUI

// MARK: - Design System Shadows & Elevation
// Layered shadows create depth hierarchy.
// Subtle shadows are key to the Airbnb/Opal premium feel.

public enum DSShadow {
    case none
    /// Subtle lift — cards at rest
    case sm
    /// Default elevation — interactive cards, dropdowns
    case md
    /// Prominent elevation — modals, floating buttons
    case lg
    /// Maximum elevation — popovers, toasts
    case xl

    public var color: Color {
        switch self {
        case .none: return .clear
        case .sm:   return .black.opacity(0.04)
        case .md:   return .black.opacity(0.08)
        case .lg:   return .black.opacity(0.12)
        case .xl:   return .black.opacity(0.16)
        }
    }

    public var radius: CGFloat {
        switch self {
        case .none: return 0
        case .sm:   return 4
        case .md:   return 8
        case .lg:   return 16
        case .xl:   return 24
        }
    }

    public var y: CGFloat {
        switch self {
        case .none: return 0
        case .sm:   return 1
        case .md:   return 4
        case .lg:   return 8
        case .xl:   return 12
        }
    }
}

// MARK: - Shadow View Modifier

public struct DSShadowModifier: ViewModifier {
    let shadow: DSShadow

    public func body(content: Content) -> some View {
        content
            .shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
    }
}

public extension View {
    /// Apply a Design System elevation shadow
    func dsShadow(_ shadow: DSShadow) -> some View {
        modifier(DSShadowModifier(shadow: shadow))
    }
}
