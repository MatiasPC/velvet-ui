import SwiftUI

// MARK: - Component Catalog
// A browsable preview of all Design System components, on the themed backdrop.
// Use it during development and for the manual walkthrough: switch the theme
// with the dots, toggle the backdrop off to see the plain page tone, and flip
// the preview between light and dark.

/// Stand-in for a declined charge, so the catalog can show the refusal path.
private struct CatalogRefusal: Error {}

/// A page for the carousel section.
private struct CatalogPage: Identifiable {
    let id: Int
}

struct ComponentCatalog: View {
    @State private var theme = DSTheme()
    @State private var useBackdrop = true

    @State private var textFieldValue = ""
    @State private var searchValue = ""
    @State private var progress: Double = 0.65
    @State private var rings: [DSRing] = [
        DSRing(progress: 0.82, color: DSColors.error,   label: "Move"),
        DSRing(progress: 0.60, color: DSColors.success, label: "Exercise"),
        DSRing(progress: 0.45, color: DSColors.info,    label: "Stand")
    ]
    @State private var segmentSelection = "Day"
    @State private var tabSelection = "Overview"
    @State private var radioPlan = "Pro"
    @State private var chipFilters: Set<String> = ["Design"]
    @State private var chipSort: String? = "Trending"
    @State private var notificationsOn = true
    @State private var darkModeOn = false
    @State private var acceptTerms = true
    @State private var wantsNewsletter = false
    @State private var wantsOffers = true
    @State private var rating: Double = 4
    @State private var page: Int = 1
    @State private var codeValue = "12"
    @State private var jiggleTrigger = 0
    @State private var sweepOn = true
    @State private var quantity = 2
    @State private var bulk = 25
    @State private var holdAttempt = 0
    @State private var holdDeleteAttempt = 0
    @State private var volume: Double = 0.6
    @State private var priceLimit: Double = 150
    @State private var paidAttempt = 0
    @State private var refusedAttempt = 0
    @State private var listening = true
    @State private var tabbarSelection = "home"
    @State private var showsSheet = false
    @State private var carouselPage = 0
    @State private var tickerValue: Double = 1284.5
    @State private var sparkline: [Double] = [12, 18, 14, 22, 19, 27, 24, 31, 28, 36]
    @State private var weekly: [Double] = [12, 18, 9, 22, 15, 6, 11]
    @State private var selectedDay: Int? = 3
    @State private var isLoadingCard = true
    @State private var isPaymentDone = false
    @State private var confettiBursts = 0
    @State private var cardFlipped = false

    @State private var presentedToast: DSToastValue?
    private let flowInterests = [
        "Design", "SwiftUI", "Motion", "Accessibility", "Haptics",
        "Typography", "Color", "Prototyping", "iOS", "Glass"
    ]
    @State private var flowSelected: Set<String> = ["SwiftUI", "Motion", "Haptics"]
    @State private var timelineStep = 2
    @State private var faqOpen = true
    @State private var liked = false
    @State private var starred = false
    @State private var postLiked = false
    @State private var postLikes = 128

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
        .dsToast($presentedToast, edge: .bottom)
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
                            Text(theme.style.name).ds(.title3)
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
                            DSIconButton(icon: "heart", accessibilityLabel: "Like") { }
                            DSIconButton(icon: "square.and.arrow.up", accessibilityLabel: "Share") { }
                            DSIconButton(icon: "ellipsis", accessibilityLabel: "More") { }
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

