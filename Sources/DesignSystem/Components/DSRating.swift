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
    private let tint: Color
    private let emptyColor: Color
    private let isEditable: Bool
    private let haptics: Bool

    // MARK: - State

    /// Live value while a drag is in progress (nil when idle).
    @State private var dragValue: Double? = nil

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
        tint: Color = DSColors.defaultPalette.warning,
        emptyColor: Color = DSColors.defaultPalette.border,
        haptics: Bool = true
    ) {
        self._rating = rating
        self.count = max(1, count)
        self.step = step <= 0 ? 1 : min(step, 1)
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
        tint: Color = DSColors.defaultPalette.warning,
        emptyColor: Color = DSColors.defaultPalette.border
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
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                star(at: index)
            }
        }
        .contentShape(Rectangle())
        .gesture(dragGesture, including: isEditable ? .all : .none)
        .animation(DSAnimation.springBouncy, value: displayValue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(formatted(displayValue)) out of \(count) stars")
        .accessibilityAddTraits(isEditable ? .isButton : [])
        .accessibilityAdjustableAction { direction in
            guard isEditable else { return }
            switch direction {
            case .increment: commit(min(rating + step, Double(count)))
            case .decrement: commit(max(rating - step, 0))
            @unknown default: break
            }
        }
    }

    // MARK: - Star Cell

    @ViewBuilder
    private func star(at index: Int) -> some View {
        let fill = fillFraction(for: index)
        let isActive = isEditable && dragValue != nil && index == activeIndex

        ZStack(alignment: .leading) {
            Image(systemName: emptySymbol)
                .foregroundStyle(emptyColor)

            Image(systemName: symbol)
                .foregroundStyle(tint)
                .mask(alignment: .leading) {
                    Rectangle()
                        .frame(width: size * CGFloat(fill))
                }
        }
        .font(.system(size: size))
        .frame(width: size, height: size)
        .scaleEffect(isActive ? 1.22 : 1.0)
        .animation(DSAnimation.springBouncy, value: isActive)
    }

    // MARK: - Derived Values

    /// The value currently shown — the live drag value if dragging, else the binding.
    private var displayValue: Double {
        dragValue ?? rating
    }

    /// Portion of star `index` that should be filled, in `0...1`.
    private func fillFraction(for index: Int) -> Double {
        min(max(displayValue - Double(index), 0), 1)
    }

    /// Zero-based index of the top-most filled star (the one that "pops").
    private var activeIndex: Int {
        Int(displayValue.rounded(.up)) - 1
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let new = rating(atX: value.location.x)
                guard new != dragValue else { return }
                if haptics, Int(new) != Int(dragValue ?? -1) {
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
        let cell = size + spacing
        guard cell > 0 else { return step }
        let raw = Double(x / cell)                 // 0..count across the row
        let starIndex = max(0, Int(raw))
        let frac = raw - Double(starIndex)
        let value: Double
        if step <= 0.5 {
            value = Double(starIndex) + (frac < 0.5 ? 0.5 : 1.0)
        } else {
            value = Double(starIndex) + 1.0
        }
        return min(max(value, step), Double(count))
    }

    private func commit(_ value: Double) {
        withAnimation(DSAnimation.springBouncy) {
            rating = value
        }
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
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
                    Text("Tap or drag").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSRating(rating: $rating)
                    Text("\(rating, specifier: "%.0f") / 5")
                        .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                }

                VStack(spacing: DSSpacing.sm) {
                    Text("Half steps").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSRating(rating: $halfRating, step: 0.5)
                    Text("\(halfRating, specifier: "%.1f") / 5")
                        .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                }

                VStack(spacing: DSSpacing.sm) {
                    Text("Read-only display").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSRating(value: 3.5)
                    DSRating(value: 4.0, symbol: "heart.fill", emptySymbol: "heart",
                             tint: DSColors.defaultPalette.primary)
                }
            }
            .padding(DSSpacing.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return Group {
        RatingPreview()
            .preferredColorScheme(.light)
        RatingPreview()
            .preferredColorScheme(.dark)
    }
}
