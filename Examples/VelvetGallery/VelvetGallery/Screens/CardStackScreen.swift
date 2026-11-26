import SwiftUI
import VelvetUI

/// An update about one order, for the card stack screen and stage.
struct GalleryOrderUpdate: Identifiable {
    let id: String
    let detail: String
    let symbol: String

    static let all = [
        GalleryOrderUpdate(id: "Your order shipped", detail: "Arrives Thursday", symbol: "shippingbox"),
        GalleryOrderUpdate(id: "Out for delivery", detail: "Driver is 4 stops away", symbol: "box.truck"),
        GalleryOrderUpdate(id: "Delivered", detail: "Left at the front door", symbol: "house"),
        GalleryOrderUpdate(id: "Rate your order", detail: "Tell us how it went", symbol: "star"),
    ]
}

/// One update on a card: an icon on a tinted tile, the title and the detail.
/// VoiceOver reads the title and the detail (the icon is decorative).
struct GalleryOrderUpdateRow: View {
    let update: GalleryOrderUpdate
    @DSThemed private var theme

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: update.symbol)
                .font(.title3)
                .foregroundStyle(theme.ink)
                .frame(width: DSSpacing.huge, height: DSSpacing.huge)
                .background(theme.subtleFill, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DSSpacing.xxxs) {
                Text(update.id).ds(.body)
                Text(update.detail).ds(.footnote, color: theme.palette.textSecondary)
            }
        }
    }
}

/// A boarding pass for the second example.
private struct GalleryPass: Identifiable {
    let id: String
    let gate: String
}

struct CardStackScreen: View {
    @State private var showUpdates = false
    @State private var showPasses = false

    private let passes = [
        GalleryPass(id: "LIS → AMS", gate: "Gate 14"),
        GalleryPass(id: "AMS → OSL", gate: "Gate D7"),
        GalleryPass(id: "OSL → LIS", gate: "Gate 22"),
    ]

    var body: some View {
        GalleryScreen(title: "Card Stack", caption: "Related cards in a pile; tap it and they fan out into a column") {
            LabeledExample("Grouped updates, with Show less") {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    HStack {
                        Text("Orders").ds(.title3)
                        Spacer()
                        if showUpdates {
                            DSButton("Show less", variant: .ghost, size: .small) { showUpdates = false }
                        }
                    }
                    DSCardStack(GalleryOrderUpdate.all, isExpanded: $showUpdates, accessibilityLabel: "Order updates") { update in
                        GalleryOrderUpdateRow(update: update)
                    }
                    Text("Content below the stack moves with it")
                        .ds(.footnote, color: DSColors.textSecondary)
                }
            }

            LabeledExample("Boarding passes, medium haptic") {
                VStack(spacing: DSSpacing.md) {
                    DSCardStack(passes, isExpanded: $showPasses, haptic: .medium, accessibilityLabel: "Boarding passes") { pass in
                        HStack {
                            Text(pass.id).ds(.title3)
                            Spacer()
                            Text(pass.gate).ds(.callout, color: DSColors.textSecondary)
                        }
                    }
                    if showPasses {
                        DSButton("Done", variant: .secondary, isFullWidth: true) { showPasses = false }
                    }
                }
            }

            Text("With VoiceOver on, the collapsed pile is one button (\"Order updates, 4 cards, collapsed\"); double-tap to expand it, then every card is read on its own.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Recording stage: four order updates in a pile named "Order updates" (value
/// "4 cards, collapsed"), a "Show less" button while it's expanded, and a
/// "Stack state" read-out ("Collapsed" / "Expanded"). The UI test taps the pile,
/// checks the cards are read one by one, then collapses it with "Show less".
struct CardStackStage: View {
    let autoplay: Bool
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack {
                Text("Orders").ds(.title2)
                Spacer()
                if isExpanded {
                    DSButton("Show less", variant: .ghost, size: .small) { isExpanded = false }
                }
            }
            DSCardStack(GalleryOrderUpdate.all, isExpanded: $isExpanded, accessibilityLabel: "Order updates") { update in
                GalleryOrderUpdateRow(update: update)
            }
            Text(isExpanded ? "Showing all 4 updates" : "Tap the pile to see all 4 updates")
                .ds(.footnote, color: DSColors.textSecondary)
                .accessibilityLabel("Stack state")
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(2.2)
                if Task.isCancelled { return }
                isExpanded.toggle()
            }
        }
    }
}
