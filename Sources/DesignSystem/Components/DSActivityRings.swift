import SwiftUI

// MARK: - Design System Activity Rings
// Concentric progress rings — the Apple Fitness "close your rings" pattern,
// translated to Velvet tokens. One ring is `DSCircularProgress`; the value of
// this component is the *set*: several goals stacked as nested rings that fill
// with a spring, each carrying its own colour, and a ring flashing a themed glow
// with a `.success` haptic the moment it closes.
//
// Reusable well beyond fitness: budgets vs. limits, storage by category, quiz
// or onboarding completion, poll shares, any "how close am I to N goals" view.
//
// Geometry is the proven `DSCircularProgress` recipe — `Circle().trim(…)` stroked
// with a round cap and rotated −90° so the fill starts at twelve o'clock — so
// there is no arc trigonometry to get wrong. Rings are stacked in a `ZStack`,
// each inset by one lane (`lineWidth + spacing`) from the one outside it.

// MARK: - Ring Model

/// One ring in a `DSActivityRings`. Rings are drawn outermost first, in array order.
public struct DSRing: Sendable {
    /// Fraction filled, `0...1`. Values above 1 read as a full, closed ring.
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

    /// A ring counts as closed once it reaches its goal.
    var isClosed: Bool { progress >= 1 }
}

// MARK: - Activity Rings

public struct DSActivityRings<Center: View>: View {
    private let rings: [DSRing]
    private let size: CGFloat
    private let lineWidth: CGFloat
    private let spacing: CGFloat
    private let spring: Animation
    private let center: Center

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Create a set of concentric activity rings.
    /// - Parameters:
    ///   - rings: The rings, outermost first.
    ///   - size: Outer diameter of the whole set.
    ///   - lineWidth: Stroke width of every ring.
    ///   - spacing: Gap between adjacent ring lanes.
    ///   - spring: Fill animation on appear and on change. Suppressed under Reduce Motion.
    ///   - center: Optional content nested inside the innermost ring (a summary number, an icon).
    public init(
        _ rings: [DSRing],
        size: CGFloat = 160,
        lineWidth: CGFloat = 14,
        spacing: CGFloat = DSSpacing.xxs,
        spring: Animation = DSAnimation.springSmooth,
        @ViewBuilder center: () -> Center
    ) {
        self.rings = rings
        self.size = size
        self.lineWidth = lineWidth
        self.spacing = spacing
        self.spring = spring
        self.center = center()
    }

    public var body: some View {
        ZStack {
            ForEach(Array(rings.enumerated()), id: \.offset) { index, ring in
                DSRingLane(
                    progress: ring.progress,
                    diameter: diameter(at: index),
                    lineWidth: lineWidth,
                    fill: ring.color ?? theme.accent,
                    track: theme.palette.border,
                    spring: spring,
                    reduceMotion: reduceMotion,
                    onClose: { DSHapticEngine.shared.fire(.success) }
                )
            }
            center
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// Outer ring uses the full size; each inner ring steps in by one lane.
    private func diameter(at index: Int) -> CGFloat {
        let inset = CGFloat(index) * 2 * (lineWidth + spacing)
        return max(size - inset, lineWidth)
    }

    private var accessibilityText: String {
        let parts = rings.enumerated().map { index, ring -> String in
            let name = ring.label ?? "Ring \(index + 1)"
            let percent = Int((max(ring.progress, 0) * 100).rounded())
            return ring.isClosed ? "\(name) \(percent) percent, complete" : "\(name) \(percent) percent"
        }
        return (["Activity rings"] + parts).joined(separator: ". ")
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
        spring: Animation = DSAnimation.springSmooth
    ) {
        self.init(rings, size: size, lineWidth: lineWidth, spacing: spacing, spring: spring) {
            EmptyView()
        }
    }
}

// MARK: - Single Ring Lane

/// One ring: a track plus a trimmed, round-capped fill that springs to `progress`
/// and glows in its own colour once closed. Mirrors `DSCircularProgress`; the only
/// additions are the close glow and the `.success` haptic on the live close.
private struct DSRingLane: View {
    let progress: Double
    let diameter: CGFloat
    let lineWidth: CGFloat
    let fill: Color
    let track: Color
    let spring: Animation
    let reduceMotion: Bool
    let onClose: () -> Void

    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: min(animated, 1))
                .stroke(fill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                // The glow rides the *interpolated* fill, so it flashes on at the
                // exact frame the ring reaches full — not when the target is set.
                .modifier(DSRingGlow(progress: animated, color: fill))
        }
        .frame(width: diameter, height: diameter)
        .onAppear {
            // Fill in from empty on first appearance; never haptic on load — a
            // ring that starts closed is a fact, not an achievement.
            animate(to: max(progress, 0), fireOnClose: false)
        }
        .onChange(of: progress) { oldValue, newValue in
            animate(to: max(newValue, 0), fireOnClose: newValue >= 1 && oldValue < 1)
        }
    }

    /// Drive the fill to `value`; when this is a live close, fire the haptic on the
    /// animation's completion so the buzz lands with the ring, not ahead of it.
    private func animate(to value: Double, fireOnClose: Bool) {
        guard !reduceMotion else {
            animated = value
            if fireOnClose { onClose() }
            return
        }
        withAnimation(spring) {
            animated = value
        } completion: {
            if fireOnClose { onClose() }
        }
    }
}

// MARK: - Ring Glow

/// Applies the close `.glow` only once the *interpolated* progress reaches full.
/// Being `Animatable` over `progress` is what lets the glow track the fill frame
/// by frame instead of snapping on when the target value is assigned.
private struct DSRingGlow: ViewModifier, Animatable {
    var progress: Double
    let color: Color

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.dsShadow(progress >= 1 ? .glow(color) : .none)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSActivityRingsPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var rings: [DSRing] = [
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
                    withAnimation(DSAnimation.springSmooth) {
                        rings = rings.map { DSRing(progress: 1, color: $0.color, label: $0.label) }
                    }
                }

                DSButton("Reset", variant: .ghost, size: .small) {
                    rings = [
                        DSRing(progress: 0.82, color: DSColors.error,   label: "Move"),
                        DSRing(progress: 0.60, color: DSColors.success, label: "Exercise"),
                        DSRing(progress: 0.45, color: DSColors.info,    label: "Stand")
                    ]
                }

                // A single accent ring with no centre — the "one goal" case.
                Text("Single ring").ds(.overline, color: DSColors.textSecondary)
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSActivityRings([DSRing(progress: 0.7, label: "Budget")], size: 96, lineWidth: 12)
                        DSActivityRings([DSRing(progress: 1, label: "Budget")], size: 96, lineWidth: 12)
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
