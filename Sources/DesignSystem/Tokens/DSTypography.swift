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

    public var font: Font {
        switch self {
        case .hero:          return .system(size: 34, weight: .bold, design: .default)
        case .largeTitle:    return .system(size: 28, weight: .bold, design: .default)
        case .title1:        return .system(size: 22, weight: .semibold, design: .default)
        case .title2:        return .system(size: 20, weight: .semibold, design: .default)
        case .title3:        return .system(size: 17, weight: .semibold, design: .default)
        case .body:          return .system(size: 17, weight: .regular, design: .default)
        case .callout:       return .system(size: 15, weight: .regular, design: .default)
        case .footnote:      return .system(size: 13, weight: .medium, design: .default)
        case .caption1:      return .system(size: 12, weight: .regular, design: .default)
        case .caption2:      return .system(size: 11, weight: .regular, design: .default)
        case .button:        return .system(size: 15, weight: .semibold, design: .rounded)
        case .buttonSmall:   return .system(size: 13, weight: .semibold, design: .rounded)
        case .overline:      return .system(size: 11, weight: .bold, design: .default)
        case .displayLarge:  return .system(size: 60, weight: .bold, design: .rounded).monospacedDigit()
        case .displayMedium: return .system(size: 40, weight: .bold, design: .rounded).monospacedDigit()
        case .numeric:       return .system(size: 17, weight: .semibold, design: .rounded).monospacedDigit()
        case .badge:         return .system(size: 11, weight: .bold, design: .rounded)
        }
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

    @DSThemed private var theme

    public func body(content: Content) -> some View {
        content
            .font(style.font)
            .lineSpacing(style.lineSpacing)
            .kerning(style.kerning)
            .foregroundStyle(color ?? theme.palette.textPrimary)
            .textCase(style == .overline ? .uppercase : nil)
    }
}

public extension View {
    /// Apply a Design System text style
    func dsTextStyle(_ style: DSTextStyle, color: Color? = nil) -> some View {
        modifier(DSTextStyleModifier(style: style, color: color))
    }
}

// MARK: - Convenience Text Extension

public extension Text {
    /// Apply Design System text style directly to Text
    func ds(_ style: DSTextStyle, color: Color? = nil) -> some View {
        self.modifier(DSTextStyleModifier(style: style, color: color))
    }
}
