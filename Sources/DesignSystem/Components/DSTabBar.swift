import SwiftUI

// MARK: - Design System Tab Bar
// A floating glass tab bar: icons over short labels on a `.glassThin` pill, with
// a single accent capsule that springs from tab to tab as the selection changes.
// The stock `TabView` bar can't be re-skinned to the Velvet surface language, so
// this is the branded alternative — glass over the gradient, an accent fill for
// the selected tab, and a `.selection` haptic on every switch.
//
// The moving indicator is one capsule shared across the items with
// `matchedGeometryEffect`, so it interpolates its frame between tabs instead of
// fading out here and in there — the same "one source of truth on screen" idea
// `DSSlideToConfirm` uses for its trail. The selected glyph swaps to its filled
// SF Symbol variant and gives a single `.bounce`; both are suppressed under
// Reduce Motion, where the indicator simply jumps to the new tab.
//
// This owns no selection state: bind it to whatever drives your content (a
// `TabView` selection, a router enum, an index). Tags are any `Hashable`.

// MARK: - DSTabItem

/// One tab: the value it selects, its label, and the SF Symbol to show above it.
/// Pass the *base* symbol name (e.g. `"house"`); the bar applies the `.fill`
/// variant itself for the selected tab and falls back to the base symbol when no
/// filled variant exists.
public struct DSTabItem<Tag: Hashable>: Identifiable {
    public let tag: Tag
    public let title: String
    public let icon: String

    public var id: Tag { tag }

    /// - Parameters:
    ///   - tag: The value this tab assigns to the binding when tapped.
    ///   - title: Short label under the icon. Also the accessibility label.
    ///   - icon: Base SF Symbol name; the selected tab shows its `.fill` variant.
    public init(tag: Tag, title: String, icon: String) {
        self.tag = tag
        self.title = title
        self.icon = icon
    }
}

// MARK: - DSTabBar

/// A themeable bottom tab bar with a spring-driven accent indicator.
///
///     enum Tab { case home, search, profile }
///     @State private var tab: Tab = .home
///
///     DSTabBar(selection: $tab, items: [
///         DSTabItem(tag: .home,    title: "Home",    icon: "house"),
///         DSTabItem(tag: .search,  title: "Search",  icon: "magnifyingglass"),
///         DSTabItem(tag: .profile, title: "Profile", icon: "person"),
///     ])
///
/// Place it over your content — pin it to the bottom safe area and let the glass
/// sit on the `DSBackdrop`. Re-tapping the current tab is a no-op (no haptic);
/// selecting a different one fires `haptic` and springs the indicator across.
public struct DSTabBar<Tag: Hashable>: View {

    // MARK: Configuration

    @Binding private var selection: Tag
    private let items: [DSTabItem<Tag>]
    private let accent: Color?
    private let haptic: DSHapticStyle

    // MARK: Environment

    @Namespace private var indicator
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - selection: The currently selected tag. Tapping a tab writes its tag here.
    ///   - items: The tabs, left to right. Each `tag` must be unique.
    ///   - accent: Fill of the selected-tab capsule. Defaults to `theme.accent`.
    ///   - haptic: Fired on a switch to a different tab. Defaults to `.selection`.
    public init(
        selection: Binding<Tag>,
        items: [DSTabItem<Tag>],
        accent: Color? = nil,
        haptic: DSHapticStyle = .selection
    ) {
        self._selection = selection
        self.items = items
        self.accent = accent
        self.haptic = haptic
    }

    // MARK: Body

    public var body: some View {
        HStack(spacing: DSSpacing.xxs) {
            ForEach(items) { item in
                tab(for: item)
            }
        }
        .padding(DSSpacing.xxs)
        .dsSurface(.glassThin, radius: DSRadius.chip)
        .dsShadow(.lg)
        // The indicator's move and the content-colour crossfade both ride this
        // one animation; nil under Reduce Motion snaps the indicator across.
        .animation(reduceMotion ? nil : DSAnimation.springSnappy, value: selection)
    }

    // MARK: Tab

    @ViewBuilder
    private func tab(for item: DSTabItem<Tag>) -> some View {
        let isSelected = item.tag == selection
        let content = isSelected ? theme.onAccent : theme.palette.textSecondary

        Button {
            guard item.tag != selection else { return }
            DSHapticEngine.shared.fire(haptic)
            selection = item.tag
        } label: {
            VStack(spacing: DSSpacing.xxxs) {
                Image(systemName: item.icon)
                    .font(DSTextStyle.title3.font)
                    .symbolVariant(isSelected ? .fill : .none)
                    .foregroundStyle(content)
                    // A single bounce as the tab is chosen. The trigger is pinned
                    // to `false` under Reduce Motion so it never fires.
                    .symbolEffect(.bounce, value: reduceMotion ? false : isSelected)

                Text(item.title)
                    .ds(.caption2, color: content)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(accent ?? theme.accent)
                        .matchedGeometryEffect(id: "indicator", in: indicator)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSTabBarPreviewHost: View {
    private enum Tab: Hashable { case home, search, create, alerts, profile }

    @State private var theme = DSTheme()
    @State private var tab: Tab = .home

    private let items: [DSTabItem<Tab>] = [
        DSTabItem(tag: .home,    title: "Home",    icon: "house"),
        DSTabItem(tag: .search,  title: "Search",  icon: "magnifyingglass"),
        DSTabItem(tag: .create,  title: "Create",  icon: "plus.circle"),
        DSTabItem(tag: .alerts,  title: "Alerts",  icon: "bell"),
        DSTabItem(tag: .profile, title: "Profile", icon: "person"),
    ]

    var body: some View {
        VStack {
            DSPreviewThemeDots(theme: theme)
            Spacer()
            Text("Selected: \(String(describing: tab))")
                .ds(.callout, color: theme.palette.textSecondary)
            Spacer()

            // Three tabs — indicator spans a wider capsule.
            DSTabBar(selection: $tab, items: Array(items.prefix(3)))

            // Five tabs, custom accent.
            DSTabBar(selection: $tab, items: items, accent: theme.palette.secondary)
        }
        .dsScreenPadding()
        .padding(.vertical, DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Tab Bar — Light") {
    DSTabBarPreviewHost().preferredColorScheme(.light)
}

#Preview("Tab Bar — Dark") {
    DSTabBarPreviewHost().preferredColorScheme(.dark)
}
#endif
