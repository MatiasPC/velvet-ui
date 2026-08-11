import SwiftUI

// MARK: - Design System Odometer
// A mechanical rolling-number counter. Each digit lives on its own vertical
// wheel that physically rolls through every value in between — like a car
// odometer or a split-flap board — so a change from 194 to 210 spins the
// units wheel up through 5…9…0 while the tens and hundreds wheels turn with
// it. Perfect for prices, live stats, scores, step counts and cart totals.
//
// Distinct from `DSAnimatedNumber`, which cross-fades only the glyphs that
// change via the system `.numericText()` transition. `DSOdometer` gives the
// tactile, continuous "rolling" motion where the whole wheel travels.

public struct DSOdometer: View {

    // MARK: - Configuration

    private let value: Int
    private let textStyle: DSTextStyle
    private let color: Color
    private let minimumDigits: Int
    private let grouping: Bool
    private let groupingSeparator: String
    private let prefix: String?
    private let suffix: String?
    private let animation: Animation
    private let fade: Bool
    private let animatesOnAppear: Bool
    private let haptics: Bool

    // MARK: - State

    /// The value the wheels are currently showing. Animating this — rather
    /// than `value` directly — is what drives the roll.
    @State private var displayed: Int

    /// Minimum number of wheels to render. Seeded to the target's width when
    /// counting up from zero so every digit rolls together, then relaxed to
    /// `minimumDigits` once the value starts changing on its own.
    @State private var renderDigits: Int

    // MARK: - Initializer

    /// A rolling-wheel numeric counter.
    /// - Parameters:
    ///   - value: The whole number to display. Negative values roll with a leading minus.
    ///   - textStyle: Typography for the digits. Defaults to `.displayMedium`.
    ///   - color: Digit color. Defaults to the primary text color.
    ///   - minimumDigits: Pad with leading zeros to at least this many digits
    ///     (e.g. `2` shows `07`). Defaults to `1`.
    ///   - grouping: Insert thousands separators (e.g. `12,480`). Defaults to `false`.
    ///   - groupingSeparator: The separator glyph used when `grouping` is on. Defaults to `","`.
    ///   - prefix: Optional leading string, e.g. `"$"`. Defaults to `nil`.
    ///   - suffix: Optional trailing string, e.g. `"%"` or `" pts"`. Defaults to `nil`.
    ///   - animation: Spring used for the roll. Defaults to `DSAnimation.springSmooth`.
    ///   - fade: Fade the wheels at their top/bottom edges for an odometer look. Defaults to `true`.
    ///   - animatesOnAppear: Roll up from zero when the view first appears. Defaults to `true`.
    ///   - haptics: Fire a selection tick when the value changes. Defaults to `true`.
    public init(
        value: Int,
        textStyle: DSTextStyle = .displayMedium,
        color: Color = DSColors.defaultPalette.textPrimary,
        minimumDigits: Int = 1,
        grouping: Bool = false,
        groupingSeparator: String = ",",
        prefix: String? = nil,
        suffix: String? = nil,
        animation: Animation = DSAnimation.springSmooth,
        fade: Bool = true,
        animatesOnAppear: Bool = true,
        haptics: Bool = true
    ) {
        self.value = value
        self.textStyle = textStyle
        self.color = color
        self.minimumDigits = max(1, minimumDigits)
        self.grouping = grouping
        self.groupingSeparator = groupingSeparator
        self.prefix = prefix
        self.suffix = suffix
        self.animation = animation
        self.fade = fade
        self.animatesOnAppear = animatesOnAppear
        self.haptics = haptics
        self._displayed = State(initialValue: animatesOnAppear ? 0 : value)
        let targetWidth = String(abs(value)).count
        self._renderDigits = State(
            initialValue: max(self.minimumDigits, animatesOnAppear ? targetWidth : 0)
        )
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 0) {
            if let prefix { affix(prefix) }
            if displayed < 0 { affix("-") }

            ForEach(tokens) { token in
                switch token {
                case let .digit(_, digit):
                    DSOdometerWheel(
                        digit: digit,
                        textStyle: textStyle,
                        color: color,
                        animation: animation,
                        fade: fade
                    )
                case .separator:
                    affix(groupingSeparator)
                }
            }

            if let suffix { affix(suffix) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
        .onAppear {
            guard animatesOnAppear, displayed != value else { return }
            displayed = value
        }
        .onChange(of: value) { _, newValue in
            if haptics, newValue != displayed {
                DSHapticEngine.shared.fire(.selection)
            }
            renderDigits = minimumDigits
            displayed = newValue
        }
    }

    // MARK: - Affix Text

    /// A non-rolling glyph (prefix, suffix, minus, separator) that matches the
    /// digit metrics so everything aligns on one baseline.
    private func affix(_ text: String) -> some View {
        Text(text)
            .font(textStyle.font.monospacedDigit())
            .foregroundStyle(color)
    }

    // MARK: - Derived Values

    /// The digits of the currently displayed value, most-significant first,
    /// padded with leading zeros to `renderDigits`.
    private var digits: [Int] {
        var arr = String(abs(displayed)).compactMap { $0.wholeNumberValue }
        while arr.count < renderDigits { arr.insert(0, at: 0) }
        return arr
    }

    /// The render sequence of wheels and grouping separators.
    private var tokens: [Token] {
        let ds = digits
        let count = ds.count
        var result: [Token] = []
        for (index, digit) in ds.enumerated() {
            let place = count - 1 - index
            if grouping, index != 0, (place + 1) % 3 == 0 {
                result.append(.separator(place: place))
            }
            result.append(.digit(place: place, value: digit))
        }
        return result
    }

    private var accessibilityText: String {
        var parts = ""
        if let prefix { parts += prefix }
        parts += String(value)
        if let suffix { parts += suffix }
        return parts
    }

    // MARK: - Token Model

    /// One slot in the rendered row: a rolling digit wheel or a static separator.
    /// `place` is the digit's power-of-ten position from the right, giving each
    /// wheel a stable identity as the number grows or shrinks.
    private enum Token: Identifiable {
        case digit(place: Int, value: Int)
        case separator(place: Int)

        var id: String {
            switch self {
            case let .digit(place, _): return "d\(place)"
            case let .separator(place): return "s\(place)"
            }
        }
    }
}

// MARK: - Rolling Digit Wheel

/// A single 0–9 wheel. An invisible reference glyph drives the layout size,
/// and the visible column of ten digits is offset so the target digit sits in
/// the window, then clipped and animated for the mechanical roll.
private struct DSOdometerWheel: View {
    let digit: Int
    let textStyle: DSTextStyle
    let color: Color
    let animation: Animation
    let fade: Bool

