import SwiftUI

// MARK: - Design System Particle Field
// A small cloud of light motes born around a moving point — the finger during a
// drag — that live for under a second and fade out. It is the "around the
// finger" companion to the `DSMotion` primitives: those decorate a view, this
// one decorates a *gesture*.
//
// Two things make it cheap enough to run underneath a live drag:
//
// 1. **One `Canvas`, not N views.** Every particle is a value in a fixed ring
//    buffer, drawn in a single pass. Nothing enters or leaves the view tree
//    while the finger is down, so there is no layout work mid-gesture.
// 2. **Analytic positions.** A particle's position at any instant is *computed*
//    from its birth state, never accumulated frame by frame. The draw closure
//    is therefore pure — it reads state and never mutates it, which is also the
//    only way `Canvas` is legal to use.
//
// Internal on purpose: `CLAUDE.md` requires a component to prove itself in a
// real app before it enters the design system, and an emitter is a large public
// surface for a single consumer. Promote it when a second one appears.

// MARK: - Metrics

private enum Metrics {
    /// Ring buffer size. At the peak rate a particle lives ~0.9s, so 48 slots
    /// is roughly double the worst-case live count — the buffer never eats a
    /// particle that is still on screen.
    static let capacity: Int = 48

    /// How far outside the host view particles may drift before being clipped.
    /// The host applies this as negative padding; see `DSParticleField.margin`.
    static let margin: CGFloat = DSSpacing.xxl

    // Birth state. These are animation shaping values, not layout: there is no
    // spacing or color token for "how big is a mote", so they live here, tuned
    // by eye against the glass surfaces they sit on.

    /// Diameter range at birth. Deliberately sub-pixel-ish — "chiquititas".
    static let sizeRange: ClosedRange<CGFloat> = 1...2.5
    /// Lifetime range. Short enough that the cloud reads as *now*, not as a trail.
    static let lifetimeRange: ClosedRange<TimeInterval> = 0.5...0.9
    /// Half-width of the band around the emitter radius where particles appear,
    /// so they ring the knob instead of sitting exactly on its edge.
    static let seedSpread: CGFloat = DSSpacing.xxs
    /// Outward speed at birth, in points per second.
    static let driftRange: ClosedRange<CGFloat> = 6...22
    /// Constant upward bias added to the birth velocity. Motes rise; dust falls,
    /// and dust is the wrong association for a payment.
    static let buoyancy: CGFloat = -12

    // Motion shaping.

    /// Exponential velocity decay. Particles coast to a near-stop inside their
    /// own lifetime, which is what makes them read as floating rather than flung.
    static let drag: Double = 2.6
    /// Lateral sway amplitude and rate. Each particle gets its own phase, so the
    /// cloud shimmers instead of pulsing as one body.
    static let wobbleAmplitude: CGFloat = 1.5
    static let wobbleFrequency: Double = 5

    // Emission.

    /// Births per second with the finger held still — enough to keep the cloud
    /// alive so it reads as "charged", not as a speedometer.
    static let baselineRate: Double = 14
    /// Extra births per second for each point-per-second of emitter travel.
    static let ratePerSpeed: Double = 0.22
    /// Ceiling, so a flick cannot empty the ring buffer in one frame.
    static let maxRate: Double = 90
    /// Particles released by one `exhale`.
    static let exhaleCount: Int = 18
    /// Radial speed of an exhaled particle — fast enough to disperse, slow
    /// enough to still be visible as it goes.
    static let exhaleRange: ClosedRange<CGFloat> = 40...90

    // Render.

    /// Peak opacity of a single mote. Everything above this stopped reading as
    /// "subtle" and started reading as confetti.
    static let peakOpacity: Double = 0.5
    /// Fraction of a lifetime spent fading in. The rest fades out.
    static let attack: Double = 0.18
    /// Softening blur. The motes are 1–2.5pt; without this they alias into
    /// hard dots and lose the light-mote quality.
    static let blur: CGFloat = 1.5
    /// How much of its birth size a particle keeps at the end of its life.
    static let endScale: CGFloat = 0.65
}

// MARK: - Particle

