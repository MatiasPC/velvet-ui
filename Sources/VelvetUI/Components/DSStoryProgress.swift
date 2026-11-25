import SwiftUI

// MARK: - Design System Story Progress
// The row of segments across the top of a story: one segment per page, the
// pages before the current one full, the current one filling as its time runs,
// the ones after it empty. When the current segment fills, the binding moves to
// the next page by itself; after the last one it calls `onFinish`. Stories and
// status updates, auto-advancing onboarding and product tours, a promo banner
// that rotates, workout intervals.
//
// Why not `DSPageControl` or `DSLinearProgress`: a page control shows where you
// are, not how long is left; a linear progress bar shows one value. Apps end up
// rebuilding this with a `Timer` per page that drifts, keeps running while
// paused, and races the user's own taps.
//
// The rules (which segments are full, the fill of the current one, what comes
// after the last page, stepping one page for VoiceOver, the spoken value) live
// in `DSStoryProgressLogic`, and the time spent on the current page, with
// pauses, lives in `DSStoryProgressClock`. Both are pure types the tests pin.
//
// Feel: the current segment fills linearly from a `TimelineView` clock, so it
// is smooth at any frame rate and stops drawing while paused. Skipping a page
// springs the segments it passes (`DSAnimation.springSnappy`); the segment
// that becomes current starts empty at once. An automatic advance is silent;
// a VoiceOver step fires a `.selection` tick. Under Reduce Motion skipped
// segments change in place. No borders: segments are `theme.subtleFill`
// capsules filled with the accent.

/// The story progress rules, kept out of the view so they can be tested.
enum DSStoryProgressLogic {
    /// The duration used when the one passed isn't a positive, finite number.
    static let defaultDuration: TimeInterval = 5

    /// What happens when the current page's time runs out.
    enum Step: Equatable {
        /// Move the binding to this page.
        case advance(to: Int)
        /// That was the last page: call `onFinish` and hold it full.
        case finish
    }

    /// Never negative.
    static func pageCount(_ numberOfPages: Int) -> Int {
        max(numberOfPages, 0)
    }

    /// `page` clamped to the pages that exist (0 when there are none).
    static func displayedPage(_ page: Int, numberOfPages: Int) -> Int {
        min(max(page, 0), max(numberOfPages - 1, 0))
    }

    /// A positive, finite duration; anything else falls back to the default.
    static func duration(_ duration: TimeInterval) -> TimeInterval {
        duration.isFinite && duration > 0 ? duration : defaultDuration
    }

    /// How full `segment` is, 0...1: full before the current page, `fraction`
    /// on it, empty after it.
    static func fill(segment: Int, currentPage: Int, fraction: Double) -> Double {
        if segment < currentPage { return 1 }
        if segment > currentPage { return 0 }
        guard fraction.isFinite else { return 0 }
        return min(max(fraction, 0), 1)
    }

    /// What follows `page` when its time runs out.
    static func next(after page: Int, numberOfPages: Int) -> Step {
        let current = displayedPage(page, numberOfPages: numberOfPages)
        return current < numberOfPages - 1 ? .advance(to: current + 1) : .finish
    }

    /// One page forward or back for VoiceOver, or nil at either end.
    static func step(from page: Int, by delta: Int, numberOfPages: Int) -> Int? {
        guard numberOfPages > 0 else { return nil }
        let from = displayedPage(page, numberOfPages: numberOfPages)
        let to = displayedPage(from + delta, numberOfPages: numberOfPages)
        return to == from ? nil : to
    }

    /// What VoiceOver reads after the label: "2 of 5". Empty with no pages.
    static func accessibilityValue(currentPage: Int, numberOfPages: Int) -> String {
        guard numberOfPages > 0 else { return "" }
        return "\(displayedPage(currentPage, numberOfPages: numberOfPages) + 1) of \(numberOfPages)"
    }
}

/// The time spent on one page, read from the wall clock and paused without
/// losing what has run. A new page starts it from zero.
struct DSStoryProgressClock: Equatable {
    /// The page this clock is timing.
    private(set) var page: Int
    /// Time run before the latest resume.
    private(set) var accumulated: TimeInterval = 0
    /// When it last resumed; nil while paused.
    private(set) var resumedAt: Date?
    /// True once the last page's time ran out (held full until the page changes).
    private(set) var isFinished = false

