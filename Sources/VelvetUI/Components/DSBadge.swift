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
    let color: Color?
    let variant: DSBadgeVariant

    @DSThemed private var theme

    /// - Parameter color: Fill (filled) / tint (soft, outline). Defaults to the theme accent.
    public init(
        _ text: String,
        color: Color? = nil,
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
                    .stroke(variant == .outline ? strokeColor : .clear, lineWidth: 1)
            )
    }

    private var strokeColor: Color {
        color ?? theme.ink
    }

    private var foregroundColor: Color {
        switch variant {
        case .filled: return color == nil ? theme.onAccent : theme.palette.textOnPrimary
        case .soft:   return color ?? theme.ink
        case .outline: return color ?? theme.ink
        }
    }

    private var backgroundColor: Color {
        let resolved = color ?? theme.accent
        switch variant {
        case .filled: return resolved
        case .soft:   return resolved.opacity(0.12)
        case .outline: return .clear
        }
    }
}

// MARK: - Notification Count Badge

public struct DSCountBadge: View {
    let count: Int
    let color: Color?

    @DSThemed private var theme

    /// - Parameter color: Fill color. Defaults to the palette's error color.
    public init(count: Int, color: Color? = nil) {
        self.count = count
        self.color = color
    }

    public var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(DSTextStyle.badge.font)
                .foregroundStyle(theme.palette.textOnPrimary)
                .padding(.horizontal, DSSpacing.xxs)
                .frame(minWidth: DSSpacing.lg, minHeight: DSSpacing.lg)
                .background(color ?? theme.palette.error)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Avatar

public struct DSAvatar: View {
    let name: String
    let imageURL: URL?
    let size: CGFloat

    @DSThemed private var theme

    public init(name: String, imageURL: URL? = nil, size: CGFloat = 40) {
        self.name = name
        self.imageURL = imageURL
        self.size = size
    }

    public var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(theme.accent.opacity(0.15))

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.ink)
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
