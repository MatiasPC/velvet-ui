import SwiftUI
import DesignSystem

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

            LabeledExample("Built-in gradient themes (reference only)") {
                VStack(spacing: DSSpacing.sm) {
                    ForEach(DSGradientTheme.all) { g in
                        HStack(spacing: DSSpacing.sm) {
                            RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                                .fill(g.linearGradient)
                                .frame(width: 60, height: 44)
                            Text(g.name).ds(.footnote)
                            Spacer()
                        }
                    }
                }
                Text("Not used in this gallery — the app is neutral-only. Shown so the themes are on camera once.")
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
