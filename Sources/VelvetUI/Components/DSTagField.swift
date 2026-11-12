import SwiftUI

// MARK: - Design System Tag Field
// A text field that turns what you type into tags: the recipients of an
// invite, the skills on a profile, the labels on a post, the keywords of a
// saved search. Type a word and press Return (or a comma) and it springs into
// an accent pill inside the field; the caret moves on, ready for the next one.
// Pasting "design, swift, ios" adds all three at once.
//
// `DSChipGroup` picks from options the app already knows; this field collects
// values the person invents. The two pair well: chips for suggestions, the
// field for what's chosen.
//
// The rules (trim and collapse whitespace, ignore blanks, refuse a duplicate in
// any letter case, stop at `maxTags`, split a paste at its separators) live in
// `DSTagFieldLogic`, a pure type the tests pin.
//
// Feel: a new tag pops in with `DSAnimation.springSnappy` and fires `haptic`
// (one tap per commit, however many tags a paste adds). A duplicate wiggles the
// tag that's already there with `dsJiggle`, and a full field wiggles the draft;
// both fire `.warning`, the same refusal vocabulary as `DSKeypad`. Tapping a
// tag removes it. On a hardware keyboard, Delete on an empty draft first
// highlights the last tag, then removes it, the way Mail treats recipients.
//
// No borders: the field is a flat `theme.subtleFill` well (it usually sits on a
// card, and glass on glass turns muddy), with `dsFocusGlow` while editing.

/// The tag-editing rules, kept out of the view so they can be tested.
enum DSTagFieldLogic {
    /// Characters that end a tag while typing or in a paste. Return also ends one.
    static let separators: Set<Character> = [",", "\n", "\r", ";"]

    /// Why a tag was not added.
    enum Refusal: Equatable {
        /// The tag is already there (compared ignoring case); the index of the existing one.
        case duplicate(index: Int)
        /// The field already holds `maxTags` tags.
        case full
    }

    /// What committing one piece of text does.
    enum Outcome: Equatable {
        /// Nothing to add (blank after trimming); no feedback.
        case ignored
        /// The tag was appended; the new list.
        case added([String])
        /// The tag was refused; the list is unchanged.
        case refused(Refusal)
    }

    /// The result of feeding the draft through the separators.
    struct Ingest: Equatable {
        /// The tags after every complete piece was committed.
        var tags: [String]
        /// What stays in the text field.
        var draft: String
        /// The tags that were added, in order.
        var added: [String]
        /// The refusals, in order.
        var refusals: [Refusal]
    }

    /// What Delete on the keyboard does.
    enum Backspace: Equatable {
        /// The draft has text (or there are no tags): let the text field handle it.
        case passThrough
        /// Highlight the last tag; the next Delete removes it.
        case arm
        /// Remove the last tag.
        case removeLast
    }

    /// A tag as it will be stored: trimmed, with every run of whitespace collapsed to one space.
    static func normalized(_ raw: String) -> String {
        raw.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).joined(separator: " ")
    }

    /// The index of the tag equal to `tag` ignoring case, if there is one.
    static func index(of tag: String, in tags: [String]) -> Int? {
        tags.firstIndex { $0.compare(tag, options: .caseInsensitive) == .orderedSame }
    }

    /// The limit in effect: `nil` (or less than 1) means none.
    static func limit(_ maxTags: Int?) -> Int? {
        maxTags.flatMap { $0 > 0 ? $0 : nil }
    }

    /// Commits `raw` as one tag.
    static func add(_ raw: String, to tags: [String], maxTags: Int?) -> Outcome {
        let tag = normalized(raw)
        guard !tag.isEmpty else { return .ignored }
        if let existing = index(of: tag, in: tags) { return .refused(.duplicate(index: existing)) }
        if let limit = limit(maxTags), tags.count >= limit { return .refused(.full) }
        return .added(tags + [tag])
    }

    /// Splits `draft` at the separators. Every piece before the last separator
    /// is complete; the text after it is still being typed.
    static func split(_ draft: String) -> (complete: [String], remainder: String) {
        let pieces = draft.split(omittingEmptySubsequences: false, whereSeparator: { separators.contains($0) })
        guard pieces.count > 1 else { return ([], draft) }
        return (pieces.dropLast().map(String.init), String(pieces.last ?? ""))
    }

    /// Commits every complete piece of `draft` and keeps the rest as the new draft.
    ///
    /// With `commitRemainder` (Return, or the field losing focus) the text after
    /// the last separator is committed too. A piece that doesn't fit because the
    /// field is full stays in the draft instead of being lost, so the person
    /// sees what didn't go in.
    static func ingest(_ draft: String, into tags: [String], maxTags: Int?, commitRemainder: Bool = false) -> Ingest {
        var (pieces, remainder) = split(draft)
        if commitRemainder {
            pieces.append(remainder)
            remainder = ""
        }
        var result = Ingest(tags: tags, draft: remainder, added: [], refusals: [])
        for piece in pieces {
            switch add(piece, to: result.tags, maxTags: maxTags) {
            case .ignored:
                continue
            case .added(let next):
                result.tags = next
                result.added.append(normalized(piece))
            case .refused(let refusal):
                result.refusals.append(refusal)
                if refusal == .full {
                    result.draft = normalized(piece)
                    return result
                }
            }
        }
        return result
    }

    /// Delete pressed on the keyboard, with `draft` in the field and `armed`
    /// telling whether the last tag is already highlighted.
    static func backspace(draft: String, tagCount: Int, armed: Bool) -> Backspace {
        guard draft.isEmpty, tagCount > 0 else { return .passThrough }
        return armed ? .removeLast : .arm
    }

    /// What VoiceOver hears after a commit or a removal.
    static func announcement(added: [String] = [], refusals: [Refusal] = [], removed: String? = nil, tags: [String]) -> String? {
        var parts: [String] = []
        if !added.isEmpty { parts.append("Added " + added.joined(separator: ", ")) }
        if let removed { parts.append("Removed \(removed)") }
        for refusal in refusals {
            switch refusal {
            case .duplicate(let index) where tags.indices.contains(index):
                parts.append("\(tags[index]) is already added")
            case .duplicate:
                parts.append("Already added")
            case .full:
                parts.append("Tag limit reached")
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: ". ")
    }
}

