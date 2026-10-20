import SwiftUI

// MARK: - Design System Success Check
// The payoff of a flow: the single moment that says "done". A soft tinted disc
// springs in, a checkmark strokes itself on across it, and a halo ripples
// outward once before fading — the visual echo of the success haptic that fires
// with it. Built to be mounted the instant an async action resolves (a payment
// clears, a file uploads, a form saves): conditionally rendering it *is* the
// trigger, so there is no play/stop API to wire up.
//
// The mark draws itself the way SwiftUI draws any stroke-on: a three-point
// `Path`, trimmed `0 → progress` *before* it is stroked, with the trim animated
// inside `withAnimation`. `DSSlideToConfirm` already ends on a tiny SF-Symbol
// check inside its knob; this is the standalone, screen-worthy version for the
// success state a flow hands off to — not a duplicate of it.
//
// Technique (animating `Shape.trim` to draw a stroke) adapted from:
//   - "How to create and animate checkboxes in SwiftUI" (Better Programming)
//   - Cindori — "Animating a Circular Progress Bar in SwiftUI"
// No upstream code is reproduced; the choreography and tokens are Velvet's own.

// MARK: - Metrics

/// Shaping constants. Sizes that must scale with the seal are kept as fractions
/// of its diameter (there is no spacing token for "a tenth of this view");
/// every value with a token equivalent uses the token, and every animation
/// comes from `DSAnimation`.
private enum Metrics {
    /// Checkmark stroke width as a fraction of the seal diameter. Bold enough to
    /// read as a deliberate mark, not a hairline.
    static let lineWidthFraction: CGFloat = 0.1
    /// Opacity of the tinted backing disc. Soft on purpose — the drawn mark is
    /// the hero; the disc only seats it, matching Velvet's wash-not-fill language.
    static let discOpacity: Double = 0.15
    /// Scale the seal grows from as it pops in.
    static let popFromScale: CGFloat = 0.5
    /// How far the halo ring expands past the seal before it has fully faded.
    static let haloMaxScale: CGFloat = 1.6
    /// Peak opacity of the halo ripple, at the instant it is born at the rim.
    static let haloOpacity: Double = 0.35
    /// Beat between the disc popping in and the mark starting to draw, so the
    /// stroke lands *onto* a settled disc rather than racing it.
    static let drawDelay: Double = 0.12
}

// MARK: - Checkmark Shape

/// A checkmark as one open polyline, ordered short arm → corner → long arm so
/// `trim(from: 0, to:)` reveals it the way a hand would draw it. Points are
/// fractions of the bounding rect, balanced around its centre.
private struct DSCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.27, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.43, y: h * 0.68))
        path.addLine(to: CGPoint(x: w * 0.73, y: h * 0.34))
        return path
    }
}

// MARK: - DSSuccessCheck

/// An animated success seal: a tinted disc with a checkmark that draws itself on,
/// a one-shot halo ripple and a success haptic — the "done" moment of a flow.
///
///     if didComplete {
///         DSSuccessCheck()
///     }
///
/// Mount it when the action resolves; it plays once on appear. To play it again,
/// re-mount it with `.id(attempt)` — the same reset `DSSlideToConfirm` documents.
public struct DSSuccessCheck: View {

    private let size: CGFloat
    private let tint: Color?
    private let haptic: DSHapticStyle?
    private let accessibilityLabel: String

    @State private var hasAppeared = false
    @State private var drawProgress: CGFloat = 0
    @State private var haloProgress: CGFloat = 0

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - size: Diameter of the seal. Defaults to `DSSpacing.massive` (64) — a
    ///     hero size for a dedicated success state.
    ///   - tint: Disc and mark color. Defaults to `theme.palette.success`.
    ///   - haptic: Fired once as the seal lands. Defaults to `.success`; pass
    ///     `nil` for a purely decorative mark.
    ///   - accessibilityLabel: Announced by VoiceOver. Defaults to "Success".
    public init(
        size: CGFloat = DSSpacing.massive,
        tint: Color? = nil,
        haptic: DSHapticStyle? = .success,
        accessibilityLabel: String = "Success"
    ) {
        self.size = size
        self.tint = tint
        self.haptic = haptic
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        let resolvedTint = tint ?? theme.palette.success
        let lineWidth = size * Metrics.lineWidthFraction

        ZStack {
            // Halo ripple: a ring born at the seal's rim that expands outward and
            // fades, once. Pure decoration, so it is skipped under Reduce Motion —
            // at rest it would otherwise sit as a static ring.
            if !reduceMotion {
                Circle()
                    .stroke(resolvedTint, lineWidth: lineWidth)
                    .scaleEffect(1 + (Metrics.haloMaxScale - 1) * haloProgress)
                    .opacity(Metrics.haloOpacity * (1 - Double(haloProgress)))
            }

            // The seal: tinted disc + the mark that draws itself across it. Scale
            // travels only when motion is allowed; the fade is kept either way
            // (opacity is not motion).
            ZStack {
                Circle()
                    .fill(resolvedTint.opacity(Metrics.discOpacity))

                DSCheckmarkShape()
                    .trim(from: 0, to: drawProgress)
                    .stroke(
                        resolvedTint,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
            }
            .scaleEffect(hasAppeared ? 1 : startScale)
            .opacity(hasAppeared ? 1 : 0)
        }
        .frame(width: size, height: size)
        .onAppear(perform: play)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isImage)
    }

    /// Pinned at rest under Reduce Motion so the seal never travels; otherwise it
    /// grows in from `popFromScale`.
    private var startScale: CGFloat {
        reduceMotion ? 1 : Metrics.popFromScale
    }

    private func play() {
        if let haptic {
            DSHapticEngine.shared.fire(haptic)
        }

        if reduceMotion {
            // Settle fully formed: the mark is already drawn, the seal only fades
            // in. Nothing travels, no halo.
            drawProgress = 1
            withAnimation(DSAnimation.fast) { hasAppeared = true }
            return
        }

        withAnimation(DSAnimation.springBouncy) { hasAppeared = true }
        withAnimation(DSAnimation.normal.delay(Metrics.drawDelay)) { drawProgress = 1 }
        withAnimation(DSAnimation.slow.delay(Metrics.drawDelay)) { haloProgress = 1 }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSuccessCheckPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var attempt = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                // Hero success state. Re-mounted with `.id` to replay.
                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        DSSuccessCheck()
                            .id(attempt)
                        Text("Payment sent").ds(.title3)
                        Text("Your transfer of $42.00 is on its way.")
                            .ds(.callout, color: DSColors.textSecondary)
                            .multilineTextAlignment(.center)
                        DSButton("Replay", variant: .ghost, size: .small) {
                            attempt += 1
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Sizes and a custom tint. Haptics muted on the secondary marks so
                // a single replay fires exactly one success tap.
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        VStack(spacing: DSSpacing.xs) {
                            DSSuccessCheck(size: DSSpacing.xxl, haptic: nil)
                                .id(attempt)
                            Text("32pt").ds(.caption1, color: DSColors.textTertiary)
                        }
                        VStack(spacing: DSSpacing.xs) {
                            DSSuccessCheck(size: DSSpacing.huge, tint: DSColors.secondary, haptic: nil)
                                .id(attempt)
                            Text("Custom tint").ds(.caption1, color: DSColors.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
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
