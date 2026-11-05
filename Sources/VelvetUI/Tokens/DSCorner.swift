import SwiftUI

// MARK: - Design System Corner
// How a shape rounds its corners: a fixed radius, or concentric with the
// container it sits in (Apple's corner concentricity, iOS / macOS 26).
//
// Concentric means the inner corner shares its centre with the container's
// corner: inner radius = container radius − distance to it. The gap between
// the two curves stays even all the way round.
//
//   • Containers publish their shape: every `dsSurface`, `DSCard` and
//     `dsContainer(radius:)` does it, and the system does it for sheets,
//     popovers and the device's own screen corners.
//   • A `.concentric(minimum:)` corner resolves against the nearest container.
//     Corners far from the container's corners — or when there is no
//     container — use `minimum`.
//   • Below iOS / macOS 26 a concentric corner is a fixed `minimum` corner, so
//     older systems look exactly like Velvet did before.

public enum DSCorner: Hashable, Sendable {
    /// Always this radius, whatever contains the shape.
    case fixed(CGFloat)
    /// Concentric with the container, never smaller than `minimum`.
    case concentric(minimum: CGFloat)

    /// The radius used where concentricity can't resolve: the fixed value, or
    /// the minimum of a concentric corner.
    public var fallbackRadius: CGFloat {
        switch self {
        case .fixed(let radius): return radius
        case .concentric(let minimum): return minimum
        }
    }

    public var isConcentric: Bool {
        if case .concentric = self { return true }
        return false
    }

    /// The shape to fill, clip or stroke. Concentric corners resolve when the
    /// shape is drawn, against the container above it.
    public var shape: AnyShape {
        if case .concentric(let minimum) = self, #available(iOS 26, macOS 26, *) {
            return AnyShape(ConcentricRectangle(corners: .concentric(minimum: .fixed(minimum))))
        }
        return AnyShape(RoundedRectangle(cornerRadius: fallbackRadius, style: .continuous))
    }

    // MARK: Semantic corners

    /// First-level cards: fixed `DSRadius.card` (20).
    public static let card = DSCorner.fixed(DSRadius.card)
    /// A surface nested inside a card: concentric, at least `DSRadius.surface` (16).
    public static let nestedSurface = DSCorner.concentric(minimum: DSRadius.surface)
    /// Buttons, inputs, selection highlights: concentric, at least `DSRadius.control` (12).
    public static let control = DSCorner.concentric(minimum: DSRadius.control)
    /// Pills: badges, chips, small buttons.
    public static let chip = DSCorner.fixed(DSRadius.chip)
}

// MARK: - Container

extension View {
    /// Publishes a fixed rounded rectangle as the container shape for
    /// concentric corners inside this view. No-op before iOS / macOS 26.
    @ViewBuilder
    func dsContainerShape(_ corner: DSCorner) -> some View {
        if case .fixed(let radius) = corner, #available(iOS 26, macOS 26, *) {
            containerShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            self
        }
    }
}

/// A stroke drawn inside `corner`'s shape. `strokeBorder` for fixed corners;
/// a concentric shape isn't insettable, so it strokes double width and clips
/// away the outer half.
struct DSInsideStroke<S: ShapeStyle>: View {
    let style: S
    let corner: DSCorner
    let lineWidth: CGFloat

    var body: some View {
        if corner.isConcentric {
            corner.shape
                .stroke(style, lineWidth: lineWidth * 2)
                .clipShape(corner.shape)
        } else {
            RoundedRectangle(cornerRadius: corner.fallbackRadius, style: .continuous)
                .strokeBorder(style, lineWidth: lineWidth)
        }
    }
}

public extension View {
    /// Makes this view the container for concentric corners inside it, with a
    /// continuous rounded rectangle of `radius`. Use it on custom containers;
    /// `dsSurface` and `DSCard` already do it. No-op before iOS / macOS 26.
    func dsContainer(radius: CGFloat) -> some View {
        dsContainerShape(.fixed(radius))
    }
}
