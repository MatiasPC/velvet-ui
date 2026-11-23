import SwiftUI

// MARK: - Design System Section Index
// The column of letters along the trailing edge of a long list (contacts,
// countries, a glossary, an ingredient list, a music library) that jumps to a
// section. Touch a letter and the list jumps there; slide along the column and
// it keeps jumping, one selection tick per section. While the finger is down the
// letters near it fan out toward the list, the one under it turns accent, and a
// bubble beside the finger shows the section in large type, so the thumb never
// hides what it is pointing at.
//
// When the column is too short for every title, it collapses the way the system
// index does: title, dot, title, …, always keeping the first and the last. The
// dots are not dead space: sliding over one walks through the titles it stands
// for, so every section stays reachable.
//
// Why these mechanisms: which section the finger is over, and how far each
// letter fans out, are pure functions of the finger's y, so they live in
// `DSSectionIndexLogic` and ride `DSAnimation.interactive`. The fan is laid out
// with padding inside a fixed-width frame (not `offset`), so it follows the
// layout direction: in a right-to-left list the column sits on the left and fans
// to the right. The jump is the caller's: the component calls `action` with the
// title, and the caller scrolls (`ScrollViewReader.scrollTo`), without animation,
// as the system index does.

/// The rules of the index: which entries fit, which title a finger is over, how
/// far each letter fans out, and VoiceOver steps. Pure, so tests can pin it.
enum DSSectionIndexLogic {
    /// One row of the column: a title, or a dot standing for the titles hidden
    /// between `after` and `before` when the column is too short for all of them.
    enum Entry: Hashable {
        case title(Int)
        case dot(after: Int, before: Int)
    }

    /// How far the letter under the finger moves toward the list.
    static let peakShift: CGFloat = DSSpacing.lg
    /// Scale of the letter under the finger.
    static let peakScale: CGFloat = 1.5
    /// The fan falls off to nothing this many rows from the finger.
    static let reach: CGFloat = 2.5

    /// The entries to draw for `count` titles in a column with room for
    /// `capacity` rows. Every title when they fit; otherwise an odd number of
    /// rows, title and dot alternating, with the first and last titles always
    /// shown and the shown titles spread evenly. Never fewer than three rows
    /// (first, dot, last), however short the column.
    static func entries(count: Int, capacity: Int) -> [Entry] {
        guard count > 0 else { return [] }
        if capacity >= count || count <= 2 { return (0..<count).map(Entry.title) }
        let slots = max(3, capacity % 2 == 0 ? capacity - 1 : capacity)
        let shown = min(count - 1, (slots + 1) / 2)
        let step = Double(count - 1) / Double(shown - 1)
        var result: [Entry] = []
        var previous = 0
        for k in 0..<shown {
            let index = Int((Double(k) * step).rounded())
            if k > 0 { result.append(.dot(after: previous, before: index)) }
            result.append(.title(index))
            previous = index
        }
        return result
    }

    /// The number of rows that fit in `height`, or `Int.max` for an unmeasured column.
    static func capacity(height: CGFloat, row: CGFloat) -> Int {
        guard height.isFinite, row > 0 else { return .max }
        return max(0, Int((height / row).rounded(.down)))
    }

    /// The entry row under a finger at `y`, measured from the top of the first
    /// row. A finger above or below the column is held on the end row.
    static func row(atY y: CGFloat, rowHeight: CGFloat, rows: Int) -> Int? {
        guard rows > 0, rowHeight > 0, y.isFinite else { return nil }
        let position = min(max(y / rowHeight, 0), CGFloat(rows))
        return min(Int(position.rounded(.down)), rows - 1)
    }

    /// The title under a finger at `y`. On a title row, that title. On a dot, the
    /// hidden titles share the dot's row from top to bottom, so sliding across it
    /// walks through each of them; a dot that hides nothing splits its row
    /// between its neighbours.
    static func title(atY y: CGFloat, rowHeight: CGFloat, entries: [Entry]) -> Int? {
        guard let row = row(atY: y, rowHeight: rowHeight, rows: entries.count) else { return nil }
        switch entries[row] {
        case .title(let index):
            return index
        case .dot(let after, let before):
            let within = min(max(y / rowHeight - CGFloat(row), 0), 1)
            let hidden = before - after - 1
            guard hidden > 0 else { return within < 0.5 ? after : before }
            return after + 1 + min(Int((within * CGFloat(hidden)).rounded(.down)), hidden - 1)
        }
    }

