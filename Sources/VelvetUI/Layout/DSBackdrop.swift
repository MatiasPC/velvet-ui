import SwiftUI

// MARK: - Design System Backdrop
// The flat page tone glass surfaces sit on. Draws the active style's solid
// background — one tone per scheme, no gradients, no radial light, no dim
// layers. Opt-in per screen: without a backdrop, `dsSurface` still works but
// reads as a plain elevated card.
//
// Wrap a style change in `withAnimation(DSAnimation.normal)` to crossfade.

public struct DSBackdrop: View {
    @DSThemed private var theme

    public init() {}

    public var body: some View {
        ZStack {
            theme.backgroundColor
                .id(theme.style.id)
                .transition(.opacity)
        }
        .ignoresSafeArea()
        .animation(DSAnimation.normal, value: theme.style.id)
        .accessibilityHidden(true)
    }
}

// MARK: - Environment: on backdrop

private struct DSOnBackdropKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// True inside a view tree that sits on a `DSBackdrop`. Components read it
    /// (through `@DSThemed` → `theme.onBackdrop`) to pick translucent washes
    /// over solid fills.
    var dsOnBackdrop: Bool {
        get { self[DSOnBackdropKey.self] }
        set { self[DSOnBackdropKey.self] = newValue }
    }
}

public extension View {
    /// Put the solid page tone behind this view and mark the subtree as
    /// "on backdrop". This is what turns `dsSurface` cards into glass.
    func dsBackdrop() -> some View {
        self
            .background(DSBackdrop())
            .environment(\.dsOnBackdrop, true)
    }
}
