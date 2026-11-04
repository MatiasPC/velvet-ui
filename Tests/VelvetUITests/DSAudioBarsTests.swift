import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/DSAudioBars.md lives here verbatim.
enum DocSnippetsAudioBars {
    struct ListeningDemo: View {
        @State private var isListening = true
        @State private var micLevel = 0.5   // feed this from your recorder's meter

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    DSCard {
                        HStack(spacing: DSSpacing.sm) {
                            DSAudioBars(isActive: isListening, level: micLevel, barCount: 7)
                            Text(isListening ? "Listening…" : "Paused").ds(.callout)
                            Spacer()
                        }
                    }
                    DSToggle("Listening", isOn: $isListening)
                }
                .dsScreenPadding()
            }
        }
    }

    struct VariantsDemo: View {
        var body: some View {
            HStack(spacing: DSSpacing.xl) {
                DSAudioBars(barCount: 3)
                DSAudioBars(barCount: 7, height: DSSpacing.xxl)
                DSAudioBars(barCount: 5, color: DSColors.success)
            }
        }
    }
}

@MainActor
final class DSAudioBarsTests: XCTestCase {
    typealias Math = DSAudioBarsMath

    func testSnippetsInstantiate() {
        _ = DocSnippetsAudioBars.ListeningDemo().body
        _ = DocSnippetsAudioBars.VariantsDemo().body
    }

    func testWaveStaysInUnitRangeAndMoves() {
        var seen = Set<Int>()
        for bar in 0..<9 {
            for step in 0..<400 {
                let w = Math.wave(bar: bar, at: Double(step) * 0.05)
                XCTAssertTrue((0...1).contains(w))
                seen.insert(Int(w * 10))
            }
        }
        XCTAssertGreaterThan(seen.count, 6, "the wave should sweep most of its range")
    }

    func testAdjacentBarsAreOutOfPhase() {
        XCTAssertNotEqual(Math.wave(bar: 0, at: 1.3), Math.wave(bar: 1, at: 1.3))
    }

    func testBellIsSymmetricAndPeaksInTheMiddle() {
        let values = (0..<5).map { Math.bell(bar: $0, of: 5) }
        XCTAssertEqual(values[0], values[4], accuracy: 1e-9)
        XCTAssertEqual(values[1], values[3], accuracy: 1e-9)
        XCTAssertEqual(values[2], 1, accuracy: 1e-9)
        XCTAssertLessThan(values[0], values[1])
        XCTAssertEqual(Math.bell(bar: 0, of: 1), 1)
    }

    func testAmplitudeClampsAndDefaultsToFull() {
        XCTAssertEqual(Math.amplitude(for: nil), 1)
        XCTAssertEqual(Math.amplitude(for: 0.4), 0.4)
        XCTAssertEqual(Math.amplitude(for: 7), 1)
        XCTAssertEqual(Math.amplitude(for: -2), 0)
        XCTAssertEqual(Math.amplitude(for: .nan), 0)
    }

    func testIdleIsFlatAndSilenceIsFlat() {
        XCTAssertEqual(Math.fraction(bar: 2, of: 5, at: 3, intensity: 0, amplitude: 1, frozen: false), 0)
        XCTAssertEqual(Math.fraction(bar: 2, of: 5, at: 3, intensity: 1, amplitude: 0, frozen: false), 0)
    }

    func testLevelScalesTheRipple() {
        let full = Math.fraction(bar: 1, of: 5, at: 2, intensity: 1, amplitude: 1, frozen: false)
        let half = Math.fraction(bar: 1, of: 5, at: 2, intensity: 1, amplitude: 0.5, frozen: false)
        XCTAssertEqual(half, full / 2, accuracy: 1e-9)
    }

    func testReduceMotionFreezesOnTheBellAndIgnoresLevel() {
        let a = Math.fraction(bar: 2, of: 5, at: 1, intensity: 1, amplitude: 0.1, frozen: true)
        let b = Math.fraction(bar: 2, of: 5, at: 99, intensity: 1, amplitude: 1, frozen: true)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a, 1)
        XCTAssertEqual(Math.fraction(bar: 2, of: 5, at: 1, intensity: 0, amplitude: 1, frozen: true), 0)
    }

    func testHeightKeepsARestingLineAndNeverThinnerThanTheBar() {
        XCTAssertEqual(Math.height(fraction: 0, full: 100, barWidth: 4), 22, accuracy: 1e-9)
        XCTAssertEqual(Math.height(fraction: 1, full: 100, barWidth: 4), 100, accuracy: 1e-9)
        XCTAssertEqual(Math.height(fraction: 0, full: 10, barWidth: 8), 8, "floored at the bar width")
    }

    func testTheClockOnlyTicksWhenSomethingCanMoveAndBeSeen() {
        XCTAssertTrue(Math.isTicking(isActive: true, reduceMotion: false, isVisible: true, isSceneActive: true))
        XCTAssertFalse(Math.isTicking(isActive: false, reduceMotion: false, isVisible: true, isSceneActive: true), "idle")
        XCTAssertFalse(Math.isTicking(isActive: true, reduceMotion: true, isVisible: true, isSceneActive: true), "Reduce Motion")
        XCTAssertFalse(Math.isTicking(isActive: true, reduceMotion: false, isVisible: false, isSceneActive: true), "off screen")
        XCTAssertFalse(Math.isTicking(isActive: true, reduceMotion: false, isVisible: true, isSceneActive: false), "backgrounded")
    }
}
