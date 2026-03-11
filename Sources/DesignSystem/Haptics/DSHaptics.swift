import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Design System Haptics
// Thoughtful haptics make apps feel alive and responsive.
// Every interaction should have appropriate tactile feedback.

public enum DSHapticStyle: Sendable {
    /// Light tap — toggles, selections, minor state changes
    case light
    /// Medium tap — button presses, confirmations
    case medium
    /// Heavy tap — significant actions, drag snaps
    case heavy
    /// Success — task completed, saved, confirmed
    case success
    /// Warning — destructive action prompt, limit reached
    case warning
    /// Error — failed action, validation error
    case error
    /// Soft tap — subtle feedback, scroll snaps
    case soft
    /// Rigid tap — precise snaps, switches
    case rigid
    /// Selection tick — picker changes, segment changes
    case selection
}

// MARK: - Haptic Engine

@MainActor
public final class DSHapticEngine {
    public static let shared = DSHapticEngine()

    #if canImport(UIKit)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    #endif

    private init() {
        prepare()
    }

    /// Pre-warm haptic generators for zero-latency response
    public func prepare() {
        #if canImport(UIKit)
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        #endif
    }

    /// Fire a haptic with the given style
    public func fire(_ style: DSHapticStyle) {
        #if canImport(UIKit)
        switch style {
        case .light:     lightGenerator.impactOccurred()
        case .medium:    mediumGenerator.impactOccurred()
        case .heavy:     heavyGenerator.impactOccurred()
        case .soft:      softGenerator.impactOccurred()
        case .rigid:     rigidGenerator.impactOccurred()
        case .selection: selectionGenerator.selectionChanged()
        case .success:   notificationGenerator.notificationOccurred(.success)
        case .warning:   notificationGenerator.notificationOccurred(.warning)
        case .error:     notificationGenerator.notificationOccurred(.error)
        }
        // Re-prepare for next use
        prepare()
        #endif
    }

    /// Fire with custom intensity (0.0 - 1.0)
    public func fire(_ style: DSHapticStyle, intensity: CGFloat) {
        #if canImport(UIKit)
        let clamped = min(max(intensity, 0), 1)
        switch style {
        case .light:  lightGenerator.impactOccurred(intensity: clamped)
        case .medium: mediumGenerator.impactOccurred(intensity: clamped)
        case .heavy:  heavyGenerator.impactOccurred(intensity: clamped)
        case .soft:   softGenerator.impactOccurred(intensity: clamped)
        case .rigid:  rigidGenerator.impactOccurred(intensity: clamped)
        default:      fire(style) // Notification/selection don't support intensity
        }
        prepare()
        #endif
    }
}

// MARK: - View Extension

public extension View {
    /// Add haptic feedback to a tap gesture
    func dsHapticTap(_ style: DSHapticStyle = .light, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            DSHapticEngine.shared.fire(style)
            action()
        }
    }
}

// MARK: - Global Convenience

/// Quick haptic fire from anywhere
@MainActor
public func dsHaptic(_ style: DSHapticStyle) {
    DSHapticEngine.shared.fire(style)
}
