import SwiftUI
import VelvetUI

/// A stand-in for a microphone meter: a speech-like level, 0...1, a few times a second.
private func voiceLevel() -> Double { Double.random(in: 0.15...1) }

struct AudioBarsScreen: View {
    @State private var isActive = true
    @State private var level = 0.6
    @State private var simulatesVoice = false

    var body: some View {
        GalleryScreen(title: "Audio Bars", caption: "An equaliser for live audio") {
            LabeledExample("Ambient") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        HStack(spacing: DSSpacing.sm) {
                            DSAudioBars(isActive: isActive)
                            Text(isActive ? "Listening…" : "Paused").ds(.callout, color: DSColors.textSecondary)
                            Spacer()
                        }
                        DSToggle("Active", isOn: $isActive)
                    }
                }
                Text("Eases between a flat line and a ripple. The clock stops when idle, off screen or in the background.")
                    .ds(.footnote, color: DSColors.textTertiary)
            }

            LabeledExample("Live level") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        HStack {
                            DSAudioBars(isActive: isActive, level: level, barCount: 9, height: DSSpacing.xxxl)
                            Spacer()
                            Text("\(Int(level * 100))%").ds(.numeric, color: DSColors.textSecondary)
                        }
                        Slider(value: $level, in: 0...1)
                            .disabled(simulatesVoice)
                            .accessibilityLabel("Audio level")
                        DSToggle("Simulate a voice", isOn: $simulatesVoice)
                    }
                }
                .task(id: simulatesVoice) {
                    guard simulatesVoice else { return }
                    while !Task.isCancelled {
                        level = voiceLevel()
                        try? await Task.sleep(for: .milliseconds(120))
                    }
                }
            }

            LabeledExample("Sizes, counts and colour") {
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSAudioBars(barCount: 3)
                        DSAudioBars(barCount: 7, height: DSSpacing.xxl)
                        DSAudioBars(barCount: 5, color: DSColors.success)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            LabeledExample("In a row") {
                DSCard(padding: 0) {
                    DSListCell(title: "Voice memo 12", subtitle: "Recording · 0:14") {
                        Image(systemName: "waveform")
                    } trailing: {
                        DSAudioBars(isActive: isActive, barCount: 4, height: DSSpacing.lg)
                    } action: {}
                }
            }
        }
    }
}

struct AudioBarsStage: View {
    let autoplay: Bool
    @State private var isActive = true
    @State private var level: Double? = nil

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.lg) {
                DSAudioBars(
                    isActive: isActive, level: level, barCount: 9,
                    barWidth: DSSpacing.xs, spacing: DSSpacing.xs, height: DSSpacing.massive
                )
                Text(isActive ? "Listening…" : "Paused").ds(.title3)
                    .animation(DSAnimation.normal, value: isActive)
            }
            .frame(maxWidth: .infinity)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                isActive = true
                for _ in 0..<30 {
                    level = voiceLevel()
                    await stagePause(0.12)
                    if Task.isCancelled { return }
                }
                isActive = false
                await stagePause(1.6)
            }
        }
    }
}
