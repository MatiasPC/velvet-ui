import SwiftUI

// MARK: - Design System Text Field
// Clean, accessible text inputs with consistent styling and validation states.

public enum DSTextFieldState {
    case normal
    case focused
    case error(String)
    case success
    case disabled
}

public struct DSTextField: View {
    let label: String
    let placeholder: String
    let icon: String?
    @Binding var text: String
    let state: DSTextFieldState
    let isSecure: Bool

    @FocusState private var isFocused: Bool

    public init(
        label: String = "",
        placeholder: String,
        icon: String? = nil,
        text: Binding<String>,
        state: DSTextFieldState = .normal,
        isSecure: Bool = false
    ) {
        self.label = label
        self.placeholder = placeholder
        self.icon = icon
        self._text = text
        self.state = state
        self.isSecure = isSecure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
            // Label
            if !label.isEmpty {
                Text(label)
                    .ds(.footnote, color: DSColors.defaultPalette.textSecondary)
            }

            // Input
            HStack(spacing: DSSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.system(size: 16, weight: .medium))
                }

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(DSTextStyle.body.font)
                .focused($isFocused)

                // State icon
                stateIcon
            }
            .padding(.horizontal, DSSpacing.md)
            .frame(height: 48)
            .background(DSColors.defaultPalette.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused || isError ? 1.5 : 0)
            )
            .animation(DSAnimation.fast, value: isFocused)

            // Error message
            if case .error(let message) = state {
                Text(message)
                    .ds(.caption1, color: DSColors.defaultPalette.error)
                    .transition(.dsSlideUp)
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    // MARK: - Computed

    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DSColors.defaultPalette.success)
                .transition(.dsScale)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(DSColors.defaultPalette.error)
                .transition(.dsScale)
        default:
            EmptyView()
        }
    }

    private var borderColor: Color {
        if case .error = state { return DSColors.defaultPalette.error }
        if case .success = state { return DSColors.defaultPalette.success }
        if isFocused { return DSColors.defaultPalette.borderFocused }
        return .clear
    }

    private var iconColor: Color {
        if isFocused { return DSColors.defaultPalette.primary }
        return DSColors.defaultPalette.textTertiary
    }

    private var isError: Bool {
        if case .error = state { return true }
        return false
    }

    private var isDisabled: Bool {
        if case .disabled = state { return true }
        return false
    }
}

// MARK: - Search Bar

public struct DSSearchBar: View {
    let placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool

    public init(placeholder: String = "Search", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DSColors.defaultPalette.textTertiary)
                .font(.system(size: 16, weight: .medium))

            TextField(placeholder, text: $text)
                .font(DSTextStyle.body.font)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                    dsHaptic(.light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DSColors.defaultPalette.textTertiary)
                }
            }
        }
        .padding(.horizontal, DSSpacing.md)
        .frame(height: 44)
        .background(DSColors.defaultPalette.backgroundSecondary)
        .clipShape(Capsule())
        .animation(DSAnimation.fast, value: text.isEmpty)
    }
}
