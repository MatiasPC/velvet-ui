import SwiftUI

// MARK: - Design System Animation
// Smooth, purposeful motion that feels natural.
// Inspired by Apple's spring physics and Opal's fluid transitions.

public enum DSAnimation {

    // MARK: - Standard Curves

    /// Quick micro-interaction (0.2s) — toggles, highlights, color changes
    public static let micro: Animation = .easeOut(duration: 0.2)
    /// Default interaction (0.3s) — button feedback, state changes
    public static let fast: Animation = .easeInOut(duration: 0.3)
    /// Standard transition (0.4s) — card reveals, layout changes
    public static let normal: Animation = .easeInOut(duration: 0.4)
    /// Deliberate motion (0.6s) — modal presentations, large layout shifts
    public static let slow: Animation = .easeInOut(duration: 0.6)

    // MARK: - Spring Animations (Premium Feel)

    /// Snappy spring — buttons, toggles, small elements
    public static let springSnappy: Animation = .spring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0
    )
    /// Smooth spring — cards, panels, medium elements
    public static let springSmooth: Animation = .spring(
        response: 0.45,
        dampingFraction: 0.75,
        blendDuration: 0
    )
    /// Gentle spring — sheets, full-screen transitions
    public static let springGentle: Animation = .spring(
        response: 0.6,
        dampingFraction: 0.8,
        blendDuration: 0
    )
    /// Bouncy spring — playful elements, celebrations
    public static let springBouncy: Animation = .spring(
        response: 0.5,
        dampingFraction: 0.5,
        blendDuration: 0
    )

    // MARK: - Interactive Springs (for gestures)

    /// Responsive to drag/gesture input
    public static let interactive: Animation = .interactiveSpring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0.05
    )

    // MARK: - Specialized

    /// Progress bar / loading animation
    public static let progress: Animation = .easeInOut(duration: 0.8)
    /// Count-up / number animation
    public static let counting: Animation = .easeOut(duration: 1.0)
    /// Stagger delay base for list items
    public static func stagger(index: Int, base: Double = 0.05) -> Animation {
        DSAnimation.springSmooth.delay(Double(index) * base)
    }
}

// MARK: - Transition Presets

public extension AnyTransition {
    /// Slide up with fade — bottom sheets, toasts
    static var dsSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// Scale with fade — modals, alerts
    static var dsScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }

    /// Fade only — subtle state changes
    static var dsFade: AnyTransition {
        .opacity
    }

    /// Slide from trailing — navigation push feel
    static var dsPush: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

// MARK: - Animated Value Helper

/// Smoothly animates a numeric value over time (great for counters, progress)
public struct DSAnimatedValue<V: VectorArithmetic>: Animatable {
    public var animatableData: V

    public init(_ value: V) {
        self.animatableData = value
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply entrance animation with stagger delay
    func dsStaggerIn(index: Int, base: Double = 0.05) -> some View {
        self
            .opacity(1)
            .animation(DSAnimation.stagger(index: index, base: base), value: true)
    }

    /// Smooth state-change animation
    func dsAnimate<V: Equatable>(_ animation: Animation = DSAnimation.springSmooth, value: V) -> some View {
        self.animation(animation, value: value)
    }
}
