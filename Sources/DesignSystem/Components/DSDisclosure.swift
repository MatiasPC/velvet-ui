import SwiftUI

// MARK: - Design System Disclosure
// An expand/collapse section: a tappable header with a title (optional subtitle
// and leading glyph) over content that springs open and shut. The stock
// `DisclosureGroup` carries system chrome and animates linearly; this one is
// surface-agnostic and uses the Velvet springs, so it drops cleanly into a
// `DSCard` for FAQ rows, settings groups or a "show more" reveal.
//
// The chevron rotates 90° on open and the content grows on `springSmooth` while
// fading in — the container clips so nothing spills during the reveal. Under
// Reduce Motion the toggle is instant (opacity is not motion, so the fade stays
// but nothing travels). A `.light` tap fires on every toggle.
//
// It draws no surface of its own: place it inside a `DSCard` (or on a
// `dsSurface`) so it inherits the glass. Stack several in one card for an
// accordion-style list.
//
// Technique adapted from the community expand/collapse pattern (Sarunw,
// Kavsoft, Swift with Majid): spring height + chevron rotation, rewritten on
// Velvet tokens.

/// Sizes derived from the spacing scale — no raw CGFloat literals in the body.
private enum Metrics {
    /// Chevron point size — matches the `DSListCell` trailing chevron (12).
    static let chevronSize: CGFloat = DSSpacing.sm
    /// Leading glyph point size (16).
    static let iconSize: CGFloat = DSSpacing.md
    /// Fixed leading column so titles align whether or not a row has an icon (20).
    static let iconColumn: CGFloat = DSSpacing.lg
}

public struct DSDisclosure<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let icon: String?
    private let showsDivider: Bool
    private let content: () -> Content

    @State private var isExpanded: Bool
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - title: The header label.
    ///   - subtitle: Optional secondary line under the title.
    ///   - icon: Optional SF Symbol shown before the title, tinted `theme.ink`.
    ///   - initiallyExpanded: Whether the section starts open. Defaults to `false`.
    ///   - showsDivider: Draw a hairline between header and content when open.
    ///     Defaults to `true`.
    ///   - content: The collapsible body.
    public init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        initiallyExpanded: Bool = false,
        showsDivider: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.showsDivider = showsDivider
        self.content = content
        self._isExpanded = State(initialValue: initiallyExpanded)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            if isExpanded {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    if showsDivider {
                        DSDivider()
                    }
                    content()
                }
                .padding(.top, DSSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }
        }
        // Clip so the growing content is revealed by the container rather than
        // spilling out at full height before the spring catches up.
        .clipped()
    }

    // MARK: - Header

    private var header: some View {
        Button {
            DSHapticEngine.shared.fire(.light)
            withAnimation(reduceMotion ? nil : DSAnimation.springSmooth) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: DSSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: Metrics.iconSize, weight: .semibold))
                        .foregroundStyle(theme.ink)
                        .frame(width: Metrics.iconColumn)
                }

                VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                    Text(title)
                        .ds(.title3)

                    if let subtitle {
                        Text(subtitle)
                            .ds(.footnote, color: theme.palette.textSecondary)
                    }
                }

                Spacer(minLength: DSSpacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: Metrics.chevronSize, weight: .semibold))
                    .foregroundStyle(theme.palette.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(.vertical, DSSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Collapses the section" : "Expands the section")
    }
}

// MARK: - Preview

#if DEBUG
private struct DSDisclosurePreviewHost: View {
    @State private var theme = DSTheme()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                // A single card holding an accordion-style stack.
                DSCard {
                    VStack(spacing: 0) {
                        DSDisclosure("Shipping & returns", icon: "shippingbox", initiallyExpanded: true) {
                            Text("Free shipping on orders over $50. Returns accepted within 30 days in original condition.")
                                .ds(.callout, color: theme.palette.textSecondary)
                        }
                        DSDivider()
                        DSDisclosure("Size guide", icon: "ruler") {
                            Text("Runs true to size. Between sizes? Size up for a relaxed fit.")
                                .ds(.callout, color: theme.palette.textSecondary)
                        }
                        DSDivider()
                        DSDisclosure("Care", icon: "sparkles") {
                            Text("Machine wash cold, tumble dry low. Do not bleach.")
                                .ds(.callout, color: theme.palette.textSecondary)
                        }
                    }
                }

                // No subtitle/icon, richer content.
                DSCard {
                    DSDisclosure("Advanced options", subtitle: "Rarely needed") {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Toggle experimental behaviour for this workspace.")
                                .ds(.callout, color: theme.palette.textSecondary)
                            DSBadge("Beta", variant: .outline)
                        }
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

#Preview("Disclosure — Light") {
    DSDisclosurePreviewHost().preferredColorScheme(.light)
}

#Preview("Disclosure — Dark") {
    DSDisclosurePreviewHost().preferredColorScheme(.dark)
}
#endif
