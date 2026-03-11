import SwiftUI

// MARK: - Design System Layout Helpers
// Consistent layout patterns for professional screen composition.

// MARK: - Screen Container

/// Standard screen container with consistent padding and background
public struct DSScreen<Content: View>: View {
    let backgroundColor: Color
    let content: () -> Content

    public init(
        backgroundColor: Color = DSColors.defaultPalette.backgroundPrimary,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.content = content
    }

    public var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                content()
                    .padding(.top, DSSpacing.screenTop)
                    .padding(.bottom, DSSpacing.screenBottom)
            }
        }
    }
}

// MARK: - Horizontal Scroll Row

/// Horizontal scrolling row (Airbnb-style carousels)
public struct DSHorizontalScroll<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    public init(
        spacing: CGFloat = DSSpacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                content()
            }
            .padding(.horizontal, DSSpacing.screenHorizontal)
        }
    }
}

// MARK: - Stack with Spacing

/// VStack with Design System spacing defaults
public struct DSVStack<Content: View>: View {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: () -> Content

    public init(
        spacing: CGFloat = DSSpacing.md,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content()
        }
    }
}

/// HStack with Design System spacing defaults
public struct DSHStack<Content: View>: View {
    let spacing: CGFloat
    let alignment: VerticalAlignment
    let content: () -> Content

    public init(
        spacing: CGFloat = DSSpacing.sm,
        alignment: VerticalAlignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    public var body: some View {
        HStack(alignment: alignment, spacing: spacing) {
            content()
        }
    }
}

// MARK: - Adaptive Grid

/// Responsive grid that adapts to available width
public struct DSGrid<Content: View>: View {
    let minItemWidth: CGFloat
    let spacing: CGFloat
    let content: () -> Content

    public init(
        minItemWidth: CGFloat = 160,
        spacing: CGFloat = DSSpacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.minItemWidth = minItemWidth
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minItemWidth), spacing: spacing)],
            spacing: spacing
        ) {
            content()
        }
        .padding(.horizontal, DSSpacing.screenHorizontal)
    }
}
