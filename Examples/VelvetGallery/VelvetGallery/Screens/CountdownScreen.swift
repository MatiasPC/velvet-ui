import SwiftUI
import VelvetUI

struct CountdownScreen: View {
    @State private var saleEnds = Date.now.addingTimeInterval(2 * 86_400 + 5 * 3_600 + 42 * 60)
    @State private var liveAt = Date.now.addingTimeInterval(3 * 3_600 + 15)
    @State private var resendAt = Date.now.addingTimeInterval(15)
    @State private var canResend = false

    var body: some View {
        GalleryScreen(title: "Countdown", caption: "Digits roll down each second; the last ten seconds turn accent, and zero lands with a haptic") {
            LabeledExample("Flash sale, days to go") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Sale ends in").ds(.title3)
                        DSCountdown(to: saleEnds, accessibilityLabel: "Sale ends in")
                    }
                }
            }

            LabeledExample("Event start, custom accent") {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Live in").ds(.overline, color: DSColors.textSecondary)
                    DSCountdown(to: liveAt, accent: DSColors.secondary, accessibilityLabel: "Live in")
                }
            }

            LabeledExample("Resend a code, with onFinish") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Didn't get it? You can ask again in").ds(.callout, color: DSColors.textSecondary)
                        DSCountdown(to: resendAt, haptic: .light, accessibilityLabel: "Resend code in") {
                            canResend = true
                        }
                        DSButton("Resend code", variant: .secondary, size: .small) {
                            canResend = false
                            resendAt = .now.addingTimeInterval(15)
                        }
                        .disabled(!canResend)
                    }
                }
            }

            Text("With VoiceOver on, the countdown is one element that reads the time left (\"2 minutes, 5 seconds\") and is marked as updating frequently.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Recording stage: a sale countdown with days to go, and a short "resend the
/// code" countdown that runs out after twelve seconds (the last ten in accent). The short one is the
/// accessibility element "Resend timer", whose value is the time left
/// ("12 seconds" … "0 seconds"); "Resend status" reads "Waiting" or "Ready", and
/// the "Resend code" button restarts it. The UI test drives exactly that.
struct CountdownStage: View {
    let autoplay: Bool
    @State private var saleEnds = Date.now.addingTimeInterval(2 * 86_400 + 5 * 3_600 + 42 * 60)
    @State private var resendAt = Date.now.addingTimeInterval(CountdownStage.resendSeconds)
    @State private var canResend = false

    static let resendSeconds: TimeInterval = 12

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Summer sale").ds(.title3)
                    DSCountdown(to: saleEnds, accessibilityLabel: "Sale ends in")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("You can ask for a new code in").ds(.callout, color: DSColors.textSecondary)
                    DSCountdown(to: resendAt, haptic: .light, accessibilityLabel: "Resend timer") {
                        canResend = true
                    }
                    HStack {
                        DSButton("Resend code", variant: .secondary, size: .small) { restart() }
                            .disabled(!canResend)
                        Spacer()
                        Text(canResend ? "Ready" : "Waiting")
                            .ds(.footnote, color: DSColors.textSecondary)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Resend status")
                            .accessibilityValue(canResend ? "Ready" : "Waiting")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task(id: canResend) {
            guard autoplay, canResend else { return }
            await stagePause(1.5)
            if Task.isCancelled { return }
            restart()
        }
    }

    private func restart() {
        canResend = false
        resendAt = .now.addingTimeInterval(Self.resendSeconds)
    }
}
