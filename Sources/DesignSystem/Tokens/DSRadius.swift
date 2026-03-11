import SwiftUI

// MARK: - Design System Corner Radius
// Soft, modern corners give apps a premium feel.
// Consistent radius creates visual harmony.

public enum DSRadius {
    /// 4pt — Subtle rounding (tags, small chips)
    public static let xs: CGFloat = 4
    /// 8pt — Default rounding (buttons, inputs)
    public static let sm: CGFloat = 8
    /// 12pt — Cards, containers
    public static let md: CGFloat = 12
    /// 16pt — Prominent cards, bottom sheets
    public static let lg: CGFloat = 16
    /// 20pt — Large cards, modals
    public static let xl: CGFloat = 20
    /// 24pt — Hero cards, feature sections
    public static let xxl: CGFloat = 24
    /// 9999pt — Pill/capsule shape
    public static let pill: CGFloat = 9999
}

// MARK: - Corner Radius Modifier

public extension View {
    /// Apply Design System corner radius with optional stroke
    func dsCornerRadius(
        _ radius: CGFloat,
        strokeColor: Color? = nil,
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
