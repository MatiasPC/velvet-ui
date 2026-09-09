import SwiftUI
import DesignSystem

struct ComponentListView: View {
    var body: some View {
        List {
            Section("Foundations") {
                row("Theme", "Neutral palette & glass surfaces") { ThemeScreen() }
                row("Typography", "Every text style") { TypographyScreen() }
                row("Layout", "Stacks & grids") { LayoutScreen() }
                row("Motion", "Ambient primitives") { MotionScreen() }
            }
            Section("Actions") {
                row("Buttons", "Variants, sizes, states") { ButtonsScreen() }
                row("Slide to Confirm", "Drag to commit") { SlideToConfirmScreen() }
            }
            Section("Containers") {
                row("Cards", "Glass containers") { CardsScreen() }
            }
            Section("Inputs") {
                row("Text Field", "Inputs & validation") { TextFieldScreen() }
                row("Code Field", "OTP entry") { CodeFieldScreen() }
                row("Toggle", "Switches") { ToggleScreen() }
                row("Segmented Control", "Pick one") { SegmentedControlScreen() }
                row("Stepper", "Numeric input") { StepperScreen() }
                row("Rating", "Star input") { RatingScreen() }
                row("Page Control", "Paged content") { PageControlScreen() }
            }
            Section("Data Display") {
                row("Badges & Avatars", "Status marks & identity") { BadgesAvatarsScreen() }
                row("Lists", "Rows & sections") { ListsScreen() }
            }
            Section("Feedback") {
                row("Toast", "Transient feedback") { ToastScreen() }
                row("Empty State", "Nothing here yet") { EmptyStateScreen() }
                row("Progress & Loading", "Determinate & skeletons") { ProgressLoadingScreen() }
                row("Thinking Indicator", "Ambient processing") { ThinkingIndicatorScreen() }
                row("Typewriter Text", "Typed reveal") { TypewriterTextScreen() }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DSColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Velvet UI")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { AppearanceMenu() } }
    }

    private func row<Destination: View>(
        _ title: String,
        _ caption: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).ds(.body)
                Text(caption).ds(.footnote, color: DSColors.textSecondary)
            }
        }
        .listRowBackground(DSColors.backgroundSecondary)
    }
}
