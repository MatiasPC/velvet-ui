import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSSwipeDeck.md lives here
// verbatim, so a drifting API breaks the build instead of the docs.
enum DocSnippetsSwipeDeck {
    struct Recipe: Identifiable {
        let id: String
        let minutes: Int
    }

    struct RecipePicker: View {
        @State private var recipes = [
            Recipe(id: "Shakshuka", minutes: 25),
            Recipe(id: "Pad thai", minutes: 30),
            Recipe(id: "Risotto", minutes: 40),
        ]
        @State private var saved: [Recipe] = []

        var body: some View {
            DSSwipeDeck($recipes, leftLabel: "Skip", rightLabel: "Save", onSwipe: { recipe, direction in
                if direction == .right { saved.append(recipe) }
            }) { recipe in
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Spacer()
                    Text(recipe.id).ds(.title1)
                    Text("\(recipe.minutes) min").ds(.callout)
                }
                .padding(DSSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .aspectRatio(3 / 4, contentMode: .fit)
            .dsScreenPadding()
        }
    }

    struct Flashcard: Identifiable {
        let id: String
    }

    struct FlashcardReview: View {
        @State private var deck = ["bonjour", "merci", "à bientôt"].map(Flashcard.init)
        @State private var history: [Flashcard] = []

        var body: some View {
            VStack(spacing: DSSpacing.lg) {
                DSSwipeDeck($deck, leftLabel: "Again", rightLabel: "Got it", haptic: .light, onSwipe: { card, direction in
                    history.append(card)
                    if direction == .left { deck.append(card) }   // see it again at the end
                }) { card in
                    Text(card.id)
                        .ds(.title2)
                        .padding(DSSpacing.xl)
                }
                .aspectRatio(4 / 3, contentMode: .fit)

                DSButton("Undo", variant: .ghost, icon: "arrow.uturn.backward") {
                    guard let last = history.popLast() else { return }
                    deck.removeAll { $0.id == last.id }
                    deck.insert(last, at: 0)
                }
                .disabled(history.isEmpty)
            }
            .dsScreenPadding()
        }
    }
}

@MainActor
final class DSSwipeDeckTests: XCTestCase {
    typealias L = DSSwipeDeckLogic

    private struct Card: Identifiable {
        let id: Int
    }

    func testBodiesBuild() {
        _ = DocSnippetsSwipeDeck.RecipePicker().body
        _ = DocSnippetsSwipeDeck.FlashcardReview().body
        _ = DSSwipeDeck(.constant([Card(id: 1), Card(id: 2)])) { card in Text("\(card.id)") }.body
        _ = DSSwipeDeck(.constant([Card]()), leftLabel: "Keep", rightLabel: "Archive", haptic: .rigid,
                        onSwipe: { _, _ in }) { card in Text("\(card.id)") }.body
    }

    func testDirectionsArePhysical() {
        XCTAssertEqual(DSSwipeDirection.allCases, [.left, .right])
        XCTAssertEqual(L.direction(of: 5), .right)
        XCTAssertEqual(L.direction(of: -5), .left)
        XCTAssertNil(L.direction(of: 0))
        XCTAssertNil(L.direction(of: .nan))
    }

    // MARK: Stack

    func testAtMostThreeCardsAreDrawn() {
        XCTAssertEqual(L.visibleCount(0), 0)
        XCTAssertEqual(L.visibleCount(1), 1)
        XCTAssertEqual(L.visibleCount(3), 3)
        XCTAssertEqual(L.visibleCount(40), 3)
        XCTAssertEqual(L.visibleCount(-2), 0)
    }

