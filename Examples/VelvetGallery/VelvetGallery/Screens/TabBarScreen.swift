import SwiftUI
import VelvetUI

private enum AppTab: String, Hashable {
    case home = "Home", search = "Search", inbox = "Inbox", profile = "Profile"
}

struct TabBarScreen: View {
    @State private var tab = AppTab.home
    @State private var three = "feed"
    @State private var accentTab = "feed"
    @State private var compact = AppTab.home

    var body: some View {
        GalleryScreen(title: "Tab Bar", caption: "Floating glass bar, sliding accent") {
            LabeledExample("App shell — tap a tab") {
                ZStack(alignment: .bottom) {
                    VStack(spacing: DSSpacing.sm) {
                        Image(systemName: "square.dashed").font(.largeTitle)
                        Text(tab.rawValue).ds(.title2)
                    }
                    .foregroundStyle(DSColors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    DSTabBar(selection: $tab, items: Self.items)
                        .padding(DSSpacing.sm)
                }
                .frame(height: 280)
                .background(DSColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: DSRadius.card))
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.card))
            }
            LabeledExample("Three tabs, String values") {
                DSTabBar(selection: $three, items: [
                    DSTabItem("Feed", value: "feed", icon: "square.stack"),
                    DSTabItem("Map", value: "map", icon: "map"),
                    DSTabItem("Saved", value: "saved", icon: "bookmark", selectedIcon: "bookmark.fill")
                ])
            }
            LabeledExample("Custom accent") {
                DSTabBar(selection: $accentTab, items: [
                    DSTabItem("Feed", value: "feed", icon: "square.stack"),
                    DSTabItem("Map", value: "map", icon: "map"),
                    DSTabItem("Saved", value: "saved", icon: "bookmark", selectedIcon: "bookmark.fill", badge: 12)
                ], accent: DSColors.secondary)
            }
            LabeledExample("Enum values, no selected icon") {
                DSTabBar(selection: $compact, items: [
                    DSTabItem("Home", value: .home, icon: "house"),
                    DSTabItem("Search", value: .search, icon: "magnifyingglass"),
                    DSTabItem("Profile", value: .profile, icon: "person")
                ])
            }
        }
    }

    fileprivate static let items: [DSTabItem<AppTab>] = [
        DSTabItem("Home", value: .home, icon: "house", selectedIcon: "house.fill"),
        DSTabItem("Search", value: .search, icon: "magnifyingglass"),
        DSTabItem("Inbox", value: .inbox, icon: "tray", selectedIcon: "tray.fill", badge: 3),
        DSTabItem("Profile", value: .profile, icon: "person", selectedIcon: "person.fill")
    ]
}

struct TabBarStage: View {
    let autoplay: Bool
    @State private var tab = AppTab.home

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: DSSpacing.sm) {
                Text(tab.rawValue).ds(.hero)
                    .contentTransition(.interpolate)
                Text("Placeholder content").ds(.callout, color: DSColors.textSecondary)
            }
            Spacer()
            DSTabBar(selection: $tab, items: TabBarScreen.items)
        }
        // A phone-height column centred on screen, so the bar stays inside the
        // 9:16 crop that recordings use instead of sitting on the bottom edge.
        .frame(maxWidth: .infinity)
        .frame(height: 560)
        .task(id: autoplay) {
            guard autoplay else { return }
            let order: [AppTab] = [.home, .search, .inbox, .profile]
            await stageLoop {
                for next in order.dropFirst() + [.home] {
                    await stagePause(1.2)
                    if Task.isCancelled { return }
                    withAnimation(DSAnimation.springSnappy) { tab = next }
                }
            }
        }
    }
}
