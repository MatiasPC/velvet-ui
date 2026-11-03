import SwiftUI
import VelvetUI

struct CheckboxScreen: View {
    @State private var terms = true
    @State private var newsletter = false
    @State private var compact = true
    @State private var regular = true
    @State private var prominent = false
    @State private var bareSmall = false
    @State private var bareMedium = true
    @State private var bareLarge = false
    @State private var confirmed = true
    @State private var synced = false
    @State private var packed = [true, false, true, false]
    @State private var isDisabled = false

    private let items = ["Passport", "Charger", "Sunscreen", "Headphones"]

    /// The "select all" parent: on when every item is, and setting it sets them all.
    private var allPacked: Binding<Bool> {
        Binding(
            get: { packed.allSatisfy { $0 } },
            set: { newValue in packed = packed.map { _ in newValue } }
        )
    }

    var body: some View {
        GalleryScreen(title: "Checkbox", caption: "Pick any, with a drawn tick") {
            LabeledExample("With label, tap the label too") {
                VStack(spacing: DSSpacing.sm) {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            DSCheckbox("I accept the terms and conditions", isOn: $terms)
                            DSCheckbox("Send me the newsletter", isOn: $newsletter)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .disabled(isDisabled)
                    }
                    DSToggle("Disable both", isOn: $isDisabled)
                }
            }

            LabeledExample("Sizes, labeled") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        DSCheckbox("Small, 20 pt", isOn: $compact, size: .small)
                        DSCheckbox("Medium, 24 pt", isOn: $regular)
                        DSCheckbox("Large, 28 pt", isOn: $prominent, size: .large)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LabeledExample("Sizes, box only (44 pt hit area each)") {
                DSCard {
                    HStack(spacing: DSSpacing.md) {
                        DSCheckbox(isOn: $bareSmall, size: .small).accessibilityLabel("Small")
                        DSCheckbox(isOn: $bareMedium).accessibilityLabel("Medium")
                        DSCheckbox(isOn: $bareLarge, size: .large).accessibilityLabel("Large")
                        Spacer()
                    }
                }
            }

            LabeledExample("Select all") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        DSCheckbox("Select all", isOn: allPacked)
                        ForEach(items.indices, id: \.self) { index in
                            DSCheckbox(items[index], isOn: $packed[index], size: .small)
                                .padding(.leading, DSSpacing.lg)
                        }
                        Text("\(packed.filter { $0 }.count) of \(items.count) packed")
                            .ds(.footnote, color: DSColors.textSecondary)
                            .padding(.top, DSSpacing.xs)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LabeledExample("Custom fill, disabled") {
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        DSCheckbox("Order confirmed", isOn: $confirmed, onColor: DSColors.success)
                        DSCheckbox("Calendar synced (off, disabled)", isOn: $synced).disabled(true)
                        DSCheckbox("Backup enabled (on, disabled)", isOn: .constant(true)).disabled(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct CheckboxStage: View {
    let autoplay: Bool
    @State private var done = [true, false, true]

    private let items = ["Passport", "Charger", "Sunscreen"]

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text("Packing list").ds(.title3)
                    .padding(.bottom, DSSpacing.xs)
                ForEach(items.indices, id: \.self) { index in
                    DSCheckbox(items[index], isOn: $done[index])
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: autoplay) {
            guard autoplay else { return }
            await stageLoop {
                done = [false, false, false]
                await stagePause(0.9)
                for index in items.indices {
                    guard !Task.isCancelled else { return }
                    done[index] = true
                    await stagePause(0.8)
                }
                await stagePause(1.2)
                for index in items.indices.reversed() {
                    guard !Task.isCancelled else { return }
                    done[index] = false
                    await stagePause(0.5)
                }
                await stagePause(0.6)
            }
        }
    }
}
