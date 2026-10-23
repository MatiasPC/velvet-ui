import SwiftUI

// MARK: - Design System Tab Bar
// A floating glass capsule of equal-width tabs. The selected tab sits on a solid
// accent capsule that slides between tabs with `matchedGeometryEffect`; the icon
// swaps to its filled variant and bounces once. Place it with
// `.safeAreaInset(edge: .bottom)` so content scrolls underneath the glass.

/// Sizes derived from the spacing scale.
private enum Metrics {
    /// Icon point size: DSSpacing.lg (20) + DSSpacing.xxs (4) = 24, a standard tab glyph size.
    static let iconSize: CGFloat = DSSpacing.lg + DSSpacing.xxs
    /// Badge offset from the icon's top-trailing corner.
    static let badgeOffsetX: CGFloat = DSSpacing.sm
    static let badgeOffsetY: CGFloat = -DSSpacing.xs
}

// MARK: - Item Model

/// One tab of a `DSTabBar`.
public struct DSTabItem<Value: Hashable>: Identifiable {
    public var id: Value { value }
    /// The value written to the bar's selection when this tab is chosen.
    public let value: Value
    /// Short label under the icon.
    public let title: String
    /// SF Symbol name, e.g. `"house"`.
    public let icon: String
    /// SF Symbol shown while selected, e.g. `"house.fill"`. `nil` reuses `icon`.
    public let selectedIcon: String?
    /// Count badge on the icon. `nil` or `0` shows none.
    public let badge: Int?

    public init(_ title: String, value: Value, icon: String, selectedIcon: String? = nil, badge: Int? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.badge = badge
    }
}

// MARK: - Tab Bar

/// A floating glass tab bar with a sliding accent indicator.
public struct DSTabBar<Value: Hashable>: View {
    @Binding private var selection: Value
    private let items: [DSTabItem<Value>]
    private let accent: Color?
    private let haptic: DSHapticStyle

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @DSThemed private var theme

    /// - Parameters:
    ///   - selection: The selected tab's value.
    ///   - items: The tabs, in order.
    ///   - accent: Fill of the selected capsule. Defaults to the theme accent.
    ///   - haptic: Fired when the selection changes. Defaults to `.selection`.
    public init(
        selection: Binding<Value>,
        items: [DSTabItem<Value>],
        accent: Color? = nil,
        haptic: DSHapticStyle = .selection
    ) {
        self._selection = selection
        self.items = items
        self.accent = accent
        self.haptic = haptic
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                tab(item)
            }
        }
        .padding(DSSpacing.xxs)
        .dsSurface(.glass, radius: DSRadius.chip)
        .dsShadow(.lg)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isTabBar)
    }

    // MARK: - Tabs

    private func tab(_ item: DSTabItem<Value>) -> some View {
        let isSelected = item.value == selection
        return Button {
            guard !isSelected else { return }
            DSHapticEngine.shared.fire(haptic)
            withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy) {
                selection = item.value
            }
        } label: {
            DSTabBarLabel(
                item: item,
                isSelected: isSelected,
                reduceMotion: reduceMotion,
                foreground: isSelected ? theme.onAccent : theme.palette.textSecondary
            )
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(accent ?? theme.accent)
                        .matchedGeometryEffect(id: "indicator", in: namespace)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(DSTabBarButtonStyle())
        .accessibilityLabel(item.title)
        .accessibilityValue(Self.accessibilityValue(badge: item.badge) ?? "")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Accessibility

    /// VoiceOver value for a tab's badge: "3 new", or `nil` for no badge.
    static func accessibilityValue(badge: Int?) -> String? {
        guard let badge, badge > 0 else { return nil }
        return "\(badge) new"
    }
}

// MARK: - Tab Label

private struct DSTabBarLabel<Value: Hashable>: View {
    let item: DSTabItem<Value>
    let isSelected: Bool
    let reduceMotion: Bool
    let foreground: Color

    /// Bumped each time this tab becomes selected, to fire one bounce.
    @State private var bounce = 0

    var body: some View {
        VStack(spacing: DSSpacing.xxxs) {
            Image(systemName: isSelected ? (item.selectedIcon ?? item.icon) : item.icon)
                .font(.system(size: Metrics.iconSize, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? 0 : bounce)
                .overlay(alignment: .topTrailing) {
                    if let badge = item.badge, badge > 0 {
                        DSCountBadge(count: badge)
                            .offset(x: Metrics.badgeOffsetX, y: Metrics.badgeOffsetY)
                    }
                }
            Text(item.title)
                .ds(.caption2, color: foreground)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.xs)
        .padding(.horizontal, DSSpacing.xs)
        .onChange(of: isSelected) { _, nowSelected in
            if nowSelected { bounce += 1 }
        }
        .accessibilityElement(children: .ignore)
    }
}

// MARK: - Button Style

private struct DSTabBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DSPress.scale : 1.0)
            .animation(DSPress.animation, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
private enum PreviewTab: Hashable { case home, search, inbox, profile }

private struct DSTabBarPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var tab = PreviewTab.home
    @State private var three = "a"

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSPreviewThemeDots(theme: theme)
            Spacer()
            DSTabBar(selection: $tab, items: [
                DSTabItem("Home", value: .home, icon: "house", selectedIcon: "house.fill"),
                DSTabItem("Search", value: .search, icon: "magnifyingglass"),
                DSTabItem("Inbox", value: .inbox, icon: "tray", selectedIcon: "tray.fill", badge: 3),
                DSTabItem("Profile", value: .profile, icon: "person", selectedIcon: "person.fill")
            ])
            DSTabBar(selection: $three, items: [
                DSTabItem("Feed", value: "a", icon: "square.stack"),
                DSTabItem("Map", value: "b", icon: "map"),
                DSTabItem("Saved", value: "c", icon: "bookmark", selectedIcon: "bookmark.fill")
            ])
        }
        .dsScreenPadding()
        .padding(.vertical, DSSpacing.xl)
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Tab bar — Light") {
    DSTabBarPreviewHost().preferredColorScheme(.light)
}

#Preview("Tab bar — Dark") {
    DSTabBarPreviewHost().preferredColorScheme(.dark)
}
#endif
