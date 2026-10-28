import SwiftUI

// MARK: - Design System Timeline
// A vertical progress timeline: a rail of nodes joined by a connector that
// fills as the flow advances. The canonical "order status" / "delivery
// tracking" pattern — Ordered → Shipped → Out for delivery → Delivered — and
// equally at home in multi-step flows, activity histories and wizards.
//
// It is the vertical, content-bearing complement to `DSStepProgress` (which is
// a row of flat capsules with no labels). Steps before `currentStep` read as
// complete (accent node, checkmark, filled connector); the step at
// `currentStep` is the live one (accent node, soft glow, a resting breath);
// steps after it wait (wash node, muted label, empty connector).
//
// No borders: the rail is a filled node over a wash track, the connector is a
// capsule whose accent fill grows from the top with a spring. Advancing the
// flow fires a single success haptic.

// MARK: - Item

/// One stop on a `DSTimeline`. Positional: identity is the step's index, so
/// rebuilding the array keeps each node animating in place.
public struct DSTimelineItem {
    public let title: String
    public let subtitle: String?
    /// SF Symbol drawn inside the node once the step is reached. When nil, a
    /// completed step shows a checkmark and the live step a filled dot.
    public let icon: String?

    public init(_ title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

// MARK: - Status

private enum DSTimelineStatus {
    case complete, current, upcoming
}

// MARK: - Timeline

public struct DSTimeline: View {
    private let items: [DSTimelineItem]
    private let currentStep: Int
    private let nodeSize: CGFloat
    private let lineWidth: CGFloat
    private let accent: Color?
    private let haptics: Bool

    @DSThemed private var theme

    /// - Parameters:
    ///   - items: The stops, top to bottom.
    ///   - currentStep: Index of the live step. Steps before it are complete,
    ///     the one at it is current, steps after it are upcoming. Pass
    ///     `items.count` when every step is done.
    ///   - nodeSize: Diameter of each node. Glyph and glow scale with it.
    ///   - lineWidth: Thickness of the connector rail.
    ///   - accent: Fill for reached nodes and the filled connector. Defaults to the theme accent.
    ///   - haptics: Fire a `.success` tick when the flow advances. Defaults to `true`.
    public init(
        _ items: [DSTimelineItem],
        currentStep: Int,
        nodeSize: CGFloat = 28,
        lineWidth: CGFloat = DSSpacing.xxxs,
        accent: Color? = nil,
        haptics: Bool = true
    ) {
        self.items = items
        self.currentStep = currentStep
        self.nodeSize = nodeSize
        self.lineWidth = lineWidth
        self.accent = accent
        self.haptics = haptics
    }

    private var clampedStep: Int { min(max(currentStep, 0), items.count) }

    private func status(for index: Int) -> DSTimelineStatus {
        if index < clampedStep { return .complete }
        if index == clampedStep { return .current }
        return .upcoming
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                row(index: index, item: item, isLast: index == items.count - 1)
                    .dsStaggerIn(index: index)
            }
        }
        .animation(DSAnimation.springSmooth, value: clampedStep)
        .onChange(of: clampedStep) { oldValue, newValue in
            guard haptics, newValue > oldValue else { return }
            DSHapticEngine.shared.fire(.success)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Row

    private func row(index: Int, item: DSTimelineItem, isLast: Bool) -> some View {
        let status = status(for: index)
        return HStack(alignment: .top, spacing: DSSpacing.md) {
            // Rail: node, then a connector that fills the rest of the row height.
            VStack(spacing: 0) {
                node(status: status, icon: item.icon)
                if !isLast {
                    connector(filled: index < clampedStep)
                }
            }
            .frame(width: nodeSize)

            // Content
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(item.title)
                    .ds(.callout, color: titleColor(status))
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .ds(.footnote, color: theme.palette.textTertiary)
                }
            }
            .padding(.top, nodeTextOffset)
            .padding(.bottom, isLast ? 0 : DSSpacing.lg)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(item))
        .accessibilityValue(accessibilityValue(status))
    }

    // MARK: - Node

