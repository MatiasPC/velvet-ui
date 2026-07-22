import SwiftUI

// MARK: - Design System Page Control
// An animated page indicator for onboarding flows, carousels, and paged
// content. The active page is drawn as a capsule that springs open from a
// dot, giving instant, elegant feedback as the user moves between pages.
// A drop-in, more polished replacement for UIPageControl.

public struct DSPageControl: View {
    @Binding private var currentPage: Int
    private let numberOfPages: Int
    private let activeColor: Color
    private let inactiveColor: Color
    private let dotSize: CGFloat
    private let activeWidth: CGFloat
    private let spacing: CGFloat
    private let allowsTap: Bool

    /// Create a page control.
    /// - Parameters:
    ///   - currentPage: Binding to the currently selected page index.
    ///   - numberOfPages: Total number of pages.
    ///   - activeColor: Fill for the selected page indicator.
    ///   - inactiveColor: Fill for the unselected page dots.
    ///   - dotSize: Diameter of an unselected dot (also the control height).
    ///   - activeWidth: Width the selected indicator expands to.
    ///   - spacing: Gap between indicators.
    ///   - allowsTap: When `true`, tapping a dot jumps to that page.
    public init(
        currentPage: Binding<Int>,
        numberOfPages: Int,
        activeColor: Color = DSColors.defaultPalette.primary,
        inactiveColor: Color = DSColors.defaultPalette.border,
        dotSize: CGFloat = DSSpacing.xs,
        activeWidth: CGFloat = DSSpacing.xl,
        spacing: CGFloat = DSSpacing.xs,
        allowsTap: Bool = true
    ) {
        self._currentPage = currentPage
        self.numberOfPages = numberOfPages
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.dotSize = dotSize
        self.activeWidth = activeWidth
        self.spacing = spacing
        self.allowsTap = allowsTap
    }

    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == currentPage ? activeColor : inactiveColor)
                    .frame(
                        width: index == currentPage ? activeWidth : dotSize,
                        height: dotSize
                    )
                    .contentShape(Capsule())
                    .onTapGesture { select(index) }
            }
        }
        .animation(DSAnimation.springSmooth, value: currentPage)
    }

    private func select(_ index: Int) {
        guard allowsTap, index != currentPage else { return }
        DSHapticEngine.shared.fire(.selection)
        currentPage = index
    }
}

// MARK: - Preview

private struct DSPageControlPreviewHost: View {
    @State private var page = 0
    private let total = 4

    var body: some View {
        VStack(spacing: DSSpacing.xxl) {
            Text("Page \(page + 1) of \(total)")
                .ds(.title3, color: DSColors.defaultPalette.textSecondary)

            DSPageControl(currentPage: $page, numberOfPages: total)

            DSPageControl(
                currentPage: $page,
                numberOfPages: total,
                activeColor: DSColors.defaultPalette.secondary
            )

            Text("Tap a dot or use the buttons")
                .ds(.footnote, color: DSColors.defaultPalette.textTertiary)

            HStack(spacing: DSSpacing.md) {
                DSButton("Back", variant: .outline, size: .small) {
                    page = max(0, page - 1)
                }
                DSButton("Next", variant: .primary, size: .small) {
                    page = min(total - 1, page + 1)
                }
            }
        }
        .padding(DSSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColors.defaultPalette.backgroundPrimary)
    }
}

#Preview("Page Control — Light") {
    DSPageControlPreviewHost()
        .preferredColorScheme(.light)
}

#Preview("Page Control — Dark") {
    DSPageControlPreviewHost()
        .preferredColorScheme(.dark)
}