/// One mote. Everything needed to evaluate its position and opacity at an
/// arbitrary instant is captured at birth — nothing here is ever updated.
private struct DSParticle {
    var birth: TimeInterval = 0
    var lifetime: TimeInterval = 0
    var origin: CGPoint = .zero
    var velocity: CGVector = .zero
    var size: CGFloat = 0
    /// Phase offset for the lateral sway, so no two motes wobble in step.
    var wobblePhase: Double = 0

    /// A slot that has never been filled, or whose particle has expired.
    func isAlive(at now: TimeInterval) -> Bool {
        lifetime > 0 && now - birth < lifetime
    }

    /// Position at `now`, from the birth state alone.
    ///
    /// Velocity decays exponentially (`v = v₀·e^(-kt)`), so displacement is its
    /// integral, `(v₀/k)·(1 - e^(-kt))` — the particle coasts outward and
    /// settles instead of travelling forever.
    func position(at now: TimeInterval) -> CGPoint {
        let age = now - birth
        let travel = (1 - exp(-Metrics.drag * age)) / Metrics.drag
        let sway = Metrics.wobbleAmplitude
            * CGFloat(sin(age * Metrics.wobbleFrequency + wobblePhase))
        return CGPoint(
            x: origin.x + velocity.dx * CGFloat(travel) + sway,
            y: origin.y + velocity.dy * CGFloat(travel)
        )
    }

    /// Opacity envelope in `0...1`: a quick attack so a mote never pops in at
    /// full strength, then a decay biased late so the cloud thins out softly.
    func envelope(at now: TimeInterval) -> Double {
        let unit = min(max((now - birth) / lifetime, 0), 1)
        let attack = min(unit / Metrics.attack, 1)
        let decay = max(1 - pow(unit, 1.6), 0)
        return attack * decay
    }

    /// Motes shrink slightly as they fade, which reads as receding rather than
    /// dissolving in place.
    func radius(at now: TimeInterval) -> CGFloat {
        let unit = CGFloat(min(max((now - birth) / lifetime, 0), 1))
        return size * (1 - (1 - Metrics.endScale) * unit) / 2
    }
}

// MARK: - DSParticleField

/// A cloud of light motes emitted around `emitter` for as long as `isEmitting`
/// is true, plus a one-shot radial burst on every change of `exhale`.
///
/// The field derives emission rate from how fast `emitter` itself moves, so a
/// host only has to say *where the finger is* — it never computes a velocity:
///
///     DSParticleField(
///         emitter: knobCentre,
///         emitterRadius: knobDiameter / 2,
///         isEmitting: phase == .dragging,
///         neutralTint: DSColors.textTertiary,
///         successTint: DSColors.success,
///         tintMix: hasSucceeded ? 1 : 0,
///         exhale: exhaleToken
///     )
///     .padding(-DSParticleField.margin)
///
/// `emitter` is given in the host's own coordinate space; the field applies
/// `margin` internally, so a host that wants motes to escape its bounds only
/// has to widen the field with negative padding as shown.
struct DSParticleField: View, Animatable {

    // MARK: Configuration

    /// Birth point, in the host's coordinate space.
    var emitter: CGPoint
    /// Motes ring the emitter at this distance, ± `Metrics.seedSpread`.
    var emitterRadius: CGFloat
    /// While false, no new motes are born — the ones alive still finish fading.
    var isEmitting: Bool
    /// Tint at `tintMix == 0`.
    var neutralTint: Color
    /// Tint at `tintMix == 1`.
    var successTint: Color
    /// Blend between the two tints. Animating it sweeps the whole living cloud
    /// at once, which is the point: the outcome arrives as one event, not as a
    /// gradual recolouring of individual motes.
    var tintMix: Double
    /// Changing this fires one radial burst from `emitter`.
    var exhale: Int

    /// How far beyond its host the field may draw. A host that wants motes
    /// outside its bounds applies this as negative padding.
    static let margin: CGFloat = Metrics.margin

    // MARK: Animatable

    /// Only the tint blend is animatable; positions come from the timeline.
    var animatableData: Double {
        get { tintMix }
        set { tintMix = newValue }
    }

    // MARK: State