    init(page: Int, isPaused: Bool, at now: Date) {
        self.page = page
        self.resumedAt = isPaused ? nil : now
    }

    /// Time spent on `page` so far.
    func elapsed(at now: Date) -> TimeInterval {
        guard let resumedAt else { return accumulated }
        return accumulated + max(0, now.timeIntervalSince(resumedAt))
    }

    /// Time left on `page` before it is done.
    func remaining(at now: Date, duration: TimeInterval) -> TimeInterval {
        max(0, duration - elapsed(at: now))
    }

    /// How full the current segment is, 0...1. Zero for any page other than
    /// the one being timed (a page that just became current starts empty).
    func fraction(for page: Int, at now: Date, duration: TimeInterval) -> Double {
        guard page == self.page else { return 0 }
        guard !isFinished, duration > 0 else { return 1 }
        return min(max(elapsed(at: now) / duration, 0), 1)
    }

    /// Brings the clock in line with the view: a different page restarts it
    /// from zero; a pause banks the time run so far; a resume starts it again.
    mutating func sync(page: Int, isPaused: Bool, at now: Date) {
        guard page == self.page else {
            self = DSStoryProgressClock(page: page, isPaused: isPaused, at: now)
            return
        }
        if isPaused, let resumedAt {
            accumulated += max(0, now.timeIntervalSince(resumedAt))
            self.resumedAt = nil
        } else if !isPaused, resumedAt == nil {
            resumedAt = now
        }
    }

    /// The last page ran out: hold it full and stop timing.
    mutating func finish() {
        isFinished = true
    }
}

private enum Metrics {
    /// The height of a segment: DSSpacing.xxs (4).
    static let height: CGFloat = DSSpacing.xxs
    /// The gap between segments: DSSpacing.xxs (4).
    static let gap: CGFloat = DSSpacing.xxs
}

/// The row of segments across the top of a story: one per page, the current
/// one filling as its time runs. When it fills, `currentPage` moves on by
/// itself; after the last page it calls `onFinish`.
///
/// Change `currentPage` yourself (a tap on the left or right half of the
/// story) and the new page starts from zero. Pause with `isPaused` while the
/// person holds the story, while a sheet is up, or while the app is in the
/// background.
public struct DSStoryProgress: View {
    @Binding private var currentPage: Int
    private let numberOfPages: Int
    private let duration: TimeInterval
    private let isPaused: Bool
    private let accent: Color?
    private let label: String
    private let onFinish: (() -> Void)?

    @State private var clock: DSStoryProgressClock

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - currentPage: The page showing. The control moves it on when a page's time runs out.
    ///   - numberOfPages: How many pages (segments) there are.
    ///   - duration: Seconds each page stays up. Defaults to 5.
    ///   - isPaused: Holds the current segment where it is while true.
    ///   - accent: The fill of the segments. Defaults to the theme accent.
    ///   - accessibilityLabel: What VoiceOver reads before "2 of 5". Defaults to "Story".
    ///   - onFinish: Called once when the last page's time runs out. Called
    ///     again after `currentPage` moves away and the last page runs out again.
    public init(
        currentPage: Binding<Int>,
        numberOfPages: Int,
        duration: TimeInterval = 5,
        isPaused: Bool = false,
        accent: Color? = nil,
        accessibilityLabel: String = "Story",
        onFinish: (() -> Void)? = nil
    ) {
        self._currentPage = currentPage
        self.numberOfPages = numberOfPages
        self.duration = duration
        self.isPaused = isPaused
        self.accent = accent
        self.label = accessibilityLabel
        self.onFinish = onFinish
        self._clock = State(initialValue: DSStoryProgressClock(
            page: DSStoryProgressLogic.displayedPage(currentPage.wrappedValue, numberOfPages: numberOfPages),
            isPaused: isPaused,
            at: .now
        ))
    }

    private var pageCount: Int { DSStoryProgressLogic.pageCount(numberOfPages) }

