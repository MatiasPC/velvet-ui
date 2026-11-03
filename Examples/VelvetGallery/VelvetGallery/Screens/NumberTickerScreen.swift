import SwiftUI
import VelvetUI

struct NumberTickerScreen: View {
    @State private var balance: Double = 1_284.50
    @State private var steps = 8_432
    @State private var goal: Double = 0.42

    var body: some View {
        GalleryScreen(title: "Number Ticker", caption: "Digits roll like an odometer") {
            LabeledExample("Balance — currency, random jumps") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        Text("Available").ds(.overline, color: DSColors.textSecondary)
                        DSNumberTicker(balance, format: .currency(code: "USD"))
                        HStack(spacing: DSSpacing.sm) {
                            DSButton("Random", variant: .secondary, size: .small) {
                                balance = Double.random(in: 0...50_000).rounded(toPlaces: 2)
                            }
                            DSButton("Deposit $100", variant: .ghost, size: .small) {
                                balance += 100
                            }
                        }
                    }
                }
            }

            LabeledExample("Steps — integer, growth 99 → 100") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSNumberTicker(steps, style: .displayLarge)
                        HStack(spacing: DSSpacing.sm) {
                            DSButton("+1", variant: .secondary, size: .small) { steps += 1 }
                            DSButton("Reset to 99", variant: .ghost, size: .small) { steps = 99 }
                            DSButton("Big jump", variant: .ghost, size: .small) { steps = 99_999 }
                        }
                    }
                }
            }

            LabeledExample("Goal — percent") {
                DSCard {
                    HStack {
                        Text("Weekly goal").ds(.body)
                        Spacer()
                        DSNumberTicker(goal, format: .percent, style: .numeric)
                        DSButton("Next", variant: .ghost, size: .small) {
                            goal = Double.random(in: 0...1)
                        }
                    }
                }
            }
        }
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10, Double(places))
        return (self * factor).rounded() / factor
    }
}

/// Chrome-free recording stage: one big balance that jumps through a sequence.
struct NumberTickerStage: View {
    let autoplay: Bool
    @State private var balance: Double = 2_480

    private let sequence: [Double] = [2_480, 12_906.40, 99.99, 100.05, 48_213.75, 7_350]

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.sm) {
                Text("Balance").ds(.overline, color: DSColors.textSecondary)
                DSNumberTicker(balance, format: .currency(code: "USD").locale(Locale(identifier: "en_US")), style: .displayMedium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.lg)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for value in sequence {
                    guard !Task.isCancelled else { return }
                    await stagePause(1.4)
                    balance = value
                }
                await stagePause(1.4)
            }
        }
    }
}
