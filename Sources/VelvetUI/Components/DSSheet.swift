import SwiftUI

// MARK: - Design System Sheet
// A thin styling wrapper around the native `.sheet`. The system keeps doing the
// hard parts (interactive dismiss, scroll handoff, VoiceOver); Velvet adds
// detents, a visible grabber, a glass background and carries the theme in.

public extension View {
    /// Presents a sheet with Velvet chrome: detents, a visible grabber, a glass
    /// background, and the presenter's theme carried into the content.
    ///
    /// - Parameters:
    ///   - isPresented: Whether the sheet is showing.
    ///   - detents: Heights the sheet can rest at. Defaults to `.medium` and `.large`.
    ///   - onDismiss: Called after the sheet is dismissed.
    ///   - content: The sheet's content.
    func dsSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(DSSheetModifier(isPresented: isPresented, detents: detents, onDismiss: onDismiss, sheetContent: content))
    }

    /// Presents a sheet for an identifiable item with Velvet chrome. The sheet shows
    /// while `item` is non-nil and sets it back to nil on dismissal.
    ///
    /// - Parameters:
    ///   - item: The item driving the sheet.
    ///   - detents: Heights the sheet can rest at. Defaults to `.medium` and `.large`.
    ///   - onDismiss: Called after the sheet is dismissed.
    ///   - content: Builds the sheet's content for the item.
    func dsSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        detents: Set<PresentationDetent> = [.medium, .large],
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(DSItemSheetModifier(item: item, detents: detents, onDismiss: onDismiss, sheetContent: content))
    }
}

// MARK: - Modifiers

private struct DSSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    let onDismiss: (() -> Void)?
    let sheetContent: () -> SheetContent

    @Environment(\.dsTheme) private var theme

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
            sheetContent()
                .dsSheetChrome(theme: theme, detents: detents)
        }
    }
}

private struct DSItemSheetModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    let detents: Set<PresentationDetent>
    let onDismiss: (() -> Void)?
    let sheetContent: (Item) -> SheetContent

    @Environment(\.dsTheme) private var theme

    func body(content: Content) -> some View {
        content.sheet(item: $item, onDismiss: onDismiss) { item in
            sheetContent(item)
                .dsSheetChrome(theme: theme, detents: detents)
        }
    }
}

// MARK: - Chrome

private extension View {
    func dsSheetChrome(theme: DSTheme, detents: Set<PresentationDetent>) -> some View {
        self
            .dsTheme(theme)
            .environment(\.dsOnBackdrop, false)
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .modifier(DSSheetBackground())
    }
}

/// Glass on older systems, system Liquid Glass on 26+, solid under Reduce Transparency.
private struct DSSheetBackground: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @DSThemed private var resolved

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.presentationBackground(resolved.palette.backgroundElevated)
        } else if #available(iOS 26, macOS 26, *) {
            content
        } else {
            content.presentationBackground(.regularMaterial)
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSheetPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var showing = true

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSPreviewThemeDots(theme: theme)
            DSButton("Show sheet") { showing = true }
        }
        .dsScreenPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsBackdrop()
        .dsTheme(theme)
        .dsSheet(isPresented: $showing, detents: [.medium, .large]) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Share trip").ds(.title2)
                DSListCell(title: "Copy link", leading: { Image(systemName: "link") })
                DSListCell(title: "Message", leading: { Image(systemName: "message") })
            }
            .padding(DSSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

#Preview("Sheet — Light") {
    DSSheetPreviewHost().preferredColorScheme(.light)
}

#Preview("Sheet — Dark") {
    DSSheetPreviewHost().preferredColorScheme(.dark)
}
#endif
