import SwiftUI

// MARK: - Design System Status Mark
// The payoff of a finished action: a ring that draws itself on, then a glyph —
// a check for success, a cross for failure — that strokes into the middle with a
// spring pop and one tap of haptic as it lands. It is the "done" counterpart to
// `DSThinkingIndicator`'s "working": show it the instant an async action
// resolves (a payment cleared, a form saved, a job refused) and let the draw
// carry the outcome instead of a static icon snapping in.
//
// Why draw the path instead of using `checkmark.circle.fill`: a symbol that
// simply appears reads as a state the screen was always in; a mark that draws
// itself reads as something that just *happened*. The ring and the glyph are
// custom `Shape`s trimmed from 0 → 1 (the same `trim → stroke` technique
// `DSCircularProgress` uses for its ring), so the whole thing is pure SwiftUI
// and both platforms build.
//
// It plays once, on appear. To replay it — a retry, a second confirmation —
// re-mount it with `.id(attempt)`, the same pattern `DSSlideToConfirm`
// documents for its morph.
//
// Technique adapted (not copied) from the community's trim-a-Shape idiom:
// Cindori's progress-ring trim, Better Programming's Shape/AnimatableData
// checkboxes, and kiliankoe/CircularCheckmarkProgress. Rewritten on Velvet
// tokens and the DSAnimation curves.

// MARK: - Outcome

/// The two outcomes a `DSStatusMark` can draw. Each carries the status color it
/// paints with, the notification haptic it fires, and a default VoiceOver label.
public enum DSStatusMarkOutcome: Sendable {
    /// A checkmark in `palette.success` with a `.success` haptic.
    case success
    /// A cross in `palette.error` with an `.error` haptic.
    case error

    var haptic: DSHapticStyle {
        switch self {
        case .success: return .success
        case .error:   return .error
        }
    }

    var defaultLabel: String {
        switch self {
        case .success: return "Success"
        case .error:   return "Error"
        }
    }

    func color(in palette: DSColorPalette) -> Color {
        switch self {
        case .success: return palette.success
        case .error:   return palette.error
        }
    }
}

// MARK: - Metrics

/// Shaping constants for the mark. Like `DSParticleField`'s mote sizes, these are
/// proportions of a size the caller chooses, not spacing — there is no token for
/// "how thick is a checkmark" — so they live here, tuned by eye and expressed as
/// fractions of the mark's box.
private enum Metrics {
    /// Ring stroke width, as a fraction of the mark's size. Lighter than the
    /// glyph so the ring frames the outcome instead of competing with it.
    static let ringWidthRatio: CGFloat = 0.06
    /// Glyph stroke width, as a fraction of the mark's size. A touch heavier, so
    /// the check or cross is what the eye lands on first.
    static let glyphWidthRatio: CGFloat = 0.09

    /// Scale the mark springs up from on appear. A little deeper than `DSPopIn`'s
    /// 0.8 so a confirmation arrives with weight rather than just fading in.
    static let entranceScale: CGFloat = 0.7

    // Checkmark vertices in unit space (0...1 within the mark's box): a short
    // down-stroke into the elbow, then the long up-stroke. Inset from every edge
    // so the glyph never kisses the ring.
    static let checkStart = CGPoint(x: 0.27, y: 0.52)
    static let checkElbow = CGPoint(x: 0.43, y: 0.68)
    static let checkEnd   = CGPoint(x: 0.73, y: 0.34)

    /// Distance of each cross endpoint from its edge, in unit space: two
    /// diagonals crossing at the centre.
    static let crossInset: CGFloat = 0.33
}

// MARK: - DSStatusMark

/// A self-drawing outcome indicator: a ring draws on, then a check (`.success`)
/// or cross (`.error`) strokes into place with a spring pop and a haptic.
///
///     // Show it when the action resolves; mount it fresh to replay.
///     if let outcome {
///         DSStatusMark(outcome)
///             .id(attempt)
///     }
///
/// - Note: It animates on appear and plays once per identity. Change the view's
///   `.id(_:)` to run the draw again.
public struct DSStatusMark: View {
    private let outcome: DSStatusMarkOutcome
    private let size: CGFloat
    private let tint: Color?
    private let haptics: Bool
    private let overrideLabel: String?

    @State private var ringProgress: CGFloat = 0
    @State private var glyphProgress: CGFloat = 0
    @State private var isRevealed = false
    @State private var hasPlayed = false

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - outcome: `.success` draws a check, `.error` draws a cross. Each picks
    ///     its own status color and haptic.
    ///   - size: Diameter of the ring, in points. The strokes scale with it.
    ///   - tint: Overrides the outcome's status color for both ring and glyph.
    ///     Defaults to `palette.success` / `palette.error`.
    ///   - haptics: Fire the outcome's notification haptic as the glyph lands.
    ///     Set `false` when many marks appear at once (a checklist) so they don't
    ///     buzz in a row.
    ///   - accessibilityLabel: VoiceOver label. Defaults to "Success" / "Error".
    public init(
        _ outcome: DSStatusMarkOutcome = .success,
        size: CGFloat = 64,
        tint: Color? = nil,
        haptics: Bool = true,
        accessibilityLabel: String? = nil
    ) {
        self.outcome = outcome
        self.size = size
        self.tint = tint
        self.haptics = haptics
        self.overrideLabel = accessibilityLabel
    }

