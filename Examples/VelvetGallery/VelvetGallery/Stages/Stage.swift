import SwiftUI
import VelvetUI

/// One isolated, chrome-free view per component, for screen recording.
/// Raw values are the stage IDs and double as the GIF file names
/// (`docs/media/<ID>.gif`).
enum Stage: String, CaseIterable, Identifiable {
    case Hero, DSButton, DSIconButton, DSCard, DSFlipCard, DSTextField, DSCodeField, DSBadge
    case DSAvatar, DSListCell, DSToast, DSEmptyState, DSSegmentedControl, DSToggle
    case DSRating, DSPageControl, DSStepper, DSSlideToConfirm, DSThinkingIndicator
    case DSTypewriterText, Progress, Motion
    case DSTabBar, DSCarousel, DSSheet, DSNumberTicker, Charts, DSSkeleton
    case DSSuccessCheck, DSConfetti
    case OnboardingFlow, SettingsFlow, CheckoutFlow

    var id: String { rawValue }

    /// True for the example flows, which fill the screen and draw their own backdrop.
    var isFullScreen: Bool {
        switch self {
        case .OnboardingFlow, .SettingsFlow, .CheckoutFlow: return true
        default: return false
        }
    }

    /// True when the stage can drive itself in a calm loop.
    var supportsAutoplay: Bool {
        switch self {
        case .Hero, .DSButton, .DSIconButton, .DSCard, .DSSlideToConfirm,
             .DSTextField, .DSBadge, .DSAvatar, .DSListCell, .DSEmptyState,
             .OnboardingFlow, .SettingsFlow, .CheckoutFlow:
            return false
        default:
            return true
        }
    }
}

enum StageBackground: String, CaseIterable, Identifiable {
    case neutral, sunset, aurora, lagoon

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var gradient: DSGradientTheme {
        switch self {
        case .neutral: return .neutral
        case .sunset:  return .sunset
        case .aurora:  return .aurora
        case .lagoon:  return .lagoon
        }
    }
}

/// UserDefaults keys. Launch arguments (`-VelvetStage Hero`) land in
/// `UserDefaults.standard`, and are copied into the persisted settings once at
/// launch so the in-app pickers keep working afterwards.
enum StageDefaults {
    static let stageKey = "VelvetStage"
    static let backgroundKey = "VelvetStageBackground"
    static let autoplayKey = "VelvetStageAutoplay"
    static let appearanceKey = "VelvetAppearance"

    static let storedBackground = "gallery.stage.background"
    static let storedAutoplay = "gallery.stage.autoplay"
    static let storedAppearance = "gallery.appearance"

    /// The stage requested at launch, if any (invalid IDs are ignored).
    static func launchStage() -> Stage? {
        UserDefaults.standard.string(forKey: stageKey).flatMap(Stage.init(rawValue:))
    }

    /// Applies launch-argument overrides for background, autoplay and appearance.
    /// Invalid values are ignored, leaving the stored (or default) setting.
    static func applyLaunchArguments() {
        let d = UserDefaults.standard
        if let raw = d.string(forKey: backgroundKey)?.lowercased(),
           StageBackground(rawValue: raw) != nil {
            d.set(raw, forKey: storedBackground)
        }
        if let raw = d.string(forKey: autoplayKey)?.lowercased() {
            if ["yes", "true", "1"].contains(raw) { d.set(true, forKey: storedAutoplay) }
            if ["no", "false", "0"].contains(raw) { d.set(false, forKey: storedAutoplay) }
        }
        if let raw = d.string(forKey: appearanceKey)?.lowercased(),
           Appearance(rawValue: raw) != nil {
            d.set(raw, forKey: storedAppearance)
        }
    }
}
