import SwiftUI
import VelvetUI

struct ActivityRingsScreen: View {
    @DSThemed private var theme

    // Percent of each goal, so a stepper can drive them (and push one past 100).
    @State private var move = 82
    @State private var exercise = 60
    @State private var stand = 45
    @State private var showsCenter = true
    @State private var hapticOn = true

    private var rings: [DSRing] {
        [
            DSRing(progress: Double(move) / 100, color: theme.palette.error, label: "Move"),
            DSRing(progress: Double(exercise) / 100, color: theme.palette.success, label: "Exercise"),
            DSRing(progress: Double(stand) / 100, color: theme.palette.info, label: "Stand")
        ]
    }

    private var closedCount: Int { rings.filter { $0.progress >= 1 }.count }

    var body: some View {
        GalleryScreen(title: "Activity Rings", caption: "Goals that fill, close and glow") {
            LabeledExample("Three goals, live") {
                DSCard {
                    VStack(spacing: DSSpacing.lg) {
                        DSActivityRings(rings, haptic: hapticOn ? .success : nil) {
                            if showsCenter {
                                VStack(spacing: DSSpacing.xxxs) {
                                    Text("\(closedCount) of \(rings.count)").ds(.title3)
                                    Text("closed").ds(.caption1, color: DSColors.textSecondary)
                                }
                            }
                        }

                        VStack(spacing: DSSpacing.sm) {
                            goalRow("Move", color: theme.palette.error, value: $move)
                            goalRow("Exercise", color: theme.palette.success, value: $exercise)
                            goalRow("Stand", color: theme.palette.info, value: $stand)
                        }

                        HStack(spacing: DSSpacing.sm) {
                            DSButton("Close all", size: .small) { move = 100; exercise = 100; stand = 100 }
                            DSButton("Reset", variant: .ghost, size: .small) { move = 82; exercise = 60; stand = 45 }
                        }

                        DSToggle("Centre content", isOn: $showsCenter)
                        DSToggle("Haptic on close", isOn: $hapticOn)
                    }
                    .frame(maxWidth: .infinity)
                }
                Text("Step a goal to 100 % and it glows with a haptic as the ring lands. Close all three together and they share one buzz. Past 100 % the ring stays closed; VoiceOver still says the real number.")
                    .ds(.footnote, color: DSColors.textTertiary)
            }

            LabeledExample("One goal, in the theme accent") {
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSActivityRings([DSRing(progress: 0.7, label: "Budget")], size: 96, lineWidth: 12)
                        DSActivityRings([DSRing(progress: 1, label: "Budget")], size: 96, lineWidth: 12)
                        DSActivityRings([DSRing(progress: 1.3, label: "Budget")], size: 96, lineWidth: 12)
                    }
                    .frame(maxWidth: .infinity)
                }
                Text("70 %, closed, and 130 %. A ring that starts closed glows but doesn't buzz.")
                    .ds(.footnote, color: DSColors.textTertiary)
            }

            LabeledExample("Stroke and size") {
                DSCard {
                    HStack(spacing: DSSpacing.xl) {
                        DSActivityRings(
                            [DSRing(progress: 0.8, color: theme.palette.error, label: "Move"),
                             DSRing(progress: 0.55, color: theme.palette.success, label: "Exercise")],
                            size: 104, lineWidth: 6, spacing: DSSpacing.xxs
                        )
                        DSActivityRings(
                            [DSRing(progress: 0.8, color: theme.palette.error, label: "Move"),
                             DSRing(progress: 0.55, color: theme.palette.success, label: "Exercise")],
                            size: 104, lineWidth: 18, spacing: DSSpacing.xxs
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            LabeledExample("Five rings in a small frame") {
                DSCard {
                    DSActivityRings(
                        [DSRing(progress: 0.9, label: "One"), DSRing(progress: 0.75, label: "Two"),
                         DSRing(progress: 0.6, label: "Three"), DSRing(progress: 0.45, label: "Four"),
                         DSRing(progress: 0.3, label: "Five")],
                        size: 120, lineWidth: 6, spacing: DSSpacing.xxxs
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func goalRow(_ name: String, color: Color, value: Binding<Int>) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Circle().fill(color).frame(width: DSSpacing.xs, height: DSSpacing.xs)
            Text(name).ds(.body)
            Spacer()
            Text("\(value.wrappedValue)%").ds(.numeric, color: DSColors.textSecondary)
            DSStepper(value: value, in: 0...150, step: 10)
                .accessibilityLabel("\(name) goal, percent")
        }
    }
}

struct ActivityRingsStage: View {
    let autoplay: Bool

    @DSThemed private var theme
    @State private var move = 0.82
    @State private var exercise = 0.60
    @State private var stand = 0.45

    private var rings: [DSRing] {
        [
            DSRing(progress: move, color: theme.palette.error, label: "Move"),
            DSRing(progress: exercise, color: theme.palette.success, label: "Exercise"),
            DSRing(progress: stand, color: theme.palette.info, label: "Stand")
        ]
    }

    var body: some View {
        DSCard {
            DSActivityRings(rings, size: 200, lineWidth: 18) {
                VStack(spacing: DSSpacing.xxxs) {
                    Text("\(rings.filter { $0.progress >= 1 }.count) of \(rings.count)").ds(.title3)
                    Text("closed").ds(.caption1, color: DSColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                // Drain, refill part way, then close the rings one at a time.
                move = 0; exercise = 0; stand = 0
                await stagePause(1.0)
                if Task.isCancelled { return }
                move = 0.65; exercise = 0.5; stand = 0.35
                await stagePause(1.2)
                if Task.isCancelled { return }
                move = 1
                await stagePause(1.1)
                if Task.isCancelled { return }
                exercise = 1
                await stagePause(1.1)
                if Task.isCancelled { return }
                stand = 1
                await stagePause(2.6)
            }
        }
    }
}
