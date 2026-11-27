import XCTest
import SwiftUI
@testable import VelvetUI

// The docs page's snippet (`TypewriterDemo`) already lives verbatim in
// `DocSnippetsDisplay`, so this file pins the stepping rules only.
@MainActor
final class DSTypewriterTextTests: XCTestCase {
    private typealias L = DSTypewriterTextLogic
    private typealias State = DSTypewriterTextLogic.State

    private func script(
        _ phrases: [String],
        typing: TimeInterval = 0.1,
        erasing: TimeInterval = 0.05,
        hold: TimeInterval = 1,
        loops: Bool = true,
        reduceMotion: Bool = false
    ) -> L.Script {
        L.Script(
            phrases: phrases,
            typingSpeed: typing,
            erasingSpeed: erasing,
            holdDuration: hold,
            loops: loops,
            reduceMotion: reduceMotion
        )
    }

    /// Plays the script from its start for at most `limit` steps.
    private func play(_ script: L.Script, limit: Int = 200) -> [L.Step] {
        var steps: [L.Step] = []
        var state = script.start
        while steps.count < limit, let step = script.step(after: state) {
            steps.append(step)
            state = step.state
        }
        return steps
    }

    private func visible(_ script: L.Script, _ state: State) -> String {
        L.visibleText(of: script.phrases[state.phraseIndex], count: state.characterCount)
    }

    // MARK: Visible text

    func testVisibleTextCountsGraphemesNotBytes() {
        XCTAssertEqual(L.visibleText(of: "Hello", count: 2), "He")
        XCTAssertEqual(L.visibleText(of: "café 👩‍👩‍👧 ok", count: 4), "café")
        XCTAssertEqual(L.visibleText(of: "café 👩‍👩‍👧 ok", count: 6), "café 👩‍👩‍👧", "The family emoji is one character.")
        XCTAssertEqual(L.visibleText(of: "🇪🇸🇦🇷", count: 1), "🇪🇸", "A flag is never split into its regional letters.")
    }

    func testVisibleTextClampsTheCount() {
        XCTAssertEqual(L.visibleText(of: "Hi", count: -3), "")
        XCTAssertEqual(L.visibleText(of: "Hi", count: 0), "")
        XCTAssertEqual(L.visibleText(of: "Hi", count: 9), "Hi")
        XCTAssertEqual(L.visibleText(of: "", count: 4), "")
    }

    // MARK: Delays

    func testDelaysAreAlwaysSleepable() {
        XCTAssertEqual(L.delay(0.06), 0.06)
        XCTAssertEqual(L.delay(0), 0)
        XCTAssertEqual(L.delay(-2), 0, "A negative duration doesn't wait.")
        XCTAssertEqual(L.delay(.nan), 0, "NaN would trap converting to nanoseconds.")
        XCTAssertEqual(L.delay(1e300), L.maximumDelay, "A huge duration would overflow UInt64 nanoseconds.")
        XCTAssertNil(L.delay(.infinity), "Infinity means never: the script stops where it is.")
        XCTAssertLessThan(L.maximumDelay * 1_000_000_000, Double(UInt64.max))
    }

    // MARK: Typing cycle

    func testItStartsEmptyAndTypesOneCharacterPerStep() {
        let s = script(["Hey"], typing: 0.1)
        XCTAssertEqual(s.start, State(phraseIndex: 0, characterCount: 0, phase: .typing))

        let steps = play(s, limit: 3)
        XCTAssertEqual(steps.map(\.state.characterCount), [1, 2, 3])
        XCTAssertEqual(steps.map(\.delay), [0.1, 0.1, 0.1])
        XCTAssertEqual(visible(s, steps[1].state), "He")
    }

    func testAFullCycleTypesHoldsErasesThenMovesOn() {
        let s = script(["Hi", "Yo"], typing: 0.1, erasing: 0.05, hold: 1)
        let steps = play(s, limit: 7)
        XCTAssertEqual(steps, [
            L.Step(delay: 0.1, state: State(phraseIndex: 0, characterCount: 1, phase: .typing)),
            L.Step(delay: 0.1, state: State(phraseIndex: 0, characterCount: 2, phase: .typing)),
            L.Step(delay: 1, state: State(phraseIndex: 0, characterCount: 2, phase: .erasing)),   // hold, nothing changes
            L.Step(delay: 0.05, state: State(phraseIndex: 0, characterCount: 1, phase: .erasing)),
            L.Step(delay: 0.05, state: State(phraseIndex: 0, characterCount: 0, phase: .erasing)),
            L.Step(delay: 0, state: State(phraseIndex: 1, characterCount: 0, phase: .typing)),     // next phrase at once
            L.Step(delay: 0.1, state: State(phraseIndex: 1, characterCount: 1, phase: .typing)),
        ])
    }

    func testTheCycleTakesTypingPlusHoldPlusErasing() {
        let s = script(["Velvet", "UI"], typing: 0.06, erasing: 0.03, hold: 1.4, loops: false)
        let firstPhrase = play(s).prefix { $0.state.phraseIndex == 0 }
        let total = firstPhrase.reduce(0) { $0 + $1.delay }
        XCTAssertEqual(total, 6 * 0.06 + 1.4 + 6 * 0.03, accuracy: 0.000_1)
    }

