import SwiftUI

// MARK: - Design System Confetti
// A one-shot celebration burst: `.dsConfetti(trigger:)` throws paper from a
// point, gravity and air drag bring it down, and it tumbles as it falls.
//
// Same approach as `DSParticleField`: one `Canvas`, and positions that are
// *computed* from each piece's birth state at any instant, never accumulated.
// The draw closure is therefore pure. The timeline sleeps once the burst is
// over, so nothing ticks while idle.
//
// Closed-form motion. With drag `k` and gravity `g` (y grows downward):
//     v(t) = g/k + (v0 - g/k) * e^(-kt)
//     p(t) = (g/k) * t + (v0 - g/k) * (1 - e^(-kt)) / k
// Pieces first fly out along v0, slow down, then settle into a drifting fall
// at terminal velocity g/k, which is what paper looks like.

// MARK: - Metrics

private enum Metrics {
    /// Upper bound for `count`; more than this stops reading as confetti and
    /// starts costing frames.
    static let maxCount: Int = 150

    static let lifetimeRange: ClosedRange<Double> = 1.6...2.4
    /// Pieces leave over this window instead of all on one frame.
    static let maxLaunchDelay: Double = 0.08
    /// Fraction of life at the end spent fading out.
    static let fadeFraction: Double = 0.3

    /// Launch speed in points per second.
    static let speedRange: ClosedRange<Double> = 380...820
    /// Half-width of the fan, in radians, around straight up.
    static let fanHalfAngle: Double = 1.25
    /// Downward acceleration (points per second squared).
    static let gravity: Double = 760
    /// Exponential velocity decay per second.
    static let drag: Double = 2.4

    /// Rotation rate in radians per second (either direction).
    static let spinRange: ClosedRange<Double> = 2...9
    /// Flutter (the cos() squash) rate in radians per second.
    static let flutterRange: ClosedRange<Double> = 5...12
    /// Smallest vertical scale while a piece is edge-on, so it never vanishes.
    static let minFlutter: Double = 0.12

    /// Piece width range, from spacing tokens.
    static let widthRange: ClosedRange<Double> = Double(DSSpacing.xs)...Double(DSSpacing.sm)
    /// Height of a rectangular piece relative to its width.
    static let aspect: Double = 0.55
    static let cornerRadius: CGFloat = DSSpacing.xxxs
    /// Share of pieces drawn as circles.
    static let circleShare: Double = 0.3

    /// How far the "light" tints are mixed toward white.
    static let tintAmount: Double = 0.45
}

// MARK: - Seeded generator

/// SplitMix64: tiny, fast and deterministic, so a seed reproduces a burst.
struct DSSplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

// MARK: - Piece

enum DSConfettiShape: Sendable { case rectangle, circle }

/// One piece of paper. Everything needed to evaluate it at any instant is fixed
/// at birth.
struct DSConfettiPiece: Equatable, Sendable {
    var delay: Double
    var lifetime: Double
    var velocity: CGVector
    var size: CGSize
    var shape: DSConfettiShape
    var colorIndex: Int
    var rotation0: Double
    var spin: Double
    var flutterPhase: Double
    var flutterRate: Double

    /// Alive between `delay` and `delay + lifetime`.
    func isAlive(at time: Double) -> Bool {
        time >= delay && time - delay < lifetime
    }

    /// Offset from the burst origin, in closed form.
    func offset(at time: Double) -> CGPoint {
        let t = max(time - delay, 0)
        let k = Metrics.drag
        let terminal = Metrics.gravity / k
        let decay = (1 - exp(-k * t)) / k
        return CGPoint(
            x: CGFloat(velocity.dx * decay),
            y: CGFloat(terminal * t + (velocity.dy - terminal) * decay)
        )
    }

    /// 1 for the first 70% of life, then a linear fade to exactly 0.
    func opacity(at time: Double) -> Double {
        let unit = (time - delay) / lifetime
        guard unit > 0 else { return 0 }
        guard unit < 1 else { return 0 }
        let fadeStart = 1 - Metrics.fadeFraction
        return unit <= fadeStart ? 1 : (1 - unit) / Metrics.fadeFraction
    }

