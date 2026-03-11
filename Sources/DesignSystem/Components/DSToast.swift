import SwiftUI

// MARK: - Design System Toast / Snackbar
// Non-intrusive feedback notifications.

public enum DSToastType {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    var color: Color {
        let palette = DSColors.defaultPalette
        switch self {
        case .success: return palette.success
        case .error:   return palette.error
        case .warning: return palette.warning
        case .info:    return palette.info
        }
    }

    var haptic: DSHapticStyle {
        switch self {
        case .success: return .success
        case .error:   return .error
        case .warning: return .warning
        case .info:    return .light
        }
    }
}

public struct DSToast: View {
    let message: String
    let type: DSToastType

    public init(_ message: String, type: DSToastType = .info) {
        self.message = message
        self.type = type
    }

    public var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)
                .font(.system(size: 18, weight: .semibold))

            Text(message)
                .ds(.callout)

            Spacer()
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
        .dsShadow(.lg)
        .padding(.horizontal, DSSpacing.screenHorizontal)
    }
}

// MARK: - Empty State

public struct DSEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(DSColors.defaultPalette.textTertiary)

            VStack(spacing: DSSpacing.xs) {
                Text(title)
                    .ds(.title2)

                Text(message)
                    .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                DSButton(actionTitle, variant: .primary, action: action)
            }
        }
        .padding(DSSpacing.xxl)
    }
}
