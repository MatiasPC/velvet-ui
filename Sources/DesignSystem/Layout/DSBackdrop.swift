import SwiftUI

// MARK: - Design System Backdrop
// The themed gradient that glass surfaces sit on. Draws the active
// `DSGradientTheme` with a soft radial "light" in the top-leading corner, a
// white wash in light mode and the black dim in dark mode. Opt-in per screen:
// without a backdrop, `dsSurface` still works but reads as a plain elevated card.
//
// Wrap a theme change in `withAnimation(DSAnimation.normal)` to crossfade.

public struct DSBackdrop: View {
    @DSThemed private var theme

    public init() {}

    public var body: some View {
        let gradient = theme.gradient
        ZStack {
            gradient.linearGradient
                .id(gradient.id)
                .transition(.opacity)

            RadialGradient(
                colors: [Color.white.opacity(0.18), .clear],
                center: UnitPoint(x: 0.14, y: 0.08),
                startRadius: 0,
                endRadius: 560
            )

            Color.white.opacity(theme.isDark ? 0 : gradient.lightWash)
            Color.black.opacity(theme.isDark ? gradient.darkDim : 0)
        }
        .ignoresSafeArea()
        .animation(DSAnimation.normal, value: gradient.id)
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
    /// Put the themed gradient behind this view and mark the subtree as
    /// "on backdrop". This is what turns `dsSurface` cards into glass.
    func dsBackdrop() -> some View {
        self
            .background(DSBackdrop())
            .environment(\.dsOnBackdrop, true)
    }
}
