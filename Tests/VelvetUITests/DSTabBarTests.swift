import XCTest
import SwiftUI
@testable import VelvetUI

// Every snippet on docs/components/DSTabBar.md lives here verbatim.
enum DocSnippetsTabBar {
    struct TabBarDemo: View {
        enum Tab: Hashable { case home, search, inbox, profile }
        @State private var tab = Tab.home

        var body: some View {
            DSScreen(backdrop: true) {
                Text(String(describing: tab).capitalized).ds(.title1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                DSTabBar(selection: $tab, items: [
                    DSTabItem("Home", value: .home, icon: "house", selectedIcon: "house.fill"),
                    DSTabItem("Search", value: .search, icon: "magnifyingglass"),
                    DSTabItem("Inbox", value: .inbox, icon: "tray", selectedIcon: "tray.fill", badge: 3),
                    DSTabItem("Profile", value: .profile, icon: "person", selectedIcon: "person.fill")
                ])
                .dsScreenPadding()
            }
        }
    }

    struct TabBarVariantsDemo: View {
        @State private var section = "feed"

        var body: some View {
            DSTabBar(selection: $section, items: [
                DSTabItem("Feed", value: "feed", icon: "square.stack"),
                DSTabItem("Map", value: "map", icon: "map"),
                DSTabItem("Saved", value: "saved", icon: "bookmark", selectedIcon: "bookmark.fill")
            ], accent: .indigo)
        }
    }
}

@MainActor
final class DSTabBarTests: XCTestCase {
    func testSnippetsInstantiate() {
        _ = DocSnippetsTabBar.TabBarDemo().body
        _ = DocSnippetsTabBar.TabBarVariantsDemo().body
    }

    func testAccessibilityValue() {
        XCTAssertNil(DSTabBar<String>.accessibilityValue(badge: nil))
        XCTAssertNil(DSTabBar<String>.accessibilityValue(badge: 0))
        XCTAssertNil(DSTabBar<String>.accessibilityValue(badge: -2))
        XCTAssertEqual(DSTabBar<String>.accessibilityValue(badge: 3), "3 new")
    }

    func testItemIdentityIsValue() {
        let item = DSTabItem("Home", value: 7, icon: "house")
        XCTAssertEqual(item.id, 7)
        XCTAssertNil(item.selectedIcon)
        XCTAssertNil(item.badge)
    }
}
