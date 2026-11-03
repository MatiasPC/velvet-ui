import SwiftUI

// MARK: - Design System Disclosure Group
// A glass "show more" section: tap the header and the body springs open while the
// chevron rotates and a light haptic fires. The Velvet reading of an accordion /
// FAQ row — for settings detail, filters, long descriptions, anything that should
// stay out of the way until asked for.
//
// Why not the stock `DisclosureGroup`: its open/close animation breaks inside a
// `ForEach` on iOS 17, its chevron ignores the tint, it has no haptics and no
// glass. This one is custom-drawn on Velvet tokens so it matches DSCard and reads
// as one surface with the rest of the system.
//
// Inspiration: the spring-chevron pattern from Sarunw ("SwiftUI Animation",
// sarunw.com/posts/swiftui-animation) and the `withAnimation { isExpanded.toggle() }`
// idiom from the Apple Developer Forums (thread 655302). No upstream code reproduced.

// MARK: - Reveal layout

/// Hosts one child and reports `progress` (0...1) of its natural height, so the
/// card grows and shrinks smoothly around the body. The child is always laid out
/// at its full height (anchored to the top and clipped by the host), so text never
/// re-wraps and nothing jumps while the spring runs. `progress` is the layout's
/// `animatableData`: the spring interpolates it and every frame is a real layout.
struct DSDisclosureReveal: Layout {
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// The height reported for a body of `natural` height. A spring overshoots 0 and
    /// 1; a negative height is nonsense, so the low end is clamped. The high end is
    /// left alone on purpose: the small overshoot past full height is the bounce.
    static func height(natural: CGFloat, progress: Double) -> CGFloat {
        max(0, natural * CGFloat(progress))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let body = subviews.first else { return .zero }
        let natural = body.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        return CGSize(width: natural.width, height: Self.height(natural: natural.height, progress: progress))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(
            at: CGPoint(x: bounds.minX, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width, height: nil)
        )
    }
}

// MARK: - DSDisclosureGroup

public struct DSDisclosureGroup<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let icon: String?
    private let haptic: DSHapticStyle
    private let content: () -> Content

    @State private var internalExpanded: Bool
    private let externalExpanded: Binding<Bool>?

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Init

    /// Self-contained disclosure that tracks its own open/closed state.
    /// - Parameters:
    ///   - title: The header label, always visible.
    ///   - subtitle: Optional secondary line under the title.
    ///   - icon: Optional SF Symbol shown before the title, tinted with the accent.
    ///   - initiallyExpanded: Whether the body is open on first appearance.
    ///   - haptic: Feedback fired on each toggle. Defaults to `.light`.
    ///   - content: The body revealed when expanded. It stays in the view tree
    ///     while collapsed (hidden from touch and VoiceOver), so it keeps its state.
    public init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        initiallyExpanded: Bool = false,
        haptic: DSHapticStyle = .light,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.haptic = haptic
        self.content = content
        self.externalExpanded = nil
        self._internalExpanded = State(initialValue: initiallyExpanded)
    }

    /// Disclosure whose open/closed state you own — drive several from one
    /// controller for an "only one open at a time" accordion.
    public init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isExpanded: Binding<Bool>,
        haptic: DSHapticStyle = .light,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.haptic = haptic
        self.content = content
        self.externalExpanded = isExpanded
        self._internalExpanded = State(initialValue: isExpanded.wrappedValue)
    }

    // MARK: - State

    private var expanded: Binding<Bool> {
        externalExpanded ?? $internalExpanded
    }

    private var isExpanded: Bool { expanded.wrappedValue }

    /// The motion for every part of the reveal (body height, fade, chevron). Driven
    /// by the state itself rather than by `withAnimation`, so it also plays when the
    /// owner flips a bound `isExpanded` from outside. Reduce Motion swaps the spring
    /// for a short ease: the same end state, without the bounce.
    private var animation: Animation {
        reduceMotion ? DSAnimation.fast : DSAnimation.springSmooth
    }

    private func toggle() {
        DSHapticEngine.shared.fire(haptic)
        expanded.wrappedValue.toggle()
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            DSDisclosureReveal(progress: isExpanded ? 1 : 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(theme.palette.divider)
                        .frame(height: 1)
                        .padding(.vertical, DSSpacing.sm)
                        .accessibilityHidden(true)

                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .opacity(isExpanded ? 1 : 0)
                .allowsHitTesting(isExpanded)
                .accessibilityHidden(!isExpanded)
            }
            .clipped()
        }
        .animation(animation, value: isExpanded)
        .padding(DSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsSurface(.glass, radius: DSRadius.card)
    }

    // MARK: - Header

    private var header: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .dsFont(.title3)
                        .foregroundStyle(theme.accent)
                        .frame(minWidth: DSSpacing.lg)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                    Text(title).ds(.title3)
                    if let subtitle {
                        Text(subtitle).ds(.footnote, color: theme.palette.textSecondary)
                    }
                }

                Spacer(minLength: DSSpacing.sm)

                Image(systemName: "chevron.down")
                    .dsFont(.button)
                    .foregroundStyle(theme.palette.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(DSDisclosureHeaderStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(Self.accessibilityValue(isExpanded: isExpanded))
        .accessibilityHint(Self.accessibilityHint(isExpanded: isExpanded))
    }

    // MARK: - Accessibility

    /// VoiceOver value of the header: "Expanded" or "Collapsed".
    static func accessibilityValue(isExpanded: Bool) -> String {
        isExpanded ? "Expanded" : "Collapsed"
    }

    /// VoiceOver hint of the header: what activating it does.
    static func accessibilityHint(isExpanded: Bool) -> String {
        isExpanded ? "Hides the details" : "Shows the details"
    }
}

// MARK: - Header button style

private struct DSDisclosureHeaderStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DSPress.scale : 1.0)
            .animation(DSPress.animation, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSDisclosureGroupPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var shipping = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                // Self-contained, starts open.
                DSDisclosureGroup(
                    "What's included",
                    subtitle: "3 items",
                    icon: "shippingbox",
                    initiallyExpanded: true
                ) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("• Unlimited projects").ds(.callout)
                        Text("• Priority support").ds(.callout)
                        Text("• Early access to betas").ds(.callout)
                    }
                }

                // Bound state, with a control that drives it from outside.
                DSDisclosureGroup("Shipping details", isExpanded: $shipping) {
                    Text("Ships in 2–3 business days with carbon-neutral delivery.")
                        .ds(.callout, color: DSColors.textSecondary)
                }

                DSToggle("Shipping open", isOn: $shipping)

                // Plain FAQ row, starts closed.
                DSDisclosureGroup("Can I cancel anytime?") {
                    Text("Yes — cancel from Settings and keep access until the end of the period.")
                        .ds(.callout, color: DSColors.textSecondary)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Disclosure — Light") {
    DSDisclosureGroupPreviewHost().preferredColorScheme(.light)
}

#Preview("Disclosure — Dark") {
    DSDisclosureGroupPreviewHost().preferredColorScheme(.dark)
}
#endif
