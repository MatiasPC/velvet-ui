import SwiftUI
import DesignSystem

struct ButtonsScreen: View {
    var body: some View {
        GalleryScreen(title: "Buttons", caption: "Variants, sizes, states") {
            LabeledExample("Variants") {
                VStack(spacing: DSSpacing.sm) {
                    DSButton("Primary", variant: .primary, isFullWidth: true) { print("primary") }
                    DSButton("Secondary", variant: .secondary, isFullWidth: true) { print("secondary") }
                    DSButton("Outline", variant: .outline, isFullWidth: true) { print("outline") }
                    HStack(spacing: DSSpacing.sm) {
                        DSButton("Ghost", variant: .ghost) { print("ghost") }
                        DSButton("Delete", variant: .destructive, icon: "trash") { print("destructive") }
                    }
                }
            }
            LabeledExample("Sizes") {
                HStack(spacing: DSSpacing.sm) {
                    DSButton("Small", size: .small) { }
                    DSButton("Medium", size: .medium) { }
                    DSButton("Large", size: .large) { }
                }
            }
            LabeledExample("States") {
                VStack(spacing: DSSpacing.sm) {
                    DSButton("Loading", isFullWidth: true, isLoading: true) { }
                    DSButton("Disabled", isFullWidth: true) { }.disabled(true)
                }
            }
            LabeledExample("Icon position") {
                VStack(spacing: DSSpacing.sm) {
                    DSButton("Back", icon: "arrow.left", iconPosition: .leading, isFullWidth: true) { }
                    DSButton("Continue", icon: "arrow.right", iconPosition: .trailing, isFullWidth: true) { }
                }
            }
            LabeledExample("Icon buttons") {
                HStack(spacing: DSSpacing.md) {
                    DSIconButton(icon: "heart") { print("like") }
                    DSIconButton(icon: "square.and.arrow.up") { print("share") }
                    DSIconButton(icon: "ellipsis") { print("more") }
                }
            }
        }
    }
}