    /// In-plane rotation in radians.
    func rotation(at time: Double) -> Double {
        rotation0 + spin * max(time - delay, 0)
    }

    /// Vertical squash for the 3D tumble: |cos| of the flutter angle, floored.
    func flutter(at time: Double) -> Double {
        let angle = flutterPhase + flutterRate * max(time - delay, 0)
        return max(abs(cos(angle)), Metrics.minFlutter)
    }
}

// MARK: - Burst

enum DSConfettiBurst {
    /// Longest any piece can live, including its launch delay.
    static let maxDuration: Double = Metrics.lifetimeRange.upperBound + Metrics.maxLaunchDelay

    /// `count` limited to `0...150`.
    static func clampedCount(_ count: Int) -> Int {
        min(max(count, 0), Metrics.maxCount)
    }

    /// Builds a burst. The same `seed` always yields the same pieces.
    /// `colorCount` is how many theme colors the pieces pick from.
    static func pieces(count: Int, seed: UInt64, colorCount: Int = 1) -> [DSConfettiPiece] {
        var rng = DSSplitMix64(seed: seed)
        let colors = max(colorCount, 1)
        return (0..<clampedCount(count)).map { _ in
            // Angle 0 is straight up; the fan spreads either side of it.
            let angle = Double.random(in: -Metrics.fanHalfAngle...Metrics.fanHalfAngle, using: &rng)
            let speed = Double.random(in: Metrics.speedRange, using: &rng)
            let width = Double.random(in: Metrics.widthRange, using: &rng)
            let isCircle = Double.random(in: 0..<1, using: &rng) < Metrics.circleShare
            let direction: Double = Bool.random(using: &rng) ? 1 : -1
            return DSConfettiPiece(
                delay: Double.random(in: 0...Metrics.maxLaunchDelay, using: &rng),
                lifetime: Double.random(in: Metrics.lifetimeRange, using: &rng),
                velocity: CGVector(dx: sin(angle) * speed, dy: -cos(angle) * speed),
                size: isCircle
                    ? CGSize(width: width * Metrics.aspect * 1.4, height: width * Metrics.aspect * 1.4)
                    : CGSize(width: width, height: width * Metrics.aspect),
                shape: isCircle ? .circle : .rectangle,
                colorIndex: Int.random(in: 0..<colors, using: &rng),
                rotation0: Double.random(in: 0..<(2 * .pi), using: &rng),
                spin: direction * Double.random(in: Metrics.spinRange, using: &rng),
                flutterPhase: Double.random(in: 0..<(2 * .pi), using: &rng),
                flutterRate: Double.random(in: Metrics.flutterRange, using: &rng)
            )
        }
    }

    /// True while any piece still has life left at `time`.
    static func isAlive(_ pieces: [DSConfettiPiece], at time: Double) -> Bool {
        pieces.contains { time < $0.delay + $0.lifetime }
    }
}

// MARK: - Modifier

private struct LiveBurst: Sendable {
    let start: TimeInterval
    let pieces: [DSConfettiPiece]
}

private struct DSConfettiModifier<T: Equatable>: ViewModifier {
    let trigger: T
    let origin: UnitPoint
    let count: Int
    let haptic: DSHapticStyle?

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bursts: [LiveBurst] = []
    @State private var generation = 0