    @State private var particles = [DSParticle](repeating: DSParticle(), count: Metrics.capacity)
    /// Next slot to overwrite. The buffer is a ring, so this only ever advances.
    @State private var cursor: Int = 0
    /// Emitter position and timestamp at the previous tick, for the speed term.
    @State private var lastEmitter: CGPoint?
    @State private var lastTick: TimeInterval?
    /// Fractional particles carried between ticks, so a rate of 14/s does not
    /// round down to zero at 120Hz.
    @State private var pending: Double = 0

    @Environment(\.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: Body

    var body: some View {
        // Both settings mean "stop showing me ambient light effects". The motes
        // are pure decoration — the drag reads perfectly without them — so the
        // field is not drawn at all rather than being shown in a reduced form.
        if reduceMotion || reduceTransparency {
            Color.clear
        } else {
            TimelineView(.animation) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, _ in
                    draw(in: &context, at: now)
                }
                .onChange(of: timeline.date) { _, newValue in
                    advance(to: newValue.timeIntervalSinceReferenceDate)
                }
            }
            // No padding of its own: the host has already widened this frame by
            // `margin` on every side, and the Canvas must fill all of it or the
            // motes clip at the host's bounds again. Host coordinates are
            // shifted into field space by `+margin` at spawn time instead.
            .onChange(of: exhale) { _, _ in
                burst(at: Date.now.timeIntervalSinceReferenceDate)
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: Draw

    /// Pure: reads `particles` and paints. Never mutates — see `advance`.
    private func draw(in context: inout GraphicsContext, at now: TimeInterval) {
        let tint = blendedTint()
        // Additive so overlapping motes bloom instead of flattening, and blurred
        // because at 1–2.5pt a hard-edged dot reads as a speck of dirt.
        context.blendMode = .plusLighter
        context.addFilter(.blur(radius: Metrics.blur))

        for particle in particles where particle.isAlive(at: now) {
            let alpha = particle.envelope(at: now) * Metrics.peakOpacity
            guard alpha > 0.01 else { continue }
            let centre = particle.position(at: now)
            let radius = particle.radius(at: now)
            let rect = CGRect(
                x: centre.x - radius,
                y: centre.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(alpha)))
        }
    }

    /// Interpolate the two tints in resolved sRGB. `Color` itself cannot be
    /// blended, and `Canvas` gives no animation of its own — resolving both ends
    /// against the environment and mixing by hand is what lets `tintMix` sweep
    /// the cloud in one animated step.
    private func blendedTint() -> Color {
        let mix = min(max(tintMix, 0), 1)
        guard mix > 0 else { return neutralTint }
        guard mix < 1 else { return successTint }
        let from = neutralTint.resolve(in: environment)
        let to = successTint.resolve(in: environment)
        return Color(
            red: Double(from.red + (to.red - from.red) * Float(mix)),
            green: Double(from.green + (to.green - from.green) * Float(mix)),
            blue: Double(from.blue + (to.blue - from.blue) * Float(mix))
        )
    }

    // MARK: Simulation

    /// Runs once per timeline tick, outside the draw closure. This is the only
    /// place particle state changes.
    private func advance(to now: TimeInterval) {
        defer {
            lastTick = now
            lastEmitter = emitter
        }
        guard let previousTick = lastTick, let previousEmitter = lastEmitter else { return }

        let delta = now - previousTick
        // A backgrounded app resumes with a huge delta; spawning against it
        // would dump the whole ring buffer into a single frame.
        guard delta > 0, delta < 0.5 else { return }

        guard isEmitting else {
            pending = 0
            return
        }

        // Speed comes from the emitter's own travel, so the host never has to
        // measure the drag — it only says where the finger is.
        let travelled = hypot(emitter.x - previousEmitter.x, emitter.y - previousEmitter.y)
        let speed = Double(travelled) / delta
        let rate = min(Metrics.baselineRate + speed * Metrics.ratePerSpeed, Metrics.maxRate)

        pending += rate * delta
        while pending >= 1 {
            pending -= 1
            spawnAroundEmitter(at: now)
        }
    }

    /// One mote on the ring around the emitter, drifting outward and up.
    private func spawnAroundEmitter(at now: TimeInterval) {
        let angle = Double.random(in: 0..<(2 * .pi))
        let distance = emitterRadius + CGFloat.random(
            in: -Metrics.seedSpread...Metrics.seedSpread
        )
        let drift = CGFloat.random(in: Metrics.driftRange)
        write(
            DSParticle(
                birth: now,
                lifetime: TimeInterval.random(in: Metrics.lifetimeRange),
                origin: CGPoint(
                    x: emitter.x + Metrics.margin + CGFloat(cos(angle)) * distance,
                    y: emitter.y + Metrics.margin + CGFloat(sin(angle)) * distance
                ),
                velocity: CGVector(
                    dx: CGFloat(cos(angle)) * drift,
                    dy: CGFloat(sin(angle)) * drift + Metrics.buoyancy
                ),
                size: CGFloat.random(in: Metrics.sizeRange),
                wobblePhase: Double.random(in: 0..<(2 * .pi))
            )
        )
    }

    /// The one-shot burst: same ring, same buffer, but fast and outward — the
    /// cloud dispersing rather than following a finger that is no longer there.
    private func burst(at now: TimeInterval) {
        for index in 0..<Metrics.exhaleCount {
            // Evenly spaced with a jittered offset, so the ring reads as a
            // dispersal and not as a clock face.
            let angle = (Double(index) / Double(Metrics.exhaleCount)) * 2 * .pi
                + Double.random(in: -0.2...0.2)
            let speed = CGFloat.random(in: Metrics.exhaleRange)
            write(
                DSParticle(
                    birth: now,
                    lifetime: TimeInterval.random(in: Metrics.lifetimeRange),
                    origin: CGPoint(
                        x: emitter.x + Metrics.margin + CGFloat(cos(angle)) * emitterRadius,
                        y: emitter.y + Metrics.margin + CGFloat(sin(angle)) * emitterRadius
                    ),
                    velocity: CGVector(
                        dx: CGFloat(cos(angle)) * speed,
                        dy: CGFloat(sin(angle)) * speed
                    ),
                    size: CGFloat.random(in: Metrics.sizeRange),
                    wobblePhase: Double.random(in: 0..<(2 * .pi))
                )
            )
        }
    }

    private func write(_ particle: DSParticle) {
        particles[cursor] = particle
        cursor = (cursor + 1) % Metrics.capacity
    }
}

// MARK: - Preview

#if DEBUG
/// The field on its own: drag the knob to see the cloud follow the finger and
/// brighten with speed, then release to watch it thin out. "Succeed" sweeps the
/// tint and fires one burst — the two things `DSSlideToConfirm` asks of it.
private struct DSParticleFieldPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var knob: CGPoint = CGPoint(x: 90, y: 150)
    @State private var isDragging = false
    @State private var tintMix: Double = 0
    @State private var exhale = 0

