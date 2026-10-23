import SwiftUI
import VelvetUI

// Recording stages for the example flows. Each hosts its flow full-screen with
// no chrome and no autoplay: the flows are driven by touch.

struct OnboardingFlowStage: View {
    var body: some View { OnboardingFlow() }
}

struct SettingsFlowStage: View {
    var body: some View { SettingsFlow() }
}

struct CheckoutFlowStage: View {
    var body: some View { CheckoutFlow() }
}
