import SwiftUI
import VelvetUI

/// A trip for the swipe deck screen and stage.
struct GalleryTrip: Identifiable {
    let id: String
    let country: String
    let nights: Int
    let symbol: String

    static let all = [
        GalleryTrip(id: "Lisbon", country: "Portugal", nights: 3, symbol: "sun.max"),
        GalleryTrip(id: "Kyoto", country: "Japan", nights: 6, symbol: "leaf"),
        GalleryTrip(id: "Oslo", country: "Norway", nights: 4, symbol: "snowflake"),
        GalleryTrip(id: "Cusco", country: "Peru", nights: 5, symbol: "mountain.2"),
        GalleryTrip(id: "Hanoi", country: "Vietnam", nights: 7, symbol: "cup.and.saucer"),
    ]
}

/// One trip on a card: an icon on a tinted tile, the city and the stay. VoiceOver
/// reads "Lisbon, Portugal · 3 nights" (the icon is decorative).
struct GalleryTripCard: View {
    let trip: GalleryTrip
    @DSThemed private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Image(systemName: trip.symbol)
                .font(.largeTitle)
                .foregroundStyle(theme.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.subtleFill, in: RoundedRectangle(cornerRadius: DSRadius.surface, style: .continuous))
                .accessibilityHidden(true)
            Text(trip.id).ds(.title1)
            Text("\(trip.country) · \(trip.nights) nights").ds(.callout, color: theme.palette.textSecondary)
        }
        .padding(DSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A word for the flashcard example.
struct GalleryFlashcard: Identifiable {
    let id: String
}

/// Not a `GalleryScreen`: that one scrolls, and a swipe deck belongs outside a
/// vertical scroll view (the scroll and the drag fight over the same touch).
struct SwipeDeckScreen: View {
    @State private var trips = GalleryTrip.all
    @State private var saved: [String] = []
    @State private var cards = ["bonjour", "merci", "à bientôt", "s'il vous plaît"].map(GalleryFlashcard.init)
    @State private var history: [GalleryFlashcard] = []
    @State private var example = 0

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text("Swipe Deck").ds(.title1)
                Text("Drag the top card past the line or flick it; short of the line it springs back")
                    .ds(.callout, color: DSColors.textSecondary)
            }

            DSSegmentedControl(selection: $example, segments: [
                DSSegment("Trips", value: 0),
                DSSegment("Flashcards", value: 1),
            ])

            if example == 0 { tripsExample } else { flashcardsExample }

            Text("With VoiceOver on, the top card reads its content and the cards left, and both directions are actions: swipe up or down to pick one.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .dsScreenPadding()
        .padding(.vertical, DSSpacing.lg)
        .background(DSColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Swipe Deck")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { AppearanceMenu() } }
    }

    private var tripsExample: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            DSSwipeDeck($trips, leftLabel: "Skip", rightLabel: "Save", onSwipe: { trip, direction in
                if direction == .right { saved.append(trip.id) }
            }) { trip in
                GalleryTripCard(trip: trip)
            }
            .frame(maxHeight: .infinity)
            .overlay {
                if trips.isEmpty {
                    Text("That's every trip").ds(.callout, color: DSColors.textSecondary)
                }
            }
            HStack {
                Text(saved.isEmpty ? "Nothing saved yet" : "Saved: \(saved.joined(separator: ", "))")
                    .ds(.footnote, color: DSColors.textSecondary)
                Spacer()
                DSButton("Start over", variant: .ghost, size: .small) {
                    trips = GalleryTrip.all
                    saved = []
                }
            }
        }
    }

    private var flashcardsExample: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            DSSwipeDeck($cards, leftLabel: "Again", rightLabel: "Got it", haptic: .light, onSwipe: { card, direction in
                history.append(card)
                if direction == .left { cards.append(card) }
            }) { card in
                Text(card.id).ds(.title2).padding(DSSpacing.xl)
            }
            .frame(maxHeight: .infinity)
            .overlay {
                if cards.isEmpty {
                    Text("All done").ds(.callout, color: DSColors.textSecondary)
                }
            }
            HStack {
                Text("\"Again\" sends a card to the back").ds(.footnote, color: DSColors.textSecondary)
                Spacer()
                DSButton("Undo", variant: .ghost, size: .small, icon: "arrow.uturn.backward") {
                    guard let last = history.popLast() else { return }
                    cards.removeAll { $0.id == last.id }
                    cards.insert(last, at: 0)
                }
                .disabled(history.isEmpty)
            }
        }
    }
}

/// Recording stage: five trips with "Skip" / "Save". The top card is one
/// accessibility element whose label starts with the city ("Lisbon, Portugal ·
/// 3 nights") and whose value is the cards left ("5 cards left"). "Tally" reads
/// "0 saved, 0 skipped", and "Start over" refills the deck. The UI test drags and
/// swipes the cards and reads both after each step.
struct SwipeDeckStage: View {
    let autoplay: Bool
    @State private var trips = GalleryTrip.all
    @State private var saved = 0
    @State private var skipped = 0

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            DSSwipeDeck($trips, leftLabel: "Skip", rightLabel: "Save", onSwipe: { _, direction in
                if direction == .right { saved += 1 } else { skipped += 1 }
            }) { trip in
                GalleryTripCard(trip: trip)
            }
            .frame(height: 400)
            .overlay {
                if trips.isEmpty {
                    Text("That's every trip").ds(.callout, color: DSColors.textSecondary)
                }
            }

            HStack {
                Text("Saved \(saved) · Skipped \(skipped)")
                    .ds(.footnote, color: DSColors.textSecondary)
                    .accessibilityLabel("Tally")
                    .accessibilityValue("\(saved) saved, \(skipped) skipped")
                Spacer()
                DSButton("Start over", variant: .ghost, size: .small) { startOver() }
            }
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(1.6)
                if Task.isCancelled { return }
                guard !trips.isEmpty else {
                    startOver()
                    return
                }
                let save = trips.count % 2 == 1
                withAnimation(DSAnimation.springSmooth) { _ = trips.removeFirst() }
                if save { saved += 1 } else { skipped += 1 }
            }
        }
    }

    private func startOver() {
        withAnimation(DSAnimation.springSmooth) {
            trips = GalleryTrip.all
            saved = 0
            skipped = 0
        }
    }
}
