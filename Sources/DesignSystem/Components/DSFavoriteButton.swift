import SwiftUI

// MARK: - Design System Favorite Button
// A tactile like/favorite/bookmark toggle with a satisfying "pop" and a
// radiating particle burst on activation — the micro-interaction that makes
// hearts, saves and bookmarks feel alive (Twitter/Instagram-style).
// The symbol crossfades between its outline and filled variants, springs up
// with a bouncy scale, and fires a burst of accent-colored particles. One
// reusable control for every "save this" moment across any app.

public struct DSFavoriteButton: View {

    // MARK: - Configuration

    @Binding private var isOn: Bool
    private let symbol: String
    private let filledSymbol: String
    private let size: CGFloat
    private let tint: Color
    private let inactiveColor: Color
    private let particleCount: Int
    private let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled

    // MARK: - State

    /// Brief scale bump applied to the symbol on every toggle.
    @State private var pop: Bool = false
    /// Burst progress, 0 (collapsed at center) → 1 (expanded and faded).
    @State private var burst: CGFloat = 0
    /// Gates the particle layer so it only renders during an active burst.
    @State private var isBursting: Bool = false

    // MARK: - Initializer

    /// A favorite/like toggle with a spring pop and particle burst.
    /// - Parameters:
    ///   - isOn: Binding driving the favorited state.
    ///   - symbol: SF Symbol shown when off. Defaults to `"heart"`.
    ///   - filledSymbol: SF Symbol shown when on. Defaults to `"heart.fill"`.
    ///   - size: Point size of the symbol. Defaults to `28`.
    ///   - tint: Color of the filled symbol and the burst particles.
    ///     Defaults to the accent primary.
    ///   - inactiveColor: Color of the symbol when off. Defaults to the
    ///     tertiary text color.
    ///   - particleCount: Number of burst particles. Use `0` to disable the
    ///     burst. Defaults to `8`.
    ///   - haptic: Feedback fired when favoriting. Defaults to `.rigid`.
    ///     Un-favoriting always fires a soft `.light` tick.
    public init(
        isOn: Binding<Bool>,
        symbol: String = "heart",
        filledSymbol: String = "heart.fill",
        size: CGFloat = 28,
        tint: Color = DSColors.defaultPalette.primary,
        inactiveColor: Color = DSColors.defaultPalette.textTertiary,
        particleCount: Int = 8,
        haptic: DSHapticStyle = .rigid
    ) {
        self._isOn = isOn
        self.symbol = symbol
        self.filledSymbol = filledSymbol
        self.size = size
        self.tint = tint
        self.inactiveColor = inactiveColor
        self.particleCount = max(0, particleCount)
        self.haptic = haptic
    }

    // MARK: - Body

    public var body: some View {
        Button(action: toggle) {
            ZStack {
                burstLayer

                Image(systemName: isOn ? filledSymbol : symbol)
                    .font(.system(size: size))
                    .foregroundStyle(isOn ? tint : inactiveColor)
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(pop ? 1.3 : 1.0)
            }
            // Generous tap target around the symbol.
            .frame(width: size * 2, height: size * 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(Text("Favorite"))
        .accessibilityValue(isOn ? Text("On") : Text("Off"))
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    // MARK: - Particle Burst

    private var burstLayer: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                let angle = Double(index) / Double(max(1, particleCount)) * 2 * .pi
                let radius = size * 1.3 * burst

                Circle()
                    .fill(tint)
                    .frame(width: size * 0.18, height: size * 0.18)
                    .scaleEffect(isBursting ? max(0, 1 - burst) : 0)
                    .opacity(isBursting ? Double(1 - burst) : 0)
                    .offset(
                        x: CGFloat(cos(angle)) * radius,
                        y: CGFloat(sin(angle)) * radius
                    )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Interaction

    private func toggle() {
        guard isEnabled else { return }
        let newValue = !isOn

        withAnimation(DSAnimation.springSnappy) {
            isOn = newValue
        }

        // A quick bouncy pop on every toggle, settling back to rest.
        withAnimation(DSAnimation.springBouncy) {
            pop = true
        } completion: {
            withAnimation(DSAnimation.springSnappy) {
                pop = false
            }
        }

        if newValue {
            DSHapticEngine.shared.fire(haptic)
            triggerBurst()
        } else {
            DSHapticEngine.shared.fire(.light)
        }
    }

    private func triggerBurst() {
        guard particleCount > 0 else { return }
        burst = 0
        isBursting = true
        withAnimation(.easeOut(duration: 0.5)) {
            burst = 1
        } completion: {
            isBursting = false
            burst = 0
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    FavoriteButtonPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    FavoriteButtonPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct FavoriteButtonPreview: View {
    @State private var liked = false
    @State private var saved = true
    @State private var starred = false
    @State private var bookmarked = false

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            HStack(spacing: DSSpacing.xl) {
                DSFavoriteButton(isOn: $liked)
                DSFavoriteButton(
                    isOn: $starred,
                    symbol: "star",
                    filledSymbol: "star.fill",
                    tint: DSColors.defaultPalette.warning
                )
                DSFavoriteButton(
                    isOn: $bookmarked,
                    symbol: "bookmark",
                    filledSymbol: "bookmark.fill",
                    tint: DSColors.defaultPalette.secondary
                )
            }

            Divider()

            // Realistic usage: a favorite affordance inside a list row.
            HStack(spacing: DSSpacing.md) {
                DSAvatar(name: "Ava Reyes", size: 44)
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text("Ava Reyes").ds(.title3)
                    Text("Sunset over the coast")
                        .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                }
                Spacer()
                DSFavoriteButton(isOn: $saved, size: 24)
            }
            .padding(DSSpacing.md)
            .background(DSColors.defaultPalette.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
            .dsShadow(.sm)

            DSFavoriteButton(isOn: $liked, size: 40)
                .disabled(true)
        }
    }
}
