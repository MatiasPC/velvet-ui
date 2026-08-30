import SwiftUI

// MARK: - Design System Confetti
// A celebratory confetti burst for success moments — task completed, purchase
// confirmed, streak extended, level unlocked. Attach it to any view and fire it
// by changing a trigger value; a shower of paper strips, discs and triangles
// erupts from an origin point, arcs up and outward, tumbles under gravity and
// fades as it falls. Built as a pure-SwiftUI particle system (TimelineView +
// Canvas) so it stays smooth even at high piece counts, and it only animates
// while a burst is on screen — no idle cost.
//
// Motion is analytic (each piece's position, spin and flutter are a closed-form
// function of elapsed time), which keeps it deterministic and lightweight.
// Colors come from the DS palette and a success haptic fires on each burst.
//
// Inspiration: pure-SwiftUI particle patterns from the community —
// Vortex (twostraws), Hacking with Swift "Special Effects with SwiftUI",
// and TimelineView + Canvas confetti write-ups.

// MARK: - Intensity

public enum DSConfettiIntensity: Sendable {
    /// A restrained sprinkle — subtle confirmations.
    case light
    /// A balanced burst — the default celebration.
    case medium
    /// A full, exuberant explosion — big wins.
    case festive

    var pieceCount: Int {
        switch self {
        case .light:   return 24
        case .medium:  return 45
        case .festive: return 80
        }
    }
}

// MARK: - Public Namespace

public enum DSConfetti {
    /// Vibrant default confetti palette drawn from the DS semantic colors.
    public static let defaultColors: [Color] = [
        DSColors.defaultPalette.primary,
        DSColors.defaultPalette.secondary,
        DSColors.defaultPalette.tertiary,
        DSColors.defaultPalette.warning,
        DSColors.defaultPalette.success,
        DSColors.defaultPalette.info
    ]
}

// MARK: - Piece Model

enum DSConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
}

/// One confetti particle. All fields are fixed at spawn; its on-screen
/// transform is derived analytically from elapsed time.
struct DSConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let shape: DSConfettiShape
    /// Launch direction in radians (screen coords; `-π/2` is straight up).
    let angle: Double
    /// Initial speed in points per second.
    let speed: Double
    /// Angular velocity in radians per second.
    let spin: Double
    /// Initial rotation in radians.
    let spinPhase: Double
    /// Horizontal sway amplitude in points (fluttering drift).
    let swayAmplitude: Double
    /// Sway frequency in radians per second.
    let swayFrequency: Double
    let swayPhase: Double
    /// Frequency of the edge-on "paper flip" in radians per second.
    let flutterFrequency: Double
    let size: CGFloat
    let lifetime: Double

    /// Longest a piece can live — used to schedule burst cleanup.
    static let maxLifetime: Double = 2.6
    /// Downward acceleration in points per second squared.
    static let gravity: Double = 1100

    static func makeBurst(count: Int, colors: [Color]) -> [DSConfettiPiece] {
        let palette = colors.isEmpty ? DSConfetti.defaultColors : colors
        let spread = 1.15 // ~66° cone on each side of straight up
        return (0..<count).map { _ in
            DSConfettiPiece(
                color: palette.randomElement() ?? DSColors.defaultPalette.primary,
                shape: DSConfettiShape.allCases.randomElement() ?? .rectangle,
                angle: -.pi / 2 + Double.random(in: -spread...spread),
                speed: Double.random(in: 320...760),
                spin: Double.random(in: 3...9) * (Bool.random() ? 1 : -1),
                spinPhase: Double.random(in: 0...(2 * .pi)),
                swayAmplitude: Double.random(in: 6...18),
                swayFrequency: Double.random(in: 3...6),
                swayPhase: Double.random(in: 0...(2 * .pi)),
                flutterFrequency: Double.random(in: 4...8),
                size: CGFloat.random(in: 7...12),
                lifetime: Double.random(in: 1.6...maxLifetime)
            )
        }
    }
}

// MARK: - Burst Model

/// A single fired burst: a set of pieces launched from `origin` at `start`.
/// Multiple bursts can overlap freely.
struct DSConfettiBurst: Identifiable {
    let id = UUID()
    let pieces: [DSConfettiPiece]
    let origin: UnitPoint
    let start: Date
}

// MARK: - Burst Renderer

