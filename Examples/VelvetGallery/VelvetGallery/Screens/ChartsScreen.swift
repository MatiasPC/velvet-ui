import SwiftUI
import VelvetUI

private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

private func shuffled(_ values: [Double], in range: ClosedRange<Double>) -> [Double] {
    values.map { _ in Double.random(in: range) }
}

struct ChartsScreen: View {
    @State private var revenue: [Double] = [12, 18, 14, 22, 19, 27, 24, 31, 28, 36]
    @State private var week: [Double] = [12, 18, 9, 22, 15, 6, 11]
    @State private var selected: Int?

    var body: some View {
        GalleryScreen(title: "Charts", caption: "Sparkline and bar chart, no Swift Charts") {
            LabeledExample("Revenue card") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Revenue").ds(.callout, color: DSColors.textSecondary)
                        Text("$\(Int(revenue.last ?? 0))k").ds(.largeTitle)
                        DSSparkline(revenue, accessibilityLabel: "Revenue trend")
                            .frame(height: 72)
                    }
                }
            }

            LabeledExample("Weekly bars — drag to scrub, tap the bar again to clear") {
                DSCard {
                    DSBarChart(week, labels: weekdays, selection: $selected, accessibilityLabel: "Orders this week")
                        .frame(height: 180)
                }
            }

            LabeledExample("Variants") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        DSSparkline(revenue, color: DSColors.success, showsFill: false, showsLastPoint: false)
                            .frame(height: 40)
                        DSBarChart(week, color: DSColors.info)
                            .frame(height: 96)
                    }
                }
            }

            DSButton("Shuffle data", variant: .secondary, isFullWidth: true) {
                revenue = shuffled(revenue, in: 10...40)
                week = shuffled(week, in: 2...30)
            }
        }
    }
}

struct ChartsStage: View {
    let autoplay: Bool
    @State private var trend: [Double] = [12, 18, 14, 22, 19, 27, 24, 31, 28, 36]
    @State private var bars: [Double] = [12, 18, 9, 22, 15, 6, 11]
    @State private var selected: Int?

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text("Revenue").ds(.callout, color: DSColors.textSecondary)
                    Text("$\(Int(trend.last ?? 0))k").ds(.displayMedium)
                }
                DSSparkline(trend, accessibilityLabel: "Revenue trend")
                    .frame(height: 96)
                DSBarChart(bars, labels: weekdays, selection: $selected, accessibilityLabel: "Orders this week")
                    .frame(height: 160)
            }
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(2.0)
                if Task.isCancelled { return }
                trend = shuffled(trend, in: 10...40)
                bars = shuffled(bars, in: 2...30)
                selected = Int.random(in: 0..<bars.count)
            }
        }
    }
}
