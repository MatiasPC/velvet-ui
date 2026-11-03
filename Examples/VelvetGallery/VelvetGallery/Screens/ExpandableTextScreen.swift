import SwiftUI
import VelvetUI

private let shortCopy = "A short note that fits on two lines, so nothing is clipped."

private let mediumCopy = "Velvet UI is a small, opinionated SwiftUI library: frosted glass over a gradient theme, spring motion on everything you touch, and haptics that make the interface feel alive."

private let longCopy = "Velvet UI is a small, opinionated SwiftUI library: frosted glass over a gradient theme, spring motion on everything you touch, and haptics that make the interface feel alive. Every component honors Reduce Motion, Reduce Transparency and Dynamic Type out of the box, so you spend your time on the app and not on the plumbing underneath it. Install it as a Swift package or copy a single component into your project with the CLI."

struct ExpandableTextScreen: View {
    @State private var length = "Long"
    @State private var lineLimit = 3

    private var copy: String {
        switch length {
        case "Short":  return shortCopy
        case "Medium": return mediumCopy
        default:       return longCopy
        }
    }

    var body: some View {
        GalleryScreen(title: "Expandable Text", caption: "Long copy that springs open") {
            LabeledExample("Default: three lines, tap Show more") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("About").ds(.title3)
                        DSExpandableText(longCopy)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LabeledExample("Live: copy length and line limit") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        DSSegmentedControl(selection: $length, options: ["Short", "Medium", "Long"])
                        HStack {
                            Text("Line limit").ds(.body)
                            Spacer()
                            DSStepper(value: $lineLimit, in: 1...6)
                                .accessibilityLabel("Line limit")
                        }
                        DSExpandableText(copy, lineLimit: lineLimit)
                        Text("The toggle only appears while the copy is clipped. Shorten the copy or raise the limit and it goes away.")
                            .ds(.caption1, color: DSColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LabeledExample("Two lines, custom labels, callout style") {
                DSCard {
                    DSExpandableText(
                        longCopy,
                        lineLimit: 2,
                        expandLabel: "Read more",
                        collapseLabel: "Read less",
                        style: .callout,
                        color: DSColors.textSecondary
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LabeledExample("Short copy: no toggle") {
                DSCard {
                    DSExpandableText(shortCopy)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LabeledExample("Two in a column: the one below slides") {
                VStack(spacing: DSSpacing.md) {
                    DSCard {
                        DSExpandableText(mediumCopy, lineLimit: 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    DSCard {
                        DSExpandableText(longCopy, lineLimit: 2, haptic: .soft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Text("Under Reduce Motion the reveal is instant. VoiceOver reads the full copy while it is clipped, and the toggle announces Collapsed or Expanded.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Chrome-free recording stage: one long paragraph, three lines, tap Show more.
struct ExpandableTextStage: View {
    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("About").ds(.title3)
                DSExpandableText(longCopy)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
