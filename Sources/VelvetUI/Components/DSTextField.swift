import SwiftUI

// MARK: - Design System Text Field
// Clean, accessible text inputs with consistent styling and validation states.
//
// The rules (the VoiceOver name, the status a state carries, when a new error
// is announced, when the search bar offers its clear button) live in
// `DSTextFieldLogic` / `DSSearchBarLogic`, pure types the tests pin.
//
// Accessibility: the visible `label` is the field's VoiceOver name (the
// placeholder only when there is no label), so "Email, text field" is read
// once instead of a caption and then an unnamed field. An error message is
// announced when it appears or changes, and stays readable after the field.
// `.success` reads "Valid". Typed text, the placeholder, the icons and the
// field's height scale with Dynamic Type; the default size is unchanged.
// Under Reduce Motion the error message and status icon fade instead of
// sliding and scaling.

public enum DSTextFieldState {
    case normal
    case focused
    case error(String)
    case success
    case disabled
}

// MARK: - Logic

/// The rules behind `DSTextField`, kept pure so they can be tested without rendering.
enum DSTextFieldLogic {
    /// The status a field state carries, reduced to what the view and VoiceOver need.
    enum Status: Equatable {
        case none
        case error(String)
        case success
        case disabled
    }

    static func status(of state: DSTextFieldState) -> Status {
        switch state {
        case .normal, .focused: return .none
        case .error(let message): return .error(message)
        case .success: return .success
        case .disabled: return .disabled
        }
    }

    /// The field's VoiceOver name: the visible label, or the placeholder when
    /// the label is blank. Surrounding whitespace is dropped.
    static func accessibilityLabel(label: String, placeholder: String) -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? placeholder.trimmingCharacters(in: .whitespacesAndNewlines) : trimmed
    }

    /// The error message shown under the field, or `nil`. A blank message still
    /// tints the field but shows and announces nothing.
    static func errorMessage(of state: DSTextFieldState) -> String? {
        guard case .error(let message) = state else { return nil }
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : message
    }

    static func isError(_ state: DSTextFieldState) -> Bool {
        if case .error = state { return true }
        return false
    }

    static func isDisabled(_ state: DSTextFieldState) -> Bool {
        if case .disabled = state { return true }
        return false
    }

    /// What VoiceOver announces when the error message goes from `old` to `new`:
    /// a new or changed message is read; the same message again, or an error
    /// clearing, is silent.
    static func announcement(from old: String?, to new: String?) -> String? {
        guard let new, new != old else { return nil }
        return new
    }

    /// The VoiceOver label of the trailing status icon. The success check reads
    /// "Valid"; the error icon is hidden because the message under the field says more.
    static func statusIconLabel(for state: DSTextFieldState) -> String? {
        if case .success = state { return "Valid" }
        return nil
    }

    /// How a message or status icon enters and leaves: moving under normal
    /// motion, a plain fade under Reduce Motion.
    static func movesStatus(reduceMotion: Bool) -> Bool { !reduceMotion }
}

/// The rules behind `DSSearchBar`.
enum DSSearchBarLogic {
    /// VoiceOver name of the clear button.
    static let clearLabel = "Clear text"

    /// The clear button shows only when there is something to clear.
    static func showsClear(_ text: String) -> Bool { !text.isEmpty }
}

private enum Metrics {
    /// Text field height at the default text size: DSSpacing.huge (48). Grows with Dynamic Type.
    static let fieldHeight: CGFloat = DSSpacing.huge
    /// Search bar height at the default text size (44, the minimum touch target). Grows with Dynamic Type.
    static let searchHeight: CGFloat = DSSpacing.xxxl + DSSpacing.xxs
    /// Leading icon size at the default text size (16). Scales with Dynamic Type.
    static let iconSize: CGFloat = DSSpacing.md
    /// The clear button's touch target (44).
    static let clearTarget: CGFloat = DSSpacing.xxxl + DSSpacing.xxs
}

public struct DSTextField: View {
    /// Concentric with the card or sheet it sits in, never under 12.
    static let corner: DSCorner = .control
    let label: String
    let placeholder: String
    let icon: String?
    @Binding var text: String
    let state: DSTextFieldState
    let isSecure: Bool

    @FocusState private var isFocused: Bool
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = Metrics.iconSize
    @ScaledMetric(relativeTo: .body) private var fieldHeight: CGFloat = Metrics.fieldHeight

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
            // Label (visible only: VoiceOver reads it as the field's name)
            if !label.isEmpty {
                Text(label)
                    .ds(.footnote, color: theme.palette.textSecondary)
                    .accessibilityHidden(true)
            }

