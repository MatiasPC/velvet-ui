import SwiftUI
import VelvetUI

/// The pill the Flow Layout examples fill their rows with. `DSFlowLayout` only
/// positions; what goes inside it is up to the app.
struct FlowDemoChip: View {
    let label: String
    var icon: String? = nil
    var isSelected = false
    let action: () -> Void

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var foreground: Color { isSelected ? theme.onAccent : theme.ink }

    var body: some View {
        Button {
            dsHaptic(.selection)
            withAnimation(reduceMotion ? nil : DSAnimation.springSnappy) { action() }
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(foreground)
                }
                Text(label).ds(.buttonSmall, color: foreground)
            }
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background(isSelected ? theme.accent : theme.subtleFill, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(FlowDemoChipStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct FlowDemoChipStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DSPress.scale : 1)
            .animation(DSPress.animation, value: configuration.isPressed)
    }
}

private enum FlowAlignment: String, CaseIterable, Hashable {
    case leading = "Leading", center = "Center", trailing = "Trailing"

    var alignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

private enum FlowWidth: String, CaseIterable, Hashable {
    case full = "Full", medium = "260", narrow = "180"

    var maxWidth: CGFloat {
        switch self {
        case .full: return .infinity
        case .medium: return 260
        case .narrow: return 180
        }
    }
}

struct FlowLayoutScreen: View {
    static let interests = [
        "Design", "SwiftUI", "Motion", "Accessibility", "Haptics",
        "Typography", "Color", "Prototyping", "Research", "iOS", "Glass"
    ]
    static let tags = ["weekend", "lisbon", "two guests", "river view", "3 nights", "balcony", "late checkout"]

    @State private var selected: Set<String> = ["SwiftUI", "Motion", "Haptics"]
    @State private var tags = FlowLayoutScreen.tags

    @State private var alignment = FlowAlignment.leading
    @State private var width = FlowWidth.full
    @State private var spacing = 8
    @State private var lineSpacing = 8
    @State private var count = 12
    @State private var rightToLeft = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let words = [
        "Design", "Code", "Ship", "SwiftUI", "Glass", "Gradient", "Haptics", "Motion",
        "Type", "Color", "Spacing", "Radius", "Springs", "Tokens", "Themes", "Cards"
    ]

    var body: some View {
        GalleryScreen(title: "Flow Layout", caption: "Wraps to new rows, reflows with a spring") {
            LabeledExample("Filter chips — tap to toggle") {
                DSFlowLayout {
                    ForEach(Self.interests, id: \.self) { interest in
                        FlowDemoChip(
                            label: interest,
                            icon: selected.contains(interest) ? "checkmark" : nil,
                            isSelected: selected.contains(interest)
                        ) {
                            if selected.contains(interest) { selected.remove(interest) } else { selected.insert(interest) }
                        }
                    }
                }
                .animation(reduceMotion ? nil : DSAnimation.springSnappy, value: selected)
            }

            LabeledExample("Tap a tag to remove it") {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    DSFlowLayout {
                        ForEach(tags, id: \.self) { tag in
                            FlowDemoChip(label: tag, icon: "xmark") { tags.removeAll { $0 == tag } }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: DSSpacing.xxxl, alignment: .topLeading)
                    DSButton("Reset", variant: .secondary, size: .small, icon: "arrow.counterclockwise") {
                        withAnimation(reduceMotion ? nil : DSAnimation.springSmooth) { tags = Self.tags }
                    }
                }
            }

            LabeledExample("Playground") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        controls
                        playground
                    }
                }
            }

            LabeledExample("A label wider than the container") {
                DSFlowLayout {
                    FlowDemoChip(label: "Short") {}
                    FlowDemoChip(label: "A label far too long to fit on one row, so it gets a row to itself and wraps") {}
                    FlowDemoChip(label: "Next") {}
                    FlowDemoChip(label: "One more") {}
                }
                Text("An over-wide item is measured again at the container width, so it wraps instead of running off the screen.")
                    .ds(.footnote, color: DSColors.textTertiary)
            }

