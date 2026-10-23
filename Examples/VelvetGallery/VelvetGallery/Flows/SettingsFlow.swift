import SwiftUI
import VelvetUI

// MARK: - Settings flow
// An example, not a component: a settings screen built from Velvet parts
// (DSCard, DSAvatar, DSBadge, DSListCell, DSDivider, DSSectionHeader, DSToggle,
// DSSegmentedControl, .dsSheet, DSSlideToConfirm, DSToast). Appearance really
// drives the flow's color scheme, and the theme row really re-themes the screen.
// It has no NavigationStack of its own (nested stacks are unsupported): the host
// provides one, and the Theme detail pushes onto it. Wrap it in
// `NavigationStack { SettingsFlow() }` when you show it standalone.
// Copy it with `swift velvet.swift add Settings` and adapt it.

struct SettingsFlow: View {
    @State private var theme: DSTheme
    @State private var appearance = SettingsAppearance.system
    @State private var toast: SettingsToast?
    @State private var toastTask: Task<Void, Never>?

    @MainActor init(theme: DSTheme? = nil) {
        _theme = State(initialValue: theme ?? DSTheme(gradient: .sunset))
    }

    var body: some View {
        SettingsList(theme: theme, appearance: $appearance, notify: show)
        .overlay(alignment: .bottom) {
            if let toast {
                DSToast(toast.message, type: toast.type)
                    .id(toast.id)
                    .padding(.bottom, DSSpacing.xl)
                    .transition(.dsSlideUp)
            }
        }
        // Injected above every view that reads it; the sheet inherits it too.
        .dsTheme(theme)
        .preferredColorScheme(appearance.colorScheme)
    }

    /// One toast at a time: a new one replaces the old and restarts the timer.
    private func show(_ message: String, _ type: DSToastType = .success) {
        toastTask?.cancel()
        withAnimation(DSAnimation.springSmooth) {
            toast = SettingsToast(message: message, type: type)
        }
        toastTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            withAnimation(DSAnimation.springSmooth) { toast = nil }
        }
    }
}

// MARK: - Model

private struct SettingsToast: Identifiable {
    let id = UUID()
    let message: String
    let type: DSToastType
}

private enum SettingsAppearance: String, CaseIterable {
    case system = "System", light = "Light", dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

private enum SettingsRoute: Hashable { case theme }

/// Stand-in for a backend, so the async path reads like real code.
private enum SettingsAccountService {
    static func deleteAccount() async throws {
        try await Task.sleep(for: .seconds(1.2))
    }
}

// MARK: - Settings list

private struct SettingsList: View {
    let theme: DSTheme
    @Binding var appearance: SettingsAppearance
    let notify: (String, DSToastType) -> Void

    @State private var notifications = true
    @State private var haptics = true
    @State private var showsDelete = false
    @DSThemed private var resolved

    var body: some View {
        DSScreen(backdrop: true) {
            VStack(alignment: .leading, spacing: 0) {
                profile
                DSSectionHeader("Preferences")
                preferences
                DSSectionHeader("Account")
                account
            }
            .dsScreenPadding()
        }
        .navigationTitle("Settings")
        .navigationDestination(for: SettingsRoute.self) { _ in
            SettingsThemeDetail(theme: theme, notify: notify)
        }
        .dsSheet(isPresented: $showsDelete, detents: [.medium]) {
            DeleteAccountSheet {
                showsDelete = false
                notify("Account deleted", .info)
            }
        }
        .onChange(of: notifications) { _, _ in notify("Saved", .success) }
        .onChange(of: haptics) { _, _ in notify("Saved", .success) }
        .onChange(of: appearance) { _, _ in notify("Saved", .success) }
    }

    private var profile: some View {
        DSCard {
            HStack(spacing: DSSpacing.md) {
                DSAvatar(name: "Ada Lovelace", size: DSSpacing.massive)
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text("Ada Lovelace").ds(.title3)
                    Text("ada@example.com").ds(.footnote, color: resolved.palette.textSecondary)
                }
                Spacer()
                DSBadge("Plus", variant: .soft)
            }
        }
    }

