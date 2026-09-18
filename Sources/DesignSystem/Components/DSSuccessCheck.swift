import SwiftUI

// MARK: - Design System Success Check
// The pure-SwiftUI answer to the ubiquitous "Lottie success tick": a filled
// seal that springs in, then draws its checkmark on with an animated stroke.
// Mount it at the moment something completes — a payment, a save, a submitted
// form — and it plays once. It is the celebratory bookend to `DSSlideToConfirm`.
//
// Two beats, choreographed so the mark lands after the seal settles:
//   1. the ring pops from `restScale` to full with a `springBouncy` overshoot,
//   2. the check draws with a short `checkDelay`, its length revealed by `trim`.
//
// A `.success` haptic fires as the seal stamps in. No borders: the ring is a
// filled `Circle`, lifted off the glass by a soft ambient shadow — the check is
// a stroked path (drawing content, not a surface edge). Colors come from the
// theme: the ring is a status fill (`palette.success`), so the mark on top is
// `palette.textOnPrimary` per the accent-role rules.

public struct DSSuccessCheck: View {

    // MARK: Metrics
    // Geometry proportions and timing offsets, tuned by eye against the glass
    // surfaces the seal sits on. Not layout tokens: they describe *this* drawing,
    // the way `DSToggle` sizes or the `DSParticleField` constants describe theirs.
    private enum Metrics {
        /// Stroke width as a fraction of the seal size, floored so tiny seals
        /// keep a readable mark.
        static let strokeRatio: CGFloat = 0.09
        static let minStroke: CGFloat = 2
        /// Scale the seal starts at before it pops in.
        static let restScale: CGFloat = 0.4
        /// Gap between the ring settling and the mark starting to draw.
        static let checkDelay: Double = 0.12
    }

    let size: CGFloat
    let tint: Color?
    let checkColor: Color?
    let haptic: DSHapticStyle?
    let animated: Bool

    @State private var ringIn = false
    @State private var checkProgress: CGFloat = 0

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - size: Diameter of the seal. Defaults to `DSSpacing.massive` (64).
    ///   - tint: Ring fill. Defaults to `palette.success`.
    ///   - checkColor: Checkmark stroke. Defaults to `palette.textOnPrimary`.
    ///   - haptic: Fired as the seal stamps in. Pass `nil` to silence it.
    ///   - animated: Play the pop-and-draw on appear. `false` renders the final
    ///     state statically — for a list of already-completed items.
    public init(
        size: CGFloat = DSSpacing.massive,
        tint: Color? = nil,
        checkColor: Color? = nil,
        haptic: DSHapticStyle? = .success,
        animated: Bool = true
    ) {
        self.size = size
        self.tint = tint
        self.checkColor = checkColor
        self.haptic = haptic
        self.animated = animated
    }

    public var body: some View {
        let strokeWidth = max(size * Metrics.strokeRatio, Metrics.minStroke)

        ZStack {
            Circle()
                .fill(tint ?? theme.palette.success)

            DSCheckmarkShape()
                .trim(from: 0, to: checkProgress)
                .stroke(
                    checkColor ?? theme.palette.textOnPrimary,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                )
        }
        .frame(width: size, height: size)
        .scaleEffect(ringIn ? 1 : Metrics.restScale)
        .opacity(ringIn ? 1 : 0)
        .dsShadow(.md)
        .onAppear(perform: play)
        .accessibilityLabel(Text("Success"))
    }

    private func play() {
        // Static: no play, no event — so no haptic either.
        guard animated else {
            ringIn = true
            checkProgress = 1
            return
        }
        // Reduce Motion settles at the resting state instead of skipping the
        // seal; the haptic still carries the confirmation.
        guard !reduceMotion else {
            ringIn = true
            checkProgress = 1
            if let haptic { DSHapticEngine.shared.fire(haptic) }
            return
        }
        withAnimation(DSAnimation.springBouncy) { ringIn = true }
        withAnimation(DSAnimation.normal.delay(Metrics.checkDelay)) { checkProgress = 1 }
        if let haptic { DSHapticEngine.shared.fire(haptic) }
    }
}

// MARK: - Checkmark Shape

/// Three points — left tip, bottom vertex, top-right tip — laid out as fractions
/// of the box. Stroked and trimmed by `DSSuccessCheck` so the tick draws on.
private struct DSCheckmarkShape: Shape {
    // Checkmark vertices as fractions of the box.
    private let tip = CGPoint(x: 0.28, y: 0.53)
    private let vertex = CGPoint(x: 0.43, y: 0.68)
    private let peak = CGPoint(x: 0.72, y: 0.34)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * tip.x, y: h * tip.y))
        path.addLine(to: CGPoint(x: w * vertex.x, y: h * vertex.y))
        path.addLine(to: CGPoint(x: w * peak.x, y: h * peak.y))
        return path
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSuccessCheckPreviewHost: View {
    @State private var theme = DSTheme()
    // Re-mounting with `.id` replays the choreography — the same trick the
    // DSSlideToConfirm catalog uses to run its animation again.
    @State private var attempt = 0

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                HStack(spacing: DSSpacing.xl) {
                    DSSuccessCheck(size: DSSpacing.xl).id(attempt)
                    DSSuccessCheck(size: DSSpacing.xxxl, tint: DSColors.secondary).id(attempt)
                    DSSuccessCheck(size: DSSpacing.xxxl, animated: false)
                }

                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        DSSuccessCheck().id(attempt)
                        Text("Payment confirmed").ds(.title3)
                        Text("Your order is on its way")
                            .ds(.callout, color: DSColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                DSButton("Play again") { attempt += 1 }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Success Check — Light") {
    DSSuccessCheckPreviewHost().preferredColorScheme(.light)
}

#Preview("Success Check — Dark") {
    DSSuccessCheckPreviewHost().preferredColorScheme(.dark)
}
#endif