private enum Metrics {
    /// The field never gets shorter than a comfortable touch target: DSSpacing.huge (48).
    static let minHeight: CGFloat = DSSpacing.huge
    /// The draft keeps at least this much room on its line before wrapping (128).
    static let draftMinWidth: CGFloat = DSSpacing.massive * 2
    /// A highlighted tag (armed for removal) grows this much.
    static let armedScale: CGFloat = 1.06
    /// Opacity of a disabled field, the same as `DSToggle`.
    static let disabledOpacity: Double = 0.5
}

/// A text field that collects tags: type a word, press Return or a comma, and it
/// becomes a pill inside the field. Tap a pill to remove it.
///
/// Bind it to an array of strings. Tags are trimmed, never blank, and unique
/// ignoring case; a duplicate or a tag past `maxTags` is refused with a warning
/// haptic and a wiggle, and the list is left as it was.
public struct DSTagField: View {
    @Binding private var tags: [String]
    private let placeholder: String
    private let maxTags: Int?
    private let accent: Color?
    private let haptic: DSHapticStyle

    @State private var draft = ""
    /// The last tag is highlighted and the next Delete removes it.
    @State private var armed = false
    /// One counter per tag (lower-cased), bumped to retrigger that tag's wiggle.
    @State private var nudges: [String: Int] = [:]
    /// Bumped to wiggle the draft when the field is full.
    @State private var draftNudge = 0
    @FocusState private var isFocused: Bool
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    /// - Parameters:
    ///   - tags: The tags, in the order they were added. New tags are appended.
    ///   - placeholder: Shown in the empty draft, and the text field's VoiceOver label. Defaults to "Add a tag".
    ///   - maxTags: The most tags the field holds. `nil`, the default, means no limit.
    ///   - accent: The tag fill. Defaults to the theme accent.
    ///   - haptic: Fired when tags are added. Defaults to `.light`; a refusal always fires `.warning`.
    public init(
        tags: Binding<[String]>,
        placeholder: String = "Add a tag",
        maxTags: Int? = nil,
        accent: Color? = nil,
        haptic: DSHapticStyle = .light
    ) {
        self._tags = tags
        self.placeholder = placeholder
        self.maxTags = maxTags
        self.accent = accent
        self.haptic = haptic
    }

