import SwiftUI
import VelvetUI

// MARK: - Onboarding flow
// An example, not a component: a four-page onboarding built only from Velvet
// parts (DSButton, DSPageControl, DSTypewriterText, DSCard, DSToggle,
// DSSegmentedControl, DSSuccessCheck, .dsConfetti, .dsBreathe, .dsPopIn).
// Page 2 changes the live theme, so the flow owns its DSTheme and injects it.
// Copy it with `swift velvet.swift add Onboarding` and adapt it.

struct OnboardingFlow: View {
    var onFinish: () -> Void = {}

    @State private var theme: DSTheme

    @MainActor init(theme: DSTheme? = nil, onFinish: @escaping () -> Void = {}) {
        _theme = State(initialValue: theme ?? DSTheme(gradient: .sunset))
        self.onFinish = onFinish
    }

    var body: some View {
        // The theme is injected here, one level above the views that read it.
        OnboardingContent(theme: theme, onFinish: onFinish)
            .dsTheme(theme)
    }
}

// MARK: - Content

private struct OnboardingContent: View {
    let theme: DSTheme
    let onFinish: () -> Void

    @State private var page = 0
    /// Bumped when the last page arrives; drives the confetti burst.
    @State private var celebrations = 0

    private let pageCount = 4

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            pager
            DSPageControl(currentPage: $page, numberOfPages: pageCount)
            DSButton(
                page == pageCount - 1 ? "Get started" : "Continue",
                size: .large,
                isFullWidth: true
            ) {
                advance()
            }
        }
        .dsScreenPadding()
        .padding(.vertical, DSSpacing.xl)
        .dsBackdrop()
        // Confetti draws inside the view it is attached to, so it goes on the
        // full-screen container, with an origin in that container's unit space.
        .dsConfetti(trigger: celebrations, origin: UnitPoint(x: 0.5, y: 0.3))
        .onChange(of: page) { _, newPage in
            if newPage == pageCount - 1 { celebrations += 1 }
        }
    }

    private var pager: some View {
        #if os(iOS)
        TabView(selection: $page) {
            pages
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(DSAnimation.springSmooth, value: page)
        #else
        // Without paging TabView, show only the current page.
        Group {
            switch page {
            case 0: WelcomePage(isCurrent: true)
            case 1: ThemePage(theme: theme, isCurrent: true)
            case 2: NotificationsPage(isCurrent: true)
            default: DonePage(isCurrent: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }

    @ViewBuilder private var pages: some View {
        WelcomePage(isCurrent: page == 0).tag(0)
        ThemePage(theme: theme, isCurrent: page == 1).tag(1)
        NotificationsPage(isCurrent: page == 2).tag(2)
        DonePage(isCurrent: page == 3).tag(3)
    }

    private func advance() {
        if page < pageCount - 1 {
            withAnimation(DSAnimation.springSmooth) { page += 1 }
        } else {
            onFinish()
        }
    }
}

// MARK: - Pages
// Each page builds its elements only while it is the current page, so the
// staggered .dsPopIn runs once per visit.

private struct WelcomePage: View {
    let isCurrent: Bool
    @DSThemed private var theme

    var body: some View {
        OnboardingPage(isCurrent: isCurrent) {
            Image(systemName: "sparkles")
                .dsFont(.displayMedium)
                .foregroundStyle(theme.ink)
                .frame(width: DSSpacing.massive * 2, height: DSSpacing.massive * 2)
                .dsSurface(.glassThick, radius: DSRadius.pill)
                .dsBreathe(.subtle)
                .accessibilityHidden(true)
                .dsPopIn()

            DSTypewriterText(
                ["Welcome to Velvet", "Made to feel good", "Calm, fast, yours"],
                style: .largeTitle
            )
            .dsPopIn(delay: 0.1)

            Text("A small app with glass, springs and haptics on every tap.")
                .ds(.body, color: theme.palette.textSecondary)
                .multilineTextAlignment(.center)
                .dsPopIn(delay: 0.2)
        }
    }
}

private struct ThemePage: View {
    let theme: DSTheme
    let isCurrent: Bool
    @DSThemed private var resolved

    var body: some View {
        OnboardingPage(isCurrent: isCurrent) {
            Text("Make it yours").ds(.largeTitle).dsPopIn()
            Text("Pick a theme. The whole screen follows.")
                .ds(.body, color: resolved.palette.textSecondary)
                .dsPopIn(delay: 0.1)

            HStack(spacing: DSSpacing.sm) {
                ForEach(Array(DSGradientTheme.all.enumerated()), id: \.element.id) { index, option in
                    ThemeTile(option: option, isSelected: theme.gradient == option) {
                        withAnimation(DSAnimation.normal) { theme.gradient = option }
                    }
                    .dsPopIn(delay: 0.2 + Double(index) * 0.08)
                }
            }
        }
    }
}

private struct ThemeTile: View {
    let option: DSGradientTheme
    let isSelected: Bool
    let action: () -> Void
    @DSThemed private var theme

    var body: some View {
        Button {
            dsHaptic(.selection)
            action()
        } label: {
            VStack(spacing: DSSpacing.xs) {
                RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                    .fill(option.linearGradient)
                    .frame(height: DSSpacing.massive)
                Text(option.name)
                    .ds(.buttonSmall, color: isSelected ? theme.ink : theme.palette.textSecondary)
            }
            .padding(DSSpacing.xs)
            .dsSurface(isSelected ? .glassThick : .glassThin, radius: DSRadius.surface)
            .scaleEffect(isSelected ? 1 : DSPress.scale)
            .animation(DSPress.animation, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.name) theme")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct NotificationsPage: View {
    let isCurrent: Bool
    @State private var notifications = true
    @State private var digest = false
    @State private var reminder = "Morning"
    @DSThemed private var theme

    var body: some View {
        OnboardingPage(isCurrent: isCurrent) {
            Text("Stay in the loop").ds(.largeTitle).dsPopIn()

            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    row("Notifications", isOn: $notifications)
                    row("Weekly digest", isOn: $digest)
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Reminder time").ds(.callout, color: theme.palette.textSecondary)
                        DSSegmentedControl(selection: $reminder, options: ["Morning", "Evening"])
                    }
                }
            }
            .dsPopIn(delay: 0.1)
        }
    }

    private func row(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title).ds(.body)
            Spacer()
            DSToggle(isOn: isOn).accessibilityLabel(title)
        }
    }
}

private struct DonePage: View {
    let isCurrent: Bool
    @DSThemed private var theme

    var body: some View {
        OnboardingPage(isCurrent: isCurrent) {
            // Completes when the page becomes current, on the same beat as the confetti.
            DSSuccessCheck(isComplete: isCurrent, size: DSSpacing.massive + DSSpacing.xxl)
            Text("You're all set").ds(.largeTitle).dsPopIn(delay: 0.1)
            Text("Notifications are on and your theme is saved.")
                .ds(.body, color: theme.palette.textSecondary)
                .multilineTextAlignment(.center)
                .dsPopIn(delay: 0.2)
        }
    }
}

/// Shared page frame: centered column, empty while the page is not current.
private struct OnboardingPage<Content: View>: View {
    let isCurrent: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            if isCurrent { content() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Onboarding — Light") {
    OnboardingFlow(theme: DSTheme(gradient: .aurora))
        .preferredColorScheme(.light)
}

#Preview("Onboarding — Dark") {
    OnboardingFlow(theme: DSTheme(gradient: .lagoon))
        .preferredColorScheme(.dark)
}
