import SwiftUI
import DesignSystem

struct PageControlScreen: View {
    @State private var page = 0

    var body: some View {
        GalleryScreen(title: "Page Control", caption: "Paged content") {
            LabeledExample("Paged content") {
                VStack(spacing: DSSpacing.md) {
                    TabView(selection: $page) {
                        ForEach(0..<4, id: \.self) { i in
                            DSCard {
                                Text("Page \(i + 1)")
                                    .ds(.title2)
                                    .frame(maxWidth: .infinity, minHeight: 120)
                            }
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 180)

                    DSPageControl(currentPage: $page, numberOfPages: 4)
                }
            }

            LabeledExample("Tap to jump") {
                DSPageControl(
                    currentPage: $page,
                    numberOfPages: 4,
                    activeColor: DSColors.textPrimary
                )
            }
        }
    }
}
