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
// `currentStep` is the live one (accent node, a glow that breathes); steps
// after it wait (wash node, muted label, empty connector).
//
// No borders: the rail is a filled node over a track, the connector is a
// capsule whose accent fill grows from the top with a spring. The spring and
// the single success haptic fire only when `currentStep` moves forward, never
// on first appearance, so a screen that opens already at step 3 simply shows
// step 3. Under Reduce Motion the fill cross-fades instead of growing.

// MARK: - Item

/// One stop on a `DSTimeline`. Positional: identity is the step's index, so
/// rebuilding the array keeps each node animating in place.
public struct DSTimelineItem: Sendable {
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

// MARK: - Progress model

/// Where a step stands relative to the live one.
enum DSTimelineStatus: Equatable {
    case complete, current, upcoming
}

/// The pure rules behind `DSTimeline`: clamping, per-step status, connector
/// fill and when a change counts as progress. Kept free of SwiftUI state so
/// they can be unit tested.
enum DSTimelineProgress {
    /// `currentStep` limited to `0...count`. `count` means every step is done.
    static func clamped(_ step: Int, count: Int) -> Int {
        min(max(step, 0), max(count, 0))
    }

    static func status(index: Int, currentStep: Int, count: Int) -> DSTimelineStatus {
        let step = clamped(currentStep, count: count)
        if index < step { return .complete }
        if index == step { return .current }
        return .upcoming
    }

    /// Whether the connector leaving step `index` is filled: its step is done.
    static func isConnectorFilled(after index: Int, currentStep: Int, count: Int) -> Bool {
        index < clamped(currentStep, count: count)
    }

    /// Only forward movement is progress. Appearing, stepping back and
    /// clamped no-ops all return false, so they play no haptic.
    static func isAdvance(from old: Int, to new: Int) -> Bool {
        new > old
    }
}

// MARK: - Metrics

private enum Metrics {
    /// Glyph size as a fraction of the node's diameter.
    static let glyphRatio: CGFloat = 0.42
    /// Live-step dot (no icon) as a fraction of the node's diameter.
    static let dotRatio: CGFloat = 0.3
}

// MARK: - Timeline

public struct DSTimeline: View {
    private let items: [DSTimelineItem]
    private let currentStep: Int
    private let lineWidth: CGFloat
    private let accent: Color?
    private let haptics: Bool

    /// Scales with Dynamic Type so the node stays centred on its title line.
    @ScaledMetric private var nodeSize: CGFloat

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - items: The stops, top to bottom.
    ///   - currentStep: Index of the live step. Steps before it are complete,
    ///     the one at it is current, steps after it are upcoming. Pass
    ///     `items.count` when every step is done.
    ///   - nodeSize: Diameter of each node at the default text size; it scales
    ///     with Dynamic Type. Glyph and glow follow it.
    ///   - lineWidth: Thickness of the connector rail.
    ///   - accent: Fill for reached nodes and the filled connector. Defaults to the theme accent.
    ///   - haptics: Fire a `.success` tick when the flow advances. Defaults to `true`.
    public init(
        _ items: [DSTimelineItem],
        currentStep: Int,
        nodeSize: CGFloat = DSSpacing.xxl,
        lineWidth: CGFloat = DSSpacing.xxxs,
        accent: Color? = nil,
        haptics: Bool = true
    ) {
        self.items = items
        self.currentStep = currentStep
        self._nodeSize = ScaledMetric(wrappedValue: nodeSize, relativeTo: .callout)
        self.lineWidth = lineWidth
        self.accent = accent
        self.haptics = haptics
    }

    private var clampedStep: Int { DSTimelineProgress.clamped(currentStep, count: items.count) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                row(index: index, item: item, isLast: index == items.count - 1)
                    .dsStaggerIn(index: index)
            }
        }
        // Keyed on the clamped step: it only runs when progress changes, never
        // on appear. Reduce Motion swaps the spring for a short fade.
        .animation(reduceMotion ? DSAnimation.fast : DSAnimation.springSmooth, value: clampedStep)
        .onChange(of: clampedStep) { oldValue, newValue in
            guard haptics, DSTimelineProgress.isAdvance(from: oldValue, to: newValue) else { return }
            DSHapticEngine.shared.fire(.success)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Row

    private func row(index: Int, item: DSTimelineItem, isLast: Bool) -> some View {
        let status = DSTimelineProgress.status(index: index, currentStep: currentStep, count: items.count)
        return HStack(alignment: .top, spacing: DSSpacing.md) {
            node(status: status, icon: item.icon)

            // Content. The title line is at least a node tall and centred in
            // that height, so it sits on the node's centre at every text size;
            // the subtitle starts right under it.
            VStack(alignment: .leading, spacing: 0) {
                Text(item.title)
                    .ds(.callout, color: titleColor(status))
                    .frame(minHeight: nodeSize, alignment: .leading)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .ds(.footnote, color: theme.palette.textTertiary)
                }
            }
            .padding(.bottom, isLast ? 0 : DSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The connector is a background, not a child of the rail: it takes the
        // row's height from the content instead of asking for all the height it
        // is offered, so the timeline never stretches inside a taller container.
        .background(alignment: .topLeading) {
            if !isLast {
                connector(filled: DSTimelineProgress.isConnectorFilled(
                    after: index, currentStep: currentStep, count: items.count
                ))
                .padding(.top, nodeSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(item))
        .accessibilityValue(accessibilityValue(status))
    }

    // MARK: - Node

    private func node(status: DSTimelineStatus, icon: String?) -> some View {
        ZStack {
            // The live glow sits on its own breathing layer behind the node, so
            // the node never swaps identity when the step changes (a conditional
            // modifier on the node itself would cross-fade the whole node).
            if status == .current {
                Circle()
                    .fill(resolvedAccent)
                    .dsShadow(.glow(resolvedAccent))
                    .dsBreathe(.medium)
                    .transition(.opacity)
            }
            Circle()
                .fill(status == .upcoming ? theme.palette.border : resolvedAccent)
            nodeGlyph(status: status, icon: icon)
        }
        .frame(width: nodeSize, height: nodeSize)
    }

    @ViewBuilder
    private func nodeGlyph(status: DSTimelineStatus, icon: String?) -> some View {
        switch status {
        case .complete:
            Image(systemName: icon ?? "checkmark")
                .font(.system(size: nodeSize * Metrics.glyphRatio, weight: .bold))
                .foregroundStyle(theme.onAccent)
        case .current:
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: nodeSize * Metrics.glyphRatio, weight: .bold))
                    .foregroundStyle(theme.onAccent)
            } else {
                Circle()
                    .fill(theme.onAccent)
                    .frame(width: nodeSize * Metrics.dotRatio, height: nodeSize * Metrics.dotRatio)
            }
        case .upcoming:
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: nodeSize * Metrics.glyphRatio, weight: .semibold))
                    .foregroundStyle(theme.palette.textTertiary)
            }
        }
    }

    // MARK: - Connector

    /// A track with an accent fill on top. The fill grows from the top with the
    /// spring; under Reduce Motion it stays full height and fades in instead.
    /// The clip stops the spring's overshoot from bleeding into the next node.
    private func connector(filled: Bool) -> some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(theme.palette.border)
            Capsule()
                .fill(resolvedAccent)
                .scaleEffect(y: filled || reduceMotion ? 1 : 0, anchor: .top)
                .opacity(filled || !reduceMotion ? 1 : 0)
        }
        .clipShape(Capsule())
        .frame(width: lineWidth)
        .frame(width: nodeSize)
    }

    // MARK: - Colors

    private var resolvedAccent: Color { accent ?? theme.accent }

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
