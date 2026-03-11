import SwiftUI

// MARK: - Design System Badge & Tag
// Compact labels for status, categories, and counts.

public enum DSBadgeVariant {
    case filled
    case soft
    case outline
}

public struct DSBadge: View {
    let text: String
    let color: Color
    let variant: DSBadgeVariant

    public init(
        _ text: String,
        color: Color = DSColors.defaultPalette.primary,
        variant: DSBadgeVariant = .soft
    ) {
        self.text = text
        self.color = color
        self.variant = variant
    }

    public var body: some View {
        Text(text)
            .font(DSTextStyle.buttonSmall.font)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xxs)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(variant == .outline ? color : .clear, lineWidth: 1)
            )
    }

    private var foregroundColor: Color {
        switch variant {
        case .filled: return DSColors.defaultPalette.textOnPrimary
        case .soft:   return color
        case .outline: return color
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .filled: return color
        case .soft:   return color.opacity(0.12)
        case .outline: return .clear
        }
    }
}

// MARK: - Notification Count Badge

public struct DSCountBadge: View {
    let count: Int
    let color: Color

    public init(count: Int, color: Color = DSColors.defaultPalette.error) {
        self.count = count
        self.color = color
    }

    public var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, count > 9 ? 6 : 4)
                .frame(minWidth: 20, minHeight: 20)
                .background(color)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Avatar

public struct DSAvatar: View {
    let name: String
    let imageURL: URL?
    let size: CGFloat

    public init(name: String, imageURL: URL? = nil, size: CGFloat = 40) {
        self.name = name
        self.imageURL = imageURL
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(DSColors.defaultPalette.primary.opacity(0.15))

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundStyle(DSColors.defaultPalette.primary)
        }
        .frame(width: size, height: size)
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }
}
