import SwiftUI
import VelvetUI

/// A label, a read-out and the control: the slider draws no value of its own.
private struct SliderRow<Control: View>: View {
    let title: String
    let readout: String
    @ViewBuilder var control: () -> Control

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack {
                Text(title).ds(.footnote, color: DSColors.textSecondary)
                Spacer()
                Text(readout).ds(.numeric)
            }
            control()
        }
    }
}

struct SliderScreen: View {
    @State private var volume = 0.6
    @State private var brightness = 0.35
    @State private var price: Double = 150
    @State private var temperature: Double = -2
    @State private var shutter: Double = 3
    @State private var opacity = 0.8
    @State private var clamped = 0.5
    @State private var silent = 0.4
    @State private var isEnabled = false

    var body: some View {
        GalleryScreen(title: "Slider", caption: "Continuous value, optional notches") {
            LabeledExample("Default (0…1) — silent between the ends, one tick at each") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        SliderRow(title: "Volume", readout: "\(Int(volume * 100))%") {
                            DSSlider(value: $volume)
                        }
                        SliderRow(title: "Brightness", readout: "\(Int(brightness * 100))%") {
                            HStack(spacing: DSSpacing.sm) {
                                Image(systemName: "sun.min").foregroundStyle(DSColors.textSecondary)
                                DSSlider(value: $brightness)
                                Image(systemName: "sun.max.fill").foregroundStyle(DSColors.textSecondary)
                            }
                        }
                    }
                }
            }

            LabeledExample("Stepped — a selection tick per notch") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        SliderRow(title: "Max price, in: 0…500, step: 25", readout: "$\(Int(price))") {
                            DSSlider(value: $price, in: 0...500, step: 25)
                        }
                        SliderRow(title: "Shutter, in: 0…10, step: 3 — 10 is still reachable", readout: "\(Int(shutter))") {
                            DSSlider(value: $shutter, in: 0...10, step: 3)
                        }
                    }
                }
            }

            LabeledExample("A range that crosses zero") {
                DSCard {
                    SliderRow(
                        title: "Temperature, in: -10…10, step: 0.5",
                        readout: String(format: "%+.1f°", temperature)
                    ) {
                        DSSlider(value: $temperature, in: -10...10, step: 0.5)
                    }
                }
            }

            LabeledExample("Custom accent") {
                DSCard {
                    SliderRow(title: "Opacity", readout: String(format: "%.2f", opacity)) {
                        DSSlider(value: $opacity, accent: DSColors.secondary)
                    }
                }
            }

            LabeledExample("Clamping — an out-of-range value is pulled back") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        SliderRow(title: "Bound value", readout: String(format: "%.2f", clamped)) {
                            DSSlider(value: $clamped)
                        }
                        HStack(spacing: DSSpacing.sm) {
                            DSButton("Set to 1.7", variant: .secondary, size: .small) { clamped = 1.7 }
                            DSButton("Set to -0.4", variant: .secondary, size: .small) { clamped = -0.4 }
                        }
                    }
                }
            }

            LabeledExample("States") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        SliderRow(title: "Haptics off", readout: "\(Int(silent * 100))%") {
                            DSSlider(value: $silent, haptics: false)
                        }
                        SliderRow(title: isEnabled ? "Enabled" : "Disabled", readout: "\(Int(silent * 100))%") {
                            DSSlider(value: $silent)
                                .disabled(!isEnabled)
                        }
                        DSToggle("Enable the slider above", isOn: $isEnabled, onColor: DSColors.textSecondary)
                    }
                }
            }

            Text("On a device a stepped slider ticks on every notch and every slider gives a firm detent at either end. With VoiceOver on, swipe up or down to adjust.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

struct SliderStage: View {
    let autoplay: Bool
    @State private var volume = 0.3
    @State private var price: Double = 100

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    HStack {
                        Text("Volume").ds(.callout, color: DSColors.textSecondary)
                        Spacer()
                        Text("\(Int(volume * 100))%").ds(.numeric)
                    }
                    DSSlider(value: $volume)
                }
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    HStack {
                        Text("Max price").ds(.callout, color: DSColors.textSecondary)
                        Spacer()
                        Text("$\(Int(price))").ds(.numeric)
                    }
                    DSSlider(value: $price, in: 0...500, step: 25)
                }
            }
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for target in [0.85, 0.15, 1.0, 0.5] {
                    await stagePause(0.9)
                    if Task.isCancelled { return }
                    withAnimation(DSAnimation.springSmooth) { volume = target }
                    withAnimation(DSAnimation.springSmooth) { price = (target * 500 / 25).rounded() * 25 }
                }
                await stagePause(1.0)
            }
        }
    }
}
