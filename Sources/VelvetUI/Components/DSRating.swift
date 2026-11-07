import SwiftUI

// MARK: - Design System Rating
// An interactive star-rating control with fluid drag-to-rate motion.
// Drag across the stars to set a value — the active star "pops" with a
// bouncy spring and each step fires a selection tick. Also renders
// fractional values (e.g. 3.5) as smoothly clipped partial fills, so the
// same component works for both input (reviews, feedback) and display.

public struct DSRating: View {

    // MARK: - Configuration

    @Binding private var rating: Double
    private let count: Int
    private let step: Double
    private let symbol: String
    private let emptySymbol: String
    private let size: CGFloat
    private let spacing: CGFloat
    private let tint: Color?
    private let emptyColor: Color?
    private let isEditable: Bool
    private let haptics: Bool

    // MARK: - State

    /// Live value while a drag is in progress (nil when idle).
    @State private var dragValue: Double? = nil
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Interactive Initializer

    /// Interactive rating bound to a value the user can drag or tap to set.
    /// - Parameters:
    ///   - rating: The current rating, in `0...count`.
    ///   - count: Number of stars. Defaults to 5.
    ///   - step: Snap increment while rating. Use `1` for whole stars or
    ///     `0.5` for half stars. Defaults to `1`.
    ///   - symbol: SF Symbol for a filled star. Defaults to `"star.fill"`.
    ///   - emptySymbol: SF Symbol for an empty star. Defaults to `"star"`.
    ///   - size: Point size of each star. Defaults to `28`.
    ///   - spacing: Gap between stars. Defaults to `DSSpacing.xs`.
    ///   - tint: Fill color for rated stars. Defaults to the warning amber.
    ///   - emptyColor: Color for unrated stars. Defaults to the border color.
    ///   - haptics: Whether to fire tactile feedback while rating. Defaults to `true`.
    public init(
        rating: Binding<Double>,
        count: Int = 5,
        step: Double = 1,
        symbol: String = "star.fill",
        emptySymbol: String = "star",
        size: CGFloat = 28,
        spacing: CGFloat = DSSpacing.xs,
        tint: Color? = nil,
        emptyColor: Color? = nil,
        haptics: Bool = true
    ) {
        self._rating = rating
        self.count = max(1, count)
        self.step = DSRatingLogic.effectiveStep(step)
        self.symbol = symbol
        self.emptySymbol = emptySymbol
        self.size = size
        self.spacing = spacing
        self.tint = tint
        self.emptyColor = emptyColor
        self.isEditable = true
        self.haptics = haptics
    }

    // MARK: - Read-only Initializer

    /// Non-interactive rating that displays a value, including fractional fills.
    /// - Parameters:
    ///   - value: The rating to display, in `0...count`.
    ///   - count: Number of stars. Defaults to 5.
    ///   - symbol: SF Symbol for a filled star. Defaults to `"star.fill"`.
    ///   - emptySymbol: SF Symbol for an empty star. Defaults to `"star"`.
    ///   - size: Point size of each star. Defaults to `20`.
    ///   - spacing: Gap between stars. Defaults to `DSSpacing.xxs`.
    ///   - tint: Fill color for rated stars. Defaults to the warning amber.
    ///   - emptyColor: Color for unrated stars. Defaults to the border color.
    public init(
        value: Double,
        count: Int = 5,
        symbol: String = "star.fill",
        emptySymbol: String = "star",
        size: CGFloat = 20,
        spacing: CGFloat = DSSpacing.xxs,
        tint: Color? = nil,
        emptyColor: Color? = nil
    ) {
        self._rating = .constant(value)
        self.count = max(1, count)
        self.step = 0.5
        self.symbol = symbol
        self.emptySymbol = emptySymbol
        self.size = size
        self.spacing = spacing
        self.tint = tint
        self.emptyColor = emptyColor
        self.isEditable = false
        self.haptics = false
    }

    // MARK: - Body

    public var body: some View {
        adjustable(
            HStack(spacing: spacing) {
                ForEach(0..<count, id: \.self) { index in
                    star(at: index)
                }
            }
            .contentShape(Rectangle())
            .gesture(dragGesture, including: isEditable ? .all : .none)
            .animation(fillAnimation, value: displayValue)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rating")
            .accessibilityValue(Self.accessibilityValue(rating: displayValue, count: count))
        )
    }

