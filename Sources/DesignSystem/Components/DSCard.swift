import SwiftUI

// MARK: - Design System Card
// Versatile card component with consistent styling.
// The foundation for content presentation across any app.

public enum DSCardStyle {
    /// Flat card with subtle background
    case flat
    /// Elevated card with shadow (Airbnb-style)
    case elevated
    /// Outlined card with border
    case outlined
}

public struct DSCard<Content: View>: View {
    let style: DSCardStyle
    let padding: CGFloat
    let cornerRadius: CGFloat
    let content: () -> Content

    public init(
        style: DSCardStyle = .elevated,
        padding: CGFloat = DSSpacing.md,
        cornerRadius: CGFloat = DSRadius.lg,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content
    }

    public var body: some View {
        content()
            .padding(padding)
            .background(DSColors.defaultPalette.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        style == .outlined ? DSColors.defaultPalette.border : .clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: style == .elevated ? DSShadow.md.color : .clear,
                radius: style == .elevated ? DSShadow.md.radius : 0,
                y: style == .elevated ? DSShadow.md.y : 0
            )
    }
}

// MARK: - Interactive Card (with press animation)

public struct DSInteractiveCard<Content: View>: View {
    let style: DSCardStyle
    let padding: CGFloat
    let cornerRadius: CGFloat
    let haptic: DSHapticStyle
    let action: () -> Void
    let content: () -> Content

    @State private var isPressed = false

    public init(
        style: DSCardStyle = .elevated,
        padding: CGFloat = DSSpacing.md,
        cornerRadius: CGFloat = DSRadius.lg,
        haptic: DSHapticStyle = .light,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.haptic = haptic
        self.action = action
        self.content = content
    }

    public var body: some View {
        Button {
            DSHapticEngine.shared.fire(haptic)
            action()
        } label: {
            DSCard(style: style, padding: padding, cornerRadius: cornerRadius, content: content)
                .scaleEffect(isPressed ? 0.97 : 1.0)
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

// MARK: - Image Card (Airbnb-style)

public struct DSImageCard: View {
    let imageURL: URL?
    let imageName: String?
    let title: String
    let subtitle: String?
    let badge: String?
    let cornerRadius: CGFloat

    public init(
        imageURL: URL? = nil,
        imageName: String? = nil,
        title: String,
        subtitle: String? = nil,
        badge: String? = nil,
        cornerRadius: CGFloat = DSRadius.lg
    ) {
        self.imageURL = imageURL
        self.imageName = imageName
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            // Image area
            ZStack(alignment: .topLeading) {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(DSColors.defaultPalette.backgroundSecondary)
                        .aspectRatio(4/3, contentMode: .fill)
                }

                if let badge {
                    Text(badge)
                        .ds(.buttonSmall, color: DSColors.defaultPalette.textOnPrimary)
                        .padding(.horizontal, DSSpacing.xs)
                        .padding(.vertical, DSSpacing.xxs)
                        .background(DSColors.defaultPalette.primary)
                        .clipShape(Capsule())
                        .padding(DSSpacing.sm)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // Text area
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(title)
                    .ds(.title3)
                    .lineLimit(2)

                if let subtitle {
                    Text(subtitle)
                        .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
