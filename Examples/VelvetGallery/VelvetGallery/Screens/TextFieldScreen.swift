import SwiftUI
import DesignSystem

struct TextFieldScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var search = ""

    var body: some View {
        GalleryScreen(title: "Text Field", caption: "Inputs & validation") {
            LabeledExample("States") {
                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        DSTextField(label: "Email", placeholder: "you@example.com", icon: "envelope", text: $email)
                        DSTextField(label: "Password", placeholder: "••••••••", icon: "lock", text: $password, isSecure: true)
                        DSTextField(label: "Username", placeholder: "username", text: .constant("m"), state: .error("Too short"))
                        DSTextField(label: "Display name", placeholder: "name", text: .constant("Matias"), state: .success)
                        DSTextField(label: "Locked", placeholder: "n/a", text: .constant("read only"), state: .disabled)
                    }
                }
            }
            LabeledExample("Search bar") {
                DSSearchBar(text: $search)
            }
        }
    }
}
