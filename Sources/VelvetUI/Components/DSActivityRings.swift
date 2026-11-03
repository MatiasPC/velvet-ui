import SwiftUI

// MARK: - Design System Activity Rings
// Concentric progress rings — the Apple Fitness "close your rings" pattern,
// translated to Velvet tokens. One ring is `DSCircularProgress`; the value of
// this component is the *set*: several goals stacked as nested rings that fill
// with a spring, each carrying its own colour, and a ring that lights up with a
// themed glow and a `.success` haptic the moment it closes.
//
// Reusable well beyond fitness: budgets vs. limits, storage by category, quiz
// or onboarding completion, poll shares, any "how close am I to N goals" view.
//
// Geometry is the `DSCircularProgress` recipe — `Circle().trim(…)` stroked with
// a round cap and rotated −90° so the fill starts at twelve o'clock — so there is
// no arc trigonometry to get wrong. Each ring is inset by half its stroke so the
// whole set lives inside `size` (a centred stroke would spill half a line width
// past the frame), and rings are stacked in a `ZStack`, each one lane
// (`lineWidth + spacing`) inside the one outside it.
//
// Beyond 100 %: the arc is clamped to a full, closed ring (it does not wrap or
// overlap), and VoiceOver still speaks the real number ("120 percent").

// MARK: - Ring Model

/// One ring in a `DSActivityRings`. Rings are drawn outermost first, in array order.
public struct DSRing: Sendable {
    /// Fraction of the goal reached. `1` is a closed ring. Values above `1` draw a closed ring
    /// (the arc does not wrap) and are still spoken as-is by VoiceOver; negative or non-finite values count as `0`.
    public var progress: Double
    /// Fill colour. `nil` follows the theme accent.
    public var color: Color?
    /// Spoken name for VoiceOver ("Move", "Exercise", "Budget"). `nil` falls back to the ring's position.
    public var label: String?

    public init(progress: Double, color: Color? = nil, label: String? = nil) {
        self.progress = progress
        self.color = color
        self.label = label
    }

    /// `progress` made safe to use: never negative, never NaN, and a (positive) infinity counts as closed.
    var fraction: Double {
        if progress.isNaN { return 0 }
        if progress == .infinity { return 1 }
        return max(progress, 0)
    }

    /// How much of the arc is drawn, `0...1`.
    var drawnFraction: Double { min(fraction, 1) }

    /// A ring counts as closed once it reaches its goal.
    var isClosed: Bool { fraction >= 1 }
}

// MARK: - Pure logic

/// The parts of `DSActivityRings` that don't need a view: geometry, close detection,
/// haptic coalescing and the VoiceOver strings. Kept internal and unit-tested.
enum DSRingMath {

    /// Two closes inside this window (seconds) share one haptic: closing every ring at once is one moment, not three buzzes.
    static let beatWindow: TimeInterval = 0.25

    /// Outer diameter of the ring at `index` (0 is outermost), or `nil` when it no longer fits
    /// inside `size` with a hole left in the middle. Rings that don't fit are not drawn.
    static func outerDiameter(index: Int, size: CGFloat, lineWidth: CGFloat, spacing: CGFloat) -> CGFloat? {
        let diameter = size - CGFloat(index) * 2 * (lineWidth + spacing)
        return diameter > 2 * lineWidth ? diameter : nil
    }

    /// A live close: a ring that was open and now is not. A ring that merely *appears* closed is not one.
    static func isLiveClose(from old: Double, to new: Double) -> Bool {
        new >= 1 && old < 1
    }

    /// Whether a close at `now` earns its own haptic, given when the last one fired.
    static func shouldFireBeat(lastBeat: Date?, now: Date) -> Bool {
        guard let lastBeat else { return true }
        return now.timeIntervalSince(lastBeat) >= beatWindow
    }

    /// Whole percent as spoken. Capped so a runaway value can't overflow `Int`.
    static func percent(of ring: DSRing) -> Int {
        Int(min(ring.fraction * 100, 99_999).rounded())
    }

    /// "Move 82 percent", or "Move 100 percent, complete" once closed.
    static func spoken(_ ring: DSRing, index: Int) -> String {
        let name = ring.label ?? "Ring \(index + 1)"
        let text = "\(name) \(percent(of: ring)) percent"
        return ring.isClosed ? text + ", complete" : text
    }

