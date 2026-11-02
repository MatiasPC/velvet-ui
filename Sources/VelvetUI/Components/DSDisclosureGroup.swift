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
    ///   - content: The body revealed when expanded.
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

    private func toggle() {
        DSHapticEngine.shared.fire(haptic)
        withAnimation(reduceMotion ? nil : DSAnimation.springSmooth) {
            expanded.wrappedValue.toggle()
        }
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isExpanded {
                Rectangle()
                    .fill(theme.palette.divider)
                    .frame(height: 1)
                    .padding(.vertical, DSSpacing.sm)

                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
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
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.accent)
                        .frame(width: DSSpacing.lg)
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.palette.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")
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
