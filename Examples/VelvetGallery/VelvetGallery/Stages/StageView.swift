import SwiftUI
import VelvetUI

/// Dispatches a `Stage` to its isolated view. Content only — no title, caption
/// or chrome — centred inside the 9:16 safe region of the screen.
struct StageView: View {
    let stage: Stage
    let autoplay: Bool

    var body: some View {
        switch stage {
        case .Hero:                HeroStage()
        case .DSButton:            ButtonStage()
        case .DSIconButton:        IconButtonStage()
        case .DSCard:              CardStage()
        case .DSFlipCard:          FlipCardStage(autoplay: autoplay)
        case .DSTextField:         TextFieldStage()
        case .DSCodeField:         CodeFieldStage(autoplay: autoplay)
        case .DSBadge:             BadgeStage()
        case .DSAvatar:            AvatarStage()
        case .DSListCell:          ListCellStage()
        case .DSToast:             ToastStage(autoplay: autoplay)
        case .DSEmptyState:        EmptyStateStage()
        case .DSSegmentedControl:  SegmentedControlStage(autoplay: autoplay)
        case .DSToggle:            ToggleStage(autoplay: autoplay)
        case .DSRating:            RatingStage(autoplay: autoplay)
        case .DSPageControl:       PageControlStage(autoplay: autoplay)
        case .DSStepper:           StepperStage(autoplay: autoplay)
        case .DSSlideToConfirm:    SlideToConfirmStage()
        case .DSThinkingIndicator: ThinkingIndicatorStage()
        case .DSTypewriterText:    TypewriterTextStage()
        case .Progress:            ProgressStage(autoplay: autoplay)
        case .Motion:              MotionStage()
        case .DSTabBar:            TabBarStage(autoplay: autoplay)
        case .DSCarousel:          CarouselStage(autoplay: autoplay)
        case .DSSheet:             SheetStage(autoplay: autoplay)
        case .DSNumberTicker:      NumberTickerStage(autoplay: autoplay)
        case .Charts:              ChartsStage(autoplay: autoplay)
        case .DSSkeleton:          SkeletonStage(autoplay: autoplay)
        case .DSSuccessCheck:      SuccessCheckStage(autoplay: autoplay)
        case .DSConfetti:          ConfettiStage(autoplay: autoplay)
        case .OnboardingFlow:      OnboardingFlowStage()
        case .SettingsFlow:        SettingsFlowStage()
        case .CheckoutFlow:        CheckoutFlowStage()
        }
    }
}

// MARK: - Hero

private struct HeroStage: View {
    @State private var notifications = true
    @State private var quantity = 2

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Checkout").ds(.title2)
                DSToggle("Push notifications", isOn: $notifications)
                HStack {
                    Text("Quantity").ds(.body)
                    Spacer()
                    DSStepper(value: $quantity, in: 1...9)
                }
                DSSlideToConfirm("Slide to pay", confirmedLabel: "Paid") {
                    try await Task.sleep(for: .milliseconds(900))
                }
            }
        }
    }
}

// MARK: - Actions

private struct ButtonStage: View {
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            DSButton("Pay $24.00", variant: .primary, size: .large, isFullWidth: true) {}
            DSButton("Save for later", variant: .secondary, isFullWidth: true) {}
            DSButton("Add a note", variant: .outline, isFullWidth: true) {}
            DSButton("Cancel order", variant: .ghost) {}
        }
    }
}

private struct IconButtonStage: View {
    var body: some View {
        HStack(spacing: DSSpacing.lg) {
            DSIconButton(icon: "heart", accessibilityLabel: "Like") {}
            DSIconButton(icon: "square.and.arrow.up", accessibilityLabel: "Share") {}
            DSIconButton(icon: "bookmark", accessibilityLabel: "Save") {}
        }
    }
}

private struct SlideToConfirmStage: View {
    @State private var attempt = 0

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text("Total").ds(.callout, color: DSColors.textSecondary)
                    Text("$24.00").ds(.title1)
                }
                DSSlideToConfirm("Slide to pay $24.00", confirmedLabel: "Paid") {
                    try await Task.sleep(for: .milliseconds(1200))
                }
                .id(attempt)
            }
        }
    }
}

// MARK: - Containers & inputs

