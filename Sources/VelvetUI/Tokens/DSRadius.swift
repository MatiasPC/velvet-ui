import SwiftUI

// MARK: - Design System Corner Radius
// "Squircle-soft" shapes: continuous corners everywhere, pills for anything small.
// The numeric scale is the source of truth; the semantic aliases below say
// *where* each value goes so the hierarchy stays consistent across components.

public enum DSRadius {
    /// 4pt — Subtle rounding
    public static let xs: CGFloat = 4
    /// 8pt — Small rounding
    public static let sm: CGFloat = 8
    /// 12pt — Controls
    public static let md: CGFloat = 12
    /// 16pt — Nested surfaces
    public static let lg: CGFloat = 16
    /// 20pt — Cards
    public static let xl: CGFloat = 20
    /// 24pt — Hero cards, feature sections
    public static let xxl: CGFloat = 24
    /// 9999pt — Pill/capsule shape
    public static let pill: CGFloat = 9999

    // MARK: - Semantic aliases

    /// 20pt — First-level cards, sheets (DSCard, DSInteractiveCard, DSImageCard)
    public static let card: CGFloat = xl
    /// 16pt — Surfaces nested inside a card: toast, list group, empty-state container
    public static let surface: CGFloat = lg
    /// 12pt — Controls: buttons medium/large, inputs, code-field boxes
    public static let control: CGFloat = md
    /// Pill — Badges, tags, small buttons, search bar, segmented pill
    public static let chip: CGFloat = pill
}

// MARK: - Corner Radius Modifier

public extension View {
    /// Clip to a continuous rounded rectangle.
    func dsCornerRadius(_ radius: CGFloat) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Clip with a stroke. Velvet UI no longer draws borders — prefer
    /// `dsSurface(_:radius:)` (glass + edge) or `dsWashEdge(radius:)`.
    @available(*, deprecated, message: "Velvet UI doesn't draw borders. Use dsSurface(_:radius:) or dsWashEdge(radius:).")
    func dsCornerRadius(
        _ radius: CGFloat,
        strokeColor: Color?,
        strokeWidth: CGFloat = 1
    ) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(strokeColor ?? .clear, lineWidth: strokeWidth)
            )
    }
}