    /// The VoiceOver value for the whole set: every ring's name and percent, outermost first.
    static func accessibilityValue(_ rings: [DSRing]) -> String {
        rings.enumerated().map { spoken($1, index: $0) }.joined(separator: ". ")
    }
}

// MARK: - Activity Rings

/// Concentric goal rings that fill with a spring and close with a glow and a haptic.
///
/// Each ring fills from empty when the view appears and animates to its new value when
/// `progress` changes. The moment a ring *transitions* to closed (`progress` reaching `1` while on
/// screen) it lights up with a `.glow` of its own colour and one haptic fires as the spring lands,
/// never on first appearance, where a closed ring is a fact, not an achievement. Rings that close in
/// the same instant share one haptic. A closed ring keeps its glow until it re-opens.
///
/// Progress above `1` is clamped to a full ring. Under Reduce Motion the rings settle at their
/// value without sweeping (the glow and haptic still mark a close). The set is one VoiceOver element
/// that reads every ring's label and percent; the centre content, if any, stays separately reachable.
public struct DSActivityRings<Center: View>: View {
    private let rings: [DSRing]
    private let size: CGFloat
    private let lineWidth: CGFloat
    private let spacing: CGFloat
    private let spring: Animation
    private let haptic: DSHapticStyle?
    private let label: String
    private let center: Center

    /// When the last close haptic fired, so simultaneous closes share one.
    @State private var lastBeat: Date?
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Create a set of concentric activity rings.
    /// - Parameters:
    ///   - rings: The rings, outermost first. Rings that would not fit inside `size` are not drawn.
    ///   - size: Outer diameter of the whole set.
    ///   - lineWidth: Stroke width of every ring.
    ///   - spacing: Gap between adjacent ring lanes.
    ///   - spring: Fill animation on appear and on change. Ignored under Reduce Motion.
    ///   - haptic: Fired when a ring closes. Pass `nil` for none. Defaults to `.success`.
    ///   - accessibilityLabel: What VoiceOver calls the set. Defaults to "Activity rings".
    ///   - center: Optional content nested inside the innermost ring (a summary number, an icon).
    public init(
        _ rings: [DSRing],
        size: CGFloat = 160,
        lineWidth: CGFloat = 14,
        spacing: CGFloat = DSSpacing.xxs,
        spring: Animation = DSAnimation.springSmooth,
        haptic: DSHapticStyle? = .success,
        accessibilityLabel: String = "Activity rings",
        @ViewBuilder center: () -> Center
    ) {
        self.rings = rings
        self.size = size
        self.lineWidth = lineWidth
        self.spacing = spacing
        self.spring = spring
        self.haptic = haptic
        self.label = accessibilityLabel
        self.center = center()
    }

