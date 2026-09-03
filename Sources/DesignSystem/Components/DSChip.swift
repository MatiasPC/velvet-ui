import SwiftUI

// MARK: - Design System Chip
// A selectable, capsule-shaped chip for filters, tags, categories, and
// interest pickers. Tapping toggles the chip's selection: the leading glyph
// slot fluidly morphs from an optional icon into a checkmark with a bouncy
// spring, the fill crossfades into the accent, and the whole chip gives a
// tactile press-scale. Unlike `DSSegmentedControl` (exclusive one-of-N) or
// `DSBadge` (static display label), each `DSChip` owns an independent
// boolean — drop several in a row or a wrapping layout for multi-select.
//
// Inspiration: Material-style filter chips and Apple's category pickers
// (Health, Wallet). Selection-morph pattern popularized across the SwiftUI
// community (e.g. theswift.dev "Wrapping Chip Layout").

// MARK: - Style

public enum DSChipStyle {
    /// Solid accent fill when selected — the boldest, highest-emphasis look.
    case filled
    /// Soft tinted fill when selected — calm, low-emphasis (default).
    case soft
    /// Bordered chip that tints its outline and label when selected.
    case outlined
}

// MARK: - Chip

public struct DSChip: View {
    private let title: String
    private let icon: String?
    @Binding private var isSelected: Bool
    private let style: DSChipStyle
    private let tint: Color
    private let showsCheckmark: Bool
    private let haptic: DSHapticStyle

    @Environment(\.isEnabled) private var isEnabled
    @State private var isPressed = false

    /// A selectable chip bound to a boolean.
    /// - Parameters:
    ///   - title: The chip's label.
    ///   - icon: Optional leading SF Symbol shown while unselected. When the
    ///     chip is selected it morphs into a checkmark (if `showsCheckmark`).
    ///   - isSelected: Binding driving the selected state.
    ///   - style: Visual treatment. Defaults to `.soft`.
    ///   - tint: Accent color for the selected state. Defaults to the primary.
    ///   - showsCheckmark: Whether a checkmark springs into the leading slot
    ///     when selected. Defaults to `true`.
    ///   - haptic: Tactile feedback fired on toggle. Defaults to `.selection`.
    public init(
        _ title: String,
        icon: String? = nil,
        isSelected: Binding<Bool>,
        style: DSChipStyle = .soft,
        tint: Color = DSColors.defaultPalette.primary,
        showsCheckmark: Bool = true,
        haptic: DSHapticStyle = .selection
    ) {
        self.title = title
        self.icon = icon
        self._isSelected = isSelected
        self.style = style
        self.tint = tint
        self.showsCheckmark = showsCheckmark
        self.haptic = haptic
    }

    public var body: some View {
        Button(action: toggle) {
            HStack(spacing: DSSpacing.xs) {
                if let leadingSymbol {
                    Image(systemName: leadingSymbol)
                        .id(leadingSymbol)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(title)
            }
            .font(DSTextStyle.buttonSmall.font)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.xs)
            .background(background)
            .clipShape(Capsule(style: .continuous))
            .overlay(border)
            .contentShape(Capsule(style: .continuous))
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(DSAnimation.springBouncy, value: isSelected)
            .animation(DSAnimation.springSnappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Leading Glyph

    /// The symbol shown in the leading slot — a checkmark when selected
    /// (and enabled), otherwise the optional icon. The slot animates open
    /// and closed as this value changes.
    private var leadingSymbol: String? {
        if isSelected && showsCheckmark { return "checkmark" }
        return icon
    }

    // MARK: - Colors

    private var foregroundColor: Color {
        let palette = DSColors.defaultPalette
        switch style {
        case .filled:
            return isSelected ? palette.textOnPrimary : palette.textPrimary
        case .soft, .outlined:
            return isSelected ? tint : palette.textSecondary
        }
    }

    @ViewBuilder
    private var background: some View {
        let palette = DSColors.defaultPalette
        switch style {
        case .filled:
            Capsule(style: .continuous)
                .fill(isSelected ? tint : palette.backgroundSecondary)
        case .soft:
            Capsule(style: .continuous)
                .fill(isSelected ? tint.opacity(0.12) : palette.backgroundSecondary)
        case .outlined:
            Capsule(style: .continuous)
                .fill(isSelected ? tint.opacity(0.08) : .clear)
        }
    }

    @ViewBuilder
    private var border: some View {
        if style == .outlined {
            Capsule(style: .continuous)
                .stroke(
                    isSelected ? tint : DSColors.defaultPalette.border,
                    lineWidth: isSelected ? 1.5 : 1
                )
        }
    }

    // MARK: - Interaction

    private func toggle() {
        guard isEnabled else { return }
        DSHapticEngine.shared.fire(haptic)
        withAnimation(DSAnimation.springBouncy) {
            isSelected.toggle()
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    ChipPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
}

#Preview("Dark") {
    ChipPreview()
        .padding(DSSpacing.xl)
        .background(DSColors.defaultPalette.backgroundPrimary)
        .preferredColorScheme(.dark)
}

private struct ChipPreview: View {
    @State private var filters: Set<String> = ["Popular"]
    @State private var single = false
    @State private var soft = true
    @State private var outlined = false

    private let options = ["Popular", "Nearby", "Open Now", "Top Rated", "Deals"]

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Multi-select filters")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                // A simple wrapping row of independent chips.
                HStack(spacing: DSSpacing.xs) {
                    ForEach(options.prefix(3), id: \.self) { option in
                        DSChip(
                            option,
                            isSelected: binding(for: option)
                        )
                    }
                }
                HStack(spacing: DSSpacing.xs) {
                    ForEach(options.suffix(2), id: \.self) { option in
                        DSChip(
                            option,
                            isSelected: binding(for: option)
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text("Styles")
                    .ds(.overline, color: DSColors.defaultPalette.textSecondary)
                HStack(spacing: DSSpacing.xs) {
                    DSChip("Filled", icon: "flame", isSelected: $single, style: .filled)
                    DSChip("Soft", icon: "leaf", isSelected: $soft, style: .soft,
                           tint: DSColors.defaultPalette.secondary)
                    DSChip("Outlined", isSelected: $outlined, style: .outlined,
                           tint: DSColors.defaultPalette.tertiary)
                }
            }

            DSChip("Disabled", isSelected: .constant(true), style: .filled)
                .disabled(true)
        }
    }

    private func binding(for option: String) -> Binding<Bool> {
        Binding(
            get: { filters.contains(option) },
            set: { isOn in
                if isOn { filters.insert(option) } else { filters.remove(option) }
            }
        )
    }
}