    func testCardsBehindStepBackAndDown() {
        XCTAssertEqual(L.scale(depth: 0), 1, accuracy: 0.0001)
        XCTAssertEqual(L.scale(depth: 1), 0.95, accuracy: 0.0001)
        XCTAssertEqual(L.scale(depth: 2), 0.9, accuracy: 0.0001)
        XCTAssertEqual(L.offset(depth: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(L.offset(depth: 1), DSSpacing.sm, accuracy: 0.0001)
        XCTAssertEqual(L.offset(depth: 2), DSSpacing.sm * 2, accuracy: 0.0001)
        XCTAssertEqual(L.stackRoom, DSSpacing.sm * 2, accuracy: 0.0001, "Room for the two fanned edges.")
    }

    func testTheNextCardMovesForwardAsTheTopCardNearsTheLine() {
        XCTAssertEqual(L.depth(index: 0, progress: 0.7), 0, accuracy: 0.0001, "The top card stays in front.")
        XCTAssertEqual(L.depth(index: 1, progress: 0), 1, accuracy: 0.0001)
        XCTAssertEqual(L.depth(index: 1, progress: 0.5), 0.5, accuracy: 0.0001)
        XCTAssertEqual(L.depth(index: 1, progress: -0.5), 0.5, accuracy: 0.0001, "Either direction.")
        XCTAssertEqual(L.depth(index: 1, progress: 1), 0, accuracy: 0.0001, "In place on the line, so nothing jumps.")
        XCTAssertEqual(L.depth(index: 2, progress: 1), 1, accuracy: 0.0001)
        XCTAssertEqual(L.depth(index: 2, progress: 3), 1, accuracy: 0.0001, "Never more than one step.")
    }

    // MARK: Drag

    func testProgressReachesOneOnTheCommitLine() {
        // 300 pt wide: the line is at 120 pt.
        XCTAssertEqual(L.progress(translation: 0, width: 300), 0, accuracy: 0.0001)
        XCTAssertEqual(L.progress(translation: 60, width: 300), 0.5, accuracy: 0.0001)
        XCTAssertEqual(L.progress(translation: -120, width: 300), -1, accuracy: 0.0001)
        XCTAssertEqual(L.progress(translation: 500, width: 300), 1, accuracy: 0.0001)
        XCTAssertEqual(L.progress(translation: 80, width: 0), 0, accuracy: 0.0001, "Not measured yet.")
        XCTAssertEqual(L.progress(translation: .infinity, width: 300), 0, accuracy: 0.0001)
    }

    func testArmedOnTheLineInBothDirections() {
        XCTAssertFalse(L.isArmed(translation: 119, width: 300))
        XCTAssertTrue(L.isArmed(translation: 121, width: 300))
        XCTAssertTrue(L.isArmed(translation: -130, width: 300))
        XCTAssertFalse(L.isArmed(translation: -20, width: 300))
    }

    func testLeanFollowsTheCardOutToTwelveDegrees() {
        XCTAssertEqual(L.lean(translation: 0, width: 300), 0, accuracy: 0.0001)
        XCTAssertEqual(L.lean(translation: 150, width: 300), 6, accuracy: 0.0001)
        XCTAssertEqual(L.lean(translation: -300, width: 300), -12, accuracy: 0.0001)
        XCTAssertEqual(L.lean(translation: 900, width: 300), 12, accuracy: 0.0001, "Clamped.")
        XCTAssertEqual(L.lean(translation: 50, width: 0), 0, accuracy: 0.0001)
    }

    // MARK: Letting go

    func testPastTheLineCommitsThatWay() {
        XCTAssertEqual(L.decision(translation: 130, predicted: 130, width: 300), .right)
        XCTAssertEqual(L.decision(translation: -150, predicted: -150, width: 300), .left)
        XCTAssertEqual(L.decision(translation: 125, predicted: 40, width: 300), .right,
                       "Past the line, a slowing finger still commits.")
    }

    func testShortOfTheLineSpringsBack() {
        XCTAssertNil(L.decision(translation: 100, predicted: 200, width: 300))
        XCTAssertNil(L.decision(translation: 0, predicted: 0, width: 300))
        XCTAssertNil(L.decision(translation: 200, predicted: 200, width: 0), "Not measured yet.")
    }

    func testAFlickCommitsShortOfTheLine() {
        XCTAssertEqual(L.decision(translation: 60, predicted: 400, width: 300), .right)
        XCTAssertEqual(L.decision(translation: -40, predicted: -320, width: 300), .left)
    }

    func testAFlickNeedsTheCardToHaveMovedThatWay() {
        XCTAssertNil(L.decision(translation: 20, predicted: 400, width: 300), "A tap with a twitch never throws a card.")
        XCTAssertNil(L.decision(translation: 60, predicted: -400, width: 300), "A flick back the other way.")
        XCTAssertNil(L.decision(translation: 60, predicted: .infinity, width: 300))
    }

    func testALeavingCardEndsWellPastTheEdge() {
        XCTAssertEqual(L.exitOffset(.right, width: 300), 480, accuracy: 0.0001)
        XCTAssertEqual(L.exitOffset(.left, width: 300), -480, accuracy: 0.0001)
        XCTAssertGreaterThan(L.exitOffset(.right, width: 0), 0, "Still leaves before the deck is measured.")
    }

    // MARK: VoiceOver

    func testSpokenValueAndAnnouncement() {
        XCTAssertEqual(L.accessibilityValue(remaining: 1), "1 card left")
        XCTAssertEqual(L.accessibilityValue(remaining: 4), "4 cards left")
        XCTAssertEqual(L.accessibilityValue(remaining: -1), "0 cards left")
        XCTAssertEqual(L.announcement(label: "Like", remaining: 2), "Like. 2 cards left")
        XCTAssertEqual(L.announcement(label: "Save", remaining: 1), "Save. 1 card left")
        XCTAssertEqual(L.announcement(label: "Pass", remaining: 0), "Pass. No cards left")
    }
}
