import SwiftUI
import VelvetUI

/// The hero both the screen and the recording stage stretch. A flat accent block
/// with a symbol and a title, so it needs no image assets.
struct StretchyHeaderHero: View {
    let height: CGFloat
    let parallax: Bool

    @DSThemed private var theme

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle().fill(theme.accent)
            Image(systemName: "sun.horizon.fill")
                .dsFont(.displayLarge)
                .foregroundStyle(theme.onAccent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text("Weekend in Lisbon").ds(.title1, color: theme.onAccent)
                Text("3 nights · 2 guests").ds(.callout, color: theme.onAccent)
            }
            .padding(DSSpacing.lg)
        }
        .frame(height: height)
        .dsStretchyHeader(parallax: parallax)
    }
}

let stretchyHeaderDetails: [(title: String, subtitle: String, icon: String)] = [
    ("Check-in", "Friday, from 15:00", "door.left.hand.open"),
    ("Check-out", "Monday, until 11:00", "door.right.hand.closed"),
    ("Room", "River view, king bed", "bed.double"),
    ("Breakfast", "Included, 7:00 to 10:30", "cup.and.saucer"),
    ("Cancellation", "Free until Wednesday", "calendar.badge.checkmark"),
    ("Address", "Rua das Flores 28, Lisbon", "mappin.and.ellipse"),
    ("Wi-Fi", "Velvet-Guest · in your welcome card", "wifi"),
    ("Parking", "Underground, €18 a night", "car"),
]

/// One details row, shared by the screen and the stage.
private struct StretchyHeaderDetailRow: View {
    let title: String
    let subtitle: String
    let icon: String

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
    }
}

struct StretchyHeaderScreen: View {
    @State private var parallax = true

    var body: some View {
        // Not a `GalleryScreen`: the header has to be the first view of a scroll
        // view that runs under the status bar.
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StretchyHeaderHero(height: 320, parallax: parallax)

                VStack(alignment: .leading, spacing: DSSpacing.xxl) {
                    LabeledExample("Parallax") {
                        DSToggle("Trail the scroll at half speed", isOn: $parallax)
                        Text("Pull the page down past the top: the hero grows to fill the gap. Scroll up: with parallax on it drifts away at half speed. With Reduce Motion on only the stretch remains.")
                            .ds(.footnote, color: DSColors.textSecondary)
                    }

                    LabeledExample("Details") {
                        VStack(spacing: DSSpacing.sm) {
                            ForEach(stretchyHeaderDetails, id: \.title) { item in
                                StretchyHeaderDetailRow(title: item.title, subtitle: item.subtitle, icon: item.icon)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsScreenPadding()
                .padding(.vertical, DSSpacing.lg)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(DSColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Stretchy Header")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { AppearanceMenu() } }
    }
}

// MARK: - Stage

/// Manual: overscroll can't be driven programmatically, so pull and scroll by hand.
struct StretchyHeaderStage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StretchyHeaderHero(height: 240, parallax: true)
                VStack(spacing: DSSpacing.sm) {
                    ForEach(stretchyHeaderDetails, id: \.title) { item in
                        StretchyHeaderDetailRow(title: item.title, subtitle: item.subtitle, icon: item.icon)
                    }
                }
                .padding(.vertical, DSSpacing.lg)
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: 560)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous))
    }
}
