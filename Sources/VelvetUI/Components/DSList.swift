import SwiftUI

// MARK: - Design System List Components
// Consistent list cells and dividers for any content type.

public struct DSListCell<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let leading: () -> Leading
    let trailing: () -> Trailing
    let action: (() -> Void)?

    @DSThemed private var theme

    public init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: @escaping () -> Leading = { EmptyView() },
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
        self.action = action
    }

    public var body: some View {
        let content = HStack(spacing: DSSpacing.md) {
            leading()

            VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                Text(title)
                    .ds(.body)

                if let subtitle {
                    Text(subtitle)
                        .ds(.callout, color: theme.palette.textSecondary)
                }
            }

            Spacer()

            trailing()

            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.palette.textTertiary)
            }
        }
        .padding(.horizontal, DSSpacing.screenHorizontal)
        .padding(.vertical, DSSpacing.sm)
        .contentShape(Rectangle())

        if let action {
            Button {
                dsHaptic(.light)
                action()
            } label: {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - Section Header

public struct DSSectionHeader: View {
    let title: String
    let action: String?
    let onAction: (() -> Void)?

    @DSThemed private var theme

    public init(_ title: String, action: String? = nil, onAction: (() -> Void)? = nil) {
        self.title = title
        self.action = action
        self.onAction = onAction
    }

    public var body: some View {
        HStack {
            Text(title)
                .ds(.overline, color: theme.palette.textSecondary)

            Spacer()

            if let action, let onAction {
                Button {
                    dsHaptic(.light)
                    onAction()
                } label: {
                    Text(action)
                        .ds(.buttonSmall, color: theme.ink)
                }
            }
        }
        .padding(.horizontal, DSSpacing.screenHorizontal)
        .padding(.top, DSSpacing.lg)
        .padding(.bottom, DSSpacing.xs)
    }
}

// MARK: - Divider

public struct DSDivider: View {
    let inset: CGFloat

    @DSThemed private var theme

    public init(inset: CGFloat = 0) {
        self.inset = inset
    }

    public var body: some View {
        Rectangle()
            .fill(theme.palette.divider)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}
