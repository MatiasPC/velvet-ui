import SwiftUI
import VelvetUI

struct ThemeScreen: View {
    var body: some View {
        GalleryScreen(title: "Theme", caption: "Neutral palette & glass surfaces") {
            LabeledExample("Neutral palette") {
                DSCard(style: .flat) {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        swatch("backgroundPrimary", DSColors.backgroundPrimary)
                        swatch("backgroundSecondary", DSColors.backgroundSecondary)
                        swatch("backgroundElevated", DSColors.backgroundElevated)
                        swatch("textPrimary", DSColors.textPrimary)
                        swatch("textSecondary", DSColors.textSecondary)
                        swatch("textTertiary", DSColors.textTertiary)
                        swatch("border", DSColors.border)
                        swatch("divider", DSColors.divider)
                    }
                }
            }

            LabeledExample("Surfaces") {
                VStack(spacing: DSSpacing.sm) {
                    surfaceRow("glassThin", .glassThin)
                    surfaceRow("glass", .glass)
                    surfaceRow("glassThick", .glassThick)
                    surfaceRow("solid", .solid)
                }
            }

            LabeledExample("Built-in styles (reference only)") {
                VStack(spacing: DSSpacing.sm) {
                    ForEach(DSThemeStyle.all) { style in
                        HStack(spacing: DSSpacing.sm) {
                            ZStack {
                                HStack(spacing: 0) {
                                    Rectangle().fill(style.background.light)
                                    Rectangle().fill(style.background.dark)
                                }
                                Circle()
                                    .fill(style.accent)
                                    .frame(width: DSSpacing.sm, height: DSSpacing.sm)
                            }
                            .frame(width: 60, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
                            Text(style.name).ds(.footnote)
                            Spacer()
                        }
                    }
                }
                Text("Each style is a flat page tone plus an accent — light on the left half, dark on the right. Not used in this gallery; the app is neutral-only.")
                    .ds(.footnote, color: DSColors.textTertiary)
            }
        }
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        HStack(spacing: DSSpacing.sm) {
            RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                .fill(color)
                .frame(width: 44, height: 44)
            Text(name).ds(.footnote)
            Spacer()
        }
    }

    private func surfaceRow(_ name: String, _ level: DSSurface) -> some View {
        HStack {
            Text(name).ds(.footnote)
            Spacer()
            Text("dsSurface(.\(name))").ds(.caption1, color: DSColors.textTertiary)
        }
        .padding(DSSpacing.md)
        .dsSurface(level, radius: DSRadius.surface)
    }
}
