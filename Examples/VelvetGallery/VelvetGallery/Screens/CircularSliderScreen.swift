import SwiftUI
import VelvetUI

struct CircularSliderScreen: View {
    @State private var temperature: Double = 21
    @State private var volume: Double = 0.4
    @State private var minutes: Double = 25
    @State private var goal: Double = 8_000
    @State private var isEnabled = false

    var body: some View {
        GalleryScreen(title: "Circular Slider", caption: "A value on a dial, its read-out in the middle") {
            LabeledExample("Thermostat — 10…30 in half degrees") {
                DSCard {
                    DSCircularSlider(value: $temperature, in: 10...30, step: 0.5,
                                     accessibilityLabel: "Temperature") {
                        VStack(spacing: DSSpacing.xxs) {
                            Text(degrees(temperature)).ds(.displayMedium)
                            Text("Heating to").ds(.footnote, color: DSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: 260)
                    .frame(maxWidth: .infinity)
                }
            }

            LabeledExample("Small dials — continuous, and in five-minute notches with a custom accent") {
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSCircularSlider(value: $volume, accessibilityLabel: "Volume") {
                            Text("\(Int((volume * 100).rounded()))%").ds(.numeric)
                        }
                        .frame(width: 120, height: 120)

                        DSCircularSlider(value: $minutes, in: 5...60, step: 5,
                                         accent: DSColors.secondary, accessibilityLabel: "Timer") {
                            Text("\(Int(minutes)) min").ds(.numeric)
                        }
                        .frame(width: 120, height: 120)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            LabeledExample("A wide range — a daily step goal in 500s") {
                DSCard {
                    HStack(spacing: DSSpacing.lg) {
                        DSCircularSlider(value: $goal, in: 2_000...20_000, step: 500, accessibilityLabel: "Daily goal")
                            .frame(width: 96, height: 96)
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text("\(Int(goal)) steps").ds(.title3)
                            Text("A bare dial, the value beside it").ds(.footnote, color: DSColors.textSecondary)
                        }
                        Spacer()
                    }
                }
            }

            LabeledExample("States") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        DSCircularSlider(value: $volume, accessibilityLabel: "Volume, states demo")
                            .frame(width: 96, height: 96)
                            .disabled(!isEnabled)
                        DSToggle("Enable the dial above", isOn: $isEnabled, onColor: DSColors.textSecondary)
                    }
                }
            }

            Text("Drag around the ring: the knob holds at an end when you drag into the gap at the bottom, and never jumps across it. On a device a stepped dial ticks on every notch and gives a firm detent at each end. With VoiceOver on, swipe up or down on the dial to adjust it.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }

    private func degrees(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "en_US"))) + "°"
    }
}

/// Recording stage: a thermostat, 10–30 °C in half degrees, starting at 21.
/// The dial is one adjustable element, "Temperature", whose value the UI test
/// reads back; the dial is a fixed 256 pt square so the test can aim at angles.
struct CircularSliderStage: View {
    let autoplay: Bool
    @State private var temperature: Double = 21

    var body: some View {
        DSCard {
            DSCircularSlider(value: $temperature, in: 10...30, step: 0.5,
                             accessibilityLabel: "Temperature") {
                VStack(spacing: DSSpacing.xxs) {
                    Text(temperature.formatted(.number.precision(.fractionLength(1))) + "°")
                        .ds(.displayMedium)
                    Text("Heating to").ds(.footnote, color: DSColors.textSecondary)
                }
            }
            .frame(width: DSSpacing.massive * 4, height: DSSpacing.massive * 4)
            .frame(maxWidth: .infinity)
        }
        .environment(\.locale, Locale(identifier: "en_US"))
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for target in [24.0, 17.5, 30.0, 10.0, 21.0] {
                    await stagePause(1.0)
                    if Task.isCancelled { return }
                    withAnimation(DSAnimation.springSmooth) { temperature = target }
                }
                await stagePause(1.0)
            }
        }
    }
}