            // Input
            HStack(spacing: DSSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.system(size: iconSize, weight: .medium))
                        .accessibilityHidden(true)
                }

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .dsFont(.body)
                .focused($isFocused)
                .accessibilityLabel(Text(DSTextFieldLogic.accessibilityLabel(label: label, placeholder: placeholder)))

                // State icon
                stateIcon
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.xs)
            .frame(minHeight: fieldHeight)
            .background(theme.palette.backgroundSecondary)
            .clipShape(Self.corner.shape)
            .overlay(
                Self.corner.shape
                    .stroke(borderColor, lineWidth: isFocused || isError ? 1.5 : 0)
            )
            .animation(DSAnimation.fast, value: isFocused)

            // Error message
            if let message = errorMessage {
                Text(message)
                    .ds(.caption1, color: theme.palette.error)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(statusTransition(.dsSlideUp))
            }
        }
        .animation(statusAnimation, value: DSTextFieldLogic.status(of: state))
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .onChange(of: errorMessage) { old, new in
            if let message = DSTextFieldLogic.announcement(from: old, to: new) {
                AccessibilityNotification.Announcement(message).post()
            }
        }
    }

    // MARK: - Computed

    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(theme.palette.success)
                .dsFont(.body)
                .accessibilityLabel(Text(DSTextFieldLogic.statusIconLabel(for: state) ?? ""))
                .transition(statusTransition(.dsScale))
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(theme.palette.error)
                .dsFont(.body)
                .accessibilityHidden(true)
                .transition(statusTransition(.dsScale))
        default:
            EmptyView()
        }
    }

    private func statusTransition(_ moving: AnyTransition) -> AnyTransition {
        DSTextFieldLogic.movesStatus(reduceMotion: reduceMotion) ? moving : .opacity
    }

    private var statusAnimation: Animation {
        reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy
    }

    private var errorMessage: String? { DSTextFieldLogic.errorMessage(of: state) }

    private var borderColor: Color {
        if case .error = state { return theme.palette.error }
        if case .success = state { return theme.palette.success }
        if isFocused { return theme.ink }
        return .clear
    }

    private var iconColor: Color {
        if isFocused { return theme.ink }
        return theme.palette.textTertiary
    }

    private var isError: Bool { DSTextFieldLogic.isError(state) }

    private var isDisabled: Bool { DSTextFieldLogic.isDisabled(state) }
}

// MARK: - Search Bar

public struct DSSearchBar: View {
    let placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool
    @DSThemed private var theme
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = Metrics.iconSize
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = Metrics.searchHeight

    public init(placeholder: String = "Search", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.palette.textTertiary)
                .font(.system(size: iconSize, weight: .medium))
                .accessibilityHidden(true)

            TextField(placeholder, text: $text)
                .dsFont(.body)
                .focused($isFocused)
                .accessibilityLabel(Text(placeholder))
                .accessibilityAddTraits(.isSearchField)

            if DSSearchBarLogic.showsClear(text) {
                Button {
                    text = ""
                    dsHaptic(.light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.palette.textTertiary)
                        .font(.system(size: iconSize, weight: .medium))
                        // A 44 pt target; the negative trailing inset keeps the glyph where it was.
                        .frame(minWidth: Metrics.clearTarget, minHeight: Metrics.clearTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, -DSSpacing.sm)
                .accessibilityLabel(Text(DSSearchBarLogic.clearLabel))
            }
        }
        .padding(.horizontal, DSSpacing.md)
        .frame(minHeight: barHeight)
        .background(theme.palette.backgroundSecondary)
        .clipShape(Capsule())
        .animation(DSAnimation.fast, value: text.isEmpty)
    }
}

// MARK: - Preview

#if DEBUG
private struct DSTextFieldPreviewHost: View {
    @State private var email = "ada@"
    @State private var name = "Ada"
    @State private var query = "Lisbon"

    var body: some View {
        VStack(spacing: DSSpacing.md) {
            DSSearchBar(placeholder: "Search destinations", text: $query)
            DSTextField(
                label: "Email",
                placeholder: "you@example.com",
                icon: "envelope",
                text: $email,
                state: email.contains(".") ? .success : .error("Enter a valid email")
            )
            DSTextField(label: "Name", placeholder: "Your name", icon: "person", text: $name)
            DSTextField(label: "Locked", placeholder: "n/a", text: .constant("read only"), state: .disabled)
        }
        .dsScreenPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dsBackdrop()
    }
}

#Preview("Text Field — Light") {
    DSTextFieldPreviewHost().preferredColorScheme(.light)
}

#Preview("Text Field — Dark") {
    DSTextFieldPreviewHost().preferredColorScheme(.dark)
}
#endif
