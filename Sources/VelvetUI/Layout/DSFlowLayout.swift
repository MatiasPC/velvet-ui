import SwiftUI

// MARK: - Design System Flow Layout
// A wrapping layout: it lays its subviews out left-to-right and drops to a new
// line the moment the next one wouldn't fit the available width. This is the
// missing primitive behind tag clouds, filter chips, keyword lists, selected
// recipients and any set of pill-shaped items whose count you don't control.
//
// Pure SwiftUI `Layout` — no `GeometryReader`, no preference keys, no second
// render pass. It measures each subview at its ideal size, packs rows within the
// proposed width, and reports the total height back so it composes anywhere a
// normal view does (inside a `VStack`, a `DSCard`, a `ScrollView`).
//
// Because it is a real `Layout`, motion comes for free and on-system: wrap a
// change to the content in `withAnimation(DSAnimation.springSmooth)` and every
// item glides to its new position — added, removed or resized items reflow along
// the Velvet spring instead of snapping. No border, no fill, no color: a layout
// positions, it never paints, so it inherits whatever the chips themselves draw.

private enum Metrics {
    /// Slack when comparing a row against the container. The parent may hand back
    /// bounds a fraction of a point narrower than the width we reported (pixel
    /// rounding); without this the last item would wrap to a row we never sized for.
    static let fitTolerance: CGFloat = 0.5
}

public struct DSFlowLayout: Layout {

    /// Horizontal gap between items on the same row. Defaults to `DSSpacing.xs` (8).
    public var spacing: CGFloat
    /// Vertical gap between rows. Defaults to `DSSpacing.xs` (8).
    public var lineSpacing: CGFloat
    /// How a row narrower than the container is positioned within it:
    /// `.leading` (default), `.center` or `.trailing`. Follows the layout
    /// direction, so `.leading` starts on the right in a right-to-left language.
    public var alignment: HorizontalAlignment