            LabeledExample("Centred in a card") {
                DSCard {
                    DSFlowLayout(alignment: .center) {
                        ForEach(["XS", "Small", "Medium", "Large", "XL", "XXL", "One size"], id: \.self) { size in
                            FlowDemoChip(label: size) {}
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Playground

    private var controls: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Alignment").ds(.overline, color: DSColors.textSecondary)
                DSSegmentedControl(
                    selection: $alignment,
                    segments: FlowAlignment.allCases.map { DSSegment($0.rawValue, value: $0) }
                )
            }
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Container width").ds(.overline, color: DSColors.textSecondary)
                DSSegmentedControl(
                    selection: $width,
                    segments: FlowWidth.allCases.map { DSSegment($0 == .full ? "Full" : "\($0.rawValue) pt", value: $0) }
                )
            }
            stepperRow("Spacing", value: $spacing, range: 0...24, step: 4)
            stepperRow("Line spacing", value: $lineSpacing, range: 0...24, step: 4)
            stepperRow("Items", value: $count, range: 1...words.count, step: 1)
            DSToggle("Right-to-left", isOn: $rightToLeft)
        }
    }

    private var playground: some View {
        DSFlowLayout(
            spacing: CGFloat(spacing),
            lineSpacing: CGFloat(lineSpacing),
            alignment: alignment.alignment
        ) {
            ForEach(words.prefix(count), id: \.self) { word in
                FlowDemoChip(label: word) {}
            }
        }
        .environment(\.layoutDirection, rightToLeft ? .rightToLeft : .leftToRight)
        .animation(reduceMotion ? nil : DSAnimation.springSmooth, value: count)
        .animation(reduceMotion ? nil : DSAnimation.springSmooth, value: spacing)
        .animation(reduceMotion ? nil : DSAnimation.springSmooth, value: lineSpacing)
        .animation(reduceMotion ? nil : DSAnimation.springSmooth, value: alignment)
        .animation(reduceMotion ? nil : DSAnimation.springSmooth, value: width)
        .padding(DSSpacing.sm)
        .background(DSColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: DSRadius.surface, style: .continuous))
        .frame(maxWidth: width.maxWidth)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stepperRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        HStack {
            Text(title).ds(.body)
            Spacer()
            DSStepper(value: value, in: range, step: step)
                .accessibilityLabel(title)
        }
    }
}

// MARK: - Stage

struct FlowLayoutStage: View {
    let autoplay: Bool

    @State private var selected: Set<String> = ["SwiftUI", "Motion"]
    @State private var interests = FlowLayoutScreen.interests
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Pick your interests").ds(.title3)
                DSFlowLayout {
                    ForEach(interests, id: \.self) { interest in
                        FlowDemoChip(
                            label: interest,
                            icon: selected.contains(interest) ? "checkmark" : nil,
                            isSelected: selected.contains(interest)
                        ) {
                            if selected.contains(interest) { selected.remove(interest) } else { selected.insert(interest) }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            let animation: Animation? = reduceMotion ? nil : DSAnimation.springSmooth
            await stageLoop {
                // Selecting a chip grows it (the check appears), so the rows reflow.
                for interest in ["Haptics", "Accessibility", "Typography"] {
                    await stagePause(0.8)
                    withAnimation(animation) { _ = selected.insert(interest) }
                }
                await stagePause(1.0)
                // Dropping items closes the gaps, adding them back reopens them.
                withAnimation(animation) { interests.removeAll { ["Research", "Prototyping", "Color"].contains($0) } }
                await stagePause(1.4)
                withAnimation(animation) { interests = FlowLayoutScreen.interests }
                await stagePause(1.4)
                withAnimation(animation) { selected = ["SwiftUI", "Motion"] }
                await stagePause(0.8)
            }
        }
    }
}