    func body(content: Content) -> some View {
        let colors = palette()
        content
            .overlay {
                TimelineView(.animation(paused: bursts.isEmpty)) { timeline in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { context, size in
                        let anchor = CGPoint(x: size.width * origin.x, y: size.height * origin.y)
                        for burst in bursts {
                            let time = now - burst.start
                            for piece in burst.pieces where piece.isAlive(at: time) {
                                draw(piece, at: time, anchor: anchor, colors: colors, in: context)
                            }
                        }
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .onChange(of: trigger) { _, _ in fire(colorCount: colors.count) }
            .task(id: generation) {
                guard generation > 0 else { return }
                try? await Task.sleep(for: .seconds(DSConfettiBurst.maxDuration + 0.1))
                guard !Task.isCancelled else { return }
                bursts = []
            }
    }

    private func fire(colorCount: Int) {
        // The haptic is the tactile half of the celebration; it still lands
        // under Reduce Motion, where the visual half is removed.
        if let haptic { DSHapticEngine.shared.fire(haptic) }
        guard !reduceMotion else { return }
        let burst = LiveBurst(
            start: Date.now.timeIntervalSinceReferenceDate,
            pieces: DSConfettiBurst.pieces(count: count, seed: .random(in: .min ... .max), colorCount: colorCount)
        )
        bursts.append(burst)
        generation += 1
    }

    /// Theme accent, gradient stops and lighter tints of each, plus the theme ink:
    /// pieces in the gradient's own colors vanish against the backdrop, the ink
    /// gives the burst contrast on every theme.
    private func palette() -> [Color] {
        let base = [theme.accent] + theme.gradient.stops
        return base + [theme.ink, theme.ink] + base.map { $0.mix(with: .white, by: Metrics.tintAmount) }
    }

    private func draw(
        _ piece: DSConfettiPiece,
        at time: Double,
        anchor: CGPoint,
        colors: [Color],
        in context: GraphicsContext
    ) {
        let alpha = piece.opacity(at: time)
        guard alpha > 0, !colors.isEmpty else { return }
        let offset = piece.offset(at: time)
        var layer = context
        layer.opacity = alpha
        layer.translateBy(x: anchor.x + offset.x, y: anchor.y + offset.y)
        layer.rotate(by: .radians(piece.rotation(at: time)))
        layer.scaleBy(x: 1, y: piece.flutter(at: time))
        let rect = CGRect(
            x: -piece.size.width / 2,
            y: -piece.size.height / 2,
            width: piece.size.width,
            height: piece.size.height
        )
        let path = piece.shape == .circle
            ? Path(ellipseIn: rect)
            : Path(roundedRect: rect, cornerRadius: Metrics.cornerRadius)
        layer.fill(path, with: .color(colors[piece.colorIndex % colors.count]))
    }
}

// MARK: - API

public extension View {
    /// Fires one burst of confetti from `origin` every time `trigger` changes.
    ///
    /// Decorative: it ignores touches, is hidden from VoiceOver, and draws no
    /// pieces under Reduce Motion. Attach it to a container that covers the area
    /// you want the paper to fall through (the screen root, say) and give
    /// `origin` in that container's unit space.
    ///
    /// - Parameters:
    ///   - trigger: A value that changes when the celebration should happen.
    ///   - origin: Where the burst starts, as a point in the view's bounds.
    ///   - count: Number of pieces, limited to 150.
    ///   - haptic: Fired on the burst. `nil` by default, because the action that
    ///     triggers confetti usually has its own haptic.
    func dsConfetti<T: Equatable>(
        trigger: T,
        origin: UnitPoint = .center,
        count: Int = 80,
        haptic: DSHapticStyle? = nil
    ) -> some View {
        modifier(DSConfettiModifier(trigger: trigger, origin: origin, count: count, haptic: haptic))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSConfettiPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var celebrations = 0

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            DSPreviewThemeDots(theme: theme)
            Spacer()
            DSCard {
                VStack(spacing: DSSpacing.md) {
                    Image(systemName: "party.popper.fill")
                        .dsFont(.displayMedium)
                    Text("You did it").ds(.title2)
                    DSButton("Celebrate", icon: "sparkles") { celebrations += 1 }
                }
                .frame(maxWidth: .infinity)
            }
            Spacer()
        }
        .dsScreenPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsConfetti(trigger: celebrations, origin: UnitPoint(x: 0.5, y: 0.55))
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Confetti — Light") {
    DSConfettiPreviewHost().preferredColorScheme(.light)
}

#Preview("Confetti — Dark") {
    DSConfettiPreviewHost().preferredColorScheme(.dark)
}
#endif