    var body: some View {
        Text("0")
            .font(textStyle.font.monospacedDigit())
            .opacity(0)                       // sizing driver: one digit tall & wide
            .overlay {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        ForEach(0..<10, id: \.self) { number in
                            Text("\(number)")
                                .font(textStyle.font.monospacedDigit())
                                .foregroundStyle(color)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                    .offset(y: -CGFloat(digit) * geo.size.height)
                    .animation(animation, value: digit)
                }
                .clipped()
                .mask { fadeMask }
            }
            .accessibilityHidden(true)
    }

    /// Soft top/bottom fade so incoming digits appear to roll behind an edge.
    @ViewBuilder
    private var fadeMask: some View {
        if fade {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.22),
                    .init(color: .black, location: 0.78),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            Color.black
        }
    }
}

// MARK: - Preview

#Preview {
    struct OdometerPreview: View {
        @State private var steps = 194
        @State private var price = 12_480
        @State private var score = 7

        var body: some View {
            VStack(spacing: DSSpacing.xxl) {
                VStack(spacing: DSSpacing.xs) {
                    Text("Steps today").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSOdometer(value: steps, color: DSColors.defaultPalette.primary)
                    DSButton("Walk +37", size: .small) { steps += 37 }
                }

                VStack(spacing: DSSpacing.xs) {
                    Text("Revenue").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSOdometer(
                        value: price,
                        textStyle: .title1,
                        color: DSColors.defaultPalette.success,
                        grouping: true,
                        prefix: "$"
                    )
                    DSButton("Sale +2,000", variant: .secondary, size: .small) { price += 2_000 }
                }

                VStack(spacing: DSSpacing.xs) {
                    Text("Level").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSOdometer(value: score, textStyle: .displayLarge, minimumDigits: 2)
                    DSButton("Next", variant: .outline, size: .small) { score += 1 }
                }
            }
            .padding(DSSpacing.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return Group {
        OdometerPreview().preferredColorScheme(.light)
        OdometerPreview().preferredColorScheme(.dark)
    }
}
