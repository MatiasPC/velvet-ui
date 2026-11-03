import SwiftUI

// MARK: - Design System Typography
// Clean sans with tight tracking for titles (SF Pro), rounded for numbers and
// buttons (SF Pro Rounded) — that mix is the Velvet voice. Display styles use
// monospaced digits so counters and timers don't jitter.

public enum DSTextStyle: CaseIterable, Sendable {
    /// 34pt Bold, −0.8 tracking — Hero headlines, onboarding screens
    case hero
    /// 28pt Bold, −0.6 — Screen titles
    case largeTitle
    /// 22pt Semibold, −0.4 — Section headers
    case title1
    /// 20pt Semibold, −0.3 — Card titles, prominent labels
    case title2
    /// 17pt Semibold, −0.2 — Subsection headers
    case title3
    /// 17pt Regular — Primary body text
    case body
    /// 15pt Regular — Secondary content, descriptions
    case callout
    /// 13pt Medium — Labels, metadata
    case footnote
    /// 12pt Regular — Timestamps, auxiliary info
    case caption1
    /// 11pt Regular — Legal text, fine print
    case caption2
    /// 15pt Semibold Rounded — Button labels
    case button
    /// 13pt Semibold Rounded — Small button labels, tags
    case buttonSmall
    /// 11pt Bold, uppercase, +1.2 tracking — Section overlines
    case overline
    /// 60pt Bold Rounded, monospaced digits — Large display numbers (timers, stats)
    case displayLarge
    /// 40pt Bold Rounded, monospaced digits — Medium display numbers
    case displayMedium
    /// 17pt Semibold Rounded, monospaced digits — Inline numbers: prices, counters, timers
    case numeric
    /// 11pt Bold Rounded — Count badges, tiny numerals
    case badge

    /// Base point size at the default Dynamic Type setting.
    public var size: CGFloat {
        switch self {
        case .hero:          return 34
        case .largeTitle:    return 28
        case .title1:        return 22
        case .title2:        return 20
        case .title3:        return 17
        case .body:          return 17
        case .callout:       return 15
        case .footnote:      return 13
        case .caption1:      return 12
        case .caption2:      return 11
        case .button:        return 15
        case .buttonSmall:   return 13
        case .overline:      return 11
        case .displayLarge:  return 60
        case .displayMedium: return 40
        case .numeric:       return 17
        case .badge:         return 11
        }
    }

    public var weight: Font.Weight {
        switch self {
        case .hero, .largeTitle, .overline, .displayLarge, .displayMedium, .badge:
            return .bold
        case .title1, .title2, .title3, .button, .buttonSmall, .numeric:
            return .semibold
        case .footnote:
            return .medium
        case .body, .callout, .caption1, .caption2:
            return .regular
        }
    }

    public var design: Font.Design {
        switch self {
        case .button, .buttonSmall, .displayLarge, .displayMedium, .numeric, .badge:
            return .rounded
        default:
            return .default
        }
    }

    /// The system text style whose Dynamic Type curve this style scales along.
    public var textStyle: Font.TextStyle {
        switch self {
        case .hero, .displayLarge, .displayMedium: return .largeTitle
        case .largeTitle:    return .title
        case .title1:        return .title2
        case .title2:        return .title3
        case .title3:        return .headline
        case .body, .numeric: return .body
        case .callout:       return .callout
        case .footnote, .buttonSmall: return .footnote
        case .caption1:      return .caption
        case .caption2, .overline, .badge: return .caption2
        case .button:        return .subheadline
        }
    }

    /// Whether digits are monospaced so counters and timers don't jitter.
    var usesMonospacedDigits: Bool {
        switch self {
        case .displayLarge, .displayMedium, .numeric: return true
        default: return false
        }
    }

    /// Fixed-size font at the base `size`. It does NOT scale with Dynamic Type;
    /// use `.ds(_:)` / `.dsTextStyle(_:)` / `.dsFont(_:)` for the scaling path.
    public var font: Font {
        let base = Font.system(size: size, weight: weight, design: design)
        return usesMonospacedDigits ? base.monospacedDigit() : base
    }

    public var lineSpacing: CGFloat {
        switch self {
        case .hero:          return 4
        case .largeTitle:    return 4
        case .title1:        return 2
        case .title2:        return 2
        case .title3:        return 2
        case .body:          return 4
        case .callout:       return 3
        case .footnote:      return 2
        case .caption1:      return 2
        case .caption2:      return 1
        case .button:        return 0
        case .buttonSmall:   return 0
        case .overline:      return 0
        case .displayLarge:  return 0
        case .displayMedium: return 0
        case .numeric:       return 0
        case .badge:         return 0
        }
    }

    public var kerning: CGFloat {
        switch self {
        case .hero:          return -0.8
        case .largeTitle:    return -0.6
        case .title1:        return -0.4
        case .title2:        return -0.3
        case .title3:        return -0.2
        case .overline:      return 1.2
        case .displayLarge:  return -1.2
        case .displayMedium: return -0.6
        default:             return 0
        }
    }
}

// MARK: - Text Style View Modifier

public struct DSTextStyleModifier: ViewModifier {
    let style: DSTextStyle
    let color: Color?

    @ScaledMetric private var size: CGFloat
    @ScaledMetric private var lineSpacing: CGFloat
    @DSThemed private var theme

    public init(style: DSTextStyle, color: Color? = nil) {
        self.style = style
        self.color = color
        self._size = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle)
        self._lineSpacing = ScaledMetric(wrappedValue: style.lineSpacing, relativeTo: style.textStyle)
    }

    public func body(content: Content) -> some View {
        content
            .font(scaledFont(style, size: size))
            .lineSpacing(lineSpacing)
            .kerning(style.kerning)
            .foregroundStyle(color ?? theme.palette.textPrimary)
            .textCase(style == .overline ? .uppercase : nil)
    }
}

fileprivate func scaledFont(_ style: DSTextStyle, size: CGFloat) -> Font {
    let base = Font.system(size: size, weight: style.weight, design: style.design)
    return style.usesMonospacedDigits ? base.monospacedDigit() : base
}

struct DSFontModifier: ViewModifier {
    let style: DSTextStyle
    @ScaledMetric private var size: CGFloat

    init(style: DSTextStyle) {
        self.style = style
        self._size = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle)
    }

    func body(content: Content) -> some View {
        content.font(scaledFont(style, size: size))
    }
}

public extension View {
    /// Apply a Design System text style
    func dsTextStyle(_ style: DSTextStyle, color: Color? = nil) -> some View {
        modifier(DSTextStyleModifier(style: style, color: color))
    }

    /// Apply only the style's font, scaled with Dynamic Type (no color, kerning or line spacing).
    /// Use instead of `.font(style.font)`, which is fixed-size.
    func dsFont(_ style: DSTextStyle) -> some View {
        modifier(DSFontModifier(style: style))
    }
}

// MARK: - Convenience Text Extension

public extension Text {
    /// Apply Design System text style directly to Text
    func ds(_ style: DSTextStyle, color: Color? = nil) -> some View {
        self.modifier(DSTextStyleModifier(style: style, color: color))
    }
}
