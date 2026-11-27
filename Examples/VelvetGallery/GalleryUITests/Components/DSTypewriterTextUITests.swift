import XCTest

/// DSTypewriterText on its stage: three looping phrases. The view is one
/// accessibility element labelled with the whole current phrase, never a
/// half-typed fragment, so the test follows the label from phrase to phrase
/// and back to the first, which proves the type → hold → erase → next cycle
/// runs and loops.
///
/// A phrase stays on screen for about 3–4 s and the whole cycle takes about
/// 10.5 s. Launching may use up part of the first phrase, so the test starts
/// from the second one, and every wait is longer than one full cycle so a slow
/// snapshot that misses a phrase still catches it on the next lap.
final class DSTypewriterTextUITests: XCTestCase {
    private let phrases = ["Design at the speed of thought.", "Glass over solid tone.", "No borders. Ever."]

    @MainActor
    func testItCyclesThroughWholePhrasesAndLoops() {
        let app = StageLauncher.launch("DSTypewriterText")

        for phrase in [phrases[1], phrases[2], phrases[0]] {
            let element = app.element(phrase)
            XCTAssertTrue(element.waitForExistence(timeout: 25), "The typewriter never reached \"\(phrase)\".")
            XCTAssertTrue(element.label == phrase, "It read \"\(element.label)\" instead of the whole phrase.")
            // One element: the other phrases aren't on the accessibility tree at the same time.
            for other in phrases where other != phrase {
                XCTAssertFalse(app.element(other).exists, "\"\(other)\" is exposed while \"\(phrase)\" is current.")
            }
        }
        StageLauncher.attachScreenshot(app, named: "DSTypewriterText · looped", to: self)
    }
}