    func testLoopingWrapsFromTheLastPhraseToTheFirst() {
        let s = script(["A", "B"])
        let indices = play(s, limit: 20).map(\.state.phraseIndex)
        XCTAssertTrue(indices.contains(1))
        let firstReturn = indices.firstIndex(of: 1).flatMap { i in indices[i...].firstIndex(of: 0) }
        XCTAssertNotNil(firstReturn, "After the last phrase it starts over. Got \(indices)")
    }

    func testWithoutLoopingItStopsOnTheLastPhraseFullyTyped() throws {
        let s = script(["Hi", "Bye"], loops: false)
        let steps = play(s)
        XCTAssertLessThan(steps.count, 200, "A non-looping script ends.")
        let last = try XCTUnwrap(steps.last).state
        XCTAssertEqual(last.phraseIndex, 1)
        XCTAssertEqual(visible(s, last), "Bye", "It rests on the whole last phrase, never erased.")
        XCTAssertNil(s.step(after: last))
    }

    func testASinglePhraseThatDoesntLoopJustTypesOnce() {
        let s = script(["Ready."], loops: false)
        let steps = play(s)
        XCTAssertEqual(steps.count, 6)
        XCTAssertTrue(steps.allSatisfy { $0.state.phase == .typing })
    }

    func testEmojiPhrasesTypeOneGlyphPerStep() {
        let s = script(["👍🏽✨"], loops: false)
        let shown = play(s).map { visible(s, $0.state) }
        XCTAssertEqual(shown, ["👍🏽", "👍🏽✨"])
    }

    // MARK: Edge cases

    func testNothingToAnimateIsStatic() {
        for phrases in [[], [""], ["", ""]] as [[String]] {
            let s = script(phrases)
            XCTAssertTrue(s.isStatic, "\(phrases)")
            XCTAssertNil(s.step(after: s.start), "\(phrases) would spin forever with no delay.")
        }
        XCTAssertFalse(script(["", "Hi"]).isStatic)
    }

    func testAnEmptyPhraseAmongOthersIsSkippedThroughItsHold() {
        let s = script(["", "Hi"], hold: 1)
        let steps = play(s, limit: 3)
        XCTAssertEqual(steps[0], L.Step(delay: 1, state: State(phraseIndex: 0, characterCount: 0, phase: .erasing)))
        XCTAssertEqual(steps[1], L.Step(delay: 0, state: State(phraseIndex: 1, characterCount: 0, phase: .typing)))
    }

    func testAnInfiniteHoldStopsOnTheTypedPhrase() throws {
        let s = script(["Hi", "Bye"], hold: .infinity)
        let steps = play(s)
        XCTAssertEqual(steps.count, 2)
        let last = try XCTUnwrap(steps.last).state
        XCTAssertEqual(visible(s, last), "Hi")
    }

    func testBadDurationsNeverProduceAnUnsleepableDelay() {
        let s = script(["Hey", "You"], typing: -1, erasing: .nan, hold: 1e300)
        for step in play(s, limit: 50) {
            XCTAssertGreaterThanOrEqual(step.delay, 0)
            XCTAssertLessThanOrEqual(step.delay, L.maximumDelay)
        }
    }

    func testAStateFromAPhraseListThatShrankEndsTheScript() {
        let s = script(["Only"])
        XCTAssertNil(s.step(after: State(phraseIndex: 3, characterCount: 2, phase: .typing)))
        XCTAssertNil(s.step(after: State(phraseIndex: -1, characterCount: 0, phase: .erasing)))
    }

    func testOutOfRangeCountsAreClampedToThePhrase() {
        let s = script(["Hi"])
        let typing = s.step(after: State(phraseIndex: 0, characterCount: -4, phase: .typing))
        XCTAssertEqual(typing?.state.characterCount, 1)
        let erasing = s.step(after: State(phraseIndex: 0, characterCount: 9, phase: .erasing))
        XCTAssertEqual(erasing?.state.characterCount, 1)
    }

    // MARK: Reduce Motion

    func testReduceMotionShowsWholePhrasesAndHoldsThemAsLongAsTypingWould() {
        let s = script(["Hello", "Yo"], typing: 0.1, hold: 1, reduceMotion: true)
        XCTAssertEqual(s.start, State(phraseIndex: 0, characterCount: 5, phase: .showing))

        let steps = play(s, limit: 3)
        XCTAssertEqual(steps.map(\.state), [
            State(phraseIndex: 1, characterCount: 2, phase: .showing),
            State(phraseIndex: 0, characterCount: 5, phase: .showing),
            State(phraseIndex: 1, characterCount: 2, phase: .showing),
        ])
        XCTAssertEqual(steps[0].delay, 5 * 0.1 + 1, accuracy: 0.000_1, "\"Hello\" stays as long as typing it plus the hold.")
        XCTAssertEqual(steps[1].delay, 2 * 0.1 + 1, accuracy: 0.000_1)
        XCTAssertTrue(steps.allSatisfy { visible(s, $0.state) == s.phrases[$0.state.phraseIndex] },
                      "Under Reduce Motion a half-typed fragment never shows.")
    }

    func testReduceMotionWithoutLoopingStopsOnTheLastPhrase() {
        let s = script(["One", "Two"], loops: false, reduceMotion: true)
        let steps = play(s)
        XCTAssertEqual(steps.map(\.state.phraseIndex), [1])
        XCTAssertNil(script(["Solo"], loops: false, reduceMotion: true).step(after: State(phraseIndex: 0, characterCount: 4, phase: .showing)))
    }
}
