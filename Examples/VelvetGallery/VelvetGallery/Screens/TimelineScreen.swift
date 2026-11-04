import SwiftUI
import VelvetUI

private let deliverySteps = [
    DSTimelineItem("Order placed", subtitle: "9:41 AM", icon: "bag"),
    DSTimelineItem("Shipped", subtitle: "Picked up by courier", icon: "shippingbox"),
    DSTimelineItem("Out for delivery", subtitle: "Arriving today", icon: "box.truck"),
    DSTimelineItem("Delivered", subtitle: "Left at front door", icon: "house")
]

struct TimelineScreen: View {
    @State private var step = 1
    @State private var haptics = true
    @State private var nodeSize = "Default"
    @State private var wizardStep = 1

    private var nodeDiameter: CGFloat {
        switch nodeSize {
        case "Small": return DSSpacing.xl
        case "Large": return DSSpacing.xxxl
        default:      return DSSpacing.xxl
        }
    }

    private var summary: String {
        step >= deliverySteps.count ? "All steps complete" : "Step \(step + 1) of \(deliverySteps.count): \(deliverySteps[step].title)"
    }

    var body: some View {
        GalleryScreen(title: "Timeline", caption: "Nodes joined by a connector that fills as the flow advances") {
            LabeledExample("Order tracking: advance, rewind, finish") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        DSTimeline(
                            deliverySteps,
                            currentStep: step,
                            nodeSize: nodeDiameter,
                            haptics: haptics
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(summary).ds(.footnote, color: DSColors.textSecondary)

                        HStack(spacing: DSSpacing.sm) {
                            DSButton("Back", variant: .ghost, size: .small) {
                                step = max(step - 1, 0)
                            }
                            DSButton("Advance", variant: .secondary, size: .small) {
                                step = min(step + 1, deliverySteps.count)
                            }
                            DSButton("Reset", variant: .ghost, size: .small) {
                                step = 0
                            }
                        }
                    }
                }
            }

            LabeledExample("Node size and haptics") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSSegmentedControl(selection: $nodeSize, options: ["Small", "Default", "Large"])
                        DSToggle("Success haptic on advance", isOn: $haptics)
                        Text("The haptic fires once when the step moves forward. Not on first appearance, not when stepping back. The simulator has no haptics: try it on a device.")
                            .ds(.caption1, color: DSColors.textTertiary)
                    }
                }
            }

            LabeledExample("No icons, with a stepper") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        DSTimeline(
                            [
                                DSTimelineItem("Account", subtitle: "Email and password"),
                                DSTimelineItem("Profile", subtitle: "Name and photo"),
                                DSTimelineItem("Preferences"),
                                DSTimelineItem("Done")
                            ],
                            currentStep: wizardStep
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            Text("Current step").ds(.body)
                            Spacer()
                            DSStepper(value: $wizardStep, in: 0...4)
                                .accessibilityLabel("Current step")
                        }
                    }
                }
            }

            LabeledExample("Custom accent") {
                DSCard {
                    DSTimeline(
                        [
                            DSTimelineItem("Submitted", subtitle: "Mon 9:12 AM", icon: "paperplane"),
                            DSTimelineItem("In review", subtitle: "Two reviewers", icon: "eye"),
                            DSTimelineItem("Approved", icon: "checkmark.seal")
                        ],
                        currentStep: 1,
                        accent: DSColors.success
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LabeledExample("Long copy wraps; the node stays on the first line") {
                DSCard {
                    DSTimeline(
                        [
                            DSTimelineItem(
                                "Your parcel has left the regional sorting facility",
                                subtitle: "Handed to the courier for the last leg, expect a delivery window by text",
                                icon: "shippingbox"
                            ),
                            DSTimelineItem("Delivered", icon: "house")
                        ],
                        currentStep: 0
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text("Under Reduce Motion the connector fades in instead of growing and the live glow rests still.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Chrome-free recording stage: an order moving through its four steps, then a cut back to the start.
struct TimelineStage: View {
    let autoplay: Bool
    @State private var step: Int

    init(autoplay: Bool) {
        self.autoplay = autoplay
        _step = State(initialValue: autoplay ? 0 : 1)
    }

    var body: some View {
        DSCard {
            DSTimeline(deliverySteps, currentStep: step)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                // Cut back to the start without rewinding the fill.
                var cut = Transaction()
                cut.disablesAnimations = true
                withTransaction(cut) { step = 0 }
                await stagePause(1.0)
                for next in 1...deliverySteps.count {
                    guard !Task.isCancelled else { return }
                    step = next
                    await stagePause(1.1)
                }
                await stagePause(1.4)
            }
        }
    }
}
