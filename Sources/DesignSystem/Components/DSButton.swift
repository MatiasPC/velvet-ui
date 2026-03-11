import SwiftUI

// MARK: - Design System Button
// Professional buttons with consistent sizing, haptics, and smooth press animations.
// Supports multiple variants for different use cases.

public enum DSButtonVariant {
    /// Filled with primary color — main CTAs
    case primary
    /// Filled with secondary color — supporting actions
    case secondary
    /// Outlined with border — alternative actions
    case outline
    /// No background — tertiary/text actions
    case ghost
    /// Red filled — destructive actions
    case destructive
}

public enum DSButtonSize {
    /// 36pt height — compact contexts
    case small
    /// 44pt height — default
    case medium
    /// 52pt height — prominent CTAs
    case large

    var height: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        }
    }

    var textStyle: DSTextStyle {
        switch self {
        case .small: return .buttonSmall
        case .medium: return .button
        case .large: return .button
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return DSSpacing.sm
        case .medium: return DSSpacing.lg
        case .large: return DSSpacing.xl
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: return DSRadius.sm
        case .medium: return DSRadius.md
        case .large: return DSRadius.md
        }
    }
}

public struct DSButton: View {
    let title: String
    let variant: DSButtonVariant
    let size: DSButtonSize
    let icon: String?
    let iconPosition: IconPosition
    let isFullWidth: Bool
    let isLoading: Bool
    let haptic: DSHapticStyle
    let action: () -> Void

    @State private var isPressed = false

    public enum IconPosition {
        case leading, trailing
    }

    public init(
        _ title: String,
        variant: DSButtonVariant = .primary,
        size: DSButtonSize = .medium,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        haptic: DSHapticStyle = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.icon = icon
        self.iconPosition = iconPosition
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        Button {
            DSHapticEngine.shared.fire(haptic)
            action()
        } label: {
            HStack(spacing: DSSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.8)
                } else {
                    if let icon, iconPosition == .leading {
                        Image(systemName: icon)
                            .font(.system(size: size == .small ? 12 : 14, weight: .semibold))
                    }

                    Text(title)
                        .font(size.textStyle.font)

                    if let icon, iconPosition == .trailing {
                        Image(systemName: icon)
                            .font(.system(size: size == .small ? 12 : 14, weight: .semibold))
                    }
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: variant == .outline ? 1.5 : 0)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isLoading ? 0.8 : 1.0)
            .animation(DSAnimation.springSnappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Computed Colors

    private var backgroundColor: Color {
        let palette = DSColors.defaultPalette
        switch variant {
        case .primary:     return palette.primary
        case .secondary:   return palette.secondary
        case .outline:     return .clear
        case .ghost:       return .clear
        case .destructive: return palette.error
        }
    }

    private var foregroundColor: Color {
        let palette = DSColors.defaultPalette
        switch variant {
        case .primary:     return palette.textOnPrimary
        case .secondary:   return palette.textOnPrimary
        case .outline:     return palette.primary
        case .ghost:       return palette.primary
        case .destructive: return palette.textOnPrimary
        }
    }

    private var borderColor: Color {
        let palette = DSColors.defaultPalette
        switch variant {
        case .outline: return palette.primary
        default:       return .clear
        }
    }
}

// MARK: - Icon-Only Button

public struct DSIconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let haptic: DSHapticStyle
    let action: () -> Void

    @State private var isPressed = false

    public init(
        icon: String,
        size: CGFloat = 44,
        color: Color = DSColors.defaultPalette.textPrimary,
        haptic: DSHapticStyle = .light,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        Button {
            DSHapticEngine.shared.fire(haptic)
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .contentShape(Rectangle())
                .scaleEffect(isPressed ? 0.88 : 1.0)
                .animation(DSAnimation.springSnappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
