import SwiftUI
import DesignSystem

struct ToggleScreen: View {
    @State private var notifications = true
    @State private var sync = false
    @State private var focus = false

    var body: some View {
        GalleryScreen(title: "Toggle", caption: "Switches") {
            DSCard {
                VStack(spacing: DSSpacing.md) {
                    LabeledExample("With label") {
                        DSToggle("Push notifications", isOn: $notifications)
                    }
                    LabeledExample("Sizes") {
                        HStack(spacing: DSSpacing.lg) {
                            DSToggle(isOn: $sync, size: .small)
                            DSToggle(isOn: $notifications, size: .medium)
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
