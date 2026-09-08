import SwiftUI
import DesignSystem

struct ListsScreen: View {
    var body: some View {
        GalleryScreen(title: "Lists", caption: "Rows & sections") {
            LabeledExample("Settings group") {
                DSSectionHeader("Settings", action: "Edit", onAction: { print("edit") })

                DSCard(padding: 0) {
                    VStack(spacing: 0) {
                        DSListCell(title: "Account", subtitle: "Profile, security") {
                            Image(systemName: "person.circle")
                        } action: { print("account") }

                        DSDivider(inset: DSSpacing.screenHorizontal)

                        DSListCell(title: "Notifications") {
                            Image(systemName: "bell")
                        } trailing: {
                            DSCountBadge(count: 3)
                        } action: { print("notifications") }

                        DSDivider(inset: DSSpacing.screenHorizontal)

                        DSListCell(title: "About", subtitle: "Version 0.2.0")
                    }
                }
            }
        }
    }
}
