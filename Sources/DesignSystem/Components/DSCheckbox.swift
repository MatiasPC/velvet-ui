import SwiftUI

// MARK: - Design System Checkbox
// The boolean control DSToggle isn't. A switch says "this setting is on now";
// a checkbox says "this item is selected" — terms accepted, a to-do done, one of
// many filters chosen. Every form needs it, so here it is with the Velvet feel.
//
// The delight is the mark itself: an accent-filled glass box whose checkmark
// *draws itself on* by animating `.trim(from:0,to:)` across a two-segment path,
// rather than popping in as a static glyph. Checking springs the fill and traces
// the mark; unchecking retracts it the way it came. One light haptic on the beat.
//
// Technique — the animatable `.trim` draw-on — is the standard SwiftUI checkmark
// pattern (a `Shape` stroked and trimmed under `.animation`), rebuilt on Velvet
// tokens. See serialcoder.dev "Animatable Circled Checkmark" and Stackademic's
// "Checkmark Animation in SwiftUI" for the underlying idea; no upstream code is
// reproduced here.

// MARK: - Size

public enum DSCheckboxSize {
    /// 20pt box — compact rows, dense forms, inline selection.
    case small
    /// 24pt box — the default, comfortable for a tappable list row.
    case medium

    /// Box edge length, drawn from the spacing scale (no raw literals).
    var box: CGFloat {
        switch self {
        case .small:  return DSSpacing.lg   // 20
        case .medium: return DSSpacing.xl   // 24
        }
    }

    /// Checkmark stroke weight — a fixed fraction of the box so it reads at the
    /// same visual weight at every size (the ratio `DSIconButton`-style controls use).
    var strokeWidth: CGFloat { box * 0.14 }

    /// Inset of the checkmark path inside the box, leaving the corners breathing room.
    var inset: CGFloat { box * 0.26 }
}

// MARK: - Checkbox

public struct DSCheckbox: View {
    private let label: String?
    @Binding private var isOn: Bool
    private let size: DSCheckboxSize
    private let onColor: Color?
    private let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @DSThemed private var theme

    /// - Parameters:
    ///   - label: Optional trailing text. The whole row (box + label) is the hit target.
    ///   - isOn: The checked state.
    ///   - size: Box size. Defaults to `.medium` (24pt).
    ///   - onColor: Box fill and edge tint while checked. Defaults to the theme accent.
    ///   - haptic: Feedback fired on every toggle. Defaults to `.light`.
    public init(
        _ label: String? = nil,
        isOn: Binding<Bool>,
        size: DSCheckboxSize = .medium,
        onColor: Color? = nil,
        haptic: DSHapticStyle = .light
    ) {
        self.label = label
        self._isOn = isOn
        self.size = size
        self.onColor = onColor
        self.haptic = haptic
    }

    public var body: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.sm) {
                box
                if let label {
                    Text(label).ds(.body)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Checkbox")
        .accessibilityValue(isOn ? Text("Checked") : Text("Unchecked"))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: - Box + Mark

    /// The glass box and the draw-on checkmark. The fill crossfades into the
    /// accent (`.micro`) while the mark traces on with a soft spring; the edge
    /// highlight (never a border) delineates the box in both states.
    private var box: some View {
        let radius = DSRadius.sm
        let resolvedOn = onColor ?? theme.accent

        return ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(isOn ? resolvedOn : theme.subtleFill)
                .animation(DSAnimation.micro, value: isOn)

            DSCheckmarkShape()
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(
                    theme.onAccent,
                    style: StrokeStyle(lineWidth: size.strokeWidth, lineCap: .round, lineJoin: .round)
                )
                .padding(size.inset)
                .animation(reduceMotion ? nil : DSAnimation.springSmooth, value: isOn)
        }
        .frame(width: size.box, height: size.box)
        .dsWashEdge(radius: radius)
    }

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        isOn.toggle()
    }
}

// MARK: - Checkmark Shape

/// A two-segment checkmark inside its rect: a short down-stroke into a long
/// up-stroke. Kept as its own `Shape` so `.trim` can animate the drawing — the
/// points are proportional, so it scales cleanly with the box.
private struct DSCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.80))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.86, y: rect.minY + rect.height * 0.26))
        return path
    }
}

// MARK: - Preview

#if DEBUG
private struct DSCheckboxPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var terms = true
    @State private var newsletter = false
    @State private var offers = false
    @State private var boxOnly = true
    @State private var small = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Labeled").ds(.overline, color: DSColors.textSecondary)
                    DSCheckbox("Accept terms & conditions", isOn: $terms)
                    DSCheckbox("Subscribe to the newsletter", isOn: $newsletter)
                    DSCheckbox("Send me occasional offers", isOn: $offers, onColor: DSColors.success)
                    DSCheckbox("Unavailable option", isOn: $offers)
                        .disabled(true)
                }

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    Text("Box only + small").ds(.overline, color: DSColors.textSecondary)
                    HStack(spacing: DSSpacing.lg) {
                        DSCheckbox(isOn: $boxOnly)
                        DSCheckbox(isOn: $newsletter)
                        DSCheckbox("Small", isOn: $small, size: .small)
                    }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Checkbox — Light") {
    DSCheckboxPreviewHost().preferredColorScheme(.light)
}

#Preview("Checkbox — Dark") {
    DSCheckboxPreviewHost().preferredColorScheme(.dark)
}
#endif
