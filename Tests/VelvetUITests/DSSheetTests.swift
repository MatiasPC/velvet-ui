import XCTest
import SwiftUI
@testable import VelvetUI

// Every snippet on docs/components/DSSheet.md lives here verbatim (variants are
// wrapped in a host view so the modifier chain is type-checked).
enum DocSnippetsSheet {
    struct SheetDemo: View {
        @State private var showShare = false

        var body: some View {
            DSScreen(backdrop: true) {
                DSButton("Share trip", icon: "square.and.arrow.up") { showShare = true }
                    .dsScreenPadding()
            }
            .dsSheet(isPresented: $showShare) {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Share trip").ds(.title2)
                    DSListCell(title: "Copy link", leading: { Image(systemName: "link") })
                    DSListCell(title: "Message", leading: { Image(systemName: "message") })
                }
                .padding(DSSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    struct Trip: Identifiable { let id = 1; let name = "Lisbon" }
    struct PlacesList: View { var body: some View { Text("Places") } }

    struct SheetVariantsDemo: View {
        @State private var confirming = false
        @State private var showPlaces = false
        @State private var selectedTrip: Trip?

        var body: some View {
            Color.clear
                .dsSheet(isPresented: $confirming, detents: [.height(220)]) {
                    VStack(spacing: DSSpacing.md) {
                        Text("Delete this trip?").ds(.title3)
                        DSButton("Delete", variant: .destructive, isFullWidth: true) { confirming = false }
                    }
                    .padding(DSSpacing.xl)
                }
                .dsSheet(isPresented: $showPlaces, detents: [.height(160), .medium, .large]) {
                    PlacesList()
                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                        .interactiveDismissDisabled()
                }
                .dsSheet(item: $selectedTrip) { trip in
                    Text(trip.name).ds(.title2).padding(DSSpacing.xl)
                }
        }
    }
}

@MainActor
final class DSSheetTests: XCTestCase {
    func testSnippetsInstantiate() {
        _ = DocSnippetsSheet.SheetDemo().body
        _ = DocSnippetsSheet.SheetVariantsDemo().body
    }
}
