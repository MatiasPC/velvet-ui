import SwiftUI
import VelvetUI

private let trips = ["Lisbon", "Porto", "Sintra", "Madeira"]

struct StoryProgressScreen: View {
    @State private var page = 0
    @State private var isHolding = false
    @State private var tipPage = 0

    var body: some View {
        GalleryScreen(title: "Story Progress", caption: "One segment per page; the current one fills, then the page moves on by itself") {
            LabeledExample("Stories: tap a side to skip, hold to pause") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        DSStoryProgress(currentPage: $page, numberOfPages: trips.count, duration: 4, isPaused: isHolding) {
                            page = 0
                        }
                        Text(trips[page]).ds(.largeTitle)
                        Text("Story \(page + 1) of \(trips.count)").ds(.footnote, color: DSColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay {
                        HStack(spacing: 0) {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { page = max(page - 1, 0) }
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { page = min(page + 1, trips.count - 1) }
                        }
                        .accessibilityHidden(true)
                    }
                    .onLongPressGesture(minimumDuration: 0.2, perform: {}, onPressingChanged: { isHolding = $0 })
                }
            }

            LabeledExample("Looping tips, custom accent") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSStoryProgress(
                            currentPage: $tipPage,
                            numberOfPages: 3,
                            duration: 3,
                            accent: DSColors.secondary,
                            accessibilityLabel: "Tip"
                        ) {
                            tipPage = 0
                        }
                        Text(["Swipe to save a trip", "Hold to pause a story", "Tap a side to skip"][tipPage]).ds(.title3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text("With VoiceOver on, the progress is one adjustable element (\"Story, 2 of 4\"): swipe up or down to move a page.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Recording stage: four trip stories, three seconds each, in a glass card
/// with Previous, Pause / Play and Next buttons and "Watch again". The progress
/// is the adjustable accessibility element "Stories", whose value is the page
/// ("1 of 4" … "4 of 4"); "Stories status" reads "Playing", "Paused" or
/// "Finished" (after `onFinish`). The UI test drives exactly that. Autoplay:
/// when the last story finishes it starts again after a beat.
struct StoryProgressStage: View {
    let autoplay: Bool
    @State private var page = 0
    @State private var isPaused = false
    @State private var isFinished = false

    static let secondsPerStory: TimeInterval = 3

    private var status: String {
        isFinished ? "Finished" : (isPaused ? "Paused" : "Playing")
    }

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                DSStoryProgress(
                    currentPage: $page,
                    numberOfPages: trips.count,
                    duration: Self.secondsPerStory,
                    isPaused: isPaused,
                    accessibilityLabel: "Stories"
                ) {
                    isFinished = true
                }

                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(trips[page]).ds(.largeTitle)
                    Text(status)
                        .ds(.footnote, color: DSColors.textSecondary)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Stories status")
                        .accessibilityValue(status)
                }

                HStack(spacing: DSSpacing.sm) {
                    DSIconButton(icon: "chevron.backward", accessibilityLabel: "Previous story") {
                        page = max(page - 1, 0)
                    }
                    DSIconButton(icon: isPaused ? "play.fill" : "pause.fill",
                                 accessibilityLabel: isPaused ? "Play stories" : "Pause stories") {
                        isPaused.toggle()
                    }
                    DSIconButton(icon: "chevron.forward", accessibilityLabel: "Next story") {
                        page = min(page + 1, trips.count - 1)
                    }
                    Spacer()
                    DSButton("Watch again", variant: .secondary, size: .small) { restart() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: page) { isFinished = false }
        .task(id: isFinished) {
            guard autoplay, isFinished else { return }
            await stagePause(1.5)
            if Task.isCancelled { return }
            restart()
        }
    }

    private func restart() {
        isFinished = false
        page = 0
    }
}
