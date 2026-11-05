import SwiftUI
import VelvetUI

private struct Trip: Identifiable {
    let id: Int
    let name: String
    let dates: String
}

struct SheetScreen: View {
    @State private var showShare = false
    @State private var showConfirm = false
    @State private var showCheckout = false
    @State private var selected: Trip?

    private let trips = [
        Trip(id: 1, name: "Lisbon", dates: "12-16 Nov"),
        Trip(id: 2, name: "Kyoto", dates: "3-14 Dec")
    ]

    var body: some View {
        GalleryScreen(title: "Sheet", caption: "Native sheet, Velvet chrome") {
            LabeledExample("Share trip — medium and large") {
                DSButton("Share trip", icon: "square.and.arrow.up") { showShare = true }
            }
            LabeledExample("Confirmation — fixed height") {
                DSButton("Delete trip", variant: .destructive, icon: "trash") { showConfirm = true }
            }
            LabeledExample("Bottom action — concentric with the sheet") {
                DSButton("Checkout", icon: "bag") { showCheckout = true }
            }
            LabeledExample("Item-driven") {
                VStack(spacing: DSSpacing.xs) {
                    ForEach(trips) { trip in
                        DSListCell(title: trip.name, subtitle: trip.dates, trailing: {
                            Image(systemName: "chevron.right")
                        }, action: { selected = trip })
                    }
                }
            }
        }
        .dsSheet(isPresented: $showShare) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Share trip").ds(.title2)
                DSListCell(title: "Copy link", leading: { Image(systemName: "link") })
                DSListCell(title: "Message", leading: { Image(systemName: "message") })
                DSListCell(title: "Add to calendar", leading: { Image(systemName: "calendar") })
                DSListCell(title: "AirDrop", leading: { Image(systemName: "airplayaudio") })
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .dsSheet(isPresented: $showConfirm, detents: [.height(220)]) {
            VStack(spacing: DSSpacing.md) {
                Text("Delete this trip?").ds(.title3)
                DSButton("Delete", variant: .destructive, isFullWidth: true) { showConfirm = false }
                DSButton("Keep it", variant: .ghost) { showConfirm = false }
            }
            .padding(DSSpacing.xl)
        }
        .dsSheet(isPresented: $showCheckout, detents: [.medium]) {
            // On iOS 26+ the button's bottom corners follow the sheet's curve.
            // Concentricity is measured from the sheet's edge, so the button
            // has to sit near it: it ignores the bottom safe area and keeps
            // only the inset. Behind the home indicator it would be too far
            // from the corner and fall back to the 12 pt minimum.
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Order summary").ds(.title2)
                Text("2 items · $48.00").ds(.callout, color: DSColors.textSecondary)
                Spacer()
                DSButton("Pay $48.00", size: .large, isFullWidth: true) { showCheckout = false }
            }
            .padding(DSSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .dsSheet(item: $selected, detents: [.fraction(0.4), .large]) { trip in
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text(trip.name).ds(.title2)
                Text(trip.dates).ds(.callout, color: DSColors.textSecondary)
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

struct SheetStage: View {
    let autoplay: Bool
    @State private var showing = false

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Lisbon").ds(.title2)
                Text("12-16 Nov · 4 travelers").ds(.callout, color: DSColors.textSecondary)
                DSButton("Share trip", icon: "square.and.arrow.up", isFullWidth: true) { showing = true }
            }
        }
        .dsSheet(isPresented: $showing, detents: [.medium]) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Share trip").ds(.title2)
                DSListCell(title: "Copy link", leading: { Image(systemName: "link") })
                DSListCell(title: "Message", leading: { Image(systemName: "message") })
                DSListCell(title: "Add to calendar", leading: { Image(systemName: "calendar") })
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(1.0)
                if Task.isCancelled { return }
                showing = true
                await stagePause(2.0)
                if Task.isCancelled { return }
                showing = false
                await stagePause(1.0)
            }
        }
    }
}
