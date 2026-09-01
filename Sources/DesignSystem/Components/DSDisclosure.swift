import SwiftUI

// MARK: - Design System Disclosure
// A themeable expand/collapse container — the tactile, on-brand alternative
// to the stock `DisclosureGroup`. The header row is fully tappable, the
// chevron rotates as the section opens, and the content unfolds with a smooth
// spring instead of the abrupt (and, on iOS 17, glitchy) default reveal.
// Perfect for FAQs, settings sections, filter panels, and accordions.

public enum DSDisclosureStyle: Sendable {
    /// Wrapped in an elevated, rounded surface — great standalone or in a stack.
    case card
    /// No surface or shadow — just a header row and a divider. Ideal inside
    /// an existing card or list where the container already provides chrome.
    case plain
}

public struct DSDisclosure<Content: View>: View {

    // MARK: - Configuration

    private let title: String
    private let icon: String?
    private let style: DSDisclosureStyle
    private let haptics: Bool
    private let content: () -> Content

    // MARK: - Expansion State
    // Supports both self-managed expansion and an external binding, so the
    // same component works standalone or as part of a single-open accordion.

    @State private var internalExpanded: Bool
    private let externalExpanded: Binding<Bool>?

    // MARK: - Self-managed Initializer

    /// A disclosure that tracks its own open/closed state.
    /// - Parameters:
    ///   - title: The header label.
    ///   - icon: Optional leading SF Symbol name.
    ///   - style: Surface treatment. Defaults to `.card`.
    ///   - initiallyExpanded: Whether the section starts open. Defaults to `false`.
    ///   - haptics: Whether toggling fires tactile feedback. Defaults to `true`.
    ///   - content: The collapsible content, revealed when expanded.
    public init(
        _ title: String,
        icon: String? = nil,
        style: DSDisclosureStyle = .card,
        initiallyExpanded: Bool = false,
        haptics: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.haptics = haptics
        self.content = content
        self._internalExpanded = State(initialValue: initiallyExpanded)
        self.externalExpanded = nil
    }

    // MARK: - Bound Initializer

    /// A disclosure whose open/closed state is driven by an external binding —
    /// use this to build a single-open accordion or to persist the state.
    /// - Parameters:
    ///   - title: The header label.
    ///   - icon: Optional leading SF Symbol name.
    ///   - style: Surface treatment. Defaults to `.card`.
    ///   - isExpanded: Binding controlling whether the section is open.
    ///   - haptics: Whether toggling fires tactile feedback. Defaults to `true`.
    ///   - content: The collapsible content, revealed when expanded.
    public init(
        _ title: String,
        icon: String? = nil,
        style: DSDisclosureStyle = .card,
        isExpanded: Binding<Bool>,
        haptics: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.haptics = haptics
        self.content = content
        self._internalExpanded = State(initialValue: isExpanded.wrappedValue)
        self.externalExpanded = isExpanded
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            header

            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .overlay { DSColors.defaultPalette.divider }

                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, style == .card ? DSSpacing.md : 0)
                        .padding(.top, DSSpacing.sm)
                        .padding(.bottom, DSSpacing.md)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(style == .card ? DSColors.defaultPalette.backgroundElevated : .clear)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
        .dsShadow(style == .card ? .sm : .none)
        .animation(DSAnimation.springSmooth, value: isExpanded)
    }

    // MARK: - Header

    private var header: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(DSTextStyle.title3.font)
                        .foregroundStyle(DSColors.defaultPalette.primary)
                        .frame(width: DSSpacing.xl)
                }

                Text(title)
                    .ds(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(DSTextStyle.callout.font.weight(.semibold))
                    .foregroundStyle(DSColors.defaultPalette.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(DSSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")
    }

    // MARK: - State Helpers

    private var isExpanded: Bool {
        externalExpanded?.wrappedValue ?? internalExpanded
    }

    private func toggle() {
        if haptics { DSHapticEngine.shared.fire(.light) }
        if let externalExpanded {
            externalExpanded.wrappedValue.toggle()
        } else {
            internalExpanded.toggle()
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    DisclosurePreview()
        .background(DSColors.defaultPalette.backgroundSecondary)
}

#Preview("Dark") {
    DisclosurePreview()
        .background(DSColors.defaultPalette.backgroundSecondary)
        .preferredColorScheme(.dark)
}

private struct DisclosurePreview: View {
    @State private var billingOpen = true

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.md) {
                DSDisclosure("What is Velvet UI?", icon: "sparkles", initiallyExpanded: true) {
                    Text("A polished SwiftUI design system with tokens, springs, and haptics baked into every component.")
                        .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                }

                DSDisclosure("Shipping & Returns", icon: "shippingbox") {
                    Text("Free returns within 30 days. Orders ship in 1–2 business days.")
                        .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                }

                DSDisclosure("Billing", isExpanded: $billingOpen) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Manage your plan and payment methods.")
                            .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                        DSButton("Update payment", variant: .outline, size: .small) { }
                    }
                }

                DSDisclosure("Advanced options", style: .plain) {
                    Text("Plain style drops the surface so it can nest inside an existing card or list.")
                        .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                }
            }
            .padding(DSSpacing.lg)
        }
    }
}
