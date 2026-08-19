import SwiftUI

// MARK: - Design System Avatar Group
// A "facepile" — a row of overlapping avatars that shows who's on a thread,
// who's in a space, or who reacted. Past a configurable limit the remainder
// collapses into a "+N" bubble. Each avatar wears a ring in the surface color
// so the stack reads cleanly on any background, and the row springs in with a
// gentle stagger. Builds on `DSAvatar`, so it themes and scales identically.

public struct DSAvatarGroup: View {

    // MARK: - Member

    /// A single participant rendered in the group.
    public struct Member: Identifiable {
        public let id: String
        public let name: String
        public let imageURL: URL?

        public init(id: String = UUID().uuidString, name: String, imageURL: URL? = nil) {
            self.id = id
            self.name = name
            self.imageURL = imageURL
        }
    }

    private let members: [Member]
    private let maxVisible: Int
    private let size: CGFloat
    private let overlap: CGFloat
    private let ringWidth: CGFloat
    private let ringColor: Color
    private let haptic: DSHapticStyle
    private let action: (() -> Void)?

    @State private var appeared = false

    /// Create an avatar group.
    /// - Parameters:
    ///   - members: The people to display, in priority order (first is drawn on top).
    ///   - maxVisible: Maximum circles to show. When exceeded, the last slot becomes a "+N" bubble.
    ///   - size: Diameter of each avatar.
    ///   - overlap: Fraction (0–0.9) each avatar overlaps its neighbor.
    ///   - ringWidth: Width of the surface-colored separating ring around each avatar.
    ///   - ringColor: Ring fill — set this to the background the pile sits on.
    ///   - haptic: Feedback fired when the group is tapped (only when `action` is set).
    ///   - action: Optional tap handler for the whole pile (e.g. open a member list).
    public init(
        members: [Member],
        maxVisible: Int = 4,
        size: CGFloat = 40,
        overlap: CGFloat = 0.32,
        ringWidth: CGFloat = 2,
        ringColor: Color = DSColors.defaultPalette.backgroundPrimary,
        haptic: DSHapticStyle = .light,
        action: (() -> Void)? = nil
    ) {
        self.members = members
        self.maxVisible = max(1, maxVisible)
        self.size = size
        self.overlap = min(max(overlap, 0), 0.9)
        self.ringWidth = ringWidth
        self.ringColor = ringColor
        self.haptic = haptic
        self.action = action
    }

    /// Convenience initializer from a list of names (initials-only avatars).
    public init(
        names: [String],
        maxVisible: Int = 4,
        size: CGFloat = 40,
        overlap: CGFloat = 0.32,
        ringWidth: CGFloat = 2,
        ringColor: Color = DSColors.defaultPalette.backgroundPrimary,
        haptic: DSHapticStyle = .light,
        action: (() -> Void)? = nil
    ) {
        self.init(
            members: names.map { Member(name: $0) },
            maxVisible: maxVisible,
            size: size,
            overlap: overlap,
            ringWidth: ringWidth,
            ringColor: ringColor,
            haptic: haptic,
            action: action
        )
    }

    public var body: some View {
        Group {
            if let action {
                Button {
                    DSHapticEngine.shared.fire(haptic)
                    action()
                } label: {
                    pile
                }
                .buttonStyle(.plain)
            } else {
                pile
            }
        }
        .onAppear { appeared = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Pile

    private var pile: some View {
        HStack(spacing: -(ringedSize * overlap)) {
            ForEach(Array(visibleMembers.enumerated()), id: \.element.id) { index, member in
                ringed {
                    DSAvatar(name: member.name, imageURL: member.imageURL, size: size)
                }
                .zIndex(Double(totalCircles - index))
                .modifier(EntranceModifier(appeared: appeared, index: index))
            }

            if overflowCount > 0 {
                ringed { overflowBubble }
                    .zIndex(0)
                    .modifier(EntranceModifier(appeared: appeared, index: visibleMembers.count))
            }
        }
        .contentShape(Rectangle())
    }

    private var overflowBubble: some View {
        ZStack {
            Circle()
                .fill(DSColors.defaultPalette.backgroundSecondary)

            Text("+\(overflowCount)")
                .font(.system(size: size * 0.34, weight: .semibold, design: .rounded))
                .foregroundStyle(DSColors.defaultPalette.textSecondary)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, DSSpacing.xxxs)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Ring

    @ViewBuilder
    private func ringed<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(ringWidth)
            .background(Circle().fill(ringColor))
    }

    // MARK: - Layout Math

    private var ringedSize: CGFloat { size + ringWidth * 2 }

    private var visibleMembers: [Member] {
        guard members.count > maxVisible else { return members }
        return Array(members.prefix(max(0, maxVisible - 1)))
    }

    private var overflowCount: Int {
        max(0, members.count - visibleMembers.count)
    }

    private var totalCircles: Int {
        visibleMembers.count + (overflowCount > 0 ? 1 : 0)
    }

    private var accessibilityLabel: Text {
        guard !members.isEmpty else { return Text("No people") }
        let names = members.map(\.name).joined(separator: ", ")
        return Text("\(members.count) people: \(names)")
    }
}

// MARK: - Entrance Animation

/// Staggered spring pop used as each avatar enters.
private struct EntranceModifier: ViewModifier {
    let appeared: Bool
    let index: Int

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)
            .animation(DSAnimation.springBouncy.delay(Double(index) * 0.06), value: appeared)
    }
}

// MARK: - Preview

private struct DSAvatarGroupPreviewHost: View {
    private let team = [
        "Ada Lovelace", "Grace Hopper", "Alan Turing",
        "Katherine Johnson", "Linus Torvalds", "Margaret Hamilton",
        "Dennis Ritchie"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Overflows to +N").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSAvatarGroup(names: team)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Exact fit, no overflow").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSAvatarGroup(names: Array(team.prefix(3)))
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Compact & tighter overlap").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSAvatarGroup(names: team, maxVisible: 5, size: 28, overlap: 0.45)
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Tappable (fires haptic)").ds(.footnote, color: DSColors.defaultPalette.textSecondary)
                DSAvatarGroup(names: team, maxVisible: 3, size: 44) { }
            }

            // Sits on an elevated surface — match the ring to that color.
            DSCard(style: .elevated) {
                HStack(spacing: DSSpacing.md) {
                    DSAvatarGroup(
                        names: team,
                        maxVisible: 4,
                        ringColor: DSColors.defaultPalette.backgroundElevated
                    )
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text("Design Review").ds(.title3)
                        Text("7 people going")
                            .ds(.callout, color: DSColors.defaultPalette.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(DSSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DSColors.defaultPalette.backgroundPrimary)
    }
}

#Preview("Avatar Group — Light") {
    DSAvatarGroupPreviewHost()
        .preferredColorScheme(.light)
}

#Preview("Avatar Group — Dark") {
    DSAvatarGroupPreviewHost()
        .preferredColorScheme(.dark)
}