    private var color: Color { tint ?? outcome.color(in: theme.palette) }

    private var restScale: CGFloat { reduceMotion ? 1 : Metrics.entranceScale }

    public var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: size * Metrics.ringWidthRatio, lineCap: .round)
                )
                // Circle's trim starts at 3 o'clock; rotate so the ring draws
                // from the top, like DSCircularProgress.
                .rotationEffect(.degrees(-90))

            glyph
        }
        .frame(width: size, height: size)
        .scaleEffect(isRevealed ? 1 : restScale)
        .onAppear(perform: play)
        .accessibilityElement()
        .accessibilityLabel(overrideLabel ?? outcome.defaultLabel)
        .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder
    private var glyph: some View {
        let style = StrokeStyle(
            lineWidth: size * Metrics.glyphWidthRatio,
            lineCap: .round,
            lineJoin: .round
        )
        switch outcome {
        case .success:
            DSCheckShape()
                .trim(from: 0, to: glyphProgress)
                .stroke(color, style: style)
        case .error:
            DSCrossShape()
                .trim(from: 0, to: glyphProgress)
                .stroke(color, style: style)
        }
    }

    /// Entrance pop, then the two-stage draw: the ring strokes on, and only once
    /// it closes does the glyph draw into the middle, so the outcome reads as
    /// landing *inside* a finished ring rather than racing it. The haptic fires
    /// in the glyph's completion — on the exact frame the mark is whole.
    ///
    /// Chaining through `withAnimation(_:completion:)` (iOS 17) means the glyph's
    /// delay is the ring's real duration, with no second copy of the timing to
    /// keep in sync.
    private func play() {
        guard !hasPlayed else { return }
        hasPlayed = true

        guard !reduceMotion else {
            // Reduce Motion settles at the finished state — no draw, no travel —
            // but the haptic still fires: it is feedback, not motion.
            ringProgress = 1
            glyphProgress = 1
            isRevealed = true
            fireHaptic()
            return
        }

        withAnimation(DSAnimation.springBouncy) { isRevealed = true }

        withAnimation(DSAnimation.normal) {
            ringProgress = 1
        } completion: {
            withAnimation(DSAnimation.fast) {
                glyphProgress = 1
            } completion: {
                fireHaptic()
            }
        }
    }

    private func fireHaptic() {
        guard haptics else { return }
        DSHapticEngine.shared.fire(outcome.haptic)
    }
}

// MARK: - Glyph Shapes

/// A checkmark drawn in unit space: down-stroke to the elbow, then up-stroke.
/// Trimmable, so `trim(from:to:)` draws it on in one continuous stroke.
private struct DSCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: rect.unitPoint(Metrics.checkStart))
        path.addLine(to: rect.unitPoint(Metrics.checkElbow))
        path.addLine(to: rect.unitPoint(Metrics.checkEnd))
        return path
    }
}

/// A cross of two diagonals. `trim` draws the first leg, then the second — which
/// reads as a deliberate "✗" being struck rather than both legs growing at once.
private struct DSCrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = Metrics.crossInset
        path.move(to: rect.unitPoint(CGPoint(x: inset, y: inset)))
        path.addLine(to: rect.unitPoint(CGPoint(x: 1 - inset, y: 1 - inset)))
        path.move(to: rect.unitPoint(CGPoint(x: 1 - inset, y: inset)))
        path.addLine(to: rect.unitPoint(CGPoint(x: inset, y: 1 - inset)))
        return path
    }
}

private extension CGRect {
    /// Map a point given in 0...1 unit space to a concrete point in this rect.
    func unitPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: minX + width * point.x, y: minY + height * point.y)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSStatusMarkPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var attempt = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(spacing: DSSpacing.lg) {
                        HStack(spacing: DSSpacing.xxl) {
                            mark("Paid", .success)
                            mark("Declined", .error)
                        }
                        .frame(maxWidth: .infinity)
                        .id(attempt) // re-mount to replay the draw

                        DSButton("Replay", variant: .ghost, size: .small) {
                            attempt += 1
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                DSCard {
                    HStack(spacing: DSSpacing.md) {
                        DSStatusMark(.success, size: 28, haptics: false)
                        Text("Changes saved").ds(.body)
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

    private func mark(_ title: String, _ outcome: DSStatusMarkOutcome) -> some View {
        VStack(spacing: DSSpacing.sm) {
            DSStatusMark(outcome)
            Text(title).ds(.footnote, color: DSColors.textSecondary)
        }
    }
}

#Preview("Status Mark — Light") {
    DSStatusMarkPreviewHost().preferredColorScheme(.light)
}

#Preview("Status Mark — Dark") {
    DSStatusMarkPreviewHost().preferredColorScheme(.dark)
}
#endif