private struct CardStage: View {
    var body: some View {
        DSInteractiveCard(action: {}) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Weekend in Lisbon").ds(.title3)
                Text("3 nights, 2 guests").ds(.callout, color: DSColors.textSecondary)
                Text("$480").ds(.title2).padding(.top, DSSpacing.xs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct FlipCardStage: View {
    let autoplay: Bool
    @State private var flipped = false

    var body: some View {
        DSFlipCard(isFlipped: $flipped) {
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
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(1.8)
                flipped.toggle()
            }
        }
    }
}

private struct TextFieldStage: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.md) {
                DSTextField(label: "Email", placeholder: "you@example.com", icon: "envelope", text: $email)
                DSTextField(label: "Password", placeholder: "••••••••", icon: "lock", text: $password, isSecure: true)
            }
        }
    }
}

private struct CodeFieldStage: View {
    let autoplay: Bool
    @State private var code = ""
    @State private var state: DSCodeFieldState = .normal
    private let digits = Array("428519")

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Text("Enter the code we sent you").ds(.callout, color: DSColors.textSecondary)
            DSCodeField(length: 6, code: $code, state: state)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                code = ""
                state = .normal
                await stagePause(0.8)
                for i in digits.indices {
                    guard !Task.isCancelled else { return }
                    code = String(digits[...i])
                    await stagePause(0.45)
                }
                state = .success
                await stagePause(2.0)
            }
        }
    }
}

private struct ToggleStage: View {
    let autoplay: Bool
    @State private var isOn = false

    var body: some View {
        DSCard {
            DSToggle("Push notifications", isOn: $isOn)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(1.2)
                isOn.toggle()
            }
        }
    }
}

private struct StepperStage: View {
    let autoplay: Bool
    @State private var quantity = 1

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.md) {
                Text("Quantity").ds(.callout, color: DSColors.textSecondary)
                DSStepper(value: $quantity, in: 0...9)
            }
            .frame(maxWidth: .infinity)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for _ in 1...5 { await stagePause(0.6); quantity += 1; if Task.isCancelled { return } }
                await stagePause(0.8)
                for _ in 1...5 { await stagePause(0.6); quantity -= 1; if Task.isCancelled { return } }
                await stagePause(0.8)
            }
        }
    }
}

private struct RatingStage: View {
    let autoplay: Bool
    @State private var rating: Double = 0

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Text("How was your stay?").ds(.title3)
            DSRating(rating: $rating, size: 40)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                rating = 0
                await stagePause(0.8)
                for i in 1...5 {
                    guard !Task.isCancelled else { return }
                    rating = Double(i)
                    await stagePause(0.5)
                }
                await stagePause(1.6)
            }
        }
    }
}

private struct SegmentedControlStage: View {
    let autoplay: Bool
    @State private var period = "Day"
    private let options = ["Day", "Week", "Month"]

    var body: some View {
        VStack(spacing: DSSpacing.xxl) {
            DSSegmentedControl(selection: $period, options: options)
            DSSegmentedControl(selection: $period, options: options, style: .underline)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            var i = 0
            await stageLoop {
                await stagePause(1.2)
                i = (i + 1) % options.count
                period = options[i]
            }
        }
    }
}

private struct PageControlStage: View {
    let autoplay: Bool
    @State private var page = 0
    private let titles = ["Welcome", "Personalize", "Stay in sync", "Get started"]

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            TabView(selection: $page) {
                ForEach(titles.indices, id: \.self) { i in
                    DSCard {
                        Text(titles[i]).ds(.title2)
                            .frame(maxWidth: .infinity, minHeight: 140)
                    }
                    .padding(.horizontal, 1)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)
            DSPageControl(currentPage: $page, numberOfPages: titles.count)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(1.6)
                withAnimation(DSAnimation.springSmooth) { page = (page + 1) % titles.count }
            }
        }
    }
}

// MARK: - Data display

private struct BadgeStage: View {
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            HStack(spacing: DSSpacing.sm) {
                DSBadge("New", variant: .filled)
                DSBadge("Active", variant: .soft)
                DSBadge("Beta", variant: .outline)
            }
            HStack(spacing: DSSpacing.sm) {
                DSBadge("Live", color: DSColors.success, variant: .soft)
                DSBadge("Overdue", color: DSColors.error, variant: .soft)
                DSBadge("Pending", color: DSColors.warning, variant: .soft)
            }
            HStack(spacing: DSSpacing.md) {
                DSCountBadge(count: 5)
                DSCountBadge(count: 24)
                DSCountBadge(count: 120)
            }
        }
    }
}

private struct AvatarStage: View {
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSAvatar(name: "Ada Lovelace", size: 96)
            HStack(spacing: DSSpacing.md) {
                DSAvatar(name: "John Doe", size: 48)
                DSAvatar(name: "Jane Smith", size: 48)
                DSAvatar(name: "Bob Marley", size: 48)
            }
        }
    }
}

