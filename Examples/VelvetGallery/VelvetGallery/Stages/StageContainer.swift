import SwiftUI
import VelvetUI

/// Full-screen host for one stage: clean background, no chrome, status bar
/// hidden. Long-press (~1 s) the background — not the component — to exit.
struct StageContainer: View {
    let stage: Stage
    let background: StageBackground
    let autoplay: Bool
    let onExit: () -> Void

    @State private var theme: DSTheme

    init(stage: Stage, background: StageBackground, autoplay: Bool, onExit: @escaping () -> Void) {
        self.stage = stage
        self.background = background
        self.autoplay = autoplay
        self.onExit = onExit
        _theme = State(initialValue: DSTheme(gradient: background.gradient))
    }

    var body: some View {
        ZStack {
            backdrop
            StageView(stage: stage, autoplay: autoplay)
                .padding(.horizontal, DSSpacing.xxl)
        }
        .dsTheme(theme)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }

    /// The exit gesture lives only on this layer, never on the component.
    @ViewBuilder
    private var backdrop: some View {
        Group {
            if background == .neutral {
                DSColors.backgroundPrimary
            } else {
                Color.clear.dsBackdrop()
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 1.0, perform: onExit)
    }
}

/// Runs `step` forever with cancellation handled by `.task`.
func stageLoop(_ step: () async -> Void) async {
    while !Task.isCancelled { await step() }
}

func stagePause(_ seconds: Double) async {
    try? await Task.sleep(for: .seconds(seconds))
}