    /// How strongly row `row` fans out with the finger at `fingerY`: 1 right
    /// under the finger, easing to 0 at `reach` rows away, 0 with no finger.
    static func fan(row: Int, fingerY: CGFloat?, rowHeight: CGFloat, rows: Int) -> CGFloat {
        guard let fingerY, fingerY.isFinite, rowHeight > 0, rows > 0 else { return 0 }
        let y = min(max(fingerY, 0), CGFloat(rows) * rowHeight)
        let distance = abs(y - (CGFloat(row) + 0.5) * rowHeight) / rowHeight
        let t = max(0, 1 - distance / reach)
        return t * t * (3 - 2 * t)   // smoothstep: no kink at the edge of the fan
    }

    /// The row an entry for title `index` sits on, or the dot that stands for it.
    static func row(ofTitle index: Int, in entries: [Entry]) -> Int? {
        entries.firstIndex { entry in
            switch entry {
            case .title(let shown): return shown == index
            case .dot(let after, let before): return index > after && index < before
            }
        }
    }

    /// One VoiceOver swipe from the current title (`nil` before any jump, which
    /// reads as the first). Up moves to the next section, down to the previous;
    /// the ends stay put. Returns the title to jump to, or `nil` when there is
    /// nothing to do. Before any jump, down from the first jumps to it.
    static func adjusted(_ current: Int?, count: Int, increment: Bool) -> Int? {
        guard count > 0 else { return nil }
        let from = min(max(current ?? 0, 0), count - 1)
        let to = increment ? min(from + 1, count - 1) : max(from - 1, 0)
        return to == current ? nil : to
    }

    /// VoiceOver value: the current title, the first before any jump.
    static func accessibilityValue(_ current: Int?, titles: [String]) -> String {
        guard !titles.isEmpty else { return "" }
        return titles[min(max(current ?? 0, 0), titles.count - 1)]
    }
}

/// One drag along the column: the title under the finger, and when to jump.
struct DSSectionIndexTracker: Equatable {
    /// The title the finger is over.
    private(set) var hovered: Int?
    /// The finger's y while the finger is down, for the fan.
    private(set) var fingerY: CGFloat?

    var isTracking: Bool { fingerY != nil }

    /// Moves the finger. Returns `true` when it is over a different title than
    /// before, including the first touch: that is a jump, and a tick.
    mutating func move(to index: Int?, y: CGFloat) -> Bool {
        fingerY = y
        guard let index, index != hovered else { return false }
        hovered = index
        return true
    }

    /// Ends the drag.
    mutating func end() {
        self = DSSectionIndexTracker()
    }
}

private enum Metrics {
    /// Column width: Apple's 44 pt target, from tokens (32 + 12).
    static let width: CGFloat = DSSpacing.xxl + DSSpacing.sm
    /// One row of the column at the default text size.
    static let row: CGFloat = DSSpacing.md
    /// The dot that stands for hidden titles.
    static let dot: CGFloat = DSSpacing.xxs
    /// The bubble that shows the current title beside the finger.
    static let bubble: CGFloat = DSSpacing.massive
    /// Gap between the bubble and the column.
    static let bubbleGap: CGFloat = DSSpacing.lg
    /// Inset of the glass track inside the column while the finger is down.
    static let trackInset: CGFloat = DSSpacing.xs
    /// Opacity of a disabled index, the same as `DSToggle`.
    static let disabledOpacity: Double = 0.5
}

/// A column of section titles along the edge of a long list. Touch or slide
/// along it to jump between sections.
///
/// Place it over the trailing edge of a scroll view and scroll in `action`:
///
/// ```swift
/// ScrollViewReader { proxy in
///     ScrollView { … each section header has .id(title) … }
///         .overlay(alignment: .trailing) {
///             DSSectionIndex(titles) { title in proxy.scrollTo(title, anchor: .top) }
///         }
/// }
/// ```
///
/// `action` runs on the first touch and each time the finger reaches another
/// title, with a selection tick each time. While the finger is down the letters
/// near it fan out toward the list and a bubble beside it shows the title. When
/// the column is too short for every title, it shows title, dot, title, … and
/// sliding over a dot walks through the titles it hides.
public struct DSSectionIndex: View {
    private let titles: [String]
    private let accent: Color?
    private let label: String
    private let action: (String) -> Void

