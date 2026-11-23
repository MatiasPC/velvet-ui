import SwiftUI
import VelvetUI

/// Contacts grouped by first letter, shared by the screen and the stage.
enum GalleryContacts {
    static let sections: [(letter: String, names: [String])] = [
        ("A", ["Ada Lovelace", "Alan Turing", "Anita Borg"]),
        ("B", ["Barbara Liskov", "Bjarne Stroustrup"]),
        ("C", ["Claude Shannon", "Corrado Böhm"]),
        ("D", ["Donald Knuth", "Dennis Ritchie"]),
        ("E", ["Edsger Dijkstra", "Erich Gamma"]),
        ("F", ["Frances Allen", "Fred Brooks"]),
        ("G", ["Grace Hopper", "Guido van Rossum"]),
        ("H", ["Hedy Lamarr", "Herbert Simon"]),
        ("J", ["Jean Bartik", "John McCarthy"]),
        ("K", ["Ken Thompson", "Kristen Nygaard"]),
        ("L", ["Leslie Lamport", "Linus Torvalds"]),
        ("M", ["Margaret Hamilton", "Mary Allen Wilkes"]),
        ("N", ["Niklaus Wirth", "Noam Chomsky"]),
        ("O", ["Ole-Johan Dahl"]),
        ("P", ["Peter Naur", "Paul Baran"]),
        ("R", ["Radia Perlman", "Rob Pike"]),
        ("S", ["Shafi Goldwasser", "Sophie Wilson"]),
        ("T", ["Tim Berners-Lee", "Tony Hoare"]),
        ("V", ["Vint Cerf"]),
        ("W", ["Whitfield Diffie", "Wendy Hall"]),
    ]

    static var letters: [String] { sections.map(\.letter) }
}

/// A contact list with a section index on its trailing edge.
struct GalleryContactList: View {
    var accent: Color? = nil
    var onJump: (String) -> Void = { _ in }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                    ForEach(GalleryContacts.sections, id: \.letter) { section in
                        Section {
                            ForEach(section.names, id: \.self) { name in
                                Text(name)
                                    .ds(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, DSSpacing.sm)
                            }
                        } header: {
                            Text(section.letter)
                                .ds(.overline, color: DSColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, DSSpacing.xxs)
                                .background(DSColors.backgroundPrimary)
                                .id(section.letter)
                        }
                    }
                }
                .padding(.leading, DSSpacing.md)
                .padding(.trailing, DSSpacing.huge)
            }
            .overlay(alignment: .trailing) {
                DSSectionIndex(GalleryContacts.letters, accent: accent) { letter in
                    proxy.scrollTo(letter, anchor: .top)
                    onJump(letter)
                }
                .padding(.vertical, DSSpacing.md)
            }
        }
    }
}

/// Not a `GalleryScreen`: that one scrolls, and the index belongs on the edge of
/// the list's own scroll view.
struct SectionIndexScreen: View {
    @State private var example = 0
    @State private var lastJump: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text("Section Index").ds(.title1)
                Text("Touch or slide along the letters to jump through a long list")
                    .ds(.callout, color: DSColors.textSecondary)
            }

            DSSegmentedControl(selection: $example, segments: [
                DSSegment("Contacts", value: 0),
                DSSegment("Short column", value: 1),
            ])

            if example == 0 {
                GalleryContactList { lastJump = $0 }
                    .frame(maxHeight: .infinity)
                    .dsSurface(.glass, radius: DSRadius.card)
            } else {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    GalleryContactList(accent: DSColors.secondary) { lastJump = $0 }
                        .frame(height: DSSpacing.massive * 3)
                        .dsSurface(.glass, radius: DSRadius.card)
                    Text("Too short for twenty letters, the column shows title, dot, title. Slide over a dot to walk through the letters it hides.")
                        .ds(.footnote, color: DSColors.textSecondary)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }

            Text(lastJump.map { "Jumped to \($0)" } ?? "With VoiceOver on, swipe up or down on the index to move one section at a time.")
                .ds(.caption1, color: DSColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .dsScreenPadding()
        .padding(.vertical, DSSpacing.lg)
        .background(DSColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Section Index")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { AppearanceMenu() } }
    }
}

/// Recording stage: twenty sections (A…W, no I, Q, U, X, Y or Z) in a 440 pt
/// glass list, with the index on its trailing edge. At the default text size
/// each letter is a 16 pt row and all twenty fit, so the index is a 44 × 320 pt
/// column and the UI test can aim at a letter by position. The index is one
/// adjustable element, "Section index" (value: the last letter jumped to, "A"
/// before any jump), and "Jumped to" reads the letter the list scrolled to.
struct SectionIndexStage: View {
    @State private var lastJump: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            GalleryContactList { lastJump = $0 }
                .frame(height: DSSpacing.massive * 7 - DSSpacing.xs)
                .dsSurface(.glass, radius: DSRadius.card)
            Text(lastJump.map { "Jumped to \($0)" } ?? "Touch a letter")
                .ds(.footnote, color: DSColors.textSecondary)
                .accessibilityLabel("Jumped to")
                .accessibilityValue(lastJump ?? "Nothing")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
