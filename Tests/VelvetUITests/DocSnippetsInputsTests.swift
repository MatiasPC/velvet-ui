import XCTest
import SwiftUI
import VelvetUI

// Every Usage snippet on the docs/components/*.md pages lives here verbatim,
// so a drifting API breaks the build instead of the docs.
enum DocSnippetsInputs {
    struct ButtonDemo: View {
        @State private var isSaving = false

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.md) {
                    DSButton("Save changes", icon: "checkmark", isFullWidth: true, isLoading: isSaving) {
                        isSaving = true
                    }
                    DSButton("Cancel", variant: .ghost) { }
                }
                .dsScreenPadding()
            }
        }
    }

    struct ButtonVariantsDemo: View {
        var body: some View {
            VStack(spacing: DSSpacing.sm) {
                DSButton("Primary") { }
                DSButton("Secondary", variant: .secondary) { }
                DSButton("Outline", variant: .outline) { }
                DSButton("Ghost", variant: .ghost) { }
                DSButton("Delete account", variant: .destructive, icon: "trash") { }
                DSButton("Next", size: .large, icon: "arrow.right", iconPosition: .trailing) { }
                DSButton("Tag", size: .small) { }
            }
        }
    }

    struct ChipDemo: View {
        @State private var topics: Set<String> = ["Design"]
        @State private var sort: String? = "Trending"

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    // Multiple selection — tap to add or remove.
                    DSChipGroup(
                        ["Design", "Engineering", "Product", "Research", "Marketing"],
                        selection: $topics
                    )
                    // Single selection — tap the selected chip again to clear it.
                    DSChipGroup(["Trending", "Newest", "Top rated", "Nearby"], selection: $sort)
                }
                .dsScreenPadding()
            }
        }
    }

    struct CodeFieldDemo: View {
        @State private var code = ""
        @State private var state = DSCodeFieldState.normal

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.md) {
                    Text("Enter the 6-digit code we texted you").ds(.callout)
                    DSCodeField(code: $code, state: state) { entered in
                        state = (entered == "123456") ? .success : .error
                    }
                }
                .dsScreenPadding()
            }
        }
    }

    struct IconButtonDemo: View {
        var body: some View {
            DSScreen(backdrop: true) {
                HStack(spacing: DSSpacing.md) {
                    DSIconButton(icon: "square.and.arrow.up", accessibilityLabel: "Share") { }
                    DSIconButton(icon: "heart", haptic: .medium, accessibilityLabel: "Favorite") { }
                    DSIconButton(icon: "ellipsis", size: 36, accessibilityLabel: "More options") { }
                }
                .dsScreenPadding()
            }
        }
    }

    struct PageControlDemo: View {
        @State private var page = 0
        private let titles = ["Welcome", "Pick a theme", "Turn on haptics", "You're set"]

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    Text(titles[page]).ds(.title2)
                    DSPageControl(currentPage: $page, numberOfPages: titles.count)
                    DSButton("Next", isFullWidth: true) {
                        page = (page + 1) % titles.count
                    }
                }
                .dsScreenPadding()
            }
        }
    }

    struct RatingDemo: View {
        @State private var stars = 3.0

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.md) {
                    Text("How was your stay?").ds(.title3)
                    DSRating(rating: $stars, step: 0.5)
                    DSRating(value: 4.5)
                }
                .dsScreenPadding()
            }
        }
    }

    struct SegmentedControlDemo: View {
        enum Range: Hashable { case day, week, month }

        @State private var range = Range.week
        @State private var tab = "Overview"

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    DSSegmentedControl(
                        selection: $range,
                        segments: [
                            DSSegment("Day", value: Range.day),
                            DSSegment("Week", value: Range.week),
                            DSSegment("Month", value: Range.month),
                        ]
                    )
                    DSSegmentedControl(
                        selection: $tab,
                        options: ["Overview", "Details", "Reviews"],
                        style: .underline
                    )
                }
                .dsScreenPadding()
            }
        }
    }

    struct SlideToConfirmDemo: View {
        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    Text("Pay $24.00").ds(.title2)
                    DSSlideToConfirm("Slide to pay", confirmedLabel: "Paid") {
                        try await chargeCard(amountCents: 2400)
                    }
                }
                .dsScreenPadding()
            }
        }

        // Stand-in for your payment call. Throwing re-opens the slider for a retry.
        private func chargeCard(amountCents: Int) async throws {
            try await Task.sleep(for: .seconds(1))
        }
    }

    struct SlideToConfirmVanishDemo: View {
        @State private var paid = false

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    if paid {
                        Text("Payment received").ds(.title2)
                    } else {
                        DSSlideToConfirm("Slide to pay", finish: .morphAndVanish) {
                            try await Task.sleep(for: .seconds(1))
                            paid = true
                        }
                    }
                }
                .dsScreenPadding()
            }
        }
    }

    struct StepperDemo: View {
        @State private var guests = 2

        var body: some View {
            DSScreen(backdrop: true) {
                HStack {
                    Text("Guests").ds(.title3)
                    Spacer()
                    DSStepper(value: $guests, in: 1...8)
                        .accessibilityLabel("Guests")
                }
                .dsScreenPadding()
            }
        }
    }

    struct TextFieldDemo: View {
        @State private var email = ""
        @State private var password = ""
        @State private var query = ""

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.md) {
                    DSSearchBar(placeholder: "Search destinations", text: $query)
                    DSTextField(
                        label: "Email",
                        placeholder: "you@example.com",
                        icon: "envelope",
                        text: $email,
                        state: email.isEmpty || email.contains("@") ? .normal : .error("Enter a valid email")
                    )
                    DSTextField(
                        label: "Password",
                        placeholder: "At least 8 characters",
                        icon: "lock",
                        text: $password,
                        isSecure: true
                    )
                }
                .dsScreenPadding()
            }
        }
    }

    struct ToggleDemo: View {
        @State private var notifications = true
        @State private var compact = false

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    DSToggle("Push notifications", isOn: $notifications)
                    DSToggle("Compact layout", isOn: $compact, size: .small)
                }
                .dsScreenPadding()
            }
        }
    }

}

@MainActor
final class DocSnippetsInputsTests: XCTestCase {
    func testSnippetsInstantiate() {
        _ = DocSnippetsInputs.ButtonDemo()
        _ = DocSnippetsInputs.ButtonVariantsDemo()
        _ = DocSnippetsInputs.ChipDemo()
        _ = DocSnippetsInputs.CodeFieldDemo()
        _ = DocSnippetsInputs.IconButtonDemo()
        _ = DocSnippetsInputs.PageControlDemo()
        _ = DocSnippetsInputs.RatingDemo()
        _ = DocSnippetsInputs.SegmentedControlDemo()
        _ = DocSnippetsInputs.SlideToConfirmDemo()
        _ = DocSnippetsInputs.SlideToConfirmVanishDemo()
        _ = DocSnippetsInputs.StepperDemo()
        _ = DocSnippetsInputs.TextFieldDemo()
        _ = DocSnippetsInputs.ToggleDemo()
    }
}
