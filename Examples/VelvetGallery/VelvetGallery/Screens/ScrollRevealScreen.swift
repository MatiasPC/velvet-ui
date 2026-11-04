import SwiftUI
import VelvetUI

/// One row of the demo feed. Shared by the screen and the recording stage.
struct ScrollRevealRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let intensity: DSScrollRevealIntensity?

    @DSThemed private var theme

    var body: some View {
        DSCard {
            HStack(spacing: DSSpacing.md) {
                Image(systemName: icon)
                    .dsFont(.title3)
                    .foregroundStyle(theme.ink)
                    .frame(width: DSSpacing.xxl)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(title).ds(.title3)
                    Text(subtitle).ds(.callout, color: DSColors.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
        .modifier(OptionalScrollReveal(intensity: intensity))
    }
}

/// Applies the reveal, or nothing when `intensity` is nil (the "Off" comparison).
private struct OptionalScrollReveal: ViewModifier {
    let intensity: DSScrollRevealIntensity?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let intensity {
            content.dsScrollReveal(intensity)
        } else {
            content
        }
    }
}

let scrollRevealFeed: [(title: String, subtitle: String, icon: String)] = [
    ("Weekly summary", "4 sessions · 2 h 35 min", "chart.bar"),
    ("New follower", "aurora_dev started following you", "person.badge.plus"),
    ("Backup complete", "1 248 photos · just now", "icloud"),
    ("Battery full", "Unplug to preserve battery health", "battery.100"),
    ("Trip reminder", "Flight to Lisbon in 3 hours", "airplane"),
    ("Goal reached", "10 000 steps — nice work", "figure.walk"),
    ("Payment received", "$24.00 from Ada Lovelace", "creditcard"),
    ("New comment", "“Love the glass on this one.”", "bubble.left"),
    ("Storage almost full", "92% of 5 GB used", "externaldrive"),
    ("Update available", "Velvet 0.3 is ready to install", "arrow.down.circle"),
    ("Calendar", "Design review at 15:30", "calendar"),
    ("Reminder", "Water the plants", "leaf"),
    ("Delivery", "Your order is on its way", "shippingbox"),
    ("Music", "New release from your favourites", "music.note"),
    ("Photos", "On this day, three years ago", "photo"),
    ("Weather", "Rain from 18:00", "cloud.rain"),
    ("Security", "New sign-in from a Mac", "lock.shield"),
    ("Tip", "Hold a card to see its actions", "lightbulb"),
]

private enum RevealChoice: CaseIterable, Hashable {
    case off, subtle, medium, strong

    var label: String {
        switch self {
        case .off: return "Off"
        case .subtle: return "Subtle"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }

    var intensity: DSScrollRevealIntensity? {
        switch self {
        case .off: return nil
        case .subtle: return .subtle
        case .medium: return .medium
        case .strong: return .strong
        }
    }
}

struct ScrollRevealScreen: View {
    @State private var choice: RevealChoice = .medium

    var body: some View {
        GalleryScreen(title: "Scroll Reveal", caption: "Receding at the edges, reversible") {
            LabeledExample("Intensity") {
                DSSegmentedControl(
                    selection: $choice,
                    segments: RevealChoice.allCases.map { DSSegment($0.label, value: $0) }
                )
                .accessibilityLabel("Intensity")
                Text("Scroll the page: rows dim and shrink as they cross the top and bottom edge, and come back when you scroll back. With Reduce Motion on they stay at full presence.")
                    .ds(.footnote, color: DSColors.textSecondary)
            }

            LabeledExample("Horizontal carousel") {
                ScrollView(.horizontal) {
                    HStack(spacing: DSSpacing.sm) {
                        ForEach(0..<6, id: \.self) { index in
                            DSCard {
                                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                    Text("Card \(index + 1)").ds(.title3)
                                    Text("Neighbours recede").ds(.callout, color: DSColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .containerRelativeFrame(.horizontal)
                            .modifier(OptionalScrollReveal(intensity: choice.intensity))
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, DSSpacing.xxxl, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
            }

            LabeledExample("Vertical feed") {
                VStack(spacing: DSSpacing.sm) {
                    ForEach(Array(scrollRevealFeed.enumerated()), id: \.offset) { _, item in
                        ScrollRevealRow(title: item.title, subtitle: item.subtitle, icon: item.icon, intensity: choice.intensity)
                    }
                }
            }
        }
    }
}

// MARK: - Stage

struct ScrollRevealStage: View {
    let autoplay: Bool
    @State private var position = ScrollPosition(edge: .top)

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.sm) {
                ForEach(Array(scrollRevealFeed.enumerated()), id: \.offset) { _, item in
                    ScrollRevealRow(title: item.title, subtitle: item.subtitle, icon: item.icon, intensity: .strong)
                }
            }
        }
        .scrollPosition($position)
        .scrollIndicators(.hidden)
        .frame(maxHeight: 560)
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                await stagePause(0.8)
                withAnimation(.easeInOut(duration: 3.2)) { position.scrollTo(edge: .bottom) }
                await stagePause(4.0)
                withAnimation(.easeInOut(duration: 3.2)) { position.scrollTo(edge: .top) }
                await stagePause(4.0)
            }
        }
    }
}