struct DSConfettiBurstView: View {
    let burst: DSConfettiBurst

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(burst.start)
                guard elapsed >= 0 else { return }
                let launch = CGPoint(
                    x: size.width * burst.origin.x,
                    y: size.height * burst.origin.y
                )
                for piece in burst.pieces {
                    draw(piece, at: elapsed, launch: launch, in: context)
                }
            }
        }
    }

    /// Render one piece at time `t`. Copies the context so each piece gets an
    /// isolated transform without disturbing the others.
    private func draw(_ piece: DSConfettiPiece, at t: Double, launch: CGPoint, in context: GraphicsContext) {
        guard t <= piece.lifetime else { return }

        let vx = cos(piece.angle) * piece.speed
        let vy = sin(piece.angle) * piece.speed
        let sway = piece.swayAmplitude * sin(t * piece.swayFrequency + piece.swayPhase)
        let x = launch.x + vx * t + sway
        let y = launch.y + vy * t + 0.5 * DSConfettiPiece.gravity * t * t
        let rotation = piece.spinPhase + piece.spin * t
        let flutter = abs(cos(t * piece.flutterFrequency))
        let fadeWindow = piece.lifetime * 0.35
        let fade = max(0, min(1, (piece.lifetime - t) / fadeWindow))

        var layer = context
        layer.opacity = fade
        layer.translateBy(x: x, y: y)
        layer.rotate(by: .radians(rotation))
        layer.scaleBy(x: max(0.15, flutter), y: 1) // edge-on paper flip
        layer.fill(path(for: piece), with: .color(piece.color))
    }

    private func path(for piece: DSConfettiPiece) -> Path {
        let s = piece.size
        switch piece.shape {
        case .rectangle:
            let rect = CGRect(x: -s / 2, y: -s * 0.3, width: s, height: s * 0.6)
            return Path(roundedRect: rect, cornerRadius: s * 0.15)
        case .circle:
            return Path(ellipseIn: CGRect(x: -s / 2, y: -s / 2, width: s, height: s))
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: 0, y: -s / 2))
            path.addLine(to: CGPoint(x: s / 2, y: s / 2))
            path.addLine(to: CGPoint(x: -s / 2, y: s / 2))
            path.closeSubpath()
            return path
        }
    }
}

// MARK: - Modifier

struct DSConfettiModifier<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let intensity: DSConfettiIntensity
    let colors: [Color]
    let origin: UnitPoint
    let haptics: Bool

    @State private var bursts: [DSConfettiBurst] = []

    func body(content: Content) -> some View {
        content.overlay {
            ZStack {
                ForEach(bursts) { burst in
                    DSConfettiBurstView(burst: burst)
                }
            }
            .allowsHitTesting(false)
        }
        .onChange(of: trigger) { _, _ in
            fire()
        }
    }

    private func fire() {
        let burst = DSConfettiBurst(
            pieces: DSConfettiPiece.makeBurst(count: intensity.pieceCount, colors: colors),
            origin: origin,
            start: Date()
        )
        if haptics {
            DSHapticEngine.shared.fire(.success)
        }
        bursts.append(burst)

        // Retire the burst once its last piece has faded, so the TimelineView
        // stops redrawing when nothing is on screen.
        let ttl = DSConfettiPiece.maxLifetime + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + ttl) {
            bursts.removeAll { $0.id == burst.id }
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Fire a confetti burst whenever `trigger` changes.
    ///
    /// Attach to any view — the confetti is drawn in a non-interactive overlay
    /// that fills the view's bounds, so taps pass straight through to your UI.
    ///
    /// ```swift
    /// @State private var celebrations = 0
    ///
    /// VStack {
    ///     DSButton("Complete") { celebrations += 1 }
    /// }
    /// .dsConfetti(trigger: celebrations, intensity: .festive)
    /// ```
    ///
    /// - Parameters:
    ///   - trigger: Any `Equatable` value; each change fires a fresh burst.
    ///     Increment an `Int` or toggle a `Bool` to celebrate on demand.
    ///   - intensity: How many pieces the burst emits. Defaults to `.medium`.
    ///   - colors: Confetti colors. Defaults to the vibrant DS palette.
    ///   - origin: Where the burst launches from, in unit space. Defaults to
    ///     `.center`. Use e.g. `.top` to rain from above.
    ///   - haptics: Whether to fire a success haptic on each burst. Defaults to `true`.
    func dsConfetti<Trigger: Equatable>(
        trigger: Trigger,
        intensity: DSConfettiIntensity = .medium,
        colors: [Color] = DSConfetti.defaultColors,
        origin: UnitPoint = .center,
        haptics: Bool = true
    ) -> some View {
        modifier(
            DSConfettiModifier(
                trigger: trigger,
                intensity: intensity,
                colors: colors,
                origin: origin,
                haptics: haptics
            )
        )
    }
}

// MARK: - Preview

#Preview {
    struct ConfettiPreview: View {
        @State private var celebrate = 0

        var body: some View {
            ZStack {
                DSColors.defaultPalette.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: DSSpacing.lg) {
                    Text("🎉").font(.system(size: 72))
                    Text("Nice work!").ds(.title1)
                    Text("Tap to celebrate")
                        .ds(.callout, color: DSColors.defaultPalette.textSecondary)

                    DSButton("Celebrate", icon: "party.popper") {
                        celebrate += 1
                    }
                    .padding(.top, DSSpacing.sm)
                }
                .padding(DSSpacing.xxl)
            }
            .dsConfetti(trigger: celebrate, intensity: .festive)
        }
    }

    return Group {
        ConfettiPreview()
            .preferredColorScheme(.light)
        ConfettiPreview()
            .preferredColorScheme(.dark)
    }
}
