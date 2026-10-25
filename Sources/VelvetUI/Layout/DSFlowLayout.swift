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

public struct DSFlowLayout: Layout {

    /// Horizontal gap between items on the same row. Defaults to `DSSpacing.xs` (8).
    public var spacing: CGFloat
    /// Vertical gap between rows. Defaults to `DSSpacing.xs` (8).
    public var lineSpacing: CGFloat
    /// How a row narrower than the container is positioned within it:
    /// `.leading` (default), `.center` or `.trailing`.
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

        // An unspecified width means "as wide as you like"; pack against infinity
        // and then report the widest row as the natural content width.
        let containerWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: containerWidth, subviews: subviews)

        let contentWidth = rows.map(\.width).max() ?? 0
        let height = rows.reduce(0) { $0 + $1.height }
            + lineSpacing * CGFloat(max(0, rows.count - 1))

        // Fill the proposed width when one was given (so alignment has room to
        // work); otherwise shrink to the content.
        return CGSize(width: proposal.width ?? contentWidth, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        guard !subviews.isEmpty else { return }

        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            // Position the row as a whole, then walk its items left-to-right.
            let leadingX: CGFloat
            if alignment == .center {
                leadingX = bounds.minX + (bounds.width - row.width) / 2
            } else if alignment == .trailing {
                leadingX = bounds.maxX - row.width
            } else {
                leadingX = bounds.minX
            }

            var x = leadingX
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    // MARK: - Row packing

    /// One line of the flow: the items on it, its used width and its tallest item.
    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0

        mutating func append(index: Int, size: CGSize, spacing: CGFloat) {
            if !items.isEmpty { width += spacing }
            items.append((index, size))
            width += size.width
            height = max(height, size.height)
        }
    }

    /// Greedy first-fit packing: keep adding to the current row until the next
    /// item would overflow `maxWidth`, then start a new one. An item wider than
    /// the whole container still lands on its own row rather than vanishing.
    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let projected = current.items.isEmpty
                ? size.width
                : current.width + spacing + size.width

            if !current.items.isEmpty && projected > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.append(index: index, size: size, spacing: spacing)
        }

        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Preview

#if DEBUG
private struct DSFlowChip: View {
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
                            DSFlowChip(label: interest, isSelected: selected.contains(interest)) {
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
                            DSFlowChip(label: tag, isSelected: false) {
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
                                DSFlowChip(label: size, isSelected: false) {}
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
