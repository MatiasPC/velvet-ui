import SwiftUI
import XCTest
@testable import VelvetUI

// Every Swift snippet in AGENTS.md, verbatim, so the patterns agents copy can't
// drift from the API. `MyApp` drops `@main` (a test target can't have an entry point)
// and `import VelvetUI` lines are lifted to the top of the file.
enum DocSnippetsAgents {
    /// Stand-in for the app's own root view in the setup snippet.
    struct RootView: View { var body: some View { Text("Root") } }

    struct MyApp: App {
        @State private var theme = DSTheme(gradient: .sunset)   // .sunset, .aurora, .lagoon
        var body: some Scene { WindowGroup { RootView().dsTheme(theme) } }
    }

    struct ProfileScreen: View {
        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    Text("Profile").ds(.largeTitle)
                    DSCard {
                        HStack(spacing: DSSpacing.md) {
                            DSAvatar(name: "Ada Lovelace", size: 56)
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text("Ada Lovelace").ds(.title3)
                                Text("Member since 2024").ds(.footnote)
                            }
                            Spacer()
                        }
                    }
                }
                .dsScreenPadding()
            }
        }
    }

    struct NotificationSettings: View {
        @State private var push = true
        @State private var digest = false

        var body: some View {
            DSCard(padding: 0) {
                VStack(spacing: 0) {
                    DSListCell(title: "Push notifications") {
                        Image(systemName: "bell")
                    } trailing: {
                        DSToggle(isOn: $push)
                    }
                    DSDivider(inset: DSSpacing.md)
                    DSListCell(title: "Weekly digest", subtitle: "Every Monday") {
                        Image(systemName: "envelope")
                    } trailing: {
                        DSToggle(isOn: $digest)
                    }
                }
            }
        }
    }

    struct CheckoutScreen: View {
        @State private var isPaying = false

        var body: some View {
            DSScreen(backdrop: true) {
                Text("Your order").ds(.largeTitle).dsScreenPadding()
            }
            .safeAreaInset(edge: .bottom) {
                DSButton("Pay $24.00", size: .large, isFullWidth: true, isLoading: isPaying) {
                    isPaying = true
                }
                .dsScreenPadding()
            }
        }
    }

    struct PayRow: View {
        var body: some View {
            DSSlideToConfirm("Slide to pay $24.00", confirmedLabel: "Paid", finish: .morphAndVanish) {
                try await PaymentService.charge(cents: 2400)   // throw to refuse; the control re-opens
            }
        }
    }

    enum PaymentService {
        static func charge(cents: Int) async throws { try await Task.sleep(for: .seconds(1)) }
    }

    struct ArticleCard: View {
        @State private var isLoading = true

        var body: some View {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("Weekend in Lisbon").ds(.title3)
                    Text("Three nights by the river, two guests.").ds(.callout)
                }
                .dsSkeleton(isLoading)
            }
            .task {
                try? await Task.sleep(for: .seconds(1))
                isLoading = false
            }
        }
    }

    enum AppTab: Hashable { case home, search, inbox, profile }

    struct AppShell: View {
        @State private var tab = AppTab.home

        var body: some View {
            Group {
                switch tab {
                case .home:    Text("Home").ds(.largeTitle)
                case .search:  Text("Search").ds(.largeTitle)
                case .inbox:   Text("Inbox").ds(.largeTitle)
                case .profile: Text("Profile").ds(.largeTitle)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dsBackdrop()
            .safeAreaInset(edge: .bottom) {
                DSTabBar(selection: $tab, items: [
                    DSTabItem("Home", value: .home, icon: "house", selectedIcon: "house.fill"),
                    DSTabItem("Search", value: .search, icon: "magnifyingglass"),
                    DSTabItem("Inbox", value: .inbox, icon: "tray", selectedIcon: "tray.fill", badge: 3),
                    DSTabItem("Profile", value: .profile, icon: "person", selectedIcon: "person.fill"),
                ])
                .dsScreenPadding()
            }
        }
    }

    struct SaveButton: View {
        @State private var showsToast = false

        var body: some View {
            DSButton("Save") {
                withAnimation(DSAnimation.springSmooth) { showsToast = true }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if showsToast {
                    DSToast("Saved to your library", type: .success)
                        .transition(.dsSlideUp)
                        .task {
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation(DSAnimation.springSmooth) { showsToast = false }
                        }
                }
            }
        }
    }

    struct PriceTag: View {
        let amount: String
        @DSThemed private var theme

        var body: some View {
            Text(amount)
                .ds(.numeric, color: theme.onAccent)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xxs)
                .background(theme.accent, in: Capsule())
        }
    }

    struct ThemePicker: View {
        let theme: DSTheme

        var body: some View {
            DSSegmentedControl(
                selection: Binding(
                    get: { theme.gradient.id },
                    set: { id in
                        withAnimation(DSAnimation.normal) {
                            theme.gradient = DSGradientTheme.all.first { $0.id == id } ?? .sunset
                        }
                    }
                ),
                segments: DSGradientTheme.all.map { DSSegment($0.name, value: $0.id) }
            )
        }
    }
}

@MainActor
final class DocSnippetsAgentsTests: XCTestCase {
    func testAgentSnippetsInstantiate() {
        _ = DocSnippetsAgents.RootView.self
        _ = DocSnippetsAgents.ProfileScreen()
        _ = DocSnippetsAgents.NotificationSettings()
        _ = DocSnippetsAgents.CheckoutScreen()
        _ = DocSnippetsAgents.PayRow()
        _ = DocSnippetsAgents.ArticleCard()
        _ = DocSnippetsAgents.AppShell()
        _ = DocSnippetsAgents.SaveButton()
        _ = DocSnippetsAgents.PriceTag(amount: "$12")
        _ = DocSnippetsAgents.ThemePicker(theme: DSTheme())
    }
}
