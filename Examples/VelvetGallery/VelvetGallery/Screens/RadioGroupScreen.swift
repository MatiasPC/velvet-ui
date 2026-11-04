import SwiftUI
import VelvetUI

struct RadioGroupScreen: View {
    enum Plan: Hashable { case free, pro, team }

    @State private var plan = Plan.pro
    @State private var payment = "Credit Card"
    @State private var speed = "Standard"
    @State private var day = 2
    @State private var tinted = "Email"
    @State private var isDisabled = false

    var body: some View {
        GalleryScreen(title: "Radio Group", caption: "Pick one, with a sliding highlight") {
            LabeledExample("Enum values with subtitles") {
                VStack(spacing: DSSpacing.sm) {
                    DSCard {
                        DSRadioGroup(selection: $plan, options: [
                            DSRadioOption("Free", value: Plan.free, subtitle: "For trying things out"),
                            DSRadioOption("Pro", value: Plan.pro, subtitle: "Everything, for one person"),
                            DSRadioOption("Team", value: Plan.team, subtitle: "Shared workspaces")
                        ])
                        .accessibilityLabel("Plan")
                        .disabled(isDisabled)
                    }
                    HStack {
                        DSButton("Jump to Team", variant: .secondary, size: .small) { plan = .team }
                        DSButton("Reset", variant: .ghost, size: .small) { plan = .free }
                    }
                    DSToggle("Disable the group", isOn: $isDisabled)
                }
            }

            LabeledExample("Leading icons") {
                DSCard {
                    DSRadioGroup(selection: $payment, options: [
                        DSRadioOption("Apple Pay", value: "Apple Pay", icon: "apple.logo"),
                        DSRadioOption("Credit Card", value: "Credit Card", icon: "creditcard"),
                        DSRadioOption("PayPal", value: "PayPal", icon: "p.circle")
                    ])
                    .accessibilityLabel("Payment method")
                }
            }

            LabeledExample("Plain strings") {
                DSCard {
                    DSRadioGroup(selection: $speed, options: ["Standard", "Express", "Overnight"])
                        .accessibilityLabel("Shipping speed")
                }
            }

            LabeledExample("Int values") {
                DSCard {
                    DSRadioGroup(selection: $day, options: [
                        DSRadioOption("Monday", value: 1),
                        DSRadioOption("Tuesday", value: 2),
                        DSRadioOption("Wednesday", value: 3)
                    ])
                }
            }

            LabeledExample("Custom accent (status color)") {
                DSCard {
                    DSRadioGroup(selection: $tinted, options: ["Email", "SMS", "Push"], accent: DSColors.success)
                }
            }

            LabeledExample("Disabled") {
                DSCard {
                    DSRadioGroup(selection: .constant("Express"), options: ["Standard", "Express"])
                        .disabled(true)
                }
            }
        }
    }
}

struct RadioGroupStage: View {
    let autoplay: Bool
    @State private var plan = "Pro"

    private let plans = [
        DSRadioOption("Free", value: "Free", subtitle: "For trying things out"),
        DSRadioOption("Pro", value: "Pro", subtitle: "Everything, for one person"),
        DSRadioOption("Team", value: "Team", subtitle: "Shared workspaces")
    ]

    var body: some View {
        DSCard {
            DSRadioGroup(selection: $plan, options: plans)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            var index = 1
            await stageLoop {
                await stagePause(1.4)
                index = (index + 1) % plans.count
                plan = plans[index].value
            }
        }
    }
}
