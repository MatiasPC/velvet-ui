import SwiftUI

// MARK: - Design System Page Control
// An animated page indicator for onboarding flows, carousels, and paged
// content. The active page is drawn as a capsule that springs open from a
// dot, giving instant, elegant feedback as the user moves between pages.
// A drop-in, more polished replacement for UIPageControl.

public struct DSPageControl: View {
    @Binding private var currentPage: Int
    private let numberOfPages: Int
    private let activeColor: Color?
    private let inactiveColor: Color?
    private let dotSize: CGFloat
    private let activeWidth: CGFloat
    private let spacing: CGFloat
    private let allowsTap: Bool

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    /// Create a page control.
    /// - Parameters:
    ///   - currentPage: Binding to the currently selected page index.
    ///   - numberOfPages: Total number of pages. Zero (or less) draws nothing.
    ///   - activeColor: Fill for the selected page indicator. Defaults to the theme accent.
    ///   - inactiveColor: Fill for the unselected page dots. Defaults to the palette border.
    ///   - dotSize: Diameter of an unselected dot (also the control height).
    ///   - activeWidth: Width the selected indicator expands to.
    ///   - spacing: Gap between indicators.
    ///   - allowsTap: When `true`, tapping a dot jumps to that page.
    public init(
        currentPage: Binding<Int>,
        numberOfPages: Int,
        activeColor: Color? = nil,
        inactiveColor: Color? = nil,
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

    private var pageCount: Int { DSPageControlLogic.pageCount(numberOfPages) }

    /// The page drawn as selected: the bound page clamped into range, so an
    /// out-of-range binding still shows (and reads) the nearest page.
    private var displayedPage: Int {
        DSPageControlLogic.displayedPage(currentPage, numberOfPages: numberOfPages)
    }

    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == displayedPage ? (activeColor ?? theme.accent) : (inactiveColor ?? theme.palette.border))
                    .frame(
                        width: index == displayedPage ? activeWidth : dotSize,
                        height: dotSize
                    )
            }
        }
        // The dots stay small, but the touch area grows to a 44 pt row and
        // closes the gaps between dots, without changing the layout.
        .contentShape(
            .interaction,
            DSPageControlHitArea(
                horizontal: spacing / 2,
                vertical: DSPageControlLogic.verticalHitSlop(dotSize: dotSize)
            )
        )
        .onTapGesture(coordinateSpace: .local) { location in
            guard let index = DSPageControlLogic.page(
                atX: location.x,
                numberOfPages: numberOfPages,
                currentPage: currentPage,
                dotSize: dotSize,
                activeWidth: activeWidth,
                spacing: spacing,
                rightToLeft: layoutDirection == .rightToLeft
            ) else { return }
            select(index)
        }
        .allowsHitTesting(allowsTap)
        .animation(DSPageControlLogic.animation(reduceMotion: reduceMotion), value: displayedPage)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue(Self.accessibilityValue(currentPage: currentPage, numberOfPages: numberOfPages))
        .modifier(DSPageControlAdjustable(isEnabled: allowsTap) { delta in
            if let page = DSPageControlLogic.step(from: currentPage, by: delta, numberOfPages: numberOfPages) {
                select(page)
            }
        })
        .accessibilityHidden(pageCount == 0)
    }

    /// 1-based "N of M", clamped into range; empty when there are no pages.
    static func accessibilityValue(currentPage: Int, numberOfPages: Int) -> String {
        DSPageControlLogic.accessibilityValue(currentPage: currentPage, numberOfPages: numberOfPages)
    }

    static func clampedPage(_ page: Int, numberOfPages: Int) -> Int {
        DSPageControlLogic.displayedPage(page, numberOfPages: numberOfPages)
    }

    private func select(_ index: Int) {
        guard allowsTap, DSPageControlLogic.shouldSelect(index, current: currentPage) else { return }
        DSHapticEngine.shared.fire(.selection)
        currentPage = index
    }
}

// MARK: - Hit Area

/// The control's bounds grown by `horizontal` and `vertical` on each side.
private struct DSPageControlHitArea: Shape {
    let horizontal: CGFloat
    let vertical: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(rect.insetBy(dx: -horizontal, dy: -vertical))
    }
}

