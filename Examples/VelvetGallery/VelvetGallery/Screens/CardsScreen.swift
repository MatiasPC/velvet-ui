import SwiftUI
import DesignSystem

struct CardsScreen: View {
    var body: some View {
        GalleryScreen(title: "Cards", caption: "Glass containers") {
            LabeledExample("Styles") {
                VStack(spacing: DSSpacing.md) {
                    DSCard(style: .flat) { cardBody("Flat", "Wash on the backdrop, no shadow") }
                    DSCard(style: .elevated) { cardBody("Elevated", "Glass, edge highlight, soft shadow") }
                    DSCard(style: .outlined) { cardBody("Outlined", "Denser glass, no shadow") }
                }
            }
            LabeledExample("Nested") {
                DSCard(style: .elevated) {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Nested").ds(.title3)
                        DSCard(style: .flat, cornerRadius: DSRadius.surface) {
                            Text("Flat card inside").ds(.callout)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            LabeledExample("Interactive") {
                DSInteractiveCard(action: { print("card tap") }) {
                    HStack {
                        Text("Interactive card").ds(.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(DSColors.textTertiary)
                    }
                }
            }
            LabeledExample("Image card") {
                DSImageCard(
                    imageURL: URL(string: "https://picsum.photos/seed/velvet/600/400"),
                    title: "Cabaña en el bosque",
                    subtitle: "$120 / noche",
                    badge: "Nuevo"
                )
            }
        }
    }

    @ViewBuilder
    private func cardBody(_ title: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text(title).ds(.title3)
            Text(sub).ds(.callout, color: DSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
