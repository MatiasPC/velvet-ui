import SwiftUI
import VelvetUI

struct ToastScreen: View {
    @State private var toast: DSToastValue?
    @State private var edge: ToastEdgeChoice = .bottom
    @State private var stay: ToastStay = .normal
    @State private var burst: Task<Void, Never>?

    var body: some View {
        GalleryScreen(title: "Toast", caption: "Present with .dsToast") {
            LabeledExample("Tap to present") {
                VStack(spacing: DSSpacing.sm) {
                    DSButton("Show success", variant: .primary, isFullWidth: true) { present(.success) }
                    DSButton("Show error", variant: .secondary, isFullWidth: true) { present(.error) }
                    DSButton("Show warning", variant: .secondary, isFullWidth: true) { present(.warning) }
                    DSButton("Show info", variant: .secondary, isFullWidth: true) { present(.info) }
                }
            }

            LabeledExample("Edge") {
                DSSegmentedControl(
                    selection: $edge,
                    segments: ToastEdgeChoice.allCases.map { DSSegment($0.label, value: $0) }
                )
                .accessibilityLabel("Edge")
            }

            LabeledExample("Stays for") {
                DSSegmentedControl(
                    selection: $stay,
                    segments: ToastStay.allCases.map { DSSegment($0.label, value: $0) }
                )
                .accessibilityLabel("Duration")
            }

            LabeledExample("Replace and dismiss") {
                VStack(spacing: DSSpacing.sm) {
                    DSButton("Replace three in a row", variant: .outline, isFullWidth: true) { replaceBurst() }
                    DSButton("Dismiss now", variant: .ghost, isFullWidth: true) { dismiss() }
                }
                Text("A new toast replaces the one on screen and restarts the timer. Flick a toast toward its edge to dismiss it. Sticky stays until you do.")
                    .ds(.footnote, color: DSColors.textSecondary)
            }
        }
        .dsToast($toast, edge: edge.value)
        .onDisappear { burst?.cancel() }
    }

    private func present(_ type: DSToastType) {
        burst?.cancel()
        toast = DSToastValue(message(for: type), type: type, duration: stay.seconds)
    }

    private func dismiss() {
        burst?.cancel()
        toast = nil
    }

    /// Three toasts 0.5 s apart: each replaces the last without overlapping.
    private func replaceBurst() {
        burst?.cancel()
        burst = Task {
            for type in [DSToastType.info, .warning, .success] {
                toast = DSToastValue(message(for: type), type: type, duration: stay.seconds)
                try? await Task.sleep(for: .seconds(0.5))
                if Task.isCancelled { return }
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
}

private enum ToastEdgeChoice: CaseIterable, Hashable {
    case top, bottom

    var label: String { self == .top ? "Top" : "Bottom" }
    var value: DSToastEdge { self == .top ? .top : .bottom }
}

private enum ToastStay: CaseIterable, Hashable {
    case brief, normal, sticky

    var label: String {
        switch self {
        case .brief:  return "1.5 s"
        case .normal: return "2.5 s"
        case .sticky: return "Sticky"
        }
    }

    /// Seconds on screen; `0` pins the toast until it is dismissed.
    var seconds: Double {
        switch self {
        case .brief:  return 1.5
        case .normal: return 2.5
        case .sticky: return 0
        }
    }
}

// MARK: - Stage

struct ToastStage: View {
    let autoplay: Bool
    @State private var toast: DSToastValue?

    var body: some View {
        DSCard {
            VStack(spacing: DSSpacing.sm) {
                Text("Photo library").ds(.title3)
                DSButton("Save", isFullWidth: true) {
                    toast = DSToastValue("Saved to your library", type: .success)
                }
                DSButton("Upload", variant: .secondary, isFullWidth: true) {
                    toast = DSToastValue("Couldn't connect", type: .error)
                }
                DSButton("Storage", variant: .secondary, isFullWidth: true) {
                    toast = DSToastValue("Low storage", type: .warning)
                }
                DSButton("Update", variant: .secondary, isFullWidth: true) {
                    toast = DSToastValue("New version available", type: .info)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsToast($toast, edge: .bottom)
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                // Each one rides in, then leaves by itself.
                await stagePause(0.8)
                toast = DSToastValue("Saved to your library", type: .success, duration: 1.8)
                await stagePause(2.8)
                // The next replaces the last without overlapping it.
                toast = DSToastValue("Couldn't connect", type: .error, duration: 3)
                await stagePause(1.2)
                toast = DSToastValue("Low storage", type: .warning, duration: 1.8)
                await stagePause(2.8)
                toast = DSToastValue("New version available", type: .info, duration: 1.8)
                await stagePause(2.8)
            }
        }
    }
}
