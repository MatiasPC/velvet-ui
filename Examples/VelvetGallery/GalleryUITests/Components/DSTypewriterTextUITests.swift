import XCTest

/// DSTypewriterText on its stage: three looping phrases. VoiceOver reads one
/// element labelled with the whole current phrase, so the test follows that
/// label from phrase to phrase and back to the first, which proves the
/// type → hold → erase → next cycle runs and loops.
///
/// XCUITest also lists the invisible sizer that reserves the widest phrase's
/// width (every phrase, all the time), so "an element labelled X exists" is
/// always true. The current phrase is the one with more matching elements than
/// the others: the sizer contributes one per phrase, the current phrase's
/// element adds one more.
///
/// A phrase stays current for about 3–4 s and the whole cycle takes about
/// 10.5 s. Launching may use up part of the first phrase, so the test starts
/// from the second one, and every wait is longer than one full cycle so a slow
/// snapshot that misses a phrase still catches it on the next lap.
final class DSTypewriterTextUITests: XCTestCase {
    private let phrases = ["Design at the speed of thought.", "Glass over solid tone.", "No borders. Ever."]

    @MainActor
    func testItCyclesThroughWholePhrasesAndLoops() {
        let app = StageLauncher.launch("DSTypewriterText")
        print(app.debugDescription)

        var seen: [String] = []
        for phrase in [phrases[1], phrases[2], phrases[0]] {
            let reached = waitForCurrent(phrase, in: app, timeout: 25)
            XCTAssertTrue(reached, "The typewriter never reached \"\(phrase)\". Counts: \(counts(in: app)). Seen so far: \(seen)")
            if reached { seen.append(phrase) }
        }
        StageLauncher.attachScreenshot(app, named: "DSTypewriterText · looped", to: self)
    }

    /// How many elements carry each phrase as their label, in `phrases` order.
    @MainActor
    private func counts(in app: XCUIApplication) -> [Int] {
        phrases.map { app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", $0)).count }
    }

    /// The phrase with strictly more matching elements than every other one.
    @MainActor
    private func currentPhrase(in app: XCUIApplication) -> String? {
        let counts = counts(in: app)
        guard let top = counts.max(), top > 0, counts.filter({ $0 == top }).count == 1,
              let index = counts.firstIndex(of: top) else { return nil }
        return phrases[index]
    }

    @MainActor
    private func waitForCurrent(_ phrase: String, in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if currentPhrase(in: app) == phrase { return true }
            StageLauncher.settle(0.2)
        }
        return false
    }
}
