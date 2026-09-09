import SwiftUI
import DesignSystem

struct ToggleScreen: View {
    @State private var notifications = true
    @State private var sync = false
    @State private var focus = false
    @State private var sizeSmall = false
    @State private var sizeMedium = true

    var body: some View {
        GalleryScreen(title: "Toggle", caption: "Switches") {
            DSCard {
                VStack(spacing: DSSpacing.md) {
                    LabeledExample("With label") {
                        DSToggle("Push notifications", isOn: $notifications)
                    }
                    LabeledExample("Sizes") {
                        HStack(spacing: DSSpacing.lg) {
                            DSToggle(isOn: $sizeSmall, size: .small)
                            DSToggle(isOn: $sizeMedium, size: .medium)
                        }
                    }
                    LabeledExample("Disabled") {
                        DSToggle("Background sync", isOn: $sync).disabled(true)
                    }
                    LabeledExample("Custom tint (neutral)") {
                        DSToggle("Focus mode", isOn: $focus, onColor: DSColors.textSecondary)
                    }
                }
            }
        }
    }
}
