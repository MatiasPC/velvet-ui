import SwiftUI

// MARK: - Component Catalog
// A browsable preview of all Design System components, on the themed backdrop.
// Use it during development and for the manual walkthrough: switch the gradient
// theme with the dots, toggle the backdrop off to see the solid fallback, and
// flip the preview between light and dark.

struct ComponentCatalog: View {
    @State private var theme = DSTheme()
    @State private var useBackdrop = true

    @State private var textFieldValue = ""
    @State private var searchValue = ""
    @State private var progress: Double = 0.65
    @State private var segmentSelection = "Day"
    @State private var tabSelection = "Overview"
    @State private var notificationsOn = true
    @State private var darkModeOn = false
    @State private var rating: Double = 4
    @State private var page: Int = 1
    @State private var codeValue = "12"
    @State private var volume: Double = 0.6
    @State private var quality: Double = 3

    var body: some View {
        NavigationStack {
            Group {
                if useBackdrop {
                    scroll.dsBackdrop()
                } else {
                    scroll.background(DSColors.backgroundPrimary.ignoresSafeArea())
                }
            }
            .navigationTitle("Velvet UI")
        }
        .dsTheme(theme)
    }

    private var scroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xxl) {

                // MARK: - Theme
                section("Theme") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            DSPreviewThemeDots(theme: theme)
                            Text(theme.gradient.name).ds(.title3)
                            DSToggle("Backdrop", isOn: $useBackdrop)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Surfaces
                section("Surfaces") {
                    VStack(spacing: DSSpacing.sm) {
                        surfaceRow("glassThin", .glassThin)
                        surfaceRow("glass", .glass)
                        surfaceRow("glassThick", .glassThick)
                        surfaceRow("solid", .solid)
                    }
                }

                // MARK: - Typography
                section("Typography") {
                    DSCard {
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
                            Text("$1,248.00").ds(.numeric)
                            Text("42").ds(.displayLarge)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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

                        HStack(spacing: DSSpacing.sm) {
                            DSIconButton(icon: "heart") { }
                            DSIconButton(icon: "square.and.arrow.up") { }
                            DSIconButton(icon: "ellipsis") { }
                        }
                    }
                }

                // MARK: - Cards
                section("Cards") {
                    DSCard(style: .elevated) {
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text("Elevated Card").ds(.title3)
                            Text("Glass, edge highlight, soft shadow")
                                .ds(.callout, color: DSColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    DSCard(style: .outlined) {
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text("Outlined Card").ds(.title3)
                            Text("Denser glass, no shadow")
                                .ds(.callout, color: DSColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    DSCard(style: .elevated) {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Nested").ds(.title3)
                            DSCard(style: .flat, cornerRadius: DSRadius.surface) {
                                Text("Flat card inside").ds(.callout)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    DSInteractiveCard(action: {}) {
                        HStack {
                            Text("Interactive card").ds(.body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(DSColors.textTertiary)
                        }
                    }

                    DSImageCard(title: "Cabaña en el bosque", subtitle: "$120 / noche", badge: "Nuevo")
                }

                // MARK: - Text Fields
                section("Text Fields") {
                    DSCard {
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
                            DSTextField(
                                label: "With error",
                                placeholder: "Username",
                                text: .constant("m"),
                                state: .error("Too short")
                            )
                            DSSearchBar(text: $searchValue)
                        }
                    }
                }

                // MARK: - Progress
                section("Progress") {
                    DSCard {
                        VStack(spacing: DSSpacing.lg) {
                            DSCircularProgress(progress: progress, size: 80)
                            DSLinearProgress(progress: progress)
                            DSGradientProgress(progress: progress)
                            DSStepProgress(currentStep: 3, totalSteps: 5)
                            DSAnimatedNumber(value: 1248, style: .displayMedium)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // MARK: - Toggles
                section("Toggles") {
                    DSCard {
                        VStack(spacing: DSSpacing.md) {
                            DSToggle("Push Notifications", isOn: $notificationsOn)
                            DSToggle("Dark Mode", isOn: $darkModeOn, onColor: DSColors.secondary)
                            DSToggle("Sync (disabled)", isOn: $notificationsOn)
                                .disabled(true)

                            HStack(spacing: DSSpacing.lg) {
                                DSToggle(isOn: $notificationsOn, size: .small)
                                DSToggle(isOn: $darkModeOn)
                                DSToggle(isOn: $notificationsOn, onColor: DSColors.success)
                            }
                        }
                    }
                }

                // MARK: - Segmented Control
                section("Segmented Control") {
                    DSCard {
                        VStack(spacing: DSSpacing.lg) {
                            DSSegmentedControl(
                                selection: $segmentSelection,
                                options: ["Day", "Week", "Month"]
                            )
                            DSSegmentedControl(
                                selection: $tabSelection,
                                options: ["Overview", "Details", "Reviews"],
                                style: .underline
                            )
                        }
                    }
                }

                // MARK: - Code Field
                section("Code Field (OTP)") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            DSCodeField(length: 6, code: $codeValue)
                            DSCodeField(length: 4, code: .constant("1234"), state: .error)
                            DSCodeField(length: 4, code: .constant("5678"), state: .success)
                        }
                    }
                }

                // MARK: - Slider
                section("Slider") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            DSSlider(value: $volume)
                            DSSlider(value: $volume, tint: DSColors.warning)
                            DSSlider(value: $quality, in: 0...5, step: 1)
                            DSSlider(value: $volume, size: .small)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Rating
                section("Rating") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            DSRating(rating: $rating)
                            DSRating(rating: $rating, step: 0.5)
                            DSRating(value: 3.5, size: 20)
                            DSRating(value: 4.0, symbol: "heart.fill", emptySymbol: "heart",
                                     size: 20, tint: DSColors.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Page Control
                section("Page Control") {
                    DSCard {
                        VStack(spacing: DSSpacing.lg) {
                            DSPageControl(currentPage: $page, numberOfPages: 4)
                            DSPageControl(
                                currentPage: $page,
                                numberOfPages: 4,
                                activeColor: DSColors.secondary
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // MARK: - Badges
                section("Badges & Tags") {
                    DSCard {
                        HStack(spacing: DSSpacing.xs) {
                            DSBadge("New", variant: .filled)
                            DSBadge("Active", color: DSColors.success, variant: .soft)
                            DSBadge("Beta", variant: .outline)
                            DSCountBadge(count: 5)
                            DSCountBadge(count: 120)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Avatars
                section("Avatars") {
                    DSCard {
                        HStack(spacing: DSSpacing.sm) {
                            DSAvatar(name: "John Doe", size: 32)
                            DSAvatar(name: "Jane Smith", size: 40)
                            DSAvatar(name: "Bob", size: 48)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Lists
                section("Lists") {
                    DSCard(padding: 0) {
                        VStack(spacing: 0) {
                            DSListCell(title: "Account", subtitle: "Profile, security") {
                                Image(systemName: "person.circle")
                            } action: { }
                            DSDivider(inset: DSSpacing.screenHorizontal)
                            DSListCell(title: "Notifications") {
                                Image(systemName: "bell")
                            } trailing: {
                                DSCountBadge(count: 3)
                            } action: { }
                            DSDivider(inset: DSSpacing.screenHorizontal)
                            DSListCell(title: "About", subtitle: "Version 0.2.0")
                        }
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
                    DSCard {
                        DSEmptyState(
                            icon: "magnifyingglass",
                            title: "No Results",
                            message: "Try adjusting your search or filters to find what you're looking for.",
                            actionTitle: "Clear Filters"
                        ) { }
                    }
                }

                // MARK: - Loading
                section("Loading") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                .fill(DSColors.backgroundSecondary)
                                .frame(height: DSSpacing.lg)
                                .dsShimmer()
                            RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                                .fill(DSColors.backgroundSecondary)
                                .frame(width: 180, height: DSSpacing.md)
                                .dsShimmer()
                            DSBadge("Pulsing", variant: .filled).dsPulse()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.lg)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text(title).ds(.overline, color: DSColors.textSecondary)
            content()
        }
    }

    private func surfaceRow(_ name: String, _ level: DSSurface) -> some View {
        HStack {
            Text(name).ds(.footnote)
            Spacer()
            Text("dsSurface(.\(name))").ds(.caption1, color: DSColors.textTertiary)
        }
        .padding(DSSpacing.md)
        .dsSurface(level, radius: DSRadius.surface)
    }
}

#Preview("Catalog — Light") {
    ComponentCatalog().preferredColorScheme(.light)
}

#Preview("Catalog — Dark") {
    ComponentCatalog().preferredColorScheme(.dark)
}