    private var preferences: some View {
        DSCard(padding: 0) {
            VStack(spacing: 0) {
                DSListCell(title: "Notifications") {
                    SettingsIcon("bell")
                } trailing: {
                    DSToggle(isOn: $notifications).accessibilityLabel("Notifications")
                }
                DSDivider(inset: DSSpacing.md)
                DSListCell(title: "Haptics") {
                    SettingsIcon("hand.tap")
                } trailing: {
                    DSToggle(isOn: $haptics).accessibilityLabel("Haptics")
                }
                DSDivider(inset: DSSpacing.md)
                DSListCell(title: "Appearance", leading: {
                    SettingsIcon("circle.lefthalf.filled")
                })
                DSSegmentedControl(
                    selection: $appearance,
                    segments: SettingsAppearance.allCases.map { DSSegment($0.rawValue, value: $0) }
                )
                .accessibilityLabel("Appearance")
                .padding(.horizontal, DSSpacing.screenHorizontal)
                .padding(.bottom, DSSpacing.sm)
                DSDivider(inset: DSSpacing.md)
                NavigationLink(value: SettingsRoute.theme) {
                    DSListCell(title: "Theme") {
                        SettingsIcon("paintpalette")
                    } trailing: {
                        HStack(spacing: DSSpacing.xs) {
                            Text(theme.gradient.name)
                                .ds(.callout, color: resolved.palette.textSecondary)
                            Image(systemName: "chevron.right")
                                .dsFont(.caption1)
                                .foregroundStyle(resolved.palette.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var account: some View {
        DSCard(padding: 0) {
            VStack(spacing: 0) {
                DSListCell(
                    title: "Email",
                    subtitle: "ada@example.com",
                    leading: { SettingsIcon("envelope") },
                    action: { notify("Changing email isn't part of this demo", .info) }
                )
                DSDivider(inset: DSSpacing.md)
                DSListCell(
                    title: "Password",
                    leading: { SettingsIcon("key") },
                    action: { notify("Changing password isn't part of this demo", .info) }
                )
                DSDivider(inset: DSSpacing.md)
                Button {
                    dsHaptic(.light)
                    showsDelete = true
                } label: {
                    HStack(spacing: DSSpacing.md) {
                        SettingsIcon("trash", color: resolved.palette.error)
                        Text("Delete account").ds(.body, color: resolved.palette.error)
                        Spacer()
                    }
                    .padding(.horizontal, DSSpacing.screenHorizontal)
                    .padding(.vertical, DSSpacing.sm)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SettingsIcon: View {
    let name: String
    var color: Color?
    @DSThemed private var theme

    init(_ name: String, color: Color? = nil) {
        self.name = name
        self.color = color
    }

    var body: some View {
        Image(systemName: name)
            .dsFont(.body)
            .foregroundStyle(color ?? theme.ink)
            .frame(width: DSSpacing.xl)
            .accessibilityHidden(true)
    }
}

// MARK: - Theme detail

private struct SettingsThemeDetail: View {
    let theme: DSTheme
    let notify: (String, DSToastType) -> Void
    @DSThemed private var resolved

    var body: some View {
        DSScreen(backdrop: true) {
            DSCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(DSGradientTheme.all.enumerated()), id: \.element.id) { index, option in
                        if index > 0 { DSDivider(inset: DSSpacing.md) }
                        Button {
                            dsHaptic(.selection)
                            withAnimation(DSAnimation.normal) { theme.gradient = option }
                            notify("Saved", .success)
                        } label: {
                            DSListCell(title: option.name) {
                                Circle()
                                    .fill(option.linearGradient)
                                    .frame(width: DSSpacing.xl, height: DSSpacing.xl)
                            } trailing: {
                                if theme.gradient == option {
                                    Image(systemName: "checkmark")
                                        .dsFont(.callout)
                                        .foregroundStyle(resolved.ink)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(option.name) theme")
                        .accessibilityAddTraits(theme.gradient == option ? .isSelected : [])
                    }
                }
            }
            .dsScreenPadding()
        }
        .navigationTitle("Theme")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Delete sheet

private struct DeleteAccountSheet: View {
    let onDeleted: () -> Void
    @DSThemed private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            Text("Delete account?").ds(.title1)
            Text("This removes your profile, saved items and settings. You can't undo it.")
                .ds(.body, color: theme.palette.textSecondary)
            Spacer(minLength: 0)
            DSSlideToConfirm(
                "Slide to delete account",
                confirmedLabel: "Deleted",
                accent: theme.palette.error
            ) {
                try await SettingsAccountService.deleteAccount()
                // Let the "Deleted" state land before the sheet goes away.
                Task {
                    try? await Task.sleep(for: .milliseconds(700))
                    onDeleted()
                }
            }
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Previews

#Preview("Settings — Light") {
    NavigationStack { SettingsFlow(theme: DSTheme(gradient: .aurora)) }
        .preferredColorScheme(.light)
}

#Preview("Settings — Dark") {
    NavigationStack { SettingsFlow(theme: DSTheme(gradient: .lagoon)) }
        .preferredColorScheme(.dark)
}
