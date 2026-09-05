import SwiftUI

// MARK: - Preview Support (internal)
// Small helpers shared by #Preview blocks and the ComponentCatalog. Internal on
// purpose: the demo app (separate target) has its own picker built on public API.

/// Row of gradient dots that switches `theme.gradient` with a crossfade.
struct DSPreviewThemeDots: View {
    let theme: DSTheme

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            ForEach(DSGradientTheme.all) { candidate in
                let isActive = candidate.id == theme.gradient.id
                Button {
                    DSHapticEngine.shared.fire(.selection)
                    withAnimation(DSAnimation.normal) {
                        theme.gradient = candidate
                    }
                } label: {
                    Circle()
                        .fill(candidate.linearGradient)
                        .frame(width: DSSpacing.xl, height: DSSpacing.xl)
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(isActive ? 0.9 : 0), lineWidth: 2)
                        )
                        .scaleEffect(isActive ? 1.0 : 0.85)
                        .animation(DSAnimation.springSnappy, value: isActive)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(candidate.name)
            }
            Spacer()
        }
    }
}
