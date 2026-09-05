import SwiftUI

// MARK: - Design System Card
// The reference surface of Velvet UI v0.2: glass over the themed backdrop.
//
//   .elevated — thin glass + specular edge + soft ambient shadow (default)
//   .flat     — translucent wash, no edge, no shadow — grouping inside another surface
//   .outlined — thicker glass + edge, no shadow — a denser surface (the old "border" look)
//
// Radius is `DSRadius.card` (20). No borders anywhere: separation comes from
// material density, the 1pt edge highlight and shadow. Without a `DSBackdrop`
// the glass sits on the plain background and still reads as an elevated card.

public enum DSCardStyle {
    /// Translucent wash — grouping inside another surface
    case flat
    /// Glass with edge highlight and soft shadow (default)
    case elevated
    /// Denser glass with edge highlight, no shadow
    case outlined
}

public struct DSCard<Content: View>: View {
    let style: DSCardStyle
    let padding: CGFloat
    let cornerRadius: CGFloat
    let content: () -> Content

    @DSThemed private var theme

    public init(
        style: DSCardStyle = .elevated,
        padding: CGFloat = DSSpacing.md,
        cornerRadius: CGFloat = DSRadius.card,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content
    }

    public var body: some View {
        switch style {
        case .elevated:
            content()
                .padding(padding)
                .dsSurface(.glass, radius: cornerRadius)
                .dsShadow(.md)
        case .outlined:
            content()
                .padding(padding)
                .dsSurface(.glassThick, radius: cornerRadius)
        case .flat:
            content()
                .padding(padding)
                .background(theme.subtleFill)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
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
        cornerRadius: CGFloat = DSRadius.card,
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
                .scaleEffect(isPressed ? DSPress.scale : 1.0)
                .animation(DSPress.animation, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Image Card

public struct DSImageCard: View {
    let imageURL: URL?
    let imageName: String?
    let title: String
    let subtitle: String?
    let badge: String?
    let cornerRadius: CGFloat

    @DSThemed private var theme

    public init(
        imageURL: URL? = nil,
        imageName: String? = nil,
        title: String,
        subtitle: String? = nil,
        badge: String? = nil,
        cornerRadius: CGFloat = DSRadius.card
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
                imageView
                    .aspectRatio(4/3, contentMode: .fill)

                if let badge {
                    Text(badge)
                        .ds(.buttonSmall, color: theme.onAccent)
                        .padding(.horizontal, DSSpacing.sm)
                        .padding(.vertical, DSSpacing.xxs)
                        .background(theme.accent)
                        .clipShape(Capsule())
                        .padding(DSSpacing.sm)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .dsWashEdge(radius: cornerRadius)

            // Text area
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(title)
                    .ds(.title3)
                    .lineLimit(2)

                if let subtitle {
                    Text(subtitle)
                        .ds(.callout, color: theme.palette.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let imageName {
            Image(imageName)
                .resizable()
        } else if let imageURL {
            AsyncImage(url: imageURL) { phase in
                if let image = phase.image {
                    image.resizable()
                } else {
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(theme.subtleFill)
            .dsShimmer()
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCardPreviewHost: View {
    @State private var theme = DSTheme()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                DSCard(style: .elevated) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Tu semana").ds(.title2)
                        Text("4 sesiones · 2 h 35 min").ds(.callout, color: DSColors.textSecondary)
                        Text("1 248").ds(.displayMedium)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard(style: .outlined) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Outlined").ds(.title3)
                        Text("Denser glass, edge highlight, no shadow").ds(.callout, color: DSColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DSCard(style: .elevated) {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Nested").ds(.title3)
                        DSCard(style: .flat, cornerRadius: DSRadius.surface) {
                            Text("Flat card inside an elevated one").ds(.callout)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                DSInteractiveCard(action: {}) {
                    HStack {
                        Text("Interactive — press me").ds(.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(DSColors.textTertiary)
                    }
                }

                DSImageCard(title: "Cabaña en el bosque", subtitle: "$120 / noche", badge: "Nuevo")
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Card — Light") {
    DSCardPreviewHost().preferredColorScheme(.light)
}

#Preview("Card — Dark") {
    DSCardPreviewHost().preferredColorScheme(.dark)
}

#Preview("Card — No backdrop") {
    ScrollView {
        VStack(spacing: DSSpacing.lg) {
            DSCard { Text("Elevated on a plain screen").ds(.body) }
            DSCard(style: .flat) { Text("Flat falls back to backgroundSecondary").ds(.body) }
            DSCard(style: .outlined) { Text("Outlined").ds(.body) }
        }
        .padding(DSSpacing.xl)
    }
    .background(DSColors.backgroundPrimary)
}
#endif