private struct ListCellStage: View {
    var body: some View {
        DSCard(padding: 0) {
            VStack(spacing: 0) {
                DSListCell(title: "Account", subtitle: "Profile, security") {
                    Image(systemName: "person.circle")
                } action: {}
                DSDivider(inset: DSSpacing.screenHorizontal)
                DSListCell(title: "Notifications") {
                    Image(systemName: "bell")
                } trailing: {
                    DSCountBadge(count: 3)
                } action: {}
                DSDivider(inset: DSSpacing.screenHorizontal)
                DSListCell(title: "Privacy", subtitle: "Data, permissions") {
                    Image(systemName: "lock")
                } action: {}
            }
        }
    }
}

// MARK: - Feedback

private struct ToastStage: View {
    let autoplay: Bool
    @State private var type: DSToastType = .success
    @State private var visible = true

    private let types: [DSToastType] = [.success, .error, .warning, .info]

    var body: some View {
        ZStack {
            if visible {
                DSToast(message(for: type), type: type)
                    .id(type)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            var i = 0
            await stageLoop {
                withAnimation(DSAnimation.springSmooth) { type = types[i]; visible = true }
                await stagePause(2.0)
                withAnimation(DSAnimation.springSmooth) { visible = false }
                await stagePause(0.7)
                i = (i + 1) % types.count
            }
        }
    }

    private func message(for type: DSToastType) -> String {
        switch type {
        case .success: return "Saved to your library"
        case .error:   return "Couldn't connect"
        case .warning: return "Low storage"
        case .info:    return "New version available"
        }
    }
}

private struct EmptyStateStage: View {
    var body: some View {
        DSCard {
            DSEmptyState(
                icon: "tray",
                title: "Inbox zero",
                message: "New messages will show up here.",
                actionTitle: "Compose"
            ) {}
        }
    }
}

private struct ThinkingIndicatorStage: View {
    var body: some View {
        DSThinkingIndicator(
            phrases: ["Reading your notes", "Cross-checking sources", "Drafting a reply"],
            symbol: "sparkles"
        )
    }
}

private struct TypewriterTextStage: View {
    var body: some View {
        DSTypewriterText(
            ["Design at the speed of thought.", "Glass over gradient.", "No borders. Ever."],
            style: .title2
        )
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
    }
}

private struct ProgressStage: View {
    let autoplay: Bool
    @State private var progress: Double = 0.65

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.xl) {
                DSCircularProgress(progress: progress, size: 120)
                DSLinearProgress(progress: progress)
                DSGradientProgress(progress: progress)
                DSStepProgress(currentStep: min(5, Int(progress * 5) + 1), totalSteps: 5)
            }
            .frame(maxWidth: .infinity)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                progress = 0
                await stagePause(0.8)
                for i in 1...10 {
                    guard !Task.isCancelled else { return }
                    withAnimation(DSAnimation.springSmooth) { progress = Double(i) / 10 }
                    await stagePause(0.45)
                }
                await stagePause(1.2)
            }
        }
    }
}

// MARK: - Motion

private struct MotionStage: View {
    @State private var jiggleTick = 0
    @State private var popInTick = 0

    private let tile = DSSpacing.huge

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            glass { Image(systemName: "circle.fill").font(.system(size: 28)).foregroundStyle(DSColors.textPrimary) }
                .dsBreathe(.medium)
            glass { Image(systemName: "bell.fill").font(.system(size: 28)).foregroundStyle(DSColors.textPrimary) }
                .dsJiggle(trigger: jiggleTick)
            HStack(spacing: DSSpacing.sm) {
                ForEach(0..<4, id: \.self) { i in
                    Color.clear
                        .frame(height: tile)
                        .dsSurface(.glass, radius: DSRadius.control)
                        .dsPopIn(delay: Double(i) * 0.08)
                }
            }
            .id(popInTick)
            glass { Image(systemName: "sparkles").font(.system(size: 28)).foregroundStyle(DSColors.textPrimary) }
                .dsEdgeSweep(radius: DSRadius.card, isActive: true)
            RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous)
                .fill(DSColors.textPrimary)
                .frame(height: tile)
                .dsHueDrift(isActive: true)
        }
        .task {
            await stageLoop {
                await stagePause(2.0)
                jiggleTick += 1
                await stagePause(2.5)
                popInTick += 1
            }
        }
    }

    private func glass<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .frame(maxWidth: .infinity, minHeight: tile)
            .dsSurface(.glass, radius: DSRadius.card)
    }
}
