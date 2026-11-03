import SwiftUI
import VelvetUI

private enum MarqueeContent: String, CaseIterable, Hashable {
    case text = "Text", mixed = "Badge + text", short = "Fits"
}

private enum MarqueeWidth: String, CaseIterable, Hashable {
    case full = "Full", narrow = "180 pt"

    var maxWidth: CGFloat { self == .full ? .infinity : 180 }
}

struct MarqueeScreen: View {
    @State private var content = MarqueeContent.text
    @State private var width = MarqueeWidth.full
    @State private var velocity = 40
    @State private var spacing = 40
    @State private var hardEdges = false

    var body: some View {
        GalleryScreen(title: "Marquee", caption: "Scrolls only when the content overflows") {
            LabeledExample("Playground") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        controls
                        DSMarquee(
                            velocity: CGFloat(velocity),
                            spacing: CGFloat(spacing),
                            fade: hardEdges ? 0 : DSSpacing.lg
                        ) {
                            playgroundContent
                        }
                        .frame(maxWidth: width.maxWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            LabeledExample("Overflowing text") {
                DSCard {
                    DSMarquee {
                        Text("Now playing — Midnight City · M83 · Hurry Up, We're Dreaming").ds(.callout)
                    }
                }
            }

            LabeledExample("Fits — stays put") {
                DSCard {
                    DSMarquee { Text("Short label").ds(.callout) }
                }
            }

            LabeledExample("A row of stats") {
                DSMarquee(spacing: DSSpacing.xxl) {
                    HStack(spacing: DSSpacing.xxl) {
                        stat("Steps", "8,420")
                        stat("Calories", "612 kcal")
                        stat("Distance", "6.1 km")
                        stat("Active", "1 h 12 m")
                    }
                }
                Text("With Reduce Motion on, the line rests from its start with a trailing fade. It also stops ticking whenever it is off screen.")
                    .ds(.footnote, color: DSColors.textTertiary)
            }
        }
    }

    @ViewBuilder
    private var playgroundContent: some View {
        switch content {
        case .text:
            Text("Midnight City · M83 · Hurry Up, We're Dreaming").ds(.callout)
        case .mixed:
            HStack(spacing: DSSpacing.xs) {
                DSBadge("LIVE", color: DSColors.error, variant: .filled)
                Text("Breaking: a seamless marquee with soft edge fades").ds(.footnote)
            }
        case .short:
            Text("Short label").ds(.callout)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Content").ds(.overline, color: DSColors.textSecondary)
                DSSegmentedControl(
                    selection: $content,
                    segments: MarqueeContent.allCases.map { DSSegment($0.rawValue, value: $0) }
                )
            }
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Container width").ds(.overline, color: DSColors.textSecondary)
                DSSegmentedControl(
                    selection: $width,
                    segments: MarqueeWidth.allCases.map { DSSegment($0.rawValue, value: $0) }
                )
            }
            stepperRow("Velocity (pt/s, 0 = off)", value: $velocity, range: 0...120, step: 20)
            stepperRow("Gap between copies", value: $spacing, range: 0...80, step: 20)
            DSToggle("Hard edges (no fade)", isOn: $hardEdges)
        }
    }

    private func stepperRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        HStack {
            Text(title).ds(.body)
            Spacer()
            DSStepper(value: value, in: range, step: step)
                .accessibilityLabel(title)
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        HStack(spacing: DSSpacing.xs) {
            Text(title).ds(.caption1, color: DSColors.textSecondary)
            Text(value).ds(.numeric)
        }
    }
}

// MARK: - Stage

struct MarqueeStage: View {
    let autoplay: Bool

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Now playing").ds(.overline, color: DSColors.textSecondary)
                DSMarquee(velocity: autoplay ? DSMarquee<Text>.defaultVelocity : 0) {
                    Text("Midnight City · M83 · Hurry Up, We're Dreaming").ds(.title3)
                }
                DSMarquee(velocity: autoplay ? 28 : 0) {
                    HStack(spacing: DSSpacing.xs) {
                        DSBadge("LIVE", color: DSColors.error, variant: .filled)
                        Text("Breaking: Velvet UI ships a seamless marquee").ds(.footnote)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
