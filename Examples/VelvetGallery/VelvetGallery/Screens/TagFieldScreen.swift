import SwiftUI
import VelvetUI

struct TagFieldScreen: View {
    @State private var skills = ["SwiftUI", "Design systems"]
    @State private var invites: [String] = []
    @State private var labels = ["Bug", "iOS"]
    @State private var locked = ["Archived", "Read-only"]

    var body: some View {
        GalleryScreen(title: "Tag Field", caption: "Type a word, press Return or a comma: it becomes a tag. Tap a tag to remove it") {
            LabeledExample("Skills (paste \"a, b, c\" to add three)") {
                DSTagField(tags: $skills, placeholder: "Add a skill")
            }

            LabeledExample("Invites, at most 3") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        DSTagField(tags: $invites, placeholder: "Email address", maxTags: 3)
                        Text("\(invites.count) of 3 invites").ds(.footnote, color: DSColors.textSecondary)
                    }
                }
            }

            LabeledExample("Custom accent, soft haptic") {
                DSTagField(tags: $labels, placeholder: "Add a label", accent: DSColors.secondary, haptic: .soft)
            }

            LabeledExample("Disabled") {
                DSTagField(tags: $locked).disabled(true)
            }
        }
    }
}

/// Recording stage: a profile's skills, at most four. The read-out under the
/// field is one accessibility element ("Tags") whose value is the list joined
/// with ", " ("None" when empty), which the UI test reads back.
struct TagFieldStage: View {
    let autoplay: Bool
    @State private var tags = ["SwiftUI", "Design systems"]

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("Skills").ds(.title3)
                DSTagField(tags: $tags, placeholder: "Add a skill", maxTags: 4)
                Text("\(tags.count) of 4")
                    .ds(.footnote, color: DSColors.textSecondary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Tags")
                    .accessibilityValue(tags.isEmpty ? "None" : tags.joined(separator: ", "))
            }
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                for next in [["SwiftUI", "Design systems", "Motion"],
                             ["SwiftUI", "Design systems", "Motion", "Haptics"],
                             ["SwiftUI", "Motion", "Haptics"],
                             ["SwiftUI", "Design systems"]] {
                    await stagePause(1.0)
                    if Task.isCancelled { return }
                    withAnimation(DSAnimation.springSnappy) { tags = next }
                }
            }
        }
    }
}
