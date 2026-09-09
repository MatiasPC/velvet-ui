import SwiftUI
import DesignSystem

struct CodeFieldScreen: View {
    @State private var code = ""
    @State private var completed = false

    var body: some View {
        GalleryScreen(title: "Code Field", caption: "OTP entry") {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    LabeledExample("Live (6 digits)") {
                        DSCodeField(length: 6, code: $code, onComplete: { _ in completed = true })
                        Text(completed ? "Completed ✓" : "Enter 6 digits")
                            .ds(.footnote, color: completed ? DSColors.success : DSColors.textSecondary)
                    }
                    LabeledExample("Error") {
                        DSCodeField(length: 4, code: .constant("1234"), state: .error)
                    }
                    LabeledExample("Success") {
                        DSCodeField(length: 4, code: .constant("5678"), state: .success)
                    }
                }
            }
        }
    }
}
