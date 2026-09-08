import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

private struct GalleryAppearanceKey: EnvironmentKey {
    static let defaultValue: Binding<Appearance> = .constant(.system)
}

extension EnvironmentValues {
    var galleryAppearance: Binding<Appearance> {
        get { self[GalleryAppearanceKey.self] }
        set { self[GalleryAppearanceKey.self] = newValue }
    }
}

struct AppearanceMenu: View {
    @Environment(\.galleryAppearance) private var appearance
    var body: some View {
        Menu {
            Picker("Appearance", selection: appearance) {
                ForEach(Appearance.allCases) { Text($0.label).tag($0) }
            }
        } label: {
            Image(systemName: "circle.lefthalf.filled")
        }
    }
}
