import SwiftUI
import VelvetUI

private enum ChipMode: String, CaseIterable, Hashable {
    case multiple = "Multiple", single = "Single"
}

private enum ChipSpacing: String, CaseIterable, Hashable {
    case tight = "Tight", normal = "Normal", loose = "Loose"

    var value: CGFloat {
        switch self {
        case .tight: return DSSpacing.xxs
        case .normal: return DSSpacing.xs
        case .loose: return DSSpacing.sm
        }
    }
}

private enum SortOrder: Hashable {
    case trending, newest, topRated, nearby
}

struct ChipScreen: View {
    static let topics = [
        "Design", "Engineering", "Marketing", "Product", "Research",
        "Operations", "Finance", "People", "Legal"
    ]

    private static let mediaItems = [
        DSChipItem("Photos", value: "photos", icon: "photo"),
        DSChipItem("Videos", value: "videos", icon: "video"),
        DSChipItem("Audio", value: "audio", icon: "waveform"),
        DSChipItem("Docs", value: "docs", icon: "doc")
    ]

    // Playground
    @State private var mode = ChipMode.multiple
    @State private var spacing = ChipSpacing.normal
    @State private var showsIcons = false
    @State private var customAccent = false
    @State private var multiple: Set<String> = ["Design", "Product"]
    @State private var single: String? = "Design"

    // Examples
    @State private var sort: SortOrder? = .trending
    @State private var media: Set<String> = ["photos"]
    @State private var isStarred = false
    @State private var tagCount = 2

    var body: some View {
        GalleryScreen(title: "Chip", caption: "Selectable pills that wrap onto new lines") {
            LabeledExample("Playground") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        controls
                        playground
                    }
                }
            }

            LabeledExample("Single selection — tap the selected chip to clear it") {
                DSChipGroup(
                    [
                        DSChipItem("Trending", value: SortOrder.trending),
                        DSChipItem("Newest", value: SortOrder.newest),
                        DSChipItem("Top rated", value: SortOrder.topRated),
                        DSChipItem("Nearby", value: SortOrder.nearby)
                    ],
                    selection: $sort
                )
            }

            LabeledExample("Leading icons") {
                DSChipGroup(Self.mediaItems, selection: $media)
            }

            LabeledExample("Standalone chips") {
                DSFlowLayout {
                    DSChip("Add tag", icon: "plus") { tagCount += 1 }
                    DSChip("Starred", icon: "star", isSelected: isStarred) { isStarred.toggle() }
                    ForEach(0..<tagCount, id: \.self) { index in
                        DSChip("Tag \(index + 1)", isSelected: true) {}
                    }
                }
                .animation(DSAnimation.springSmooth, value: tagCount)
                DSButton("Reset tags", variant: .secondary, size: .small, icon: "arrow.counterclockwise") {
                    withAnimation(DSAnimation.springSmooth) { tagCount = 2 }
                }
            }

            LabeledExample("Disabled") {
                DSChipGroup(["Design", "Engineering", "Product"], selection: .constant(["Design"]))
                    .disabled(true)
            }
        }
    }

    // MARK: - Playground

    private var controls: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Selection").ds(.overline, color: DSColors.textSecondary)
                DSSegmentedControl(
                    selection: $mode,
                    segments: ChipMode.allCases.map { DSSegment($0.rawValue, value: $0) }
                )
            }
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Spacing").ds(.overline, color: DSColors.textSecondary)
                DSSegmentedControl(
                    selection: $spacing,
                    segments: ChipSpacing.allCases.map { DSSegment($0.rawValue, value: $0) }
                )
            }
            DSToggle("Icons", isOn: $showsIcons)
            DSToggle("Custom accent", isOn: $customAccent)
        }
    }

    @ViewBuilder
    private var playground: some View {
        let items = Self.topics.map { DSChipItem($0, value: $0, icon: showsIcons ? Self.icon(for: $0) : nil) }
        let accent: Color? = customAccent ? DSColors.success : nil
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            switch mode {
            case .multiple:
                DSChipGroup(items, selection: $multiple, spacing: spacing.value, accent: accent)
                Text(multiple.isEmpty ? "Nothing selected" : "Selected: " + multiple.sorted().joined(separator: ", "))
                    .ds(.footnote, color: DSColors.textTertiary)
            case .single:
                DSChipGroup(items, selection: $single, spacing: spacing.value, accent: accent)
                Text(single.map { "Selected: " + $0 } ?? "Nothing selected")
                    .ds(.footnote, color: DSColors.textTertiary)
            }
        }
        .animation(DSAnimation.springSmooth, value: spacing)
    }

    private static func icon(for topic: String) -> String {
        switch topic {
        case "Design": return "paintbrush"
        case "Engineering": return "hammer"
        case "Marketing": return "megaphone"
        case "Product": return "shippingbox"
        case "Research": return "magnifyingglass"
        case "Operations": return "gearshape"
        case "Finance": return "dollarsign.circle"
        case "People": return "person.2"
        default: return "building.columns"
        }
    }
}

// MARK: - Stage

struct ChipStage: View {
    let autoplay: Bool

    @State private var topics: Set<String> = ["Design"]
    @State private var sort: String? = "Trending"

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Topics").ds(.overline, color: DSColors.textSecondary)
                    DSChipGroup(ChipScreen.topics, selection: $topics)
                }
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Sort by").ds(.overline, color: DSColors.textSecondary)
                    DSChipGroup(["Trending", "Newest", "Top rated"], selection: $sort)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for topic in ["Product", "Research", "Legal"] {
                    await stagePause(0.8)
                    topics.insert(topic)
                }
                await stagePause(0.8)
                sort = "Newest"
                await stagePause(0.8)
                topics.remove("Design")
                await stagePause(0.8)
                sort = "Top rated"
                await stagePause(1.4)
                topics = ["Design"]
                sort = "Trending"
                await stagePause(0.8)
            }
        }
    }
}
