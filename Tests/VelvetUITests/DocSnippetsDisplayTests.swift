import XCTest
import SwiftUI
import VelvetUI

// Usage snippets from docs/components/*.md (display, feedback and motion pages).
// They are pasted verbatim between the BEGIN/END markers so that `swift build`
// fails if a documented snippet drifts from the public API.

enum DocSnippetsDisplay {

    // BEGIN CardDemo
    struct CardDemo: View {
        @State private var opened = false

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.md) {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text("This week").ds(.title2)
                            Text("4 sessions · 2 h 35 min").ds(.callout)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    DSInteractiveCard(action: { opened.toggle() }) {
                        HStack {
                            Text(opened ? "Opened" : "Open plan").ds(.body)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }

                    DSImageCard(
                        title: "Cabin in the woods",
                        subtitle: "$120 / night",
                        badge: "New"
                    )
                }
                .dsScreenPadding()
            }
        }
    }
    // END CardDemo

    // BEGIN CardStylesDemo
    struct CardStylesDemo: View {
        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.md) {
                    DSCard(style: .outlined) {
                        Text("Denser glass, no shadow").ds(.body)
                    }

                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Nested").ds(.title3)
                            DSCard(style: .flat, cornerRadius: DSRadius.surface) {
                                Text("Flat card inside an elevated one").ds(.callout)
                            }
                        }
                    }
                }
                .dsScreenPadding()
            }
        }
    }
    // END CardStylesDemo

    // BEGIN BadgeDemo
    struct BadgeDemo: View {
        @State private var unread = 3

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    HStack(spacing: DSSpacing.xs) {
                        DSBadge("Beta")
                        DSBadge("Pro", variant: .filled)
                        DSBadge("Draft", variant: .outline)
                        DSBadge("Live", color: .green)
                    }

                    HStack(spacing: DSSpacing.md) {
                        Image(systemName: "bell.fill")
                            .font(.title)
                            .overlay(alignment: .topTrailing) {
                                DSCountBadge(count: unread)
                                    .offset(x: DSSpacing.xs, y: -DSSpacing.xs)
                            }
                        DSBadge("Mark all read", variant: .soft)
                            .onTapGesture { unread = 0 }
                    }
                }
                .dsScreenPadding()
            }
        }
    }
    // END BadgeDemo

    // BEGIN AvatarDemo
    struct AvatarDemo: View {
        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    HStack(spacing: DSSpacing.md) {
                        DSAvatar(name: "Ada Lovelace")
                        DSAvatar(name: "Grace Hopper", size: 56)
                        DSAvatar(name: "Linus", size: 32)
                    }

                    DSAvatar(
                        name: "Margaret Hamilton",
                        imageURL: URL(string: "https://example.com/margaret.jpg"),
                        size: 72
                    )
                    .accessibilityLabel("Margaret Hamilton")
                }
                .dsScreenPadding()
            }
        }
    }
    // END AvatarDemo

    // BEGIN ListDemo
    struct ListDemo: View {
        @State private var selected = "None yet"

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: 0) {
                    DSSectionHeader("Account", action: "Edit") { selected = "Edit" }

                    DSCard(padding: 0) {
                        VStack(spacing: 0) {
                            DSListCell(
                                title: "Ada Lovelace",
                                subtitle: "ada@example.com",
                                leading: { DSAvatar(name: "Ada Lovelace") },
                                action: { selected = "Profile" }
                            )
                            DSDivider(inset: DSSpacing.screenHorizontal)
                            DSListCell(
                                title: "Notifications",
                                trailing: { DSCountBadge(count: 3) },
                                action: { selected = "Notifications" }
                            )
                            DSDivider(inset: DSSpacing.screenHorizontal)
                            DSListCell(title: "Version", subtitle: "0.2.0")
                        }
                    }
                    .padding(.horizontal, DSSpacing.screenHorizontal)

                    Text("Last tapped: \(selected)")
                        .ds(.caption1)
                        .padding(DSSpacing.screenHorizontal)
                }
            }
        }
    }
    // END ListDemo

    // BEGIN ToastDemo
    struct ToastDemo: View {
        @State private var toast: (message: String, type: DSToastType)?

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.sm) {
                    DSButton("Save", isFullWidth: true) {
                        show("Saved to your library", type: .success)
                    }
                    DSButton("Simulate failure", variant: .secondary, isFullWidth: true) {
                        show("Couldn't connect", type: .error)
                    }
                }
                .dsScreenPadding()
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    DSToast(toast.message, type: toast.type)
                        .padding(.bottom, DSSpacing.md)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task(id: toast.message) {
                            try? await Task.sleep(for: .seconds(2.5))
                            withAnimation(DSAnimation.springSmooth) { self.toast = nil }
                        }
                }
            }
        }

        private func show(_ message: String, type: DSToastType) {
            withAnimation(DSAnimation.springSmooth) { toast = (message, type) }
            switch type {
            case .success: DSHapticEngine.shared.fire(.success)
            case .error:   DSHapticEngine.shared.fire(.error)
            case .warning: DSHapticEngine.shared.fire(.warning)
            case .info:    DSHapticEngine.shared.fire(.light)
            }
        }
    }
    // END ToastDemo

    // BEGIN EmptyStateDemo
    struct EmptyStateDemo: View {
        @State private var items: [String] = []

        var body: some View {
            DSScreen(backdrop: true) {
                if items.isEmpty {
                    DSEmptyState(
                        icon: "tray",
                        title: "Nothing here yet",
                        message: "Saved recipes show up here so you can find them later.",
                        actionTitle: "Add a recipe"
                    ) {
                        items.append("Shakshuka")
                    }
                } else {
                    VStack(spacing: DSSpacing.sm) {
                        ForEach(items, id: \.self) { item in
                            DSCard { Text(item).ds(.body) }
                        }
                    }
                    .dsScreenPadding()
                }
            }
        }
    }
    // END EmptyStateDemo

    // BEGIN ProgressDemo
    struct ProgressDemo: View {
        @State private var progress = 0.35
        @State private var step = 2

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    DSCircularProgress(progress: progress, size: 96)
                    DSAnimatedNumber(value: progress * 100, style: .displayMedium)
                    DSLinearProgress(progress: progress)
                    DSGradientProgress(progress: progress)
                    DSStepProgress(currentStep: step, totalSteps: 4)

                    DSButton("Advance", isFullWidth: true) {
                        progress = min(progress + 0.15, 1)
                        step = min(step + 1, 4)
                    }

                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 16)
                            .dsShimmer()
                        RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                            .fill(Color.gray.opacity(0.25))
                            .frame(width: 160, height: 16)
                            .dsShimmer()
                    }
                }
                .dsScreenPadding()
            }
        }
    }
    // END ProgressDemo

    // BEGIN ThinkingDemo
    struct ThinkingDemo: View {
        @State private var isWorking = true

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    DSCard {
                        if isWorking {
                            DSThinkingIndicator(
                                phrases: ["Reading your notes", "Drafting a summary", "Almost there"]
                            )
                        } else {
                            Text("Summary ready").ds(.body)
                        }
                    }
                    .dsEdgeSweep(isActive: isWorking)

                    DSButton(isWorking ? "Stop" : "Run again", variant: .secondary) {
                        isWorking.toggle()
                    }
                }
                .dsScreenPadding()
            }
        }
    }
    // END ThinkingDemo

    // BEGIN TypewriterDemo
    struct TypewriterDemo: View {
        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Build something").ds(.largeTitle)
                    DSTypewriterText(
                        ["that feels alive.", "with glass and springs.", "in an afternoon."],
                        style: .title1
                    )

                    DSTypewriterText(["Ready when you are."], style: .callout, loops: false)
                }
                .dsScreenPadding()
            }
        }
    }
    // END TypewriterDemo

    // BEGIN MotionDemo
    struct MotionDemo: View {
        @State private var shakes = 0
        @State private var isSweeping = true

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .dsBreathe(.subtle)

                    Image(systemName: "bell.fill")
                        .font(.largeTitle)
                        .dsJiggle(trigger: shakes)
                    DSButton("Shake", variant: .secondary, size: .small) { shakes += 1 }

                    HStack(spacing: DSSpacing.sm) {
                        ForEach(0..<4, id: \.self) { index in
                            RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                                .fill(Color.blue)
                                .frame(height: DSSpacing.huge)
                                .dsHueDrift()
                                .dsPopIn(delay: Double(index) * 0.08)
                        }
                    }

                    Text("Processing…")
                        .ds(.body)
                        .padding(DSSpacing.md)
                        .frame(maxWidth: .infinity)
                        .dsSurface(.glass, radius: DSRadius.card)
                        .dsEdgeSweep(radius: DSRadius.card, isActive: isSweeping)
                }
                .dsScreenPadding()
            }
        }
    }
    // END MotionDemo

    // BEGIN TimelineDemo
    struct TimelineDemo: View {
        @State private var step = 2

        var body: some View {
            DSScreen(backdrop: true) {
                DSCard {
                    DSTimeline(
                        [
                            DSTimelineItem("Order placed", subtitle: "March 3, 9:41 AM", icon: "bag"),
                            DSTimelineItem("Shipped", subtitle: "Picked up by courier", icon: "shippingbox"),
                            DSTimelineItem("Out for delivery", subtitle: "Arriving today", icon: "box.truck"),
                            DSTimelineItem("Delivered", icon: "house")
                        ],
                        currentStep: step
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .dsScreenPadding()
            }
        }
    }
    // END TimelineDemo
}

@MainActor
final class DocSnippetsDisplayTests: XCTestCase {
    func testDisplayFeedbackAndMotionSnippetsInstantiate() {
        _ = DocSnippetsDisplay.CardDemo()
        _ = DocSnippetsDisplay.CardStylesDemo()
        _ = DocSnippetsDisplay.BadgeDemo()
        _ = DocSnippetsDisplay.AvatarDemo()
        _ = DocSnippetsDisplay.ListDemo()
        _ = DocSnippetsDisplay.ToastDemo()
        _ = DocSnippetsDisplay.EmptyStateDemo()
        _ = DocSnippetsDisplay.ProgressDemo()
        _ = DocSnippetsDisplay.ThinkingDemo()
        _ = DocSnippetsDisplay.TypewriterDemo()
        _ = DocSnippetsDisplay.MotionDemo()
        _ = DocSnippetsDisplay.TimelineDemo()
    }
}