    public var body: some View {
        DSFlowLayout(spacing: DSSpacing.xs, lineSpacing: DSSpacing.xs) {
            ForEach(Array(tags.enumerated()), id: \.element) { index, tag in
                tagPill(tag, isArmed: armed && index == tags.count - 1)
                    .transition(reduceMotion ? AnyTransition.opacity : .dsScale)
            }
            draftField
        }
        .padding(.horizontal, DSSpacing.sm)
        .padding(.vertical, DSSpacing.xs)
        .frame(maxWidth: .infinity, minHeight: Metrics.minHeight, alignment: .leading)
        .background(theme.subtleFill, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
        .dsFocusGlow(theme.ink, radius: DSRadius.control, isActive: isFocused)
        .contentShape(RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
        .onTapGesture { isFocused = true }
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
        .animation(animation, value: tags)
        .animation(animation, value: armed)
        .accessibilityElement(children: .contain)
        .onChange(of: draft) { _, newValue in
            if !newValue.isEmpty { armed = false }
            if newValue.contains(where: { DSTagFieldLogic.separators.contains($0) }) {
                commit(finishing: false)
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                armed = false
                commit(finishing: true)
            }
        }
        .onChange(of: tags) { _, _ in
            // The list changed (here or from outside): a highlight no longer points anywhere useful.
            armed = false
        }
    }

    private var animation: Animation {
        reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy
    }

    // MARK: Pieces

    private func tagPill(_ tag: String, isArmed: Bool) -> some View {
        Button {
            remove(tag)
        } label: {
            HStack(spacing: DSSpacing.xxs) {
                Text(tag)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .dsFont(.caption2)
                    .accessibilityHidden(true)
            }
            .dsTextStyle(.buttonSmall, color: pillForeground)
            .padding(.leading, DSSpacing.sm)
            .padding(.trailing, DSSpacing.xs)
            .padding(.vertical, DSSpacing.xxs)
            .background(accent ?? theme.accent, in: Capsule(style: .continuous))
            .dsShadow(isArmed ? .md : .none)
            .scaleEffect(isArmed ? Metrics.armedScale : 1)
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(DSTagPillButtonStyle())
        .dsJiggle(trigger: nudges[tag.lowercased(), default: 0])
        .accessibilityLabel("Remove \(tag)")
    }

    private var draftField: some View {
        TextField(placeholder, text: $draft)
            .dsFont(.body)
            .foregroundStyle(theme.palette.textPrimary)
            .tint(theme.ink)
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .submitLabel(.done)
            #endif
            .focused($isFocused)
            .onSubmit {
                commit(finishing: true)
                // Keep the keyboard up for the next tag.
                isFocused = true
            }
            .onKeyPress(.delete) { handleDelete() }
            .frame(minWidth: Metrics.draftMinWidth, alignment: .leading)
            .dsJiggle(trigger: draftNudge)
            .accessibilityLabel(placeholder)
            .accessibilityHint("Return adds a tag")
    }

    private var pillForeground: Color {
        // A custom accent falls back to the palette's text-on-primary, as DSChip does.
        accent == nil ? theme.onAccent : theme.palette.textOnPrimary
    }

    // MARK: Behavior

    private func commit(finishing: Bool) {
        let result = DSTagFieldLogic.ingest(draft, into: tags, maxTags: maxTags, commitRemainder: finishing)
        if result.draft != draft { draft = result.draft }
        if result.tags != tags {
            withAnimation(animation) { tags = result.tags }
        }
        if !result.added.isEmpty {
            DSHapticEngine.shared.fire(haptic)
        } else if !result.refusals.isEmpty {
            // One event, one haptic: a paste with several refusals buzzes once.
            DSHapticEngine.shared.fire(.warning)
        }
        for refusal in result.refusals {
            switch refusal {
            case .duplicate(let index) where result.tags.indices.contains(index):
                nudges[result.tags[index].lowercased(), default: 0] += 1
            case .duplicate:
                break
            case .full:
                draftNudge += 1
            }
        }
        announce(DSTagFieldLogic.announcement(added: result.added, refusals: result.refusals, tags: result.tags))
    }

    private func remove(_ tag: String) {
        guard let index = tags.firstIndex(of: tag) else { return }
        var next = tags
        next.remove(at: index)
        withAnimation(animation) { tags = next }
        DSHapticEngine.shared.fire(.selection)
        announce(DSTagFieldLogic.announcement(removed: tag, tags: next))
    }

    private func handleDelete() -> KeyPress.Result {
        switch DSTagFieldLogic.backspace(draft: draft, tagCount: tags.count, armed: armed) {
        case .passThrough:
            return .ignored
        case .arm:
            armed = true
            DSHapticEngine.shared.fire(.selection)
            return .handled
        case .removeLast:
            if let last = tags.last { remove(last) }
            return .handled
        }
    }

    private func announce(_ message: String?) {
        guard let message else { return }
        AccessibilityNotification.Announcement(message).post()
    }
}

// MARK: - Button Style

/// Press feedback as a `ButtonStyle`, so a touch that turns into a scroll
/// releases the pill instead of leaving it scaled down (same as `DSChip`).
private struct DSTagPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DSPress.scale : 1)
            .animation(DSPress.animation, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSTagFieldPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var skills = ["SwiftUI", "Design systems"]
    @State private var invites: [String] = []
    @State private var labels = ["Bug", "iOS", "Needs design"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Skills").ds(.overline, color: DSColors.textSecondary)
                    DSTagField(tags: $skills, placeholder: "Add a skill")
                }

                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Invite (up to 3)").ds(.overline, color: DSColors.textSecondary)
                        DSTagField(tags: $invites, placeholder: "Email address", maxTags: 3)
                    }
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Custom accent, disabled").ds(.overline, color: DSColors.textSecondary)
                    DSTagField(tags: $labels, accent: DSColors.secondary)
                        .disabled(true)
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Tag Field — Light") {
    DSTagFieldPreviewHost().preferredColorScheme(.light)
}

#Preview("Tag Field — Dark") {
    DSTagFieldPreviewHost().preferredColorScheme(.dark)
}
#endif