    public init(
        spacing: CGFloat = DSSpacing.xs,
        lineSpacing: CGFloat = DSSpacing.xs,
        alignment: HorizontalAlignment = .leading
    ) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.alignment = alignment
    }

    // MARK: - Layout

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        // An unspecified width means "as wide as you like": pack against infinity
        // (one row) and report the widest row as the natural content width.
        let maxWidth = proposal.width ?? .infinity
        let rows = Self.pack(measure(subviews, maxWidth: maxWidth), maxWidth: maxWidth, spacing: spacing)

        let contentWidth = rows.map(\.width).max() ?? 0
        let height = Self.totalHeight(of: rows, lineSpacing: lineSpacing)

        // Fill a finite proposed width (so alignment has room to work); otherwise
        // shrink to the content. An infinite proposal (a horizontal ScrollView, an
        // HStack probing its maximum) must never be echoed back as our size.
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? contentWidth
        return CGSize(width: width, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        guard !subviews.isEmpty else { return }

        let rows = Self.pack(measure(subviews, maxWidth: bounds.width), maxWidth: bounds.width, spacing: spacing)
        var y = bounds.minY

        for row in rows {
            // Always laid out left-to-right: SwiftUI mirrors a custom Layout's placements
            // itself in a right-to-left environment, so mirroring here would cancel it out.
            var x = bounds.minX + Self.leadingOffset(rowWidth: row.width, boundsWidth: bounds.width, alignment: alignment)
            for item in row.items {
                // Shorter items sit centred in their row, like an HStack.
                let originY = y + (row.height - item.size.height) / 2
                subviews[item.index].place(
                    at: CGPoint(x: x, y: originY),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    // MARK: - Measuring

    /// Each subview's size at its ideal width. One that is wider than the whole
    /// container is measured again at the container width, so text can wrap or
    /// truncate instead of running off the edge.
    private func measure(_ subviews: Subviews, maxWidth: CGFloat) -> [CGSize] {
        subviews.map { subview in
            let ideal = subview.sizeThatFits(.unspecified)
            guard maxWidth.isFinite, ideal.width > maxWidth else { return ideal }
            return subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
        }
    }

    // MARK: - Row packing (pure)

    /// One item on a row: which subview it is and the size it was measured at.
    struct Item: Equatable {
        let index: Int
        let size: CGSize
    }

    /// One line of the flow: the items on it, its used width and its tallest item.
    struct Row: Equatable {
        private(set) var items: [Item] = []
        private(set) var width: CGFloat = 0
        private(set) var height: CGFloat = 0

        mutating func append(_ item: Item, spacing: CGFloat) {
            if !items.isEmpty { width += spacing }
            items.append(item)
            width += item.size.width
            height = max(height, item.size.height)
        }
    }

    /// Greedy first-fit packing: keep adding to the current row until the next
    /// item would overflow `maxWidth`, then start a new one. An item wider than
    /// the whole container still lands on its own row rather than vanishing.
    static func pack(_ sizes: [CGSize], maxWidth: CGFloat, spacing: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for (index, size) in sizes.enumerated() {
            if !current.items.isEmpty, current.width + spacing + size.width > maxWidth + Metrics.fitTolerance {
                rows.append(current)
                current = Row()
            }
            current.append(Item(index: index, size: size), spacing: spacing)
        }

        if !current.items.isEmpty { rows.append(current) }
        return rows
    }

    /// Combined height of `rows` plus the gaps between them.
    static func totalHeight(of rows: [Row], lineSpacing: CGFloat) -> CGFloat {
        rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
    }

    /// How far from the container's left edge a row of `rowWidth` starts.
    /// Never negative: a row wider than the container starts flush and overflows.
    static func leadingOffset(rowWidth: CGFloat, boundsWidth: CGFloat, alignment: HorizontalAlignment) -> CGFloat {
        let slack = max(0, boundsWidth - rowWidth)
        if alignment == .center { return slack / 2 }
        if alignment == .trailing { return slack }
        return 0
    }
}

// MARK: - Preview

#if DEBUG
private struct FlowPreviewChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @DSThemed private var theme

    var body: some View {
        Button {
            DSHapticEngine.shared.fire(.selection)
            withAnimation(DSAnimation.springSnappy) { action() }
        } label: {
            Text(label)
                .ds(.buttonSmall, color: isSelected ? theme.onAccent : theme.ink)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xs)
                .background {
                    Capsule().fill(isSelected ? theme.accent : theme.subtleFill)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct DSFlowLayoutPreviewHost: View {
    @State private var theme = DSTheme()

    private let interests = [
        "Design", "SwiftUI", "Motion", "Accessibility", "Haptics",
        "Typography", "Color", "Prototyping", "Research", "iOS", "Glass"
    ]
    @State private var selected: Set<String> = ["SwiftUI", "Motion", "Haptics"]
    @State private var tags = ["weekend", "lisbon", "two guests", "river view", "3 nights", "balcony"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                // Filter chips — tap to toggle; the accent fill follows selection.
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("INTERESTS").ds(.overline, color: DSColors.textSecondary)
                    DSFlowLayout {
                        ForEach(interests, id: \.self) { interest in
                            FlowPreviewChip(label: interest, isSelected: selected.contains(interest)) {
                                if selected.contains(interest) {
                                    selected.remove(interest)
                                } else {
                                    selected.insert(interest)
                                }
                            }
                        }
                    }
                }

                // Removable tags — tap to drop one and watch the rest reflow.
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("TAP TO REMOVE").ds(.overline, color: DSColors.textSecondary)
                    DSFlowLayout(spacing: DSSpacing.xs, lineSpacing: DSSpacing.xs) {
                        ForEach(tags, id: \.self) { tag in
                            FlowPreviewChip(label: tag, isSelected: false) {
                                tags.removeAll { $0 == tag }
                            }
                        }
                    }
                }

                // Centered alignment inside a card.
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("CENTER ALIGNED").ds(.overline, color: DSColors.textSecondary)
                    DSCard {
                        DSFlowLayout(alignment: .center) {
                            ForEach(["XS", "Small", "Medium", "Large", "XL", "XXL"], id: \.self) { size in
                                FlowPreviewChip(label: size, isSelected: false) {}
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Flow Layout — Light") {
    DSFlowLayoutPreviewHost().preferredColorScheme(.light)
}

#Preview("Flow Layout — Dark") {
    DSFlowLayoutPreviewHost().preferredColorScheme(.dark)
}
#endif
