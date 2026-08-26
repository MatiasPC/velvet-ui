import SwiftUI

// MARK: - Design System Animated Number
// A numeric display that rolls smoothly between values — the same
// count-up/count-down motion Apple uses in the stock Timer and Stopwatch.
// Built on iOS 17's `.contentTransition(.numericText(value:))`, it turns any
// changing figure (a cart total, a like count, a live stat, a price) into a
// premium, tactile moment. Monospaced digits keep the layout rock-steady while
// the numbers animate, and a haptic ticks on every change.

// MARK: - Number Style

/// How a value is formatted for display.
public enum DSNumberStyle {
    /// Whole number with grouping separators — `1,234`
    case plain
    /// Fixed fraction digits with grouping — `1,234.50`
    case decimal(Int)
    /// Localized currency for an ISO code — `$1,234.00`
    case currency(String)
    /// Percentage of a `0...1` fraction — `0.65` renders as `65%`
    case percent
    /// Fully custom formatting.
    case custom(@Sendable (Double) -> String)

    func string(for value: Double) -> String {
        switch self {
        case .plain:
            return value.formatted(.number.precision(.fractionLength(0)))
        case .decimal(let places):
            return value.formatted(.number.precision(.fractionLength(max(0, places))))
        case .currency(let code):
            return value.formatted(.currency(code: code))
        case .percent:
            return value.formatted(.percent.precision(.fractionLength(0)))
        case .custom(let transform):
            return transform(value)
        }
    }
}

// MARK: - Animated Number

public struct DSAnimatedNumber: View {

    // MARK: - Configuration

    private let value: Double
    private let style: DSNumberStyle
    private let textStyle: DSTextStyle
    private let color: Color?
    private let animation: Animation
    private let haptic: DSHapticStyle?

    // MARK: - Init

    /// Create an animated number that rolls between values as `value` changes.
    /// - Parameters:
    ///   - value: The number to display. Changing it animates the digits.
    ///   - style: How the value is formatted. Defaults to `.plain`.
    ///   - textStyle: Design System type scale for the figure. Defaults to `.displayMedium`.
    ///   - color: Text color. Defaults to the primary text color.
    ///   - animation: Spring used to drive the roll. Defaults to `DSAnimation.springSmooth`.
    ///   - haptic: Feedback fired on each change. Pass `nil` to silence. Defaults to `.light`.
    public init(
        _ value: Double,
        style: DSNumberStyle = .plain,
        textStyle: DSTextStyle = .displayMedium,
        color: Color? = nil,
        animation: Animation = DSAnimation.springSmooth,
        haptic: DSHapticStyle? = .light
    ) {
        self.value = value
        self.style = style
        self.textStyle = textStyle
        self.color = color
        self.animation = animation
        self.haptic = haptic
    }

    // MARK: - Body

    public var body: some View {
        Text(style.string(for: value))
            .font(textStyle.font.monospacedDigit())
            .kerning(textStyle.kerning)
            .foregroundStyle(color ?? DSColors.defaultPalette.textPrimary)
            .contentTransition(.numericText(value: value))
            .animation(animation, value: value)
            .onChange(of: value) { _, _ in
                if let haptic {
                    DSHapticEngine.shared.fire(haptic)
                }
            }
            .accessibilityLabel(Text(style.string(for: value)))
    }
}

// MARK: - Preview

#Preview("Light") {
    AnimatedNumberPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    AnimatedNumberPreview()
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct AnimatedNumberPreview: View {
    @State private var count: Double = 1250
    @State private var price: Double = 49.99
    @State private var progress: Double = 0.65

    var body: some View {
        VStack(spacing: DSSpacing.xxl) {
            VStack(spacing: DSSpacing.xs) {
                Text("FOLLOWERS").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                DSAnimatedNumber(count)
                HStack(spacing: DSSpacing.sm) {
                    DSButton("−100", variant: .outline, size: .small) { count = max(0, count - 100) }
                    DSButton("+100", variant: .primary, size: .small) { count += 100 }
                }
            }

            HStack(spacing: DSSpacing.xxl) {
                VStack(spacing: DSSpacing.xs) {
                    Text("PRICE").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSAnimatedNumber(
                        price,
                        style: .currency("USD"),
                        textStyle: .title1,
                        color: DSColors.defaultPalette.primary
                    )
                }
                VStack(spacing: DSSpacing.xs) {
                    Text("SAVINGS").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSAnimatedNumber(
                        progress,
                        style: .percent,
                        textStyle: .title1,
                        color: DSColors.defaultPalette.success
                    )
                }
            }

            DSButton("Shuffle", variant: .secondary) {
                price = Double.random(in: 10...199).rounded() - 0.01
                progress = Double.random(in: 0...1)
            }
        }
    }
}