    // MARK: State

    @State private var tracker = DSSectionIndexTracker()
    /// The last title jumped to, for VoiceOver. `nil` before any jump.
    @State private var current: Int?
    /// The column's height, to decide how many titles fit. Unmeasured: all of them.
    @State private var available: CGFloat = .infinity
    /// Whether the finger is on the column. A `GestureState`, so it also clears
    /// when the system cancels the touch without calling `onEnded`.
    @GestureState private var isPressing = false
    @ScaledMetric(relativeTo: .caption2) private var row: CGFloat = Metrics.row
    @ScaledMetric(relativeTo: .caption2) private var width: CGFloat = Metrics.width
    @ScaledMetric(relativeTo: .title1) private var bubble: CGFloat = Metrics.bubble

    @DSThemed private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Init

    /// - Parameters:
    ///   - titles: The section titles, top to bottom, usually letters ("A", "B", …).
    ///     Pass only sections the list has, so every jump lands somewhere.
    ///   - accent: Color of the title under the finger and of the bubble. Defaults to the theme accent.
    ///   - accessibilityLabel: What VoiceOver calls the index. Defaults to "Section index".
    ///   - action: Called with the title to jump to. Scroll there without animation.
    public init(
        _ titles: [String],
        accent: Color? = nil,
        accessibilityLabel: String = "Section index",
        action: @escaping (String) -> Void
    ) {
        self.titles = titles
        self.accent = accent
        self.label = accessibilityLabel
        self.action = action
    }

    // MARK: Body

