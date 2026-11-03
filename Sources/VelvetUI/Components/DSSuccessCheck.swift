import SwiftUI

// MARK: - Design System Success Check
// An animated success seal. When `isComplete` turns true the ring strokes itself,
// the disc fills, the checkmark draws, and a single springy pop peaks exactly as
// the check finishes — the haptic lands on that same beat, together with one soft
// halo that expands and fades. About 0.9s end to end.
//
// Why two mechanisms: the strokes are plain eased state changes (they have to
// *hold* their end value), while the pop and halo are transient — they return to
// rest — and decay like a spring, so they run on one `keyframeAnimator` track
// instead of a chain of phases that each settle before the next one starts.

/// Timeline and geometry of the seal. Seconds from the moment `isComplete` turns true.
enum DSSuccessCheckTimeline {
    /// The ring strokes itself.
    static let ringStart: Double = 0
    static let ringDuration: Double = 0.35
    /// The disc fills in behind the ring.
    static let discStart: Double = 0.15
    static let discDuration: Double = 0.30
    /// The checkmark draws.
    static let checkStart: Double = 0.38
    static let checkDuration: Double = 0.27
    /// The beat: the check is complete, the pop peaks, the haptic fires.
    static var peak: Double { checkStart + checkDuration }

    /// The pop climbs to its peak over this long, so it arrives exactly at `peak`.
    static let popRise: Double = 0.12
    /// Time the pop and halo track start at.
    static var popStart: Double { peak - popRise }
    /// The pop springs back to rest over this long (response/damping of `DSAnimation.springBouncy`).
    static let popSettle: Double = 0.25
    /// Scale at the peak of the pop.
    static let popScale: Double = 1.14
    /// How long the halo expands and fades after the peak.
    static let haloDuration: Double = 0.25
    /// Halo growth: it expands to this multiple of the seal.
    static let haloGrowth: Double = 0.6
    /// Halo opacity when it starts.
    static let haloOpacity: Double = 0.35

    /// End of the whole choreography.
    static var total: Double { max(popStart + popRise + popSettle, peak + haloDuration) }

    /// Seconds from the pop's start to the peak (when the haptic fires).
    static var peakDelayFromPopStart: Double { popRise }

    /// The check, as points in the unit square. Kept well inside the ring.
    static let checkPoints: [CGPoint] = [
        CGPoint(x: 0.29, y: 0.52),
        CGPoint(x: 0.44, y: 0.66),
        CGPoint(x: 0.72, y: 0.36)
    ]

    /// VoiceOver label: present only while complete, hidden otherwise.
    static func accessibilityLabel(_ label: String, isComplete: Bool) -> String? {
        isComplete ? label : nil
    }
}

private enum Metrics {
    /// Ring stroke as a fraction of the seal's size.
    static let ringWidthRatio: CGFloat = 0.075
    /// Check stroke as a fraction of the seal's size.
    static let checkWidthRatio: CGFloat = 0.085
    /// The disc starts at this fraction of its size and scales up while it fills.
    static let discStartScale: CGFloat = 0.6
}

private struct DSCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points = DSSuccessCheckTimeline.checkPoints.map {
            CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
        }
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        return path
    }
}

/// The transient part of the choreography: a scale pop and a halo that grows and fades.
private struct SealPop {
    var scale: Double = 1
    var halo: Double = 0
}

/// An animated success seal: ring, filled disc and checkmark, with a single springy
/// pop and a soft halo when `isComplete` turns true.
///
/// It plays on every change of `isComplete` to `true` (and once on first appear if it
/// already is); a view that re-appears already complete shows the finished seal at
/// rest, without haptic or announcement. The haptic fires on the beat the check completes. When `isComplete` goes
/// back to `false` the seal fades out quietly. With Reduce Motion on, the finished
/// seal crossfades in; the haptic still fires. The halo extends past `size`, so leave
/// a little room around it.
public struct DSSuccessCheck: View {
    private let isComplete: Bool
    private let size: CGFloat
    private let color: Color?
    private let haptic: DSHapticStyle?
    private let label: String

    @State private var ring: CGFloat = 0
    @State private var disc: CGFloat = 0
    @State private var check: CGFloat = 0
    @State private var sealOpacity: Double = 0
    @State private var popTrigger = 0
    /// True while the seal shows (or is playing) its finished state. A view that
    /// re-appears with this still set (tab switch, pop-back) stays at rest
    /// instead of replaying the haptic and announcement.
    @State private var hasPlayed = false
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - isComplete: Plays the choreography when it turns `true`; fades out when `false`.
    ///   - size: Diameter of the seal. Defaults to 64.
    ///   - color: Ring and disc fill. Defaults to `theme.palette.success`.
    ///   - haptic: Fired as the check completes. Pass `nil` for none. Defaults to `.success`.
    ///   - accessibilityLabel: What VoiceOver says, and announces on completion. Defaults to "Done".
    public init(
        isComplete: Bool,
        size: CGFloat = 64,
        color: Color? = nil,
        haptic: DSHapticStyle? = .success,
        accessibilityLabel: String = "Done"
    ) {
        self.isComplete = isComplete
        self.size = size
        self.color = color
        self.haptic = haptic
        self.label = accessibilityLabel
    }

