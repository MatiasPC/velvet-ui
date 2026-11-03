import SwiftUI
import VelvetUI

/// Shared faces: a stat on the front, its trend on the back. The back is taller, to show
/// that both faces take the larger size.
private struct StatFront: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text("This month").ds(.footnote, color: DSColors.textSecondary)
            Text("1 248").ds(.displayMedium)
            Text("Tap to see the trend").ds(.callout, color: DSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StatBack: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text("vs. last month").ds(.footnote, color: DSColors.textSecondary)
            Text("+12%").ds(.displayMedium)
            Text("Tap to flip back").ds(.callout, color: DSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FlipCardScreen: View {
    private static let axes = ["Horizontal", "Vertical"]
    private static let styles = ["Elevated", "Outlined", "Flat"]

    @State private var axisLabel = "Horizontal"
    @State private var styleLabel = "Elevated"
    @State private var hasHaptic = true
    @State private var revealed = false
    @State private var taps = 0

    private var axis: DSFlipAxis { axisLabel == "Vertical" ? .vertical : .horizontal }

    private var style: DSCardStyle {
        switch styleLabel {
        case "Outlined": return .outlined
        case "Flat": return .flat
        default: return .elevated
        }
    }

    var body: some View {
        GalleryScreen(title: "Flip Card", caption: "Two-sided glass that turns over in 3D") {
            LabeledExample("Default — tap the card") {
                DSFlipCard { StatFront() } back: { StatBack() }
            }

            LabeledExample("Playground") {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    DSFlipCard(axis: axis, style: style, haptic: hasHaptic ? .rigid : nil) {
                        StatFront()
                    } back: {
                        StatBack()
                    }
                    Text("Axis").ds(.caption1, color: DSColors.textTertiary)
                    DSSegmentedControl(selection: $axisLabel, options: Self.axes)
                    Text("Style").ds(.caption1, color: DSColors.textTertiary)
                    DSSegmentedControl(selection: $styleLabel, options: Self.styles)
                    DSToggle("Haptic on the turn", isOn: $hasHaptic)
                }
            }

            LabeledExample("Driven from a binding") {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    DSFlipCard(isFlipped: $revealed, axis: .vertical) {
                        Text("•••• 4242").ds(.numeric)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } back: {
                        Text("CVC 123 · 09/28").ds(.numeric)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    DSButton(revealed ? "Hide details" : "Show details", variant: .secondary, size: .small) {
                        revealed.toggle()
                    }
                }
            }

            LabeledExample("Controls on a face — flipOnTap: false") {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    DSFlipCard(isFlipped: $revealed, flipOnTap: false, haptic: nil) {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Front").ds(.title3)
                            DSButton("Count a tap (\(taps))", size: .small) { taps += 1 }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } back: {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Back").ds(.title3)
                            DSButton("Count a tap (\(taps))", size: .small) { taps += 1 }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("Taps reach the buttons on whichever face shows; the card turns only from the binding (the button above).")
                        .ds(.caption1, color: DSColors.textTertiary)
                }
            }

            Text("Under Reduce Motion the card does not turn; the faces crossfade.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Chrome-free recording stage: autoplay turns the card over every ~1.8 s.
struct FlipCardStage: View {
    let autoplay: Bool
    @State private var flipped = false

    var body: some View {
        DSFlipCard(isFlipped: $flipped) {
            StatFront()
        } back: {
            StatBack()
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(1.8)
                flipped.toggle()
            }
        }
    }
}
