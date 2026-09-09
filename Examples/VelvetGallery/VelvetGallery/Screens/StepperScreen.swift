import SwiftUI
import DesignSystem

struct StepperScreen: View {
    @State private var quantity = 3
    @State private var bulk = 25
    @State private var atBound = 99

    var body: some View {
        GalleryScreen(title: "Stepper", caption: "Numeric input, tick per step") {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    LabeledExample("Default (0…99)") {
                        DSStepper(value: $quantity)
                    }
                    LabeledExample("Step 5, range 0…100") {
                        DSStepper(value: $bulk, in: 0...100, step: 5)
                    }
                    LabeledExample("At upper bound — tap + for the refusal jiggle") {
                        DSStepper(value: $atBound, in: 0...99)
                    }
                }
            }
        }
    }
}
