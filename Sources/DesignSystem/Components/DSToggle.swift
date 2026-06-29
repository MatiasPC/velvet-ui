import SwiftUI

// MARK: - Design System Toggle
// An on-brand switch with a knob that springs between states and a track
// that crossfades into the accent color. Every app needs a boolean control —
// this is the themeable, tactile alternative to the stock `Toggle`.

public enum DSToggleSize {
    /// 42×26 track — compact rows, dense forms
    case small
    /// 51×31 track — default, matches the platform switch footprint
    case medium

    var trackWidth: CGFloat {
        switch self {
        case .small:  return 42
        case .medium: return 51
        }
    }

    var trackHeight: CGFloat {
        switch self {
        case .small:  return 26
        case .medium: return 31
        }
    }

    /// Gap between the knob and the track edge
    var inset: CGFloat {
        switch self {
        case .small:  return 2
        case .medium: return 2
        }
    }

    var knobSize: CGFloat {
        trackHeight - inset * 2
    }

    /// Horizontal travel of the knob center between off and on
    var travel: CGFloat {
        (trackWidth - knobSize) / 2 - inset
    }
}

public struct DSToggle: View {
    let label: String?
    @Binding var isOn: Bool
    let size: DSToggleSize
    let onColor: Color
    let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        size: DSToggleSize = .medium,
        onColor: Color = DSColors.defaultPalette.primary,
        haptic: DSHapticStyle = .rigid
    ) {
        self.label = label
        self._isOn = isOn
        self.size = size
        self.onColor = onColor
        self.haptic = haptic
    }

    public var body: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.md) {
                if let label {
                    Text(label)
                        .ds(.body)
                    Spacer(minLength: DSSpacing.sm)
                }
                switchTrack
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityValue(isOn ? Text("On") : Text("Off"))
    }

    // MARK: - Track + Knob

    private var switchTrack: some View {
        ZStack {
            Capsule()
                .fill(isOn ? onColor : DSColors.defaultPalette.border)

            Circle()
                .fill(DSColors.defaultPalette.textOnPrimary)
                .frame(width: size.knobSize, height: size.knobSize)
                .dsShadow(.sm)
                .offset(x: isOn ? size.travel : -size.travel)
        }
        .frame(width: size.trackWidth, height: size.trackHeight)
        .animation(DSAnimation.springSnappy, value: isOn)
    }

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        isOn.toggle()
    }
}

// MARK: - Preview

#Preview("Light") {
    TogglePreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    TogglePreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct TogglePreview: View {
    @State private var wifi = true
    @State private var bluetooth = false
    @State private var airplane = false
    @State private var compact = true

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            DSToggle("Wi-Fi", isOn: $wifi)
            DSToggle("Bluetooth", isOn: $bluetooth, onColor: DSColors.defaultPalette.secondary)
            DSToggle("Airplane Mode", isOn: $airplane)
                .disabled(true)

            Divider()

            HStack(spacing: DSSpacing.xl) {
                DSToggle(isOn: $compact, size: .small)
                DSToggle(isOn: $wifi)
                DSToggle(isOn: $bluetooth, onColor: DSColors.defaultPalette.success)
            }
        }
    }
}