                    DSImageCard(title: "Cabin in the woods", subtitle: "$120 / night", badge: "New")
                }

                // MARK: - Flip Card
                section("Flip Card") {
                    VStack(spacing: DSSpacing.md) {
                        DSFlipCard(isFlipped: $cardFlipped) {
                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                Text("This month").ds(.footnote, color: DSColors.textSecondary)
                                Text("1 248").ds(.displayMedium)
                                Text("Tap to see the trend").ds(.callout, color: DSColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } back: {
                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                Text("vs. last month").ds(.footnote, color: DSColors.textSecondary)
                                Text("+12%").ds(.displayMedium)
                                Text("Tap to flip back").ds(.callout, color: DSColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        DSButton(cardFlipped ? "Flip to front" : "Flip to back", variant: .ghost, size: .small) {
                            withAnimation(DSAnimation.springSmooth) { cardFlipped.toggle() }
                        }
                    }
                }

                // MARK: - Tilt Card
                section("Tilt Card") {
                    DSTiltCard {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Image(systemName: "creditcard.fill")
                                .font(.title2)
                                .foregroundStyle(theme.style.accent)
                            Text("Drag to tilt").ds(.title3)
                            Text("3D tilt with a sheen that slides across the glass, then springs back.")
                                .ds(.callout, color: DSColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
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

                // MARK: - Activity Rings
                section("Activity Rings") {
                    DSCard {
                        VStack(spacing: DSSpacing.lg) {
                            DSActivityRings(rings) {
                                VStack(spacing: DSSpacing.xxxs) {
                                    Text("62%").ds(.title3)
                                    Text("today").ds(.caption1, color: DSColors.textSecondary)
                                }
                            }
                            HStack(spacing: DSSpacing.sm) {
                                DSButton("Close rings", size: .small) {
                                    rings = rings.map { DSRing(progress: 1, color: $0.color, label: $0.label) }
                                }
                                DSButton("Reset", variant: .ghost, size: .small) {
                                    rings = [
                                        DSRing(progress: 0.82, color: DSColors.error,   label: "Move"),
                                        DSRing(progress: 0.60, color: DSColors.success, label: "Exercise"),
                                        DSRing(progress: 0.45, color: DSColors.info,    label: "Stand")
                                    ]
                                }
                            }
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

                // MARK: - Checkboxes
                section("Checkboxes") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            DSCheckbox("Accept terms & conditions", isOn: $acceptTerms)
                            DSCheckbox("Subscribe to the newsletter", isOn: $wantsNewsletter)
                            DSCheckbox("Send me offers", isOn: $wantsOffers, onColor: DSColors.success)
                            DSCheckbox("Unavailable option", isOn: .constant(false))
                                .disabled(true)

                            HStack(spacing: DSSpacing.md) {
                                DSCheckbox(isOn: $acceptTerms, size: .small).accessibilityLabel("Small")
                                DSCheckbox(isOn: $wantsNewsletter, size: .medium).accessibilityLabel("Medium")
                                DSCheckbox(isOn: $wantsOffers, size: .large).accessibilityLabel("Large")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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

                // MARK: - Radio Group
                section("Radio Group") {
                    DSCard {
                        DSRadioGroup(selection: $radioPlan, options: [
                            DSRadioOption("Free", value: "Free", subtitle: "For trying things out"),
                            DSRadioOption("Pro", value: "Pro", subtitle: "Everything, for one person"),
                            DSRadioOption("Team", value: "Team", subtitle: "Shared workspaces")
                        ])
                    }
                }

                // MARK: - Chips
                section("Chips") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            DSChipGroup(
                                ["Design", "Engineering", "Product", "Research", "Marketing", "Finance"],
                                selection: $chipFilters
                            )
                            DSChipGroup(
                                ["Trending", "Newest", "Top rated", "Nearby"],
                                selection: $chipSort
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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

                // MARK: - Flow Layout
                section("Flow Layout") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            Text("Tap to toggle — wraps and reflows")
                                .ds(.footnote, color: DSColors.textSecondary)
                            DSFlowLayout {
                                ForEach(flowInterests, id: \.self) { interest in
                                    catalogChip(interest, isSelected: flowSelected.contains(interest)) {
                                        DSHapticEngine.shared.fire(.selection)
                                        withAnimation(DSAnimation.springSnappy) {
                                            if flowSelected.contains(interest) {
                                                flowSelected.remove(interest)
                                            } else {
                                                flowSelected.insert(interest)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
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

                // MARK: - Avatar Group
                section("Avatar Group") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            DSAvatarGroup(names: [
                                "Ada Lovelace", "Grace Hopper", "Alan Turing",
                                "Katherine Johnson", "Linus Torvalds", "Margaret Hamilton"
                            ])
                            DSAvatarGroup(
                                names: ["Ada Lovelace", "Grace Hopper", "Alan Turing"],
                                size: DSSpacing.xxl,
                                overlap: 0.3
                            )
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

                // MARK: - Timeline
                section("Timeline") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            DSTimeline(
                                [
                                    DSTimelineItem("Order placed", subtitle: "9:41 AM", icon: "bag"),
                                    DSTimelineItem("Shipped", subtitle: "Picked up by courier", icon: "shippingbox"),
                                    DSTimelineItem("Out for delivery", subtitle: "Arriving today", icon: "box.truck"),
                                    DSTimelineItem("Delivered", icon: "house")
                                ],
                                currentStep: timelineStep
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: DSSpacing.sm) {
                                DSButton("Back", variant: .ghost, size: .small) {
                                    timelineStep = max(timelineStep - 1, 0)
                                }
                                DSButton("Advance", size: .small) {
                                    timelineStep = min(timelineStep + 1, 4)
                                }
                            }
                        }
                    }
                }

                // MARK: - Disclosure Group
                section("Disclosure Group") {
                    VStack(spacing: DSSpacing.sm) {
                        DSDisclosureGroup(
                            "What's included",
                            subtitle: "3 items",
                            icon: "shippingbox",
                            isExpanded: $faqOpen
                        ) {
                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                Text("• Unlimited projects").ds(.callout)
                                Text("• Priority support").ds(.callout)
                                Text("• Early access to betas").ds(.callout)
                            }
                        }
                        DSDisclosureGroup("Can I cancel anytime?") {
                            Text("Yes — cancel from Settings and keep access until the end of the period.")
                                .ds(.callout, color: DSColors.textSecondary)
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

                // MARK: - Toast Presenter
                section("Toast Presenter") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text(".dsToast — replaces, auto-dismisses, flicks away")
                                .ds(.footnote, color: DSColors.textSecondary)
                            HStack(spacing: DSSpacing.sm) {
                                DSButton("Success", size: .small) {
                                    presentedToast = DSToastValue("Saved to your library", type: .success)
                                }
                                DSButton("Error", variant: .secondary, size: .small) {
                                    presentedToast = DSToastValue("Couldn't connect", type: .error)
                                }
                                DSButton("Sticky", variant: .ghost, size: .small) {
                                    presentedToast = DSToastValue("Uploading…", type: .info, duration: 0)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                            DSBadge("Breathing", variant: .filled).dsBreathe()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Typewriter
                section("Typewriter") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            DSTypewriterText(
                                ["Glass over paper.", "No borders. Ever.", "Springs, not ramps."],
                                style: .title2
                            )
                            DSTypewriterText(["Types once, then stops."], style: .body, loops: false)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Marquee
                section("Marquee") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            DSMarquee {
                                Text("Now playing — Midnight City · M83 · Hurry Up, We're Dreaming")
                                    .ds(.callout)
                            }
                            DSMarquee(velocity: 28) {
                                HStack(spacing: DSSpacing.xs) {
                                    DSBadge("LIVE", color: DSColors.error, variant: .filled)
                                    Text("Breaking: a seamless marquee with glass edge fades")
                                        .ds(.footnote)
                                }
                            }
                            DSMarquee {
                                Text("Short label — stays put").ds(.callout)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Expandable Text
                section("Expandable Text") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            DSExpandableText(
                                "Velvet UI is a small, opinionated SwiftUI library: frosted glass over a calm page tone, spring motion on everything you touch, and haptics that make the interface feel alive. Every component honors Reduce Motion, Reduce Transparency and Dynamic Type out of the box.",
                                lineLimit: 2,
                                expandLabel: "Read more",
                                collapseLabel: "Read less"
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Slide to Confirm
                section("Slide to Confirm") {
                    VStack(spacing: DSSpacing.md) {
                        DSSlideToConfirm("Slide to delete account") { }
                        DSSlideToConfirm(
                            "Slide to cancel ride",
                            icon: "xmark",
                            confirmedLabel: "Cancelled"
                        ) { }

                        // .morphAndVanish leaves an empty slot behind, so both
                        // payment rows are re-mounted with .id — the documented
                        // way to run the choreography again.
                        DSSlideToConfirm(
                            "Slide to pay $42.00",
                            confirmedLabel: "Paid",
                            finish: .morphAndVanish
                        ) {
                            try? await Task.sleep(for: .milliseconds(1200))
                        }
                        .id(paidAttempt)

                        DSSlideToConfirm(
                            "Slide to pay — refused",
                            finish: .morphAndVanish
                        ) {
                            try await Task.sleep(for: .milliseconds(900))
                            throw CatalogRefusal()
                        }
                        .id(refusedAttempt)

                        DSButton("Reset payments", variant: .ghost, size: .small) {
                            paidAttempt += 1
                            refusedAttempt += 1
                        }
                    }
                }

                // MARK: - Hold to Confirm
                section("Hold to Confirm") {
                    VStack(spacing: DSSpacing.md) {
                        DSHoldToConfirm("Hold to confirm", icon: "hand.tap") { }
                            .id(holdAttempt)
                        DSHoldToConfirm(
                            "Hold to delete",
                            icon: "trash",
                            confirmedLabel: "Deleted",
                            accent: DSColors.error
                        ) { }
                        .id(holdDeleteAttempt)

                        DSButton("Reset holds", variant: .ghost, size: .small) {
                            holdAttempt += 1
                            holdDeleteAttempt += 1
                        }
                    }
                }

                // MARK: - Thinking Indicator
                section("Thinking Indicator") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            DSThinkingIndicator()
                            DSThinkingIndicator(
                                phrases: ["Reading your notes", "Cross-checking sources", "Drafting a reply"],
                                symbol: "brain",
                                interval: 2.0
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Audio Bars
                section("Audio Bars") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            HStack(spacing: DSSpacing.sm) {
                                DSAudioBars(isActive: listening)
                                Text(listening ? "Listening…" : "Paused")
                                    .ds(.callout, color: DSColors.textSecondary)
                                Spacer()
                            }
                            DSToggle("Active", isOn: $listening)
                            HStack(spacing: DSSpacing.xl) {
                                DSAudioBars(barCount: 3)
                                DSAudioBars(barCount: 7, height: DSSpacing.xxl)
                                DSAudioBars(barCount: 5, color: DSColors.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Stepper
                section("Stepper") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            DSStepper(value: $quantity)
                            DSStepper(value: $bulk, in: 0...100, step: 5)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Slider
                section("Slider") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                HStack {
                                    Text("Volume").ds(.footnote, color: DSColors.textSecondary)
                                    Spacer()
                                    Text("\(Int(volume * 100))%").ds(.numeric)
                                }
                                DSSlider(value: $volume)
                            }

                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                HStack {
                                    Text("Max price — snaps in 25s")
                                        .ds(.footnote, color: DSColors.textSecondary)
                                    Spacer()
                                    Text("$\(Int(priceLimit))").ds(.numeric)
                                }
                                DSSlider(value: $priceLimit, in: 0...500, step: 25)
                            }

                            DSSlider(value: .constant(0.5), accent: DSColors.secondary)
                                .disabled(true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Tab Bar
                section("Tab Bar") {
                    DSTabBar(selection: $tabbarSelection, items: [
                        DSTabItem("Home", value: "home", icon: "house", selectedIcon: "house.fill"),
                        DSTabItem("Search", value: "search", icon: "magnifyingglass"),
                        DSTabItem("Inbox", value: "inbox", icon: "tray", selectedIcon: "tray.fill", badge: 3),
                        DSTabItem("Profile", value: "profile", icon: "person", selectedIcon: "person.fill")
                    ])
                }

                // MARK: - Carousel
                section("Carousel") {
                    VStack(spacing: DSSpacing.md) {
                        DSCarousel((0..<4).map(CatalogPage.init), currentPage: $carouselPage) { page in
                            Text("Page \(page.id + 1)")
                                .ds(.title2)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .dsSurface(.glass, radius: DSRadius.card)
                        }
                        .frame(height: 140)
                        .padding(.horizontal, -DSSpacing.screenHorizontal)
                        DSPageControl(currentPage: $carouselPage, numberOfPages: 4)
                    }
                }

                // MARK: - Sheet
                section("Sheet") {
                    DSButton("Show sheet", variant: .secondary) { showsSheet = true }
                        .dsSheet(isPresented: $showsSheet) {
                            VStack(alignment: .leading, spacing: DSSpacing.md) {
                                Text("Share trip").ds(.title2)
                                Text("Glass background, a grabber and two detents.").ds(.callout)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DSSpacing.xl)
                        }
                }

                // MARK: - Number Ticker
                section("Number Ticker") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            DSNumberTicker(tickerValue, format: .currency(code: "USD"))
                            DSButton("Random jump", variant: .ghost, size: .small) {
                                tickerValue = Double.random(in: 0...50_000).rounded()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Charts
                section("Charts") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            DSSparkline(sparkline).frame(height: 72)
                            DSBarChart(weekly, labels: ["M", "T", "W", "T", "F", "S", "S"], selection: $selectedDay)
                                .frame(height: 140)
                            DSButton("Shuffle data", variant: .ghost, size: .small) {
                                sparkline = sparkline.map { _ in Double.random(in: 10...40) }
                                weekly = weekly.map { _ in Double.random(in: 2...30) }
                            }
                        }
                    }
                }

                // MARK: - Skeleton
                section("Skeleton") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            HStack(spacing: DSSpacing.sm) {
                                DSSkeleton.circle(DSSpacing.xxxl)
                                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                    DSSkeleton(width: 140)
                                    DSSkeleton(width: 90)
                                }
                            }
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text("Weekend in Lisbon").ds(.title3)
                                Text("Three nights by the river, two guests.").ds(.callout)
                            }
                            .dsSkeleton(isLoadingCard)
                            DSToggle("Loading", isOn: $isLoadingCard)
                        }
                    }
                }

                // MARK: - Success Check
                section("Success Check") {
                    HStack(spacing: DSSpacing.lg) {
                        DSSuccessCheck(isComplete: isPaymentDone, size: 64)
                        DSButton(isPaymentDone ? "Reset" : "Complete", variant: .secondary, size: .small) {
                            isPaymentDone.toggle()
                        }
                    }
                }

                // MARK: - Like Button
                section("Like Button") {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            HStack(spacing: DSSpacing.xl) {
                                DSLikeButton(isLiked: $liked, accessibilityLabel: "Like")
                                DSLikeButton(isLiked: $starred, symbol: "star.fill", emptySymbol: "star",
                                             tint: DSColors.warning, accessibilityLabel: "Favorite")
                                DSLikeButton(isLiked: $postLiked, count: postLikes, accessibilityLabel: "Like post")
                                    .onChange(of: postLiked) { _, on in postLikes += on ? 1 : -1 }
                            }
                            Text("Pops and radiates a halo on the way in; quiet on the way out.")
                                .ds(.footnote, color: DSColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Confetti
                section("Confetti") {
                    DSCard {
                        DSButton("Celebrate", icon: "sparkles") { confettiBursts += 1 }
                            .frame(maxWidth: .infinity, minHeight: 120)
                    }
                    .dsConfetti(trigger: confettiBursts)
                }

                // MARK: - Motion
                section("Motion") {
                    VStack(spacing: DSSpacing.md) {
                        DSCard {
                            VStack(alignment: .leading, spacing: DSSpacing.md) {
                                Text("dsBreathe").ds(.footnote, color: DSColors.textSecondary)
                                HStack(spacing: DSSpacing.xl) {
                                    breatheDot("subtle", .subtle)
                                    breatheDot("medium", .medium)
                                    breatheDot("strong", .strong)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        DSCard {
                            VStack(alignment: .leading, spacing: DSSpacing.md) {
                                Text("dsJiggle — fires once per trigger")
                                    .ds(.footnote, color: DSColors.textSecondary)
                                HStack(spacing: DSSpacing.md) {
                                    Image(systemName: "bell.fill")
                                        .font(.title2)
                                        .foregroundStyle(theme.style.accent)
                                        .dsJiggle(trigger: jiggleTrigger)
                                    Spacer()
                                    DSButton("Shake", size: .small) { jiggleTrigger += 1 }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("dsEdgeSweep — light travelling the edge")
                                .ds(.footnote, color: DSColors.textSecondary)
                            DSToggle("Sweeping", isOn: $sweepOn)
                        }
                        .padding(DSSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dsSurface(.glass, radius: DSRadius.card)
                        .dsEdgeSweep(radius: DSRadius.card, isActive: sweepOn)

                        DSCard {
                            VStack(alignment: .leading, spacing: DSSpacing.md) {
                                Text("dsPopIn / dsHueDrift")
                                    .ds(.footnote, color: DSColors.textSecondary)
                                HStack(spacing: DSSpacing.sm) {
                                    ForEach(0..<4, id: \.self) { index in
                                        RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                                            .fill(theme.style.accent)
                                            .frame(height: DSSpacing.xxl)
                                            .dsHueDrift()
                                            .dsPopIn(delay: Double(index) * 0.08)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                // MARK: - Scroll Reveal
                section("Scroll Reveal") {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("dsScrollReveal — neighbours recede at the edges")
                            .ds(.footnote, color: DSColors.textSecondary)
                        ScrollView(.horizontal) {
                            HStack(spacing: DSSpacing.md) {
                                ForEach(0..<5, id: \.self) { index in
                                    DSCard {
                                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                            Text("Card \(index + 1)").ds(.title3)
                                            Text("Swipe me").ds(.callout, color: DSColors.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .containerRelativeFrame(.horizontal)
                                    .dsScrollReveal(.strong)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .contentMargins(.horizontal, DSSpacing.xxxl, for: .scrollContent)
                        .scrollTargetBehavior(.viewAligned)
                        .scrollIndicators(.hidden)
                    }
                }

                // MARK: - Stretchy Header
                section("Stretchy Header") {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("dsStretchyHeader — pull down inside the frame, then scroll up")
                            .ds(.footnote, color: DSColors.textSecondary)
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ZStack(alignment: .bottomLeading) {
                                    Rectangle().fill(theme.style.accent)
                                    Text("Weekend in Lisbon")
                                        .ds(.title2, color: theme.style.onAccent)
                                        .padding(DSSpacing.md)
                                }
                                .frame(height: DSSpacing.massive * 2)
                                .dsStretchyHeader()

                                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                    ForEach(["Check-in · Friday", "Check-out · Monday", "2 guests", "River view"], id: \.self) { row in
                                        Text(row)
                                            .ds(.callout)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(DSSpacing.sm)
                                            .dsSurface(.glass, radius: DSRadius.control)
                                    }
                                }
                                .padding(DSSpacing.md)
                            }
                        }
                        .frame(height: DSSpacing.massive * 4)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous))
                        .scrollIndicators(.hidden)
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

    private func breatheDot(_ label: String, _ intensity: DSBreatheIntensity) -> some View {
        VStack(spacing: DSSpacing.xs) {
            Circle()
                .fill(theme.style.accent)
                .frame(width: DSSpacing.xxl, height: DSSpacing.xxl)
                .dsBreathe(intensity)
            Text(label).ds(.caption1, color: DSColors.textTertiary)
        }
    }

    private func catalogChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .ds(.buttonSmall, color: isSelected ? theme.style.onAccent : DSColors.textPrimary)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xs)
                .background {
                    Capsule().fill(isSelected ? theme.style.accent : DSColors.backgroundSecondary)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
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
