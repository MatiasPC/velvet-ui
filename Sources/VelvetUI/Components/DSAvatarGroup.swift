import SwiftUI

// MARK: - Design System Avatar Group
// A "facepile": a row of overlapping `DSAvatar`s that shows who's on a thread,
// who's in a space, or who reacted. Past a limit the remainder collapses into a
// "+N" bubble.
//
// The separation between neighbours is a *cut-out*, not a ring: each avatar has a
// slightly larger circle erased from it where the avatar before it overlaps. That
// keeps the pile legible on any surface (glass, a flat page tone, a photo) without
// ever knowing the background colour, and without a stroke: the gap simply shows
// whatever is behind the group. Because the cut-out removes the whole overlap,
// no two translucent circles are ever composited on top of each other.

// MARK: - Pure logic

/// The parts of `DSAvatarGroup` that don't need a view. Internal and unit-tested.
enum DSAvatarGroupLogic {

    /// Never fewer than two slots: with one, "+N" would be all that shows.
    static func slots(maxVisible: Int) -> Int { max(2, maxVisible) }

    /// How many real avatars are drawn. When everyone fits they all are; otherwise the
    /// last slot becomes the "+N" bubble, so one fewer than `maxVisible`.
    static func visibleCount(total: Int, maxVisible: Int) -> Int {
        let limit = slots(maxVisible: maxVisible)
        return total > limit ? limit - 1 : total
    }

    /// People not drawn, shown as "+N".
    static func overflow(total: Int, maxVisible: Int) -> Int {
        total - visibleCount(total: total, maxVisible: maxVisible)
    }

    /// "Ana", "Ana and Ben", "Ana, Ben and Cy", "Ana, Ben and 3 others". `names` are the people
    /// drawn; `others` are the ones collapsed into the bubble.
    static func spokenSummary(names: [String], others: Int) -> String {
        guard !names.isEmpty || others > 0 else { return "No people" }
        var parts = names
        if others > 0 { parts.append(others == 1 ? "1 other" : "\(others) others") }
        guard parts.count > 1 else { return parts[0] }
        return parts.dropLast().joined(separator: ", ") + " and " + parts[parts.count - 1]
    }

    /// Stable ids for a list of names: equal names get a numbered suffix so `ForEach` never sees a clash.
    static func uniqueIDs(for names: [String]) -> [String] {
        var seen: [String: Int] = [:]
        return names.map { name in
            let count = seen[name, default: 0]
            seen[name] = count + 1
            return count == 0 ? name : "\(name)#\(count)"
        }
    }

    /// Distance between the centres of neighbouring avatars.
    static func step(size: CGFloat, overlap: CGFloat) -> CGFloat {
        size * (1 - clampedOverlap(overlap))
    }

    /// Overlap as a fraction of the avatar, `0...0.9`.
    static func clampedOverlap(_ overlap: CGFloat) -> CGFloat {
        overlap.isNaN ? 0 : min(max(overlap, 0), 0.9)
    }
}

private enum Metrics {
    /// "+N" label size as a fraction of the avatar, matching `DSAvatar`'s initials.
    static let labelRatio: CGFloat = 0.34
    /// Gap between a cut-out and the avatar that causes it.
    static let gap: CGFloat = DSSpacing.xxxs
    /// Stagger between avatars as they pop in.
    static let popStagger: Double = 0.06
}

// MARK: - Avatar Group

/// A row of overlapping avatars with a "+N" overflow bubble.
///
///     DSAvatarGroup(names: ["Ana Ruiz", "Ben Cole", "Cy Park", "Di Sol", "Eli Wu"], maxVisible: 3)
///
/// Built from `DSAvatar`, so it themes and scales with it. The first person is on top. With more people
/// than `maxVisible`, the last slot becomes a "+N" bubble. Avatars pop in with a short stagger
/// (a fade under Reduce Motion).
///
/// VoiceOver reads the group as one element, "Ana, Ben and 3 others", naming the people shown
/// and counting the rest. Pass `action` to make it a button (a light haptic, a press dip), for
/// example to open the full member list.
public struct DSAvatarGroup: View {

    /// One person in the group.
    public struct Member: Identifiable {
        public let id: String
        public let name: String
        public let imageURL: URL?

        /// - Parameters:
        ///   - id: Unique within the group. Defaults to `name`.
        ///   - name: Spoken by VoiceOver and used for the avatar's initials.
        ///   - imageURL: Remote photo. Falls back to initials.
        public init(id: String? = nil, name: String, imageURL: URL? = nil) {
            self.id = id ?? name
            self.name = name
            self.imageURL = imageURL
        }
    }

    private let members: [Member]
    private let maxVisible: Int
    private let size: CGFloat
    private let overlap: CGFloat
    private let haptic: DSHapticStyle?
    private let action: (() -> Void)?

    @DSThemed private var theme
    @Environment(\.layoutDirection) private var layoutDirection

