import SwiftUI

// MARK: - Design System Surface
// Frosted-glass surfaces, from most transparent to opaque. Apply with
// `.dsSurface(_:radius:)`: it fills with the material, clips to a continuous
// rounded rect and draws the specular edge highlight (`DSWash.edge`) — no border.
//
// Default for cards is `.glass` (thinMaterial), NOT `.glassThin`: over a
// saturated gradient, ultraThin lets too much color through and secondary text
// loses contrast. Keep `.glassThin` for small floating elements.
//
// Falls back to `.solid` automatically when the user enables
// "Reduce Transparency".

public enum DSSurface: Sendable {
    /// ultraThinMaterial — chips, badges, toolbars, toast, page-control track
    case glassThin
    /// thinMaterial — cards (default), list groups, inputs, segmented track
    case glass
    /// regularMaterial — sheets, modals, popovers
    case glassThick
    /// backgroundElevated — fallback when there is no backdrop / reduced transparency
    case solid

    var material: Material? {
        switch self {
        case .glassThin:  return .ultraThinMaterial
        case .glass:      return .thinMaterial
        case .glassThick: return .regularMaterial
        case .solid:      return nil
        }
    }
}

// MARK: - Modifier

public struct DSSurfaceModifier: ViewModifier {
    let level: DSSurface
    let radius: CGFloat
    let edge: Bool

    @DSThemed private var theme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background {
                if let material = level.material, !reduceTransparency {
                    shape.fill(material)
                } else {
                    shape.fill(theme.palette.backgroundElevated)
                }
            }
            .clipShape(shape)
            .overlay {
                if edge {
                    shape.strokeBorder(theme.washEdge, lineWidth: DSWash.edgeWidth)
                }
            }
    }
}

public extension View {
    /// Frosted-glass surface with continuous corners and a specular edge highlight.
    /// - Parameters:
    ///   - level: How opaque the glass is. Cards use `.glass`.
    ///   - radius: Corner radius. Defaults to `DSRadius.card` (20).
    ///   - edge: Draw the 1pt `DSWash.edge` highlight. Defaults to `true`.
    func dsSurface(
        _ level: DSSurface = .glass,
        radius: CGFloat = DSRadius.card,
        edge: Bool = true
    ) -> some View {
        modifier(DSSurfaceModifier(level: level, radius: radius, edge: edge))
    }
}