    public var body: some View {
        let fill = color ?? theme.palette.success

        seal(fill: fill)
            .keyframeAnimator(initialValue: SealPop(), trigger: popTrigger) { content, pop in
                content
                    .scaleEffect(pop.scale)
                    .background {
                        Circle()
                            .fill(fill.opacity(DSSuccessCheckTimeline.haloOpacity * (1 - pop.halo)))
                            .scaleEffect(1 + DSSuccessCheckTimeline.haloGrowth * pop.halo)
                    }
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(DSSuccessCheckTimeline.popScale, duration: DSSuccessCheckTimeline.popRise)
                    // Same feel as DSAnimation.springBouncy (response 0.5, damping 0.5).
                    SpringKeyframe(1, duration: DSSuccessCheckTimeline.popSettle, spring: Spring(response: 0.5, dampingRatio: 0.5))
                }
                KeyframeTrack(\.halo) {
                    LinearKeyframe(0, duration: DSSuccessCheckTimeline.popRise)
                    CubicKeyframe(1, duration: DSSuccessCheckTimeline.haloDuration)
                }
            }
            .frame(width: size, height: size)
            .opacity(sealOpacity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(DSSuccessCheckTimeline.accessibilityLabel(label, isComplete: isComplete) ?? "")
            .accessibilityAddTraits(.isImage)
            .accessibilityHidden(!isComplete)
            .task(id: isComplete) { await run(complete: isComplete) }
    }

    // MARK: Seal

    private func seal(fill: Color) -> some View {
        ZStack {
            Circle()
                .fill(fill)
                .scaleEffect(Metrics.discStartScale + (1 - Metrics.discStartScale) * disc)
                .opacity(Double(disc))

            Circle()
                .inset(by: size * Metrics.ringWidthRatio / 2)
                .trim(from: 0, to: ring)
                .stroke(fill, style: StrokeStyle(lineWidth: size * Metrics.ringWidthRatio, lineCap: .round))
                .rotationEffect(.degrees(-90))

            DSCheckShape()
                .trim(from: 0, to: check)
                .stroke(
                    theme.palette.textOnPrimary,
                    style: StrokeStyle(lineWidth: size * Metrics.checkWidthRatio, lineCap: .round, lineJoin: .round)
                )
        }
    }

    // MARK: Choreography

    private func setInstantly(_ change: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, change)
    }

    private func run(complete: Bool) async {
        guard complete else {
            // Quiet reset: fade, then rewind the strokes out of sight.
            hasPlayed = false
            withAnimation(DSAnimation.fast) { sealOpacity = 0 }
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            setInstantly { ring = 0; disc = 0; check = 0 }
            return
        }

        // Re-appeared with the finished seal intact: leave it at rest.
        guard !hasPlayed else { return }
        hasPlayed = true

        if reduceMotion {
            setInstantly { ring = 1; disc = 1; check = 1 }
            withAnimation(DSAnimation.fast) { sealOpacity = 1 }
            fireBeat()
            return
        }

        typealias T = DSSuccessCheckTimeline
        setInstantly { ring = 0; disc = 0; check = 0; sealOpacity = 1 }
        // Let the rewound state commit before animating, otherwise both changes
        // merge into one transaction and the strokes never redraw.
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(16))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: T.ringDuration).delay(T.ringStart)) { ring = 1 }
        withAnimation(.easeOut(duration: T.discDuration).delay(T.discStart)) { disc = 1 }
        withAnimation(.easeInOut(duration: T.checkDuration).delay(T.checkStart)) { check = 1 }

        // Start the pop so it peaks at T.peak, then fire the haptic on the peak.
        try? await Task.sleep(for: .seconds(T.popStart))
        guard !Task.isCancelled else { return }
        popTrigger += 1
        try? await Task.sleep(for: .seconds(T.peakDelayFromPopStart))
        guard !Task.isCancelled else { return }
        fireBeat()
    }

    /// The beat the check completes on: haptic plus a spoken announcement.
    private func fireBeat() {
        if let haptic { DSHapticEngine.shared.fire(haptic) }
        AccessibilityNotification.Announcement(label).post()
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSuccessCheckPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var done = false

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSPreviewThemeDots(theme: theme)

            DSSuccessCheck(isComplete: done, size: 96)
                .padding(DSSpacing.xl)
            Text(done ? "Payment sent" : "Waiting…").ds(.title2)

            HStack(spacing: DSSpacing.lg) {
                DSSuccessCheck(isComplete: done, size: 32)
                DSSuccessCheck(isComplete: done, size: 48)
                DSSuccessCheck(isComplete: done, size: 48, color: DSColors.info, haptic: nil)
            }

            DSButton(done ? "Reset" : "Complete") { done.toggle() }
        }
        .dsScreenPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsBackdrop()
        .dsTheme(theme)
        .task {
            try? await Task.sleep(for: .seconds(0.6))
            done = true
        }
    }
}

#Preview("SuccessCheck — Light") {
    DSSuccessCheckPreviewHost().preferredColorScheme(.light)
}

#Preview("SuccessCheck — Dark") {
    DSSuccessCheckPreviewHost().preferredColorScheme(.dark)
}
#endif