    public var body: some View {
        ZStack {
            ZStack {
                ForEach(rings.indices, id: \.self) { index in
                    if let diameter = DSRingMath.outerDiameter(index: index, size: size, lineWidth: lineWidth, spacing: spacing) {
                        DSRingLane(
                            ring: rings[index],
                            diameter: diameter,
                            lineWidth: lineWidth,
                            fill: rings[index].color ?? theme.accent,
                            track: theme.palette.border,
                            spring: spring,
                            reduceMotion: reduceMotion,
                            onClose: ringClosed
                        )
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(DSRingMath.accessibilityValue(rings))

            center
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .contain)
    }

    /// One haptic per close moment, however many rings land in it.
    private func ringClosed() {
        let now = Date()
        guard DSRingMath.shouldFireBeat(lastBeat: lastBeat, now: now) else { return }
        lastBeat = now
        if let haptic { DSHapticEngine.shared.fire(haptic) }
    }
}

// MARK: - No-center convenience

public extension DSActivityRings where Center == EmptyView {
    /// Create activity rings with no centre content.
    init(
        _ rings: [DSRing],
        size: CGFloat = 160,
        lineWidth: CGFloat = 14,
        spacing: CGFloat = DSSpacing.xxs,
        spring: Animation = DSAnimation.springSmooth,
        haptic: DSHapticStyle? = .success,
        accessibilityLabel: String = "Activity rings"
    ) {
        self.init(
            rings,
            size: size,
            lineWidth: lineWidth,
            spacing: spacing,
            spring: spring,
            haptic: haptic,
            accessibilityLabel: accessibilityLabel
        ) {
            EmptyView()
        }
    }
}

// MARK: - Single Ring Lane

/// One ring: a track plus a trimmed, round-capped fill that springs to its value, and a glow
/// that comes on when the fill lands closed. Mirrors `DSCircularProgress`; the additions are the
/// glow and the live-close haptic hand-off.
private struct DSRingLane: View {
    let ring: DSRing
    let diameter: CGFloat
    let lineWidth: CGFloat
    let fill: Color
    let track: Color
    let spring: Animation
    let reduceMotion: Bool
    let onClose: () -> Void

    /// The arc as drawn, `0...1`. Doubles as the *target* once a change is underway,
    /// which is what the completion handlers below compare against.
    @State private var drawn: Double = 0
    @State private var isGlowing = false

    var body: some View {
        ZStack {
            Circle()
                .inset(by: lineWidth / 2)
                .stroke(track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .inset(by: lineWidth / 2)
                .trim(from: 0, to: drawn)
                .stroke(fill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .dsShadow(isGlowing ? .glow(fill) : .none)
        }
        .frame(width: diameter, height: diameter)
        .onAppear {
            // Fill in from empty on first appearance. A ring that starts closed lights up when
            // it lands, but never buzzes: it's a fact, not an achievement.
            advance(to: ring.drawnFraction, liveClose: false)
        }
        .onChange(of: ring.fraction) { old, new in
            advance(to: min(new, 1), liveClose: DSRingMath.isLiveClose(from: old, to: new))
        }
    }

    /// Drive the arc to `target`. The glow and the haptic wait for the spring to land, so they arrive with
    /// the ring instead of ahead of it, and only if the ring is still closed by then.
    private func advance(to target: Double, liveClose: Bool) {
        guard !reduceMotion else {
            drawn = target
            setGlow(target >= 1, animated: false)
            if liveClose { onClose() }
            return
        }
        if target < 1 { setGlow(false, animated: true) }
        withAnimation(spring) {
            drawn = target
        } completion: {
            guard drawn >= 1 else { return }
            setGlow(true, animated: true)
            if liveClose { onClose() }
        }
    }

    private func setGlow(_ on: Bool, animated: Bool) {
        guard isGlowing != on else { return }
        if animated {
            withAnimation(DSAnimation.normal) { isGlowing = on }
        } else {
            isGlowing = on
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSActivityRingsPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var rings = Self.openRings

    private static let openRings = [
        DSRing(progress: 0.82, color: DSColors.error,   label: "Move"),
        DSRing(progress: 0.60, color: DSColors.success, label: "Exercise"),
        DSRing(progress: 0.45, color: DSColors.info,    label: "Stand")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                // Hero: three rings with a summary number in the middle.
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSActivityRings(rings) {
                            VStack(spacing: DSSpacing.xxxs) {
                                Text("62%").ds(.title2)
                                Text("today").ds(.caption1, color: DSColors.textSecondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            legend("Move", DSColors.error, "82%")
                            legend("Exercise", DSColors.success, "60%")
                            legend("Stand", DSColors.info, "45%")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSButton("Close the rings", variant: .primary, isFullWidth: true) {
                    rings = rings.map { DSRing(progress: 1, color: $0.color, label: $0.label) }
                }

                DSButton("Reset", variant: .ghost, size: .small) {
                    rings = Self.openRings
                }

                // A single accent ring with no centre — the "one goal" case — open, closed, and past its goal.
                Text("Single ring").ds(.overline, color: DSColors.textSecondary)
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSActivityRings([DSRing(progress: 0.7, label: "Budget")], size: 96, lineWidth: 12)
                        DSActivityRings([DSRing(progress: 1, label: "Budget")], size: 96, lineWidth: 12)
                        DSActivityRings([DSRing(progress: 1.3, label: "Budget")], size: 96, lineWidth: 12)
                        Spacer()
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func legend(_ name: String, _ color: Color, _ value: String) -> some View {
        HStack(spacing: DSSpacing.xs) {
            Circle().fill(color).frame(width: DSSpacing.xs, height: DSSpacing.xs)
            Text(name).ds(.footnote)
            Spacer(minLength: DSSpacing.md)
            Text(value).ds(.numeric, color: DSColors.textSecondary)
        }
    }
}

#Preview("Activity Rings — Light") {
    DSActivityRingsPreviewHost().preferredColorScheme(.light)
}

#Preview("Activity Rings — Dark") {
    DSActivityRingsPreviewHost().preferredColorScheme(.dark)
}
#endif