    /// Create an avatar group.
    /// - Parameters:
    ///   - members: The people, first on top.
    ///   - maxVisible: Most circles to show, "+N" included (at least 2). Defaults to 4.
    ///   - size: Diameter of each avatar. Defaults to `DSSpacing.xxxl`.
    ///   - overlap: How much each avatar is covered by its neighbour, as a fraction of its width (`0...0.9`).
    ///   - haptic: Fired when the group is tapped (only with `action`). `nil` for none.
    ///   - action: Makes the whole group a button.
    public init(
        members: [Member],
        maxVisible: Int = 4,
        size: CGFloat = DSSpacing.xxxl,
        overlap: CGFloat = 0.32,
        haptic: DSHapticStyle? = .light,
        action: (() -> Void)? = nil
    ) {
        self.members = members
        self.maxVisible = maxVisible
        self.size = size
        self.overlap = DSAvatarGroupLogic.clampedOverlap(overlap)
        self.haptic = haptic
        self.action = action
    }

    /// Create an avatar group from names (initials-only avatars).
    public init(
        names: [String],
        maxVisible: Int = 4,
        size: CGFloat = DSSpacing.xxxl,
        overlap: CGFloat = 0.32,
        haptic: DSHapticStyle? = .light,
        action: (() -> Void)? = nil
    ) {
        let ids = DSAvatarGroupLogic.uniqueIDs(for: names)
        self.init(
            members: zip(ids, names).map { Member(id: $0, name: $1) },
            maxVisible: maxVisible,
            size: size,
            overlap: overlap,
            haptic: haptic,
            action: action
        )
    }

    public var body: some View {
        Group {
            if let action {
                Button {
                    if let haptic { DSHapticEngine.shared.fire(haptic) }
                    action()
                } label: {
                    pile
                }
                .buttonStyle(DSAvatarGroupPressStyle())
                .accessibilityAddTraits(.isButton)
            } else {
                pile
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DSAvatarGroupLogic.spokenSummary(names: shown.map(\.name), others: overflow))
    }

    // MARK: - Pile

    private var shown: [Member] {
        Array(members.prefix(DSAvatarGroupLogic.visibleCount(total: members.count, maxVisible: maxVisible)))
    }

    private var overflow: Int {
        DSAvatarGroupLogic.overflow(total: members.count, maxVisible: maxVisible)
    }

    private var pile: some View {
        let count = shown.count + (overflow > 0 ? 1 : 0)
        return HStack(spacing: -size * overlap) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, member in
                DSAvatar(name: member.name, imageURL: member.imageURL, size: size)
                    .modifier(cutOut(index: index))
                    .zIndex(Double(count - index))
                    .dsPopIn(delay: Double(index) * Metrics.popStagger)
            }
            if overflow > 0 {
                overflowBubble
                    .modifier(cutOut(index: shown.count))
                    .zIndex(0)
                    .dsPopIn(delay: Double(shown.count) * Metrics.popStagger)
            }
        }
        .contentShape(Rectangle())
    }

    private var overflowBubble: some View {
        ZStack {
            Circle().fill(theme.subtleFill)
            Text("+\(overflow)")
                .font(.system(size: size * Metrics.labelRatio, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.palette.textSecondary)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, DSSpacing.xxxs)
        }
        .frame(width: size, height: size)
    }

    private func cutOut(index: Int) -> CutOut {
        let step = DSAvatarGroupLogic.step(size: size, overlap: overlap)
        return CutOut(
            isActive: index > 0,
            diameter: size + 2 * Metrics.gap,
            offset: layoutDirection == .rightToLeft ? step : -step
        )
    }
}

// MARK: - Cut-out

/// Erases a circle where the previous avatar sits, leaving a clean gap of the surface behind.
private struct CutOut: ViewModifier {
    let isActive: Bool
    let diameter: CGFloat
    /// Horizontal offset of the erasing circle's centre from this avatar's centre.
    let offset: CGFloat

    func body(content: Content) -> some View {
        if isActive {
            content.mask {
                Rectangle()
                    .overlay {
                        Circle()
                            .frame(width: diameter, height: diameter)
                            .offset(x: offset)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
            }
        } else {
            content
        }
    }
}

// MARK: - Press

private struct DSAvatarGroupPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DSPress.scale : 1)
            .animation(DSPress.animation, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSAvatarGroupPreviewHost: View {
    @State private var theme = DSTheme()

    private let team = [
        "Ada Lovelace", "Grace Hopper", "Alan Turing",
        "Katherine Johnson", "Linus Torvalds", "Margaret Hamilton",
        "Dennis Ritchie"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                labeled("Overflows to +N") { DSAvatarGroup(names: team) }
                labeled("Exact fit, no overflow") { DSAvatarGroup(names: Array(team.prefix(3))) }
                labeled("Compact, tighter overlap") { DSAvatarGroup(names: team, maxVisible: 5, size: DSSpacing.xxl, overlap: 0.45) }
                labeled("Tappable") { DSAvatarGroup(names: team, maxVisible: 3, size: DSSpacing.huge) {} }

                DSCard {
                    HStack(spacing: DSSpacing.md) {
                        DSAvatarGroup(names: team)
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text("Design Review").ds(.title3)
                            Text("7 people going").ds(.callout)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }

    private func labeled<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(title).ds(.overline, color: DSColors.textSecondary)
            content()
        }
    }
}

#Preview("Avatar Group — Light") {
    DSAvatarGroupPreviewHost().preferredColorScheme(.light)
}

#Preview("Avatar Group — Dark") {
    DSAvatarGroupPreviewHost().preferredColorScheme(.dark)
}
#endif
