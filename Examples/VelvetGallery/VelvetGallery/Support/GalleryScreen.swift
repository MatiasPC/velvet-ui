import SwiftUI
import DesignSystem

/// Shared chrome for every component screen: neutral background, scroll,
/// screen padding, a header, and the appearance menu in the toolbar. No backdrop.
struct GalleryScreen<Content: View>: View {
    let title: String
    let caption: String
    @ViewBuilder var content: () -> Content

    init(title: String, caption: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.caption = caption
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xxl) {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(title).ds(.title1)
                    Text(caption).ds(.callout, color: DSColors.textSecondary)
                }
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.lg)
        }
        .background(DSColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { AppearanceMenu() } }
    }
}

/// A titled block within a screen.
struct LabeledExample<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    init(_ label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(label).ds(.overline, color: DSColors.textSecondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
