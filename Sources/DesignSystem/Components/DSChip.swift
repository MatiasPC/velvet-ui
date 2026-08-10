import SwiftUI

// MARK: - Design System Chip
// A selectable pill for filters, tags, and multi-select options. Chips toggle
// with a snappy spring "pop", crossfade from a neutral resting look to an
// accent-tinted selected state, and fire a selection tick on every change —
// the same tactile feel used across the rest of the Design System.
//
// Chips are almost always shown as a wrapping group, so this file also ships
// `DSFlowLayout`: a reusable `Layout` that arranges any subviews left-to-right
// and wraps them onto new lines when they run out of width (an auto-wrapping
// `HStack`). Compose the two for filter bars, tag pickers, and category lists:
//
//     DSFlowLayout {
//         ForEach(tags) { tag in
//             DSChip(tag.name, isSelected: bindingForTag(tag))
//         }
//     }

// MARK: - Chip

public struct DSChip: View {
    private let title: String
    private let icon: String?
    @Binding private var isSelected: Bool
    private let accent: Color
    private let haptic: DSHapticStyle

    @State private var isPressed = false

    /// A selectable chip bound to an on/off state.
    /// - Parameters:
    ///   - title: The chip label.
    ///   - isSelected: Binding to the chip's selected state — toggled on tap.
    ///   - icon: Optional leading SF Symbol. Stays a fixed width so selecting a
    ///     chip never reflows the surrounding layout.
    ///   - accent: Tint used for the selected fill, text, and border.
    ///     Defaults to the primary brand color.
    ///   - haptic: Feedback fired on each toggle. Defaults to a selection tick.
    public init(
        _ title: String,
        isSelected: Binding<Bool>,
        icon: String? = nil,
        accent: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .selection
    ) {
        self.title = title
        self._isSelected = isSelected
        self.icon = icon
        self.accent = accent
        self.haptic = haptic
    }

    public var body: some View {
        Button {
            DSHapticEngine.shared.fire(haptic)
            withAnimation(DSAnimation.springSnappy) {
                isSelected.toggle()
            }
        } label: {
            HStack(spacing: DSSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(DSTextStyle.buttonSmall.font)
            }
            .foregroundStyle(isSelected ? accent : DSColors.defaultPalette.textSecondary)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? accent.opacity(0.15) : DSColors.defaultPalette.backgroundSecondary)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        isSelected ? accent.opacity(0.5) : DSColors.defaultPalette.border,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1)
            .animation(DSAnimation.springSnappy, value: isSelected)
            .animation(DSAnimation.springSnappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Flow Layout

/// A `Layout` that places subviews in a horizontal run and wraps to the next
/// line when the proposed width runs out — an auto-wrapping `HStack`. Ideal for
/// chips, tags, keywords, or any collection of variable-width elements.
public struct DSFlowLayout: Layout {
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat
    private let alignment: HorizontalAlignment

    /// - Parameters:
    ///   - horizontalSpacing: Gap between items on the same line. Defaults to `DSSpacing.xs`.
    ///   - verticalSpacing: Gap between wrapped lines. Defaults to `DSSpacing.xs`.
    ///   - alignment: Horizontal alignment of each line within the available
    ///     width. Defaults to `.leading`.
    public init(
        horizontalSpacing: CGFloat = DSSpacing.xs,
        verticalSpacing: CGFloat = DSSpacing.xs,
        alignment: HorizontalAlignment = .leading
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.alignment = alignment
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.replacingUnspecifiedDimensions().width
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(into: CGFloat.zero) { $0 += $1.height }
            + verticalSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: maxWidth, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let leftover = max(0, bounds.width - row.width)
            let startX: CGFloat
            if alignment == .center {
                startX = bounds.minX + leftover / 2
            } else if alignment == .trailing {
                startX = bounds.minX + leftover
            } else {
                startX = bounds.minX
            }

            var x = startX
            for element in row.elements {
                subviews[element.index].place(
                    at: CGPoint(x: x, y: y + (row.height - element.size.height) / 2),
                    proposal: ProposedViewSize(element.size)
                )
                x += element.size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    // MARK: - Row Computation

    private struct Element {
        let index: Int
        let size: CGSize
    }

    private struct Row {
        var elements: [Element] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// Break the subviews into wrapped rows for the given width.
    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let projected = current.elements.isEmpty
                ? size.width
                : current.width + horizontalSpacing + size.width

            if !current.elements.isEmpty && projected > maxWidth {
                rows.append(current)
                current = Row()
            }

            let originX = current.elements.isEmpty ? 0 : current.width + horizontalSpacing
            current.elements.append(Element(index: index, size: size))
            current.width = originX + size.width
            current.height = max(current.height, size.height)
        }

        if !current.elements.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

// MARK: - Preview

#Preview {
    struct ChipPreview: View {
        private let filters = ["Design", "Engineering", "Product", "Marketing", "Sales", "Support", "Research"]
        @State private var selected: Set<String> = ["Design", "Product"]

        var body: some View {
            VStack(alignment: .leading, spacing: DSSpacing.xxl) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Filter chips").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSFlowLayout {
                        ForEach(filters, id: \.self) { filter in
                            DSChip(
                                filter,
                                isSelected: Binding(
                                    get: { selected.contains(filter) },
                                    set: { $0 ? selected.insert(filter) : selected.remove(filter) }
                                )
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("With icons & accent").ds(.overline, color: DSColors.defaultPalette.textSecondary)
                    DSFlowLayout {
                        DSChip("Favorites", isSelected: .constant(true), icon: "heart.fill",
                               accent: DSColors.defaultPalette.primary)
                        DSChip("Nearby", isSelected: .constant(false), icon: "location.fill",
                               accent: DSColors.defaultPalette.secondary)
                        DSChip("Trending", isSelected: .constant(true), icon: "flame.fill",
                               accent: DSColors.defaultPalette.tertiary)
                    }
                }
            }
            .padding(DSSpacing.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DSColors.defaultPalette.backgroundPrimary)
        }
    }

    return Group {
        ChipPreview()
            .preferredColorScheme(.light)
        ChipPreview()
            .preferredColorScheme(.dark)
    }
}
