import SwiftUI
import DesignSystem

struct SegmentedControlScreen: View {
    @State private var period = "Day"
    @State private var tab = "Overview"
    @State private var mode = "List"

    var body: some View {
        GalleryScreen(title: "Segmented Control", caption: "Pick one") {
            DSCard {
                VStack(spacing: DSSpacing.lg) {
                    LabeledExample("Pill") {
                        DSSegmentedControl(selection: $period, options: ["Day", "Week", "Month"])
                    }
                    LabeledExample("Underline") {
                        DSSegmentedControl(
                            selection: $tab,
                            options: ["Overview", "Details", "Reviews"],
                            style: .underline
                        )
                    }
                    LabeledExample("With icons") {
                        DSSegmentedControl(selection: $mode, segments: [
                            DSSegment("List", value: "List", icon: "list.bullet"),
                            DSSegment("Grid", value: "Grid", icon: "square.grid.2x2"),
                            DSSegment("Map", value: "Map", icon: "map")
                        ])
                    }
                }
            }
        }
    }
}
