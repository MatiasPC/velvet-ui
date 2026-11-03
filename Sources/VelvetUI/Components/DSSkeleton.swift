import SwiftUI

// MARK: - Design System Skeleton
// Loading placeholders in two forms:
//
// 1. `DSSkeleton` — a single block (or circle) you compose into a loading layout.
//    It sweeps with `dsShimmer`.
// 2. `.dsSkeleton(isLoading)` — turns a real view into its own placeholder using
//    `.redacted(reason: .placeholder)`, so the loading layout can't drift from
//    the loaded one.
//
// The modifier never branches on `isLoading` and never instantiates the content
// twice: the wrapped view keeps its identity (and its @State, .task and
// .onAppear) across the toggle. That is also why its motion is a calm opacity
// pulse on the whole view rather than a shimmer sweep, which would need a second
// copy of the content as a mask.

private enum Metrics {
    /// Lowest opacity of the loading pulse.
    static let pulseDim: Double = 0.5
    /// One full dim-and-back cycle: `DSAnimation.ambient` (1.8 s) each way.
    static let pulsePeriod: TimeInterval = 3.6
}

/// A placeholder block for loading layouts (decorative, hidden from VoiceOver).
public struct DSSkeleton: View {
    private let width: CGFloat?
    private let height: CGFloat
    private let cornerRadius: CGFloat

    @DSThemed private var theme

    /// - Parameters:
    ///   - width: Fixed width. `nil` fills the available width.
    ///   - height: Block height. Defaults to `DSSpacing.sm`.
    ///   - cornerRadius: Corner radius. Defaults to `DSRadius.xs`.
    public init(
        width: CGFloat? = nil,
        height: CGFloat = DSSpacing.sm,
        cornerRadius: CGFloat = DSRadius.xs
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    /// A round placeholder, e.g. for an avatar.
    /// - Parameter diameter: Width and height.
    public static func circle(_ diameter: CGFloat) -> DSSkeleton {
        DSSkeleton(width: diameter, height: diameter, cornerRadius: DSRadius.pill)
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(theme.onBackdrop ? theme.washSurface : theme.palette.border)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .dsShimmer()
            .accessibilityHidden(true)
    }
}

// MARK: - Modifier

struct DSSkeletonModifier: ViewModifier {
    let isLoading: Bool

    /// When the current loading phase began; the pulse is sampled relative to it.
    @State private var loadingStart = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// "Loading" while loading, `nil` otherwise (so the real content reads normally).
    static func accessibilityLabel(isLoading: Bool) -> String? {
        isLoading ? "Loading" : nil
    }

    /// Opacity of the pulse `elapsed` seconds into a loading phase: starts at 1,
    /// eases down to `Metrics.pulseDim` at half a period and back (a cosine).
    static func pulseOpacity(elapsed: TimeInterval) -> Double {
        let phase = (1 - cos(2 * .pi * elapsed / Metrics.pulsePeriod)) / 2
        return 1 - (1 - Metrics.pulseDim) * phase
    }

    func body(content: Content) -> some View {
        // The pulse is sampled from a timeline instead of a repeatForever animation:
        // a repeating animation can keep running after loading ends, while a paused
        // timeline simply stops. The TimelineView is always present, so the content
        // keeps its identity across the toggle.
        let pulses = isLoading && !reduceMotion
        return TimelineView(.animation(paused: !pulses)) { context in
            content
                .redacted(reason: isLoading ? .placeholder : [])
                .opacity(pulses ? Self.pulseOpacity(elapsed: context.date.timeIntervalSince(loadingStart)) : 1)
        }
        .animation(DSAnimation.normal, value: isLoading)
        .allowsHitTesting(!isLoading)
        .modifier(SkeletonAccessibility(isLoading: isLoading))
        .onChange(of: isLoading) { _, loading in
            if loading { loadingStart = Date() }
        }
    }
}

/// Collapses to a single "Loading" element while loading; transparent otherwise.
/// Always the same modifier type so the content's identity is untouched.
private struct SkeletonAccessibility: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: isLoading ? .ignore : .contain)
            .accessibilityLabel(DSSkeletonModifier.accessibilityLabel(isLoading: isLoading) ?? "")
    }
}

public extension View {
    /// While `isLoading`, renders this view as placeholder shapes of its own layout, dims it in a calm pulse,
    /// disables interaction and reads "Loading" to VoiceOver.
    ///
    /// The view keeps its identity when `isLoading` flips, so any `@State` or `.task` inside it is not reset.
    func dsSkeleton(_ isLoading: Bool) -> some View {
        modifier(DSSkeletonModifier(isLoading: isLoading))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSkeletonPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                HStack(spacing: DSSpacing.sm) {
                    DSSkeleton.circle(DSSpacing.huge)
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        DSSkeleton(width: 140)
                        DSSkeleton(width: 90)
                    }
                }

                HStack(spacing: DSSpacing.sm) {
                    DSAvatar(name: "Ada Lovelace", size: DSSpacing.huge)
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text("Ada Lovelace").ds(.title3)
                        Text("Analyst, mathematician").ds(.callout)
                    }
                }
                .dsSkeleton(isLoading)

                DSToggle("Loading", isOn: $isLoading)
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Skeleton — Light") {
    DSSkeletonPreviewHost().preferredColorScheme(.light)
}

#Preview("Skeleton — Dark") {
    DSSkeletonPreviewHost().preferredColorScheme(.dark)
}
#endif
