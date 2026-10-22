import SwiftUI

// MARK: - Design System Tilt Card
// A glass card that leans in 3D toward the finger, with a specular sheen that
// tracks the lean — the Velvet reading of the "parallax / holographic card"
// that premium wallet, collectible and product UIs reach for. Press anywhere on
// the card and it tips toward the touch as if it were a physical card catching
// the light; let go and a spring floats it back to rest.
//
// It is a Velvet surface first: glass + the 1pt specular edge (never a border),
// a soft ambient shadow, DS springs for the motion and a soft haptic the instant
// the finger lands. The sheen is light moving *under* the glass — white, clipped
// to the card shape, fading to clear — not a stroke and not a fill. It honors
// Reduce Motion (the card rests flat and static, with no gesture) and Reduce
// Transparency (glass falls back to a solid surface, via `dsSurface`).
//
// Inspiration: the SwiftUI "interactive 3D / parallax card" pattern widely shared
// by the community — Hacking with Swift's drag-to-`rotation3DEffect` example and
// the light-following-touch variants (Design+Code, Codelaby). Rebuilt on Velvet
// tokens; no upstream code is reproduced.

public struct DSTiltCard<Content: View>: View {

    // MARK: Metrics

    /// Motion shaping with no spacing/radius/opacity token to borrow — the lean
    /// angle, its perspective and the sheen. Kept together and justified here the
    /// way `DSMotion` holds its own bounds, so the feel is frozen and consistent.
    private enum Metrics {
        /// Peak lean at a corner. ~12° reads as a lean into the light, not a flip —
        /// and matches the restraint of `DSMotion.driftDegrees`.
        static let maxTilt: Double = 12
        /// Shallow 3D perspective: the card tips like a flat object catching light,
        /// not like a door swinging open.
        static let perspective: CGFloat = 0.5
        /// Sheen spread, as a multiple of the card's longest edge.
        static let sheenRadiusScale: CGFloat = 0.9
        /// Brightest the sheen gets at a full-corner lean. Dimmer on dark glass,
        /// where white reads hotter — mirrors how the edge sweep in `DSMotion`
        /// lowers its peak in the dark. Tuned by eye; opacity has no token.
        static func sheenPeak(isDark: Bool) -> Double { isDark ? 0.18 : 0.32 }
        /// Floor on the sheen while touched, so a dead-centre press still glints.
        static let sheenFloor: Double = 0.4
    }

    // MARK: Configuration

    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let content: () -> Content

    // MARK: State

    /// Finger position in the card's own coordinate space, or `nil` at rest.
    /// Everything visual — the lean and the sheen — derives from this one value,
    /// so there is no second source of truth about where the card is pointing.
    @State private var touch: CGPoint?
    /// Measured card size, used to normalise the touch into `-1...1`.
    @State private var size: CGSize = .zero

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - padding: Inset around `content`. Defaults to `DSSpacing.md`.
    ///   - cornerRadius: Surface and sheen corner radius. Defaults to `DSRadius.card`.
    ///   - content: The card's contents.
    public init(
        padding: CGFloat = DSSpacing.md,
        cornerRadius: CGFloat = DSRadius.card,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content
    }

    // MARK: Body

    public var body: some View {
        if reduceMotion {
            // The lean *is* the component, so Reduce Motion drops it entirely and
            // leaves a plain resting glass card — no tilt, no sheen, no gesture.
            surface
        } else {
            surface
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(sheen)
                        .allowsHitTesting(false)
                }
                // Two composed rotations so the card leans *toward* the touch: the
                // vertical finger position drives the X-axis tilt, the horizontal
                // position the Y-axis tilt. (If the lean reads inverted on device,
                // flip the sign on one axis — it is purely which way "toward" points.)
                .rotation3DEffect(
                    .degrees(-Double(normalized.y) * Metrics.maxTilt),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: Metrics.perspective
                )
                .rotation3DEffect(
                    .degrees(Double(normalized.x) * Metrics.maxTilt),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: Metrics.perspective
                )
                // Snappy follow under the finger; a gentle spring floats it back to
                // flat on release. Keyed on `touch`, the one value both derive from.
                .animation(touch == nil ? DSAnimation.springGentle : DSAnimation.interactive, value: touch)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .gesture(tiltGesture)
        }
    }

    // MARK: Surface

    private var surface: some View {
        content()
            .padding(padding)
            .dsSurface(.glass, radius: cornerRadius)
            .dsShadow(.md)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { size = proxy.size }
                        .onChange(of: proxy.size) { _, newValue in size = newValue }
                }
            }
    }

    // MARK: Gesture

    private var tiltGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if touch == nil { DSHapticEngine.shared.fire(.soft) }
                touch = value.location
            }
            .onEnded { _ in touch = nil }
    }

    // MARK: Derived

    /// Whether the card is resting: no touch, or not yet measured.
    private var resting: Bool { touch == nil || size.width == 0 || size.height == 0 }

    /// Touch mapped to `-1...1` on each axis; `.zero` (flat) at rest.
    private var normalized: CGPoint {
        guard let touch, !resting else { return .zero }
        let nx = (touch.x / size.width) * 2 - 1
        let ny = (touch.y / size.height) * 2 - 1
        return CGPoint(x: clamp(nx), y: clamp(ny))
    }

    /// Specular highlight: white under the glass, centred on the finger, fading to
    /// clear. Brightens with the lean and vanishes at rest.
    private var sheen: RadialGradient {
        let center: UnitPoint = resting
            ? .center
            : UnitPoint(x: touch!.x / size.width, y: touch!.y / size.height)
        let magnitude = Double((normalized.x * normalized.x + normalized.y * normalized.y).squareRoot())
        let peak = Metrics.sheenPeak(isDark: theme.isDark)
        let opacity = resting ? 0 : peak * (Metrics.sheenFloor + (1 - Metrics.sheenFloor) * min(1, magnitude))
        let radius = max(size.width, size.height) * Metrics.sheenRadiusScale
        return RadialGradient(
            gradient: Gradient(colors: [Color.white.opacity(opacity), .clear]),
            center: center,
            startRadius: 0,
            endRadius: max(radius, 1)
        )
    }

    private func clamp(_ value: CGFloat) -> CGFloat { min(max(value, -1), 1) }
}

// MARK: - Preview

#if DEBUG
private struct DSTiltCardPreviewHost: View {
    @State private var theme = DSTheme()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                Text("Press and drag a card — it leans toward your finger.")
                    .ds(.callout, color: DSColors.textSecondary)

                // A loyalty / payment card over the gradient fill.
                DSTiltCard(padding: DSSpacing.lg) {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        HStack {
                            Text("VELVET").ds(.overline, color: theme.ink)
                            Spacer()
                            Image(systemName: "wave.3.right")
                                .foregroundStyle(theme.ink)
                        }
                        Text("4921  ••••  ••••  8317").ds(.numeric)
                        HStack {
                            VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                                Text("Card holder").ds(.caption2, color: DSColors.textTertiary)
                                Text("A. Rivera").ds(.footnote)
                            }
                            Spacer()
                            Text("1 248 pts").ds(.numeric, color: theme.ink)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // A stat card — proving arbitrary content works, not just "cards".
                DSTiltCard {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("This week").ds(.title3)
                        Text("1 248").ds(.displayMedium)
                        Text("4 sessions · 2 h 35 min")
                            .ds(.callout, color: DSColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Tilt Card — Light") {
    DSTiltCardPreviewHost().preferredColorScheme(.light)
}

#Preview("Tilt Card — Dark") {
    DSTiltCardPreviewHost().preferredColorScheme(.dark)
}
#endif
