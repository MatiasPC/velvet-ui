import SwiftUI
import VelvetUI

/// "Recording stages" list: pick a stage, background, appearance and autoplay.
struct StageListView: View {
    @AppStorage(StageDefaults.storedBackground) private var backgroundRaw = StageBackground.neutral.rawValue
    @AppStorage(StageDefaults.storedAutoplay) private var autoplay = false
    @Environment(\.galleryAppearance) private var appearance
    @State private var presented: Stage?

    private var background: StageBackground { StageBackground(rawValue: backgroundRaw) ?? .neutral }

    var body: some View {
        List {
            Section("Options") {
                Picker("Background", selection: $backgroundRaw) {
                    ForEach(StageBackground.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Picker("Appearance", selection: appearance) {
                    ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                }
                Toggle("Autoplay", isOn: $autoplay)
            }
            .listRowBackground(DSColors.backgroundSecondary)

            Section {
                ForEach(Stage.allCases) { stage in
                    Button {
                        presented = stage
                    } label: {
                        HStack {
                            Text(stage.rawValue).ds(.body)
                            Spacer()
                            if stage.supportsAutoplay {
                                Text("autoplay").ds(.caption1, color: DSColors.textTertiary)
                            }
                        }
                    }
                    .listRowBackground(DSColors.backgroundSecondary)
                }
            } header: {
                Text("Stages")
            } footer: {
                Text("Stages show no chrome. Long-press the background for 1 second to exit (the top edge on the example flows).")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DSColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Recording stages")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $presented) { stage in
            StageContainer(stage: stage, background: background, autoplay: autoplay) {
                presented = nil
            }
            .preferredColorScheme(appearance.wrappedValue.colorScheme)
        }
    }
}