    /// Only the interactive form is adjustable. The read-only form drops the
    /// action so VoiceOver doesn't announce "adjustable" on a value it can't change.
    @ViewBuilder
    private func adjustable(_ content: some View) -> some View {
        if isEditable {
            content.accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: commit(DSRatingLogic.adjusted(rating, .increment, step: step, count: count))
                case .decrement: commit(DSRatingLogic.adjusted(rating, .decrement, step: step, count: count))
                @unknown default: break
                }
            }
        } else {
            content
        }
    }

    // MARK: - Star Cell

    @ViewBuilder
    private func star(at index: Int) -> some View {
        let fill = DSRatingLogic.fillFraction(for: index, value: displayValue)
        let isActive = isEditable && dragValue != nil && index == DSRatingLogic.activeStar(for: displayValue)

        ZStack(alignment: .leading) {
            Image(systemName: emptySymbol)
                .foregroundStyle(emptyColor ?? theme.palette.border)

            Image(systemName: symbol)
                .foregroundStyle(tint ?? theme.palette.warning)
                .mask(alignment: .leading) {
                    Rectangle()
                        .frame(width: size * CGFloat(fill))
                }
        }
        .font(.system(size: size))
        .frame(width: size, height: size)
        .scaleEffect(DSRatingLogic.popScale(isActive: isActive, reduceMotion: reduceMotion))
        .animation(reduceMotion ? nil : DSAnimation.springBouncy, value: isActive)
    }

    // MARK: - Derived Values

    /// The value currently shown — the live drag value if dragging, else the
    /// binding — clamped into `0...count`.
    private var displayValue: Double {
        DSRatingLogic.clamped(dragValue ?? rating, count: count)
    }

    /// Fills spring between values; under Reduce Motion they ease quickly instead.
    private var fillAnimation: Animation {
        reduceMotion ? DSAnimation.micro : DSAnimation.springBouncy
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let new = rating(atX: value.location.x)
                guard new != dragValue else { return }
                if haptics, DSRatingLogic.shouldTick(from: dragValue, to: new) {
                    DSHapticEngine.shared.fire(.selection)
                }
                dragValue = new
            }
            .onEnded { value in
                let new = rating(atX: value.location.x)
                if haptics { DSHapticEngine.shared.fire(.light) }
                commit(new)
                dragValue = nil
            }
    }

    /// Map a horizontal touch position to a snapped rating value.
    private func rating(atX x: CGFloat) -> Double {
        DSRatingLogic.value(atX: Double(x), size: Double(size), spacing: Double(spacing), step: step, count: count)
    }

    private func commit(_ value: Double) {
        withAnimation(fillAnimation) {
            rating = value
        }
    }

    /// VoiceOver value, e.g. "3 out of 5 stars" or "4.5 out of 5 stars". Values
    /// outside `0...count` read as the nearest bound, matching what's drawn.
    static func accessibilityValue(rating: Double, count: Int) -> String {
        "\(DSRatingLogic.formatted(DSRatingLogic.clamped(rating, count: count))) out of \(count) stars"
    }
}

// MARK: - Logic

/// The rating's mapping and stepping, kept pure so tests can pin it without rendering.
enum DSRatingLogic {
    /// Which way a VoiceOver swipe moves the rating.
    enum Direction: Sendable {
        case increment, decrement
    }

    /// How far the active star grows while a drag rests on it.
    static let activeScale: CGFloat = 1.22

    /// `step`, guarded: zero, negative or NaN falls back to whole stars, and
    /// anything above one star is capped at one.
    static func effectiveStep(_ step: Double) -> Double {
        step > 0 ? min(step, 1) : 1
    }

    /// `rating` clamped into `0...count`; NaN reads as 0.
    static func clamped(_ rating: Double, count: Int) -> Double {
        guard !rating.isNaN else { return 0 }
        return min(max(rating, 0), Double(max(1, count)))
    }

