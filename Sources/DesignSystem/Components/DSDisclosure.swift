import SwiftUI

// MARK: - Design System Disclosure
// A glass expand/collapse container — the themeable, tactile alternative to the
// stock `DisclosureGroup`, whose default motion snaps and whose chrome ignores
// the surface language. A header row (title, optional icon and subtitle, and a
// chevron that rotates 180° on open) sits on a glass surface; toggling it
// reveals the content by unfolding it downward while the panel's height springs
// open. Every FAQ, settings group and filter panel needs one.
//
// Two ways to drive it:
//   • self-managed — `DSDisclosure("Title") { … }`, optionally `initiallyExpanded: true`.
//   • controlled   — `DSDisclosure("Title", isExpanded: $flag) { … }`, so a parent
//     can build an accordion where opening one row closes the others.
//
// The reveal is animated from inside the toggle (one `withAnimation` spring for
// both the transition and the height change), so a controlled parent that flips
// the binding should do so inside `withAnimation` too. Reduce Motion turns the
// spring into an instant change and drops the slide, keeping only the fade.

public struct DSDisclosure<Content: View>: View {

    // MARK: Configuration

    private let title: String
    private let icon: String?
    private let subtitle: String?
    private let accent: Color?
    private let haptic: DSHapticStyle
    private let content: () -> Content

    // MARK: State

    /// The external binding when the caller drives expansion; `nil` when the
    /// control manages its own state. Only one of these is ever the source of
    /// truth — `isExpanded` reads whichever is in play.
    private let externalExpanded: Binding<Bool>?
    @State private var internalExpanded: Bool

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// A self-managed disclosure that owns its expanded state.
    /// - Parameters:
    ///   - title: The always-visible header label.
    ///   - icon: Optional leading SF Symbol, tinted with `accent`.
    ///   - subtitle: Optional secondary line under the title.
    ///   - initiallyExpanded: Whether it starts open. Defaults to `false`.
    ///   - accent: Icon tint. Defaults to the theme accent.
    ///   - haptic: Fired on every toggle. Defaults to `.light`.
    ///   - content: The revealed body.
    public init(
        _ title: String,
        icon: String? = nil,
        subtitle: String? = nil,
        initiallyExpanded: Bool = false,
        accent: Color? = nil,
        haptic: DSHapticStyle = .light,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.accent = accent
        self.haptic = haptic
        self.content = content
        self.externalExpanded = nil
        self._internalExpanded = State(initialValue: initiallyExpanded)
    }

    /// A controlled disclosure whose expanded state the caller owns — bind
    /// several to one `@State` selection to make an exclusive accordion.
    /// - Parameters:
    ///   - title: The always-visible header label.
    ///   - icon: Optional leading SF Symbol, tinted with `accent`.
    ///   - subtitle: Optional secondary line under the title.
    ///   - isExpanded: Binding the control reads and writes.
    ///   - accent: Icon tint. Defaults to the theme accent.
    ///   - haptic: Fired on every toggle. Defaults to `.light`.
    ///   - content: The revealed body.
    public init(
        _ title: String,
        icon: String? = nil,
        subtitle: String? = nil,
        isExpanded: Binding<Bool>,
        accent: Color? = nil,
        haptic: DSHapticStyle = .light,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.accent = accent
        self.haptic = haptic
        self.content = content
        self.externalExpanded = isExpanded
        self._internalExpanded = State(initialValue: false)
    }

    // MARK: Body

    public var body: some View {
        let resolvedAccent = accent ?? theme.accent

        VStack(alignment: .leading, spacing: 0) {
            header(resolvedAccent)

            if isExpanded {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.bottom, DSSpacing.md)
                    .transition(revealTransition)
            }
        }
        // The glass surface clips to its rounded rect, so the unfolding content
        // never spills past the panel while it slides in.
        .dsSurface(.glass, radius: DSRadius.surface)
    }

    // MARK: Header

    private func header(_ accent: Color) -> some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .dsTextStyle(.title3, color: accent)
                }

                VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                    Text(title).ds(.title3)
                    if let subtitle {
                        Text(subtitle)
                            .ds(.footnote, color: theme.palette.textSecondary)
                    }
                }

                Spacer(minLength: DSSpacing.sm)

                Image(systemName: "chevron.down")
                    .dsTextStyle(.footnote, color: theme.palette.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(DSSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))
        .accessibilityHint(isExpanded ? Text("Double tap to collapse") : Text("Double tap to expand"))
    }

    // MARK: Motion

    /// Slide down + fade in on open; fade out on close. The removal stays a plain
    /// fade so the content never appears to fly up behind the header as the panel
    /// folds. Reduce Motion drops the slide entirely.
    private var revealTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        )
    }

    // MARK: State plumbing

    private var isExpanded: Bool {
        externalExpanded?.wrappedValue ?? internalExpanded
    }

    private func setExpanded(_ value: Bool) {
        if let externalExpanded {
            externalExpanded.wrappedValue = value
        } else {
            internalExpanded = value
        }
    }

    private func toggle() {
        DSHapticEngine.shared.fire(haptic)
        // One spring carries both the height change and the content transition;
        // `nil` under Reduce Motion applies the change instantly.
        let animation = reduceMotion ? nil : DSAnimation.springSmooth
        withAnimation(animation) {
            setExpanded(!isExpanded)
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSDisclosurePreviewHost: View {
    @State private var theme = DSTheme()
    @State private var marketingOn = false
    /// Drives the exclusive accordion: at most one row open at a time.
    @State private var openRow: Int? = 0

    private let faq: [(String, String)] = [
        ("How do refunds work?", "Refunds land back on your original payment method within 5–10 business days. You can request one any time from Settings › Billing."),
        ("Can I change my plan later?", "Yes — upgrade or downgrade whenever you like. Changes are prorated to the day, so you only ever pay for what you use."),
        ("Is my data encrypted?", "Everything is encrypted in transit and at rest. We never sell your data, and you can export or delete it from your account at any time.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSPreviewThemeDots(theme: theme)

                // Self-managed, with icon + subtitle, starts open.
                DSDisclosure(
                    "Notifications",
                    icon: "bell.badge",
                    subtitle: "Sounds, badges, delivery",
                    initiallyExpanded: true
                ) {
                    VStack(spacing: DSSpacing.md) {
                        DSToggle("Marketing emails", isOn: $marketingOn)
                        Text("We'll only email you about things you asked to hear about.")
                            .ds(.footnote, color: DSColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Controlled exclusive accordion.
                Text("FAQ").ds(.overline, color: DSColors.textSecondary)
                VStack(spacing: DSSpacing.sm) {
                    ForEach(Array(faq.enumerated()), id: \.offset) { index, item in
                        DSDisclosure(
                            item.0,
                            isExpanded: Binding(
                                get: { openRow == index },
                                set: { openRow = $0 ? index : nil }
                            )
                        ) {
                            Text(item.1)
                                .ds(.callout, color: DSColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
