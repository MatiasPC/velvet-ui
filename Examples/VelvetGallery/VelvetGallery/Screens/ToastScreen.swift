import SwiftUI
import DesignSystem

struct ToastScreen: View {
    @State private var active: DSToastType?

    var body: some View {
        GalleryScreen(title: "Toast", caption: "Transient feedback") {
            LabeledExample("Tap to present") {
                VStack(spacing: DSSpacing.sm) {
                    DSButton("Show success", variant: .primary, isFullWidth: true) { present(.success) }
                    DSButton("Show error", variant: .secondary, isFullWidth: true) { present(.error) }
                    DSButton("Show warning", variant: .secondary, isFullWidth: true) { present(.warning) }
                    DSButton("Show info", variant: .secondary, isFullWidth: true) { present(.info) }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let active {
                DSToast(message(for: active), type: active)
                    .padding(DSSpacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func message(for type: DSToastType) -> String {
        switch type {
        case .success: return "Saved to your library"
        case .error:   return "Couldn't connect"
        case .warning: return "Low storage"
        case .info:    return "New version available"
        }
    }

    private func haptic(for type: DSToastType) -> DSHapticStyle {
        switch type {
        case .success: return .success
        case .error:   return .error
        case .warning: return .warning
        case .info:    return .light
        }
    }

    private func present(_ type: DSToastType) {
        withAnimation(DSAnimation.springSmooth) { active = type }
        DSHapticEngine.shared.fire(haptic(for: type))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(DSAnimation.springSmooth) { if active == type { active = nil } }
        }
    }
}