// MARK: - Adjustable

/// VoiceOver's swipe up / down, only when the control is interactive, so a
/// read-only indicator isn't announced as adjustable.
private struct DSPageControlAdjustable: ViewModifier {
    let isEnabled: Bool
    let step: (Int) -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content.accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: step(1)
                case .decrement: step(-1)
                @unknown default: break
                }
            }
        } else {
            content
        }
    }
}

// MARK: - Logic

/// The control's rules, kept pure so `DSPageControlTests` can pin them
/// without rendering.
enum DSPageControlLogic {
    /// Apple's minimum comfortable touch target.
    static let minimumHitTarget: CGFloat = DSSpacing.xxl + DSSpacing.sm

    /// Pages to draw. A negative count draws none instead of trapping in `0..<n`.
    static func pageCount(_ numberOfPages: Int) -> Int {
        max(numberOfPages, 0)
    }

    /// The bound page clamped into `0..<numberOfPages` (0 when there are none).
    static func displayedPage(_ page: Int, numberOfPages: Int) -> Int {
        min(max(page, 0), max(numberOfPages - 1, 0))
    }

    /// 1-based "N of M" for the displayed page; empty when there are no pages
    /// (the control is hidden from VoiceOver then, never "1 of 0").
    static func accessibilityValue(currentPage: Int, numberOfPages: Int) -> String {
        guard numberOfPages > 0 else { return "" }
        return "\(displayedPage(currentPage, numberOfPages: numberOfPages) + 1) of \(numberOfPages)"
    }

    /// A tap writes only when it changes the page, so a tap on the current
    /// dot fires no haptic.
    static func shouldSelect(_ index: Int, current: Int) -> Bool {
        index != current
    }

    /// The page one VoiceOver swipe lands on, or `nil` at either end.
    static func step(from page: Int, by delta: Int, numberOfPages: Int) -> Int? {
        guard numberOfPages > 0 else { return nil }
        let from = displayedPage(page, numberOfPages: numberOfPages)
        let to = displayedPage(from + delta, numberOfPages: numberOfPages)
        return to == from ? nil : to
    }

    /// Extra touch height above and below the dots so the row is at least
    /// `minimumHitTarget` tall.
    static func verticalHitSlop(dotSize: CGFloat) -> CGFloat {
        max(minimumHitTarget - dotSize, 0) / 2
    }

    /// The page under `x` in the control's own coordinates. Each indicator owns
    /// its width plus half the gap on each side; a touch before the first or
    /// past the last goes to that end. `nil` when there are no pages.
    static func page(
        atX x: CGFloat,
        numberOfPages: Int,
        currentPage: Int,
        dotSize: CGFloat,
        activeWidth: CGFloat,
        spacing: CGFloat,
        rightToLeft: Bool = false
    ) -> Int? {
        let count = pageCount(numberOfPages)
        guard count > 0 else { return nil }
        let active = displayedPage(currentPage, numberOfPages: count)
        let total = activeWidth + dotSize * CGFloat(count - 1) + spacing * CGFloat(count - 1)
        let position = rightToLeft ? total - x : x

        var end: CGFloat = 0
        for index in 0..<count {
            end += index == active ? activeWidth : dotSize
            if position < end + spacing / 2 { return index }
            end += spacing
        }
        return count - 1
    }

    /// The selected capsule springs open; under Reduce Motion it changes in place.
    static func animation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : DSAnimation.springSmooth
    }
}

// MARK: - Preview

private struct DSPageControlPreviewHost: View {
    @State private var page = 0
    private let total = 4

    var body: some View {
        VStack(spacing: DSSpacing.xxl) {
            Text("Page \(page + 1) of \(total)")
                .ds(.title3, color: DSColors.textSecondary)

            DSPageControl(currentPage: $page, numberOfPages: total)

            DSPageControl(
                currentPage: $page,
                numberOfPages: total,
                activeColor: DSColors.secondary
            )

            Text("Tap a dot or use the buttons")
                .ds(.footnote, color: DSColors.textTertiary)

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
        .background(DSColors.backgroundPrimary)
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