    @ViewBuilder
    private func node(status: DSTimelineStatus, icon: String?) -> some View {
        let reached = status != .upcoming
        ZStack {
            Circle()
                .fill(reached ? resolvedAccent : theme.subtleFill)
            nodeGlyph(status: status, icon: icon)
        }
        .frame(width: nodeSize, height: nodeSize)
        .dsShadow(status == .current ? .glow(resolvedAccent) : .none)
        .modifier(DSTimelineBreathe(isActive: status == .current))
    }

    @ViewBuilder
    private func nodeGlyph(status: DSTimelineStatus, icon: String?) -> some View {
        switch status {
        case .complete:
            Image(systemName: icon ?? "checkmark")
                .font(.system(size: nodeSize * 0.42, weight: .bold))
                .foregroundStyle(theme.onAccent)
        case .current:
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: nodeSize * 0.42, weight: .bold))
                    .foregroundStyle(theme.onAccent)
            } else {
                Circle()
                    .fill(theme.onAccent)
                    .frame(width: nodeSize * 0.3, height: nodeSize * 0.3)
            }
        case .upcoming:
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: nodeSize * 0.42, weight: .semibold))
                    .foregroundStyle(theme.palette.textTertiary)
            }
        }
    }

    // MARK: - Connector

    private func connector(filled: Bool) -> some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(theme.palette.border)
            Capsule()
                .fill(resolvedAccent)
                .scaleEffect(y: filled ? 1 : 0, anchor: .top)
        }
        .frame(width: lineWidth)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Colors

    private var resolvedAccent: Color { accent ?? theme.accent }

    /// Nudge the label down so its cap-height lines up with the node's centre.
    private var nodeTextOffset: CGFloat { max((nodeSize - DSTextStyle.callout.size) / 2, 0) }

    private func titleColor(_ status: DSTimelineStatus) -> Color {
        status == .upcoming ? theme.palette.textTertiary : theme.palette.textPrimary
    }

    // MARK: - Accessibility

    private func accessibilityLabel(_ item: DSTimelineItem) -> String {
        if let subtitle = item.subtitle {
            return "\(item.title), \(subtitle)"
        }
        return item.title
    }

    private func accessibilityValue(_ status: DSTimelineStatus) -> String {
        switch status {
        case .complete: return "Completed"
        case .current:  return "In progress"
        case .upcoming: return "Upcoming"
        }
    }
}

// MARK: - Live-node breath

/// A resting breath on the live node. Split into a modifier so the whole node —
/// fill, glyph and glow — swells together, and so Reduce Motion settles it
/// static (handled inside `dsBreathe`).
private struct DSTimelineBreathe: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content.dsBreathe(.subtle)
        } else {
            content
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSTimelinePreviewHost: View {
    @State private var theme = DSTheme()
    @State private var step = 2

    private let delivery = [
        DSTimelineItem("Order placed", subtitle: "March 3, 9:41 AM", icon: "bag"),
        DSTimelineItem("Payment confirmed", subtitle: "March 3, 9:42 AM", icon: "creditcard"),
        DSTimelineItem("Shipped", subtitle: "Picked up by courier", icon: "shippingbox"),
        DSTimelineItem("Out for delivery", subtitle: "Arriving today", icon: "box.truck"),
        DSTimelineItem("Delivered", subtitle: "Left at front door", icon: "house")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    DSTimeline(delivery, currentStep: step)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: DSSpacing.sm) {
                    DSButton("Back", variant: .ghost, size: .small) {
                        step = max(step - 1, 0)
                    }
                    DSButton("Advance", size: .small) {
                        step = min(step + 1, delivery.count)
                    }
                }

                Text("Plain, no icons").ds(.overline, color: DSColors.textSecondary)
                DSCard {
                    DSTimeline(
                        [
                            DSTimelineItem("Account", subtitle: "Email and password"),
                            DSTimelineItem("Profile", subtitle: "Name and photo"),
                            DSTimelineItem("Done")
                        ],
                        currentStep: 1
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Timeline — Light") {
    DSTimelinePreviewHost().preferredColorScheme(.light)
}

#Preview("Timeline — Dark") {
    DSTimelinePreviewHost().preferredColorScheme(.dark)
}
#endif