    public var body: some View {
        let entries = DSSectionIndexLogic.entries(
            count: titles.count,
            capacity: DSSectionIndexLogic.capacity(height: available, row: row)
        )
        column(entries)
            .frame(width: width)
            .frame(maxHeight: CGFloat(titles.count) * row)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                available = height
            }
            .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
            .onChange(of: isPressing) { _, pressing in
                // A touch the system took away never reaches `onEnded`: settle.
                if !pressing && tracker.isTracking {
                    withAnimation(motion(DSAnimation.springSnappy)) { tracker.end() }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(DSSectionIndexLogic.accessibilityValue(current, titles: titles))
            .accessibilityAdjustableAction { direction in
                guard isEnabled else { return }
                switch direction {
                case .increment: adjust(increment: true)
                case .decrement: adjust(increment: false)
                @unknown default: break
                }
            }
            .accessibilityHidden(titles.isEmpty)
    }

    // MARK: Column

    private func column(_ entries: [DSSectionIndexLogic.Entry]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element) { position, entry in
                cell(entry, row: position, rows: entries.count)
            }
        }
        .frame(width: width)
        .background {
            Color.clear
                .dsSurface(.glassThin, radius: DSRadius.chip)
                .padding(.horizontal, Metrics.trackInset)
                .opacity(tracker.isTracking ? 1 : 0)
        }
        .overlay(alignment: .topLeading) {
            if let hovered = tracker.hovered, titles.indices.contains(hovered),
               let line = DSSectionIndexLogic.row(ofTitle: hovered, in: entries) {
                bubbleView(titles[hovered], centreY: (CGFloat(line) + 0.5) * row)
            }
        }
        .contentShape(Rectangle())
        .gesture(dragGesture(entries), including: isEnabled ? .all : .none)
    }

    @ViewBuilder
    private func cell(_ entry: DSSectionIndexLogic.Entry, row position: Int, rows: Int) -> some View {
        let fan = reduceMotion ? 0 : DSSectionIndexLogic.fan(
            row: position, fingerY: tracker.fingerY, rowHeight: row, rows: rows
        )
        Group {
            switch entry {
            case .title(let index):
                let isHovered = tracker.hovered == index
                Text(titles[index])
                    .ds(.caption2, color: isHovered ? (accent ?? theme.accent) : theme.ink)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .scaleEffect(1 + (DSSectionIndexLogic.peakScale - 1) * fan)
            case .dot:
                Circle()
                    .fill(theme.palette.textTertiary)
                    .frame(width: Metrics.dot, height: Metrics.dot)
            }
        }
        // The fan: padding on the trailing side pushes the letter toward the
        // list, and the fixed-width frame lets it spill out on the leading side.
        // Unlike `offset`, this follows the layout direction.
        .frame(width: width, height: row)
        .padding(.trailing, DSSectionIndexLogic.peakShift * fan)
        .frame(width: width, alignment: .trailing)
        .zIndex(Double(fan))
    }

    private func bubbleView(_ title: String, centreY: CGFloat) -> some View {
        let fill = accent ?? theme.accent
        return Text(title)
            .ds(.title1, color: theme.onAccent)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(DSSpacing.xs)
            .frame(width: bubble, height: bubble)
            .background(fill, in: Circle())
            .dsShadow(.md)
            // Trailing edge a gap before the column, centre on the hovered row.
            .alignmentGuide(.leading) { d in d[.trailing] + Metrics.bubbleGap }
            .alignmentGuide(.top) { d in d[VerticalAlignment.center] - centreY }
            .transition(reduceMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: Gesture

    private func dragGesture(_ entries: [DSSectionIndexLogic.Entry]) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isPressing) { _, state, _ in state = true }
            .onChanged { gesture in
                guard isEnabled else { return }
                let y = gesture.location.y
                let index = DSSectionIndexLogic.title(atY: y, rowHeight: row, entries: entries)
                let jumps = withAnimation(motion(DSAnimation.interactive)) {
                    tracker.move(to: index, y: y)
                }
                guard jumps, let index, titles.indices.contains(index) else { return }
                jump(to: index)
            }
            .onEnded { _ in
                withAnimation(motion(DSAnimation.springSnappy)) { tracker.end() }
            }
    }

    // MARK: Behavior

    /// Tells the caller, ticks, and remembers the title for VoiceOver.
    private func jump(to index: Int) {
        current = index
        DSHapticEngine.shared.fire(.selection)
        action(titles[index])
    }

    /// The VoiceOver adjustable action: one section at a time.
    private func adjust(increment: Bool) {
        guard let index = DSSectionIndexLogic.adjusted(current, count: titles.count, increment: increment) else { return }
        jump(to: index)
    }

    /// `animation`, or none under Reduce Motion.
    private func motion(_ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

// MARK: - Preview

#if DEBUG
private struct DSSectionIndexPreviewHost: View {
    @State private var theme = DSTheme()
    private let sections: [(String, [String])] = [
        ("A", ["Ada", "Alan", "Anita"]), ("B", ["Barbara", "Bjarne"]), ("C", ["Claude", "Corrado"]),
        ("D", ["Donald", "Dennis"]), ("E", ["Edsger", "Erich"]), ("F", ["Frances", "Fred"]),
        ("G", ["Grace", "Guido"]), ("J", ["Jean", "John"]), ("K", ["Ken", "Kristen"]),
        ("L", ["Leslie", "Linus"]), ("M", ["Margaret", "Mary"]), ("N", ["Niklaus"]),
        ("R", ["Radia", "Rob"]), ("S", ["Shafi", "Sophie"]), ("T", ["Tim", "Tony"]),
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DSSpacing.xs, pinnedViews: .sectionHeaders) {
                    DSPreviewThemeDots(theme: theme)
                    ForEach(sections, id: \.0) { title, names in
                        Section {
                            ForEach(names, id: \.self) { Text($0).ds(.body) }
                        } header: {
                            Text(title).ds(.overline, color: DSColors.textSecondary).id(title)
                        }
                    }
                }
                .dsScreenPadding()
            }
            .overlay(alignment: .trailing) {
                DSSectionIndex(sections.map(\.0)) { title in
                    proxy.scrollTo(title, anchor: .top)
                }
                .padding(.vertical, DSSpacing.xl)
            }
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("SectionIndex — Light") {
    DSSectionIndexPreviewHost().preferredColorScheme(.light)
}

#Preview("SectionIndex — Dark") {
    DSSectionIndexPreviewHost().preferredColorScheme(.dark)
}
#endif
