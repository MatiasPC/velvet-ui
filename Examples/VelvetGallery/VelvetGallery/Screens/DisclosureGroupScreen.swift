import SwiftUI
import VelvetUI

/// The accordion used by both the screen and the recording stage: one section
/// open at a time, each bound to the same selection.
private struct FAQAccordion: View {
    @Binding var open: Int?

    private let items: [(question: String, answer: String)] = [
        ("Can I cancel anytime?", "Yes. Cancel from Settings and keep access until the end of the period."),
        ("Do you offer refunds?", "Within 14 days of your first charge, no questions asked."),
        ("Is my data private?", "Everything stays on your device unless you turn on sync.")
    ]

    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            ForEach(items.indices, id: \.self) { index in
                DSDisclosureGroup(
                    items[index].question,
                    isExpanded: Binding(
                        get: { open == index },
                        set: { open = $0 ? index : nil }
                    )
                ) {
                    Text(items[index].answer)
                        .ds(.callout, color: DSColors.textSecondary)
                }
            }
        }
    }
}

struct DisclosureGroupScreen: View {
    @State private var shippingOpen = true
    @State private var accordionOpen: Int? = 0
    @State private var hapticChoice = "Light"

    private let hapticOptions = ["Light", "Medium", "Soft", "Rigid"]

    private var haptic: DSHapticStyle {
        switch hapticChoice {
        case "Medium": return .medium
        case "Soft":   return .soft
        case "Rigid":  return .rigid
        default:       return .light
        }
    }

    var body: some View {
        GalleryScreen(title: "Disclosure Group", caption: "Glass accordion that springs open") {
            LabeledExample("Closed by default") {
                DSDisclosureGroup("Can I cancel anytime?") {
                    Text("Yes. Cancel from Settings and keep access until the end of the period.")
                        .ds(.callout, color: DSColors.textSecondary)
                }
            }

            LabeledExample("Icon and subtitle, starts open") {
                DSDisclosureGroup(
                    "What's included",
                    subtitle: "3 items",
                    icon: "shippingbox",
                    initiallyExpanded: true
                ) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("• Unlimited projects").ds(.callout)
                        Text("• Priority support").ds(.callout)
                        Text("• Early access to betas").ds(.callout)
                    }
                }
            }

            LabeledExample("Controlled, driven from outside") {
                VStack(spacing: DSSpacing.sm) {
                    DSDisclosureGroup("Shipping details", icon: "box.truck", isExpanded: $shippingOpen) {
                        Text("Ships in 2 to 3 business days with carbon-neutral delivery. Orders placed after 2 pm leave the next morning, and you get a tracking link by email as soon as the parcel is handed over.")
                            .ds(.callout, color: DSColors.textSecondary)
                    }
                    DSCard {
                        DSToggle("Shipping open", isOn: $shippingOpen)
                    }
                }
            }

            LabeledExample("One open at a time") {
                FAQAccordion(open: $accordionOpen)
            }

            LabeledExample("Haptic on toggle") {
                VStack(spacing: DSSpacing.sm) {
                    DSSegmentedControl(selection: $hapticChoice, options: hapticOptions)
                    DSDisclosureGroup("Tap me", subtitle: "Feel the \(hapticChoice.lowercased()) tap", haptic: haptic) {
                        Text("The haptic fires on every toggle, on the beat the body starts to move. Haptics need a device; the Simulator is silent.")
                            .ds(.callout, color: DSColors.textSecondary)
                    }
                }
            }
        }
    }
}

struct DisclosureGroupStage: View {
    let autoplay: Bool
    @State private var open: Int? = 0

    var body: some View {
        FAQAccordion(open: $open)
            .task(id: autoplay) {
                guard autoplay else { return }
                await stageLoop {
                    for index in 0..<3 {
                        await stagePause(2.0)
                        if Task.isCancelled { return }
                        open = index
                    }
                    await stagePause(2.0)
                    if Task.isCancelled { return }
                    open = nil
                }
            }
    }
}
