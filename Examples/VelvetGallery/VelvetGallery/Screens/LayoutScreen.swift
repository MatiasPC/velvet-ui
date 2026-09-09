import SwiftUI
import DesignSystem

struct LayoutScreen: View {
    var body: some View {
        GalleryScreen(title: "Layout", caption: "Stacks & grids") {
            LabeledExample("DSVStack") {
                DSVStack(spacing: DSSpacing.sm) {
                    tile("A")
                    tile("B")
                    tile("C")
                }
            }

            LabeledExample("DSHStack") {
                DSHStack(spacing: DSSpacing.sm) {
                    tile("1")
                    tile("2")
                    tile("3")
                }
            }

            LabeledExample("DSGrid") {
                DSGrid(minItemWidth: 100, spacing: DSSpacing.sm) {
                    ForEach(0..<6, id: \.self) { tile("\($0)") }
                }
            }

            LabeledExample("DSHorizontalScroll") {
                DSHorizontalScroll(spacing: DSSpacing.sm) {
                    ForEach(0..<8, id: \.self) { tile("#\($0)", width: 120) }
                }
                Text("DSGrid and DSHorizontalScroll add their own screen-edge padding, so these two sit inset from the flush stacks above.")
                    .ds(.footnote, color: DSColors.textTertiary)
            }

            LabeledExample("DSScreen") {
                DSScreen {
                    VStack(spacing: DSSpacing.sm) {
                        tile("DSScreen")
                        tile("scroll + padding")
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.card, style: .continuous))
                Text("DSScreen supplies the scroll container and screen padding.")
                    .ds(.footnote, color: DSColors.textTertiary)
            }
        }
    }

    private func tile(_ label: String, width: CGFloat? = nil) -> some View {
        Text(label)
            .ds(.footnote, color: DSColors.textSecondary)
            .frame(width: width, height: 64)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .background(DSColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
    }
}