    private var displayedPage: Int {
        DSStoryProgressLogic.displayedPage(currentPage, numberOfPages: numberOfPages)
    }

    private var pageDuration: TimeInterval { DSStoryProgressLogic.duration(duration) }

    /// The clock only needs frames while the current segment is filling.
    private var isTimelinePaused: Bool {
        isPaused || clock.isFinished || pageCount == 0
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: isTimelinePaused)) { context in
            let fraction = clock.fraction(for: displayedPage, at: context.date, duration: pageDuration)
            HStack(spacing: Metrics.gap) {
                ForEach(0..<pageCount, id: \.self) { index in
                    segment(index, fraction: fraction)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.height)
        .task(id: RunKey(page: displayedPage, isPaused: isPaused, duration: pageDuration, count: pageCount)) {
            await run()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(DSStoryProgressLogic.accessibilityValue(currentPage: currentPage, numberOfPages: numberOfPages))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(1)
            case .decrement: step(-1)
            @unknown default: break
            }
        }
        .accessibilityHidden(pageCount == 0)
    }

    // MARK: Segments

    private func segment(_ index: Int, fraction: Double) -> some View {
        let isCurrent = index == displayedPage
        let fill = DSStoryProgressLogic.fill(segment: index, currentPage: displayedPage, fraction: fraction)

        return Capsule(style: .continuous)
            .fill(theme.subtleFill)
            .overlay {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(accent ?? theme.accent)
                        .frame(width: geometry.size.width * fill)
                        // The segment that becomes current starts empty at once;
                        // the ones a skip passes spring to full or empty.
                        .animation(isCurrent || reduceMotion ? nil : DSAnimation.springSnappy, value: displayedPage)
                }
            }
            .clipShape(Capsule(style: .continuous))
    }

    // MARK: Behavior

    /// Restarted by SwiftUI whenever one of these changes.
    private struct RunKey: Equatable {
        let page: Int
        let isPaused: Bool
        let duration: TimeInterval
        let count: Int
    }

    /// Brings the clock in line with the page and pause state, then sleeps
    /// until the current page's time runs out and moves on (or finishes).
    private func run() async {
        clock.sync(page: displayedPage, isPaused: isPaused, at: .now)
        guard pageCount > 0, !isPaused, !clock.isFinished else { return }

        while !Task.isCancelled {
            let left = clock.remaining(at: .now, duration: pageDuration)
            if left > 0 {
                try? await Task.sleep(for: .seconds(left))
                continue
            }
            switch DSStoryProgressLogic.next(after: displayedPage, numberOfPages: numberOfPages) {
            case .advance(let page):
                currentPage = page          // a new RunKey restarts the clock for it
            case .finish:
                clock.finish()
                onFinish?()
            }
            return
        }
    }

    /// One page forward or back from VoiceOver.
    private func step(_ delta: Int) {
        guard let page = DSStoryProgressLogic.step(from: currentPage, by: delta, numberOfPages: numberOfPages) else { return }
        DSHapticEngine.shared.fire(.selection)
        currentPage = page
    }
}

// MARK: - Preview

#if DEBUG
private struct DSStoryProgressPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var page = 0
    @State private var isPaused = false
    @State private var tourPage = 0

    private let stories = ["Lisbon", "Porto", "Sintra", "Madeira"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        DSStoryProgress(currentPage: $page, numberOfPages: stories.count, duration: 3, isPaused: isPaused) {
                            page = 0
                        }
                        Text(stories[page]).ds(.largeTitle)
                        Text("Hold the card to pause").ds(.footnote, color: DSColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 0.2, perform: {}, onPressingChanged: { isPaused = $0 })
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Product tour, custom accent").ds(.overline, color: DSColors.textSecondary)
                    DSStoryProgress(currentPage: $tourPage, numberOfPages: 3, duration: 4, accent: DSColors.secondary, accessibilityLabel: "Tour")
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Story Progress — Light") {
    DSStoryProgressPreviewHost().preferredColorScheme(.light)
}

#Preview("Story Progress — Dark") {
    DSStoryProgressPreviewHost().preferredColorScheme(.dark)
}
#endif
