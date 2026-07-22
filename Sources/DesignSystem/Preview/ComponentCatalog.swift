import SwiftUI

// MARK: - Component Catalog
// A browsable preview of all Design System components.
// Use this during development to see and test every component.

struct ComponentCatalog: View {
    @State private var textFieldValue = ""
    @State private var searchValue = ""
    @State private var progress: Double = 0.65
    @State private var segment = "Week"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xxl) {

                    // MARK: - Typography
                    section("Typography") {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Hero Title").ds(.hero)
                            Text("Large Title").ds(.largeTitle)
                            Text("Title 1").ds(.title1)
                            Text("Title 2").ds(.title2)
                            Text("Title 3").ds(.title3)
                            Text("Body text for reading").ds(.body)
                            Text("Callout text").ds(.callout)
                            Text("Footnote text").ds(.footnote)
                            Text("Caption 1").ds(.caption1)
                            Text("OVERLINE").ds(.overline)
                            Text("42").ds(.displayLarge)
                        }
                    }

                    // MARK: - Buttons
                    section("Buttons") {
                        VStack(spacing: DSSpacing.sm) {
                            DSButton("Primary Button", variant: .primary, isFullWidth: true) { }
                            DSButton("Secondary", variant: .secondary, isFullWidth: true) { }
                            DSButton("Outline", variant: .outline, isFullWidth: true) { }
                            DSButton("Ghost", variant: .ghost) { }
                            DSButton("Destructive", variant: .destructive, icon: "trash") { }

                            HStack(spacing: DSSpacing.sm) {
                                DSButton("Small", size: .small) { }
                                DSButton("Medium", size: .medium) { }
                                DSButton("Large", size: .large) { }
                            }

                            DSButton("Loading...", isLoading: true) { }
                        }
                    }

                    // MARK: - Cards
                    section("Cards") {
                        DSCard(style: .elevated) {
                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                Text("Elevated Card").ds(.title3)
                                Text("Beautiful shadow and rounded corners")
                                    .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        DSCard(style: .outlined) {
                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                Text("Outlined Card").ds(.title3)
                                Text("Subtle border styling")
                                    .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // MARK: - Text Fields
                    section("Text Fields") {
                        VStack(spacing: DSSpacing.md) {
                            DSTextField(
                                label: "Email",
                                placeholder: "Enter your email",
                                icon: "envelope",
                                text: $textFieldValue
                            )
                            DSTextField(
                                label: "Password",
                                placeholder: "Enter password",
                                icon: "lock",
                                text: $textFieldValue,
                                isSecure: true
                            )
                            DSSearchBar(text: $searchValue)
                        }
                    }

                    // MARK: - Progress
                    section("Progress") {
                        VStack(spacing: DSSpacing.lg) {
                            DSCircularProgress(progress: progress, size: 80)
                            DSLinearProgress(progress: progress)
                            DSGradientProgress(progress: progress)
                            DSStepProgress(currentStep: 3, totalSteps: 5)
                        }
                    }

                    // MARK: - Segmented Control
                    section("Segmented Control") {
                        DSSegmentedControl(
                            selection: $segment,
                            options: ["Day", "Week", "Month", "Year"]
                        )
                    }

                    // MARK: - Badges
                    section("Badges & Tags") {
                        HStack(spacing: DSSpacing.xs) {
                            DSBadge("New", variant: .filled)
                            DSBadge("Active", color: DSColors.defaultPalette.success, variant: .soft)
                            DSBadge("Beta", variant: .outline)
                            DSCountBadge(count: 5)
                        }
                    }

                    // MARK: - Avatars
                    section("Avatars") {
                        HStack(spacing: DSSpacing.sm) {
                            DSAvatar(name: "John Doe", size: 32)
                            DSAvatar(name: "Jane Smith", size: 40)
                            DSAvatar(name: "Bob", size: 48)
                        }
                    }

                    // MARK: - Toast
                    section("Toasts") {
                        VStack(spacing: DSSpacing.sm) {
                            DSToast("Action completed!", type: .success)
                            DSToast("Something went wrong", type: .error)
                            DSToast("Check your connection", type: .warning)
                        }
                    }

                    // MARK: - Empty State
                    section("Empty State") {
                        DSEmptyState(
                            icon: "magnifyingglass",
                            title: "No Results",
                            message: "Try adjusting your search or filters to find what you're looking for.",
                            actionTitle: "Clear Filters"
                        ) { }
                    }
                }
                .dsScreenPadding()
                .padding(.vertical, DSSpacing.lg)
            }
            .background(DSColors.defaultPalette.backgroundPrimary)
            .navigationTitle("Design System")
        }
    }

    @ViewBuilder
    func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text(title).ds(.overline, color: DSColors.defaultPalette.textSecondary)
            content()
        }
    }
}

#Preview {
    ComponentCatalog()
}
