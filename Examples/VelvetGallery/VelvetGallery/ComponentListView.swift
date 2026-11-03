import SwiftUI
import VelvetUI

struct ComponentListView: View {
    /// Examples show Velvet the way an app ships it: on a gradient theme, not the
    /// Gallery's neutral one.
    @State private var exampleTheme = DSTheme(gradient: .sunset)

    var body: some View {
        List {
            Section("Recording") {
                row("Recording stages", "Clean, chrome-free views for clips") { StageListView() }
            }
            Section {
                row("Onboarding", "Four swipeable pages, live theme") { OnboardingFlow() }
                row("Settings", "Grouped rows, sheet, toasts") { SettingsFlow() }
                row("Checkout", "Cart, promo, slide to pay") { CheckoutFlow().dsTheme(exampleTheme) }
            } header: {
                Text("Examples")
            } footer: {
                Text("Example flows built only from Velvet components. Copy one and adapt it.")
            }
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
            Section("Navigation") {
                row("Tab Bar", "Floating glass bar, sliding accent") { TabBarScreen() }
            }
            Section("Containers") {
                row("Cards", "Glass containers") { CardsScreen() }
                row("Carousel", "Snapping, peeking, with depth") { CarouselScreen() }
                row("Sheet", "Native sheet, Velvet chrome") { SheetScreen() }
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
                row("Number Ticker", "Digits roll like an odometer") { NumberTickerScreen() }
                row("Charts", "Sparkline & scrubbable bars") { ChartsScreen() }
            }
            Section("Feedback") {
                row("Toast", "Transient feedback") { ToastScreen() }
                row("Empty State", "Nothing here yet") { EmptyStateScreen() }
                row("Progress & Loading", "Determinate & shimmer") { ProgressLoadingScreen() }
                row("Skeleton", "Placeholders that match the layout") { SkeletonScreen() }
                row("Success Check", "Ring, check and a pop on the beat") { SuccessCheckScreen() }
                row("Confetti", "A themed burst on any trigger") { ConfettiScreen() }
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