    /// The snapped value under a touch at `x` along the row. The touch lands on
    /// the step that contains it, rounded up, so touching any part of a star
    /// rates at least that far into it (whole stars: the touched star; half
    /// steps: its left or right half). Never below one step, never above `count`.
    static func value(atX x: Double, size: Double, spacing: Double, step: Double, count: Int) -> Double {
        let step = effectiveStep(step)
        let cell = size + spacing
        let upper = Double(max(1, count))
        guard cell > 0, x.isFinite else { return step }
        let raw = x / cell                         // 0..count across the row
        let snapped = ((raw / step + epsilon).rounded(.down) + 1) * step
        return tidy(min(max(snapped, step), upper))
    }

    /// One VoiceOver adjustment: moves to the next step on the `step` grid in
    /// `direction` (an off-grid value snaps onto it), clamped into `0...count`.
    static func adjusted(_ rating: Double, _ direction: Direction, step: Double, count: Int) -> Double {
        let step = effectiveStep(step)
        let position = clamped(rating, count: count) / step
        let target: Double
        switch direction {
        case .increment: target = ((position + epsilon).rounded(.down) + 1) * step
        case .decrement: target = ((position - epsilon).rounded(.up) - 1) * step
        }
        return tidy(clamped(target, count: count))
    }

    /// Portion of star `index` that is filled at `value`, in `0...1`.
    static func fillFraction(for index: Int, value: Double) -> Double {
        guard !value.isNaN else { return 0 }
        return min(max(value - Double(index), 0), 1)
    }

    /// Zero-based index of the top-most lit star (the one that pops); -1 at 0.
    static func activeStar(for value: Double) -> Int {
        guard value.isFinite else { return -1 }
        return Int(max(value, 0).rounded(.up)) - 1
    }

    /// The selection tick fires when the finger enters a new star: the first
    /// touch, then every change of the lit star. Half steps inside one star are silent.
    static func shouldTick(from old: Double?, to new: Double) -> Bool {
        guard let old else { return true }
        return activeStar(for: old) != activeStar(for: new)
    }

    /// The active star's scale. Reduce Motion keeps every star at rest.
    static func popScale(isActive: Bool, reduceMotion: Bool) -> CGFloat {
        isActive && !reduceMotion ? activeScale : 1
    }

    /// `value` for VoiceOver: whole numbers bare ("3"), otherwise up to two
    /// decimals with trailing zeros dropped ("2.5", "2.25", "4.33").
    static func formatted(_ value: Double) -> String {
        var text = String(format: "%.2f", tidy(value))
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text == "-0" ? "0" : text
    }

    // MARK: Helpers

    /// Absorbs floating-point error at step boundaries (0.1 × 3 is 0.30000000000000004).
    private static let epsilon = 1e-9

    /// Snapped values are rounded to a millionth of a star.
    private static let precision = 1e6

    /// Rounds away floating-point noise so snapped values compare and read cleanly.
    private static func tidy(_ value: Double) -> Double {
        (value * precision).rounded() / precision
    }
}

// MARK: - Preview

#Preview {
    struct RatingPreview: View {
        @State private var rating: Double = 3
        @State private var halfRating: Double = 2.5

        var body: some View {
            VStack(spacing: DSSpacing.xl) {
                VStack(spacing: DSSpacing.sm) {
                    Text("Tap or drag").ds(.overline, color: DSColors.textSecondary)
                    DSRating(rating: $rating)
                    Text("\(rating, specifier: "%.0f") / 5")
                        .ds(.callout, color: DSColors.textSecondary)
                }

                VStack(spacing: DSSpacing.sm) {
                    Text("Half steps").ds(.overline, color: DSColors.textSecondary)
                    DSRating(rating: $halfRating, step: 0.5)
                    Text("\(halfRating, specifier: "%.1f") / 5")
                        .ds(.callout, color: DSColors.textSecondary)
                }

                VStack(spacing: DSSpacing.sm) {
                    Text("Read-only display").ds(.overline, color: DSColors.textSecondary)
                    DSRating(value: 3.5)
                    DSRating(value: 4.0, symbol: "heart.fill", emptySymbol: "heart",
                             tint: DSColors.primary)
                }
            }
            .padding(DSSpacing.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.backgroundPrimary)
        }
    }

    return Group {
        RatingPreview()
            .preferredColorScheme(.light)
        RatingPreview()
            .preferredColorScheme(.dark)
    }
}
