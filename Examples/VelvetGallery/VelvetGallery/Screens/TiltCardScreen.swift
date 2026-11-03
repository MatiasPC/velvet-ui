import SwiftUI
import VelvetUI

/// The card content every example tilts: a loyalty card with a number, so the
/// perspective is easy to read.
private struct MemberCard: View {
    @DSThemed private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack {
                Text("Velvet Club").ds(.overline, color: theme.palette.textSecondary)
                Spacer()
                Image(systemName: "sparkles").foregroundStyle(theme.ink)
            }
            Text("2,480 pts").ds(.displayMedium)
            HStack {
                Text("Ada Lovelace").ds(.callout)
                Spacer()
                Text("Gold").ds(.callout, color: theme.palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// A glass panel on a gradient backdrop, so the card reads as glass over colour.
private struct GradientPanel<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(DSSpacing.lg)
            .frame(maxWidth: .infinity)
            .dsBackdrop()
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous))
    }
}

struct TiltCardScreen: View {
    private static let tilts = ["6°", "12°", "24°"]
    private static let radii = ["Card", "Surface", "Control"]
    private static let themes: [String: DSGradientTheme] = [
        "Sunset": .sunset, "Aurora": .aurora, "Lagoon": .lagoon
    ]

    @State private var tiltLabel = "12°"
    @State private var radiusLabel = "Card"
    @State private var hasHaptic = true
    @State private var themeName = "Sunset"
    @State private var redeemed = 0
    @State private var panelTheme = DSTheme(gradient: .sunset)

    private var maxTilt: Angle? {
        switch tiltLabel {
        case "6°": return .degrees(6)
        case "24°": return .degrees(24)
        default: return nil   // 12°, the default
        }
    }

    private var cornerRadius: CGFloat {
        switch radiusLabel {
        case "Surface": return DSRadius.surface
        case "Control": return DSRadius.control
        default: return DSRadius.card
        }
    }

    var body: some View {
        GalleryScreen(title: "Tilt Card", caption: "Drag to tip the glass; release to spring back") {
            LabeledExample("Default — drag the card") {
                DSTiltCard { MemberCard() }
            }

            LabeledExample("Playground") {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    DSTiltCard(maxTilt: maxTilt, cornerRadius: cornerRadius, haptic: hasHaptic ? .soft : nil) {
                        MemberCard()
                    }
                    Text("Max tilt").ds(.caption1, color: DSColors.textTertiary)
                    DSSegmentedControl(selection: $tiltLabel, options: Self.tilts)
                    Text("Corner radius").ds(.caption1, color: DSColors.textTertiary)
                    DSSegmentedControl(selection: $radiusLabel, options: Self.radii)
                    DSToggle("Haptic when the touch begins", isOn: $hasHaptic)
                }
            }

            LabeledExample("A control inside keeps its tap") {
                DSTiltCard {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        MemberCard()
                        DSButton(redeemed == 0 ? "Redeem reward" : "Redeemed \(redeemed)×", isFullWidth: true) {
                            redeemed += 1
                        }
                    }
                }
            }

            LabeledExample("On a gradient — glass over colour") {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    GradientPanel {
                        DSTiltCard { MemberCard() }
                    }
                    .dsTheme(panelTheme)
                    DSSegmentedControl(selection: $themeName, options: ["Sunset", "Aurora", "Lagoon"])
                }
            }
            .onChange(of: themeName) { _, name in
                guard let gradient = Self.themes[name] else { return }
                withAnimation(DSAnimation.normal) { panelTheme.gradient = gradient }
            }

            Text("Scroll this screen by dragging from a card: the card tilts for a moment, then springs flat when the scroll takes over. Under Reduce Motion the cards stay flat and only a still sheen fades in while held.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
    }
}

/// Chrome-free recording stage: one card, drag it by hand (manual, no autoplay).
struct TiltCardStage: View {
    var body: some View {
        DSTiltCard { MemberCard() }
    }
}
