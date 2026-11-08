import SwiftUI
import VelvetUI

struct KeypadScreen: View {
    @State private var amount = ""
    @State private var pin = ""
    @State private var guests = ""
    @State private var euros = ""

    var body: some View {
        GalleryScreen(title: "Keypad", caption: "Amounts, passcodes and quantities, without the system keyboard") {
            LabeledExample("Amount (two decimals, at most 7 digits)") {
                DSCard {
                    VStack(spacing: DSSpacing.lg) {
                        Text(amount.isEmpty ? "$0" : "$" + amount)
                            .ds(.displayMedium)
                            .contentTransition(.numericText())
                            .animation(DSAnimation.springSnappy, value: amount)
                        DSKeypad(text: $amount, maxLength: 7, decimalPlaces: 2)
                    }
                }
            }

            LabeledExample("Passcode (4 digits, leading zeros kept)") {
                DSCard {
                    VStack(spacing: DSSpacing.lg) {
                        PinDots(count: pin.count, length: 4)
                        DSKeypad(text: $pin, maxLength: 4)
                            .onChange(of: pin) { _, code in
                                guard code.count == 4 else { return }
                                Task {
                                    try? await Task.sleep(for: .seconds(0.6))
                                    withAnimation(DSAnimation.springSnappy) { pin = "" }
                                }
                            }
                    }
                }
            }

            LabeledExample("A comma locale (de_DE)") {
                DSCard {
                    VStack(spacing: DSSpacing.lg) {
                        Text(euros.isEmpty ? "0 €" : euros + " €").ds(.title1)
                        DSKeypad(text: $euros, maxLength: 6, decimalPlaces: 2, haptic: .soft)
                            .environment(\.locale, Locale(identifier: "de_DE"))
                    }
                }
            }

            LabeledExample("Disabled") {
                DSCard {
                    DSKeypad(text: $guests).disabled(true)
                }
            }
        }
    }
}

/// Filled dots for the digits entered so far.
private struct PinDots: View {
    let count: Int
    let length: Int

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            ForEach(0..<length, id: \.self) { index in
                Circle()
                    .fill(index < count ? DSColors.textPrimary : DSColors.backgroundSecondary)
                    .frame(width: DSSpacing.sm, height: DSSpacing.sm)
                    .animation(DSAnimation.springSnappy, value: count)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Passcode")
        .accessibilityValue("\(count) of \(length) digits")
    }
}

/// Recording stage: a send-money amount. Pinned to en_US so the separator is "."
/// on any simulator. The read-out is one accessibility element ("Amount") whose
/// value is the raw text, which the UI test reads back.
struct KeypadStage: View {
    let autoplay: Bool
    @State private var amount = ""

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.lg) {
                Text("Send to Ada").ds(.callout, color: DSColors.textSecondary)
                Text(amount.isEmpty ? "$0" : "$" + amount)
                    .ds(.displayMedium)
                    .contentTransition(.numericText())
                    .animation(DSAnimation.springSnappy, value: amount)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Amount")
                    .accessibilityValue(amount.isEmpty ? "0" : amount)
                DSKeypad(text: $amount, maxLength: 7, decimalPlaces: 2)
            }
        }
        .environment(\.locale, Locale(identifier: "en_US"))
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for step in ["2", "24", "24.", "24.5", "24.50"] {
                    await stagePause(0.5)
                    if Task.isCancelled { return }
                    amount = step
                }
                await stagePause(1.2)
                for step in ["24.5", "24.", "24", "2", ""] {
                    await stagePause(0.25)
                    if Task.isCancelled { return }
                    amount = step
                }
            }
        }
    }
}
