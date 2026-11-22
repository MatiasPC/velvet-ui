import SwiftUI
import VelvetUI

struct ReactionBarScreen: View {
    @State private var reaction: String? = "❤️"
    @State private var mood: String?
    @State private var postReaction: String?
    @State private var isEnabled = false

    var body: some View {
        GalleryScreen(title: "Reaction Bar", caption: "Slide across emoji, let go to react") {
            LabeledExample("Over a message — the default six") {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    DSReactionBar(selection: $reaction)
                    Text("Dinner at eight? I booked the place by the river.")
                        .ds(.body)
                        .padding(DSSpacing.md)
                        .dsSurface(.glass, radius: DSRadius.card)
                    Text(reaction.map { "You reacted \($0)" } ?? "No reaction")
                        .ds(.footnote, color: DSColors.textSecondary)
                }
                .padding(.top, DSSpacing.lg)
            }

            LabeledExample("A feedback card — your own scale") {
                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        Text("How was your ride?").ds(.title3)
                        DSReactionBar(selection: $mood, reactions: ["😡", "🙁", "😐", "🙂", "😍"],
                                      accessibilityLabel: "Ride rating")
                        Text(mood == nil ? "Tap a face" : "Thanks for the feedback")
                            .ds(.footnote, color: DSColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, DSSpacing.lg)
                }
            }

            LabeledExample("Four reactions with a custom accent") {
                DSReactionBar(selection: $postReaction, reactions: ["🔥", "👏", "💡", "🎉"],
                              accent: DSColors.secondary, accessibilityLabel: "Post reaction")
                    .padding(.top, DSSpacing.lg)
            }

            LabeledExample("States") {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    DSReactionBar(selection: $postReaction, reactions: ["🔥", "👏", "💡", "🎉"],
                                  accessibilityLabel: "Post reaction, states demo")
                        .disabled(!isEnabled)
                    DSToggle("Enable the bar above", isOn: $isEnabled, onColor: DSColors.textSecondary)
                }
            }

            Text("Press and slide: the emoji under your finger swells with its neighbours, and a tick lands on each new one. Let go to react; pick the same emoji again to take it back. Lift your finger well above the bar to cancel. With VoiceOver on, swipe up or down on the bar to step through the reactions.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Recording stage: a message with the default six reactions, starting with none.
/// The bar is one adjustable element, "Reaction", whose value (the emoji, or
/// "None") the UI test reads back. Each emoji sits in a 44 pt cell inside a 4 pt
/// inset, at the default text size, so the test can aim at a cell by position.
struct ReactionBarStage: View {
    let autoplay: Bool
    @State private var reaction: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            DSReactionBar(selection: $reaction)
            Text("Dinner at eight? I booked the place by the river.")
                .ds(.body)
                .padding(DSSpacing.md)
                .dsSurface(.glass, radius: DSRadius.card)
            Text(reaction.map { "You reacted \($0)" } ?? "No reaction yet")
                .ds(.footnote, color: DSColors.textSecondary)
        }
        .padding(.top, DSSpacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for target in ["❤️", "😂", "👍", nil] as [String?] {
                    await stagePause(1.2)
                    if Task.isCancelled { return }
                    reaction = target
                }
                await stagePause(1.0)
            }
        }
    }
}
