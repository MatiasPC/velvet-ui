import SwiftUI
import VelvetUI

/// A label, a read-out and the control: the range slider draws no values of its own.
private struct RangeRow<Control: View>: View {
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

struct RangeSliderScreen: View {
    @State private var price: ClosedRange<Double> = 100...400
    @State private var hours: ClosedRange<Double> = 9...17
    @State private var age: ClosedRange<Double> = 25...40
    @State private var level: ClosedRange<Double> = 0.2...0.7
    @State private var clamped: ClosedRange<Double> = 0.3...0.6
    @State private var isEnabled = false

    var body: some View {
        GalleryScreen(title: "Range Slider", caption: "Two knobs, a span between them") {
            LabeledExample("Stepped, with a minimum gap — the knobs stop short of each other") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        RangeRow(title: "Price, step: 25, minimumDistance: 50",
                                 readout: "$\(Int(price.lowerBound)) – $\(Int(price.upperBound))") {
                            DSRangeSlider(range: $price, in: 0...500, step: 25, minimumDistance: 50)
                                .accessibilityLabel("Price")
                        }
                        RangeRow(title: "Open hours, step: 1, minimumDistance: 2",
                                 readout: "\(Int(hours.lowerBound)):00 – \(Int(hours.upperBound)):00") {
                            DSRangeSlider(range: $hours, in: 0...24, step: 1, minimumDistance: 2)
                                .accessibilityLabel("Open hours")
                        }
                    }
                }
            }

            LabeledExample("No gap — the knobs may meet") {
                DSCard {
                    RangeRow(title: "Age, in: 18…80, step: 1",
                             readout: "\(Int(age.lowerBound))–\(Int(age.upperBound))") {
                        DSRangeSlider(range: $age, in: 18...80, step: 1)
                            .accessibilityLabel("Age")
                    }
                }
            }

            LabeledExample("Continuous, custom accent") {
                DSCard {
                    RangeRow(title: "Level",
                             readout: String(format: "%.2f – %.2f", level.lowerBound, level.upperBound)) {
                        DSRangeSlider(range: $level, accent: DSColors.secondary)
                            .accessibilityLabel("Level")
                    }
                }
            }

            LabeledExample("Normalising — an invalid range is corrected and written back") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        RangeRow(title: "Bound range, minimumDistance: 0.2",
                                 readout: String(format: "%.2f – %.2f", clamped.lowerBound, clamped.upperBound)) {
                            DSRangeSlider(range: $clamped, minimumDistance: 0.2)
                        }
                        HStack(spacing: DSSpacing.sm) {
                            DSButton("Set to -1…3", variant: .secondary, size: .small) { clamped = -1...3 }
                            DSButton("Set to 0.9…0.9", variant: .secondary, size: .small) { clamped = 0.9...0.9 }
                        }
                    }
                }
            }

            LabeledExample("States") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        RangeRow(title: isEnabled ? "Enabled" : "Disabled",
                                 readout: String(format: "%.2f – %.2f", level.lowerBound, level.upperBound)) {
                            DSRangeSlider(range: $level)
                                .disabled(!isEnabled)
                        }
                        DSToggle("Enable the range slider above", isOn: $isEnabled, onColor: DSColors.textSecondary)
                    }
                }
            }

            Text("On a device a stepped range slider ticks on every notch and gives a firm detent when a knob reaches the end of the track or the gap to the other knob. With VoiceOver on, swipe to a knob, then up or down to adjust it.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Recording stage: a price filter, $0–500 in 25s with at least $50 between the
/// knobs. The knobs are the accessibility elements "Minimum" and "Maximum",
/// whose values the UI test reads back.
struct RangeSliderStage: View {
    let autoplay: Bool
    @State private var price: ClosedRange<Double> = 100...400

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                HStack {
                    Text("Price").ds(.callout, color: DSColors.textSecondary)
                    Spacer()
                    Text("$\(Int(price.lowerBound)) – $\(Int(price.upperBound))").ds(.numeric)
                }
                DSRangeSlider(range: $price, in: 0...500, step: 25, minimumDistance: 50)
                    .accessibilityLabel("Price")
            }
        }
        .environment(\.locale, Locale(identifier: "en_US"))
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for target in [150.0...350.0, 0.0...300.0, 0.0...500.0, 225.0...275.0, 100.0...400.0] {
                    await stagePause(0.9)
                    if Task.isCancelled { return }
                    withAnimation(DSAnimation.springSmooth) { price = target }
                }
                await stagePause(1.0)
            }
        }
    }
}