    private let knobRadius: CGFloat = DSSpacing.xxl / 2

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            DSPreviewThemeDots(theme: theme)

            ZStack(alignment: .topLeading) {
                Circle()
                    .fill(theme.gradient.accent)
                    .frame(width: knobRadius * 2, height: knobRadius * 2)
                    .position(knob)
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .dsSurface(.glassThin, radius: DSRadius.card)
            .overlay {
                DSParticleField(
                    emitter: knob,
                    emitterRadius: knobRadius,
                    isEmitting: isDragging,
                    neutralTint: DSColors.textTertiary,
                    successTint: DSColors.success,
                    tintMix: tintMix,
                    exhale: exhale
                )
                .padding(-DSParticleField.margin)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        knob = value.location
                    }
                    .onEnded { _ in isDragging = false }
            )

            HStack(spacing: DSSpacing.sm) {
                DSButton("Succeed", variant: .primary) {
                    withAnimation(DSAnimation.normal) { tintMix = 1 }
                    exhale += 1
                }
                DSButton("Reset", variant: .secondary) {
                    withAnimation(DSAnimation.fast) { tintMix = 0 }
                }
            }

            Text("Drag inside the panel — the cloud follows the finger and\nbrightens with speed.")
                .ds(.caption1, color: DSColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .dsScreenPadding()
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Particle Field — Light") {
    DSParticleFieldPreviewHost().preferredColorScheme(.light)
}

#Preview("Particle Field — Dark") {
    DSParticleFieldPreviewHost().preferredColorScheme(.dark)
}
#endif
