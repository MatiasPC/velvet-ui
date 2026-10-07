import SwiftUI

// MARK: - Design System Tilt Card
// A glass card that leans in 3D toward the touch, with a specular glare that
// rides the finger, then springs flat on release. The Velvet reading of the
// "parallax / hover" card: premium and tactile, built for a single hero or
// feature card the user is meant to play with — a product shot, a collectible,
// a highlighted plan.
//
// Pure SwiftUI. A drag gesture normalises the touch to -1...1 on each axis and
// feeds two `rotation3DEffect`s (X and Y) with perspective; a radial white
// highlight — the same specular language `DSBackdrop` and `DSWash.edge` already
// speak — rides the same normalised point. Motion is driven by explicit
// `withAnimation` (an interactive spring while the finger is down, a smooth
// spring back to rest), never an implicit `.animation(_:value:)`, so a theme
// crossfade never makes a resting card drift.
//
// Scroll-safe: the tilt rides a `simultaneousGesture`, so a card inside a
// `ScrollView` still scrolls. Under Reduce Motion the card renders flat and
// still — no gesture, no glare, no lift — so it degrades to a plain glass card.
// Reduce Transparency falls back through `dsSurface` to a solid fill, as
// everywhere else.

// MARK: - Metrics

/// Drawing constants, named so the feel is tunable in one place. Rotation is an
/// API parameter (`maxTilt`); everything here is the surface's own polish.
private enum Metrics {
    /// How much the card grows while held — a small lift; the 3D does the rest.
    static let liftScale: CGFloat = 1.03
    /// `rotation3DEffect` perspective. Lower is flatter and more subtle; 0.5
    /// reads as glass catching the light, not as a page starting to flip.
    static let perspective: CGFloat = 0.5
    /// Glare radius as a fraction of the card's longest edge.
    static let glareRadiusRatio: CGFloat = 0.9

    /// Peak glare opacity, by scheme. Mirrors the top-lit values of `DSWash.edge`
    /// so the sheen belongs to the same specular family as every other surface.
    static func glarePeak(dark: Bool) -> Double { dark ? 0.14 : 0.32 }
}

// MARK: - DSTiltCard

public struct DSTiltCard<Content: View>: View {
    let maxTilt: Double
    let padding: CGFloat
    let cornerRadius: CGFloat
    let haptics: Bool
    let content: () -> Content

    @State private var size: CGSize = .zero
    /// The touch, normalised to -1...1 on each axis (centre is `.zero`).
    @State private var touch: CGSize = .zero
    @State private var isActive = false

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - maxTilt: Peak rotation in degrees at each edge. 12 is a lively lean;
    ///     drop to ~6 for a subtler, more serious surface.
    ///   - padding: Inset around `content`. Defaults to `DSSpacing.lg`.
    ///   - cornerRadius: Card radius. Defaults to `DSRadius.card` (20).
    ///   - haptics: Fire a `.light` tap the moment the finger lands. Defaults to `true`.
    ///   - content: The card's contents.
    public init(
        maxTilt: Double = 12,
        padding: CGFloat = DSSpacing.lg,
        cornerRadius: CGFloat = DSRadius.card,
        haptics: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.maxTilt = maxTilt
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.haptics = haptics
        self.content = content
    }

    public var body: some View {
        if reduceMotion {
            surface
        } else {
            surface
                .overlay { glare }
                .scaleEffect(isActive ? Metrics.liftScale : 1)
                .rotation3DEffect(.degrees(rotationX), axis: (x: 1, y: 0, z: 0), perspective: Metrics.perspective)
                .rotation3DEffect(.degrees(rotationY), axis: (x: 0, y: 1, z: 0), perspective: Metrics.perspective)
                .dsShadow(isActive ? .lg : .md)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
                .simultaneousGesture(tiltGesture)
        }
    }

    // MARK: Surface

    private var surface: some View {
        content()
            .padding(padding)
            .dsSurface(.glass, radius: cornerRadius)
    }

    // MARK: Glare

    /// A radial white highlight centred on the touch, clipped to the card. Fixed
    /// peak; it fades in and out via `.opacity` so the sheen animates cleanly
    /// while its centre tracks the finger with the same spring as the tilt.
    private var glare: some View {
        let center = UnitPoint(x: (touch.width + 1) / 2, y: (touch.height + 1) / 2)
        let radius = max(size.width, size.height) * Metrics.glareRadiusRatio
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [.white.opacity(Metrics.glarePeak(dark: theme.isDark)), .clear],
                    center: center,
                    startRadius: 0,
                    endRadius: max(radius, 1)
                )
            )
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(false)
    }

    // MARK: Rotation

    // The surface leans into the touch: a finger near the bottom tips the bottom
    // edge forward, a finger to the right tips the right edge back.
    private var rotationX: Double { -touch.height * maxTilt }
    private var rotationY: Double {  touch.width * maxTilt }

    // MARK: Gesture

    private var tiltGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard size.width > 0, size.height > 0 else { return }
                let nx = clamp((value.location.x / size.width) * 2 - 1)
                let ny = clamp((value.location.y / size.height) * 2 - 1)
                if !isActive, haptics { DSHapticEngine.shared.fire(.light) }
                withAnimation(DSAnimation.interactive) {
                    isActive = true
                    touch = CGSize(width: nx, height: ny)
                }
            }
            .onEnded { _ in
                withAnimation(DSAnimation.springSmooth) {
                    isActive = false
                    touch = .zero
                }
            }
    }

    private func clamp(_ value: CGFloat) -> CGFloat { min(max(value, -1), 1) }
}

// MARK: - Preview

#if DEBUG
private struct DSTiltCardPreviewHost: View {
    @State private var theme = DSTheme()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                Text("Press and drag across a card").ds(.footnote, color: DSColors.textSecondary)

                DSTiltCard {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Velvet Pro").ds(.overline, color: DSColors.textSecondary)
                        Text("Lifetime access").ds(.title2)
                        Text("One payment. Every component, every theme, forever.")
                            .ds(.callout, color: DSColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSTiltCard(maxTilt: 6) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Subtler lean (maxTilt: 6)").ds(.title3)
                        Text("$1 248").ds(.displayMedium)
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
