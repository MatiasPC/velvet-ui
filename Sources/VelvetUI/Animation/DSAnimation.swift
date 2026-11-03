import SwiftUI

// MARK: - Design System Animation
// Fast, soft curves for micro-interactions (~200ms) and view transitions
// (~320ms); springs for anything the user touches. Springs are the Velvet
// signature and their values are frozen — tune the curves, not the springs.

public enum DSAnimation {

    // MARK: - Standard Curves

    /// 0.20s "standard" curve — toggles, highlights, color changes
    public static let micro: Animation = .timingCurve(0.25, 0.10, 0.25, 1.0, duration: 0.20)
    /// 0.24s decelerate — state changes, button feedback
    public static let fast: Animation = .timingCurve(0.20, 0.00, 0.00, 1.0, duration: 0.24)
    /// 0.32s decelerate — view transitions, card reveals, layout changes
    public static let normal: Animation = .timingCurve(0.20, 0.00, 0.00, 1.0, duration: 0.32)
    /// 0.48s — large layout shifts. Prefer `springGentle` for sheets.
    public static let slow: Animation = .timingCurve(0.30, 0.00, 0.10, 1.0, duration: 0.48)

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
    /// 1.8s soft ease — the base curve for ambient loops (breathing, drifting,
    /// shimmering). Springs read wrong when nothing was touched; this is what
    /// every looping effect in `DSMotion` starts from.
    public static let ambient: Animation = .easeInOut(duration: 1.8)
    /// Count-up / number animation
    public static let counting: Animation = .easeOut(duration: 1.0)
    /// Stagger delay base for list items
    public static func stagger(index: Int, base: Double = 0.05) -> Animation {
        DSAnimation.springSmooth.delay(Double(index) * base)
    }
}

// MARK: - Press State

/// The one press feel for the whole catalog. Every pressable component reads
/// from here so a change lands everywhere at once.
public enum DSPress {
    /// Scale for buttons, cards, cells while pressed.
    public static let scale: CGFloat = 0.96
    /// Scale for icon-only targets (small hit areas need a bigger dip).
    public static let iconScale: CGFloat = 0.88
    /// Animation driving the press in/out.
    public static let animation: Animation = DSAnimation.springSnappy
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

@available(*, deprecated, message: "Unused since v0.2. Will be removed in v0.3.")
public struct DSAnimatedValue<V: VectorArithmetic>: Animatable {
    public var animatableData: V

    public init(_ value: V) {
        self.animatableData = value
    }
}

// MARK: - Stagger Entrance

public struct DSStaggerInModifier: ViewModifier {
    let index: Int
    let base: Double

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : DSSpacing.xs)
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    withAnimation(DSAnimation.stagger(index: index, base: base)) {
                        isVisible = true
                    }
                }
            }
    }
}

// MARK: - View Extensions

public extension View {
    /// Fade + rise entrance, delayed by `index * base` seconds. Use inside `ForEach`.
    func dsStaggerIn(index: Int, base: Double = 0.05) -> some View {
        modifier(DSStaggerInModifier(index: index, base: base))
    }

    /// Smooth state-change animation
    func dsAnimate<V: Equatable>(_ animation: Animation = DSAnimation.springSmooth, value: V) -> some View {
        self.animation(animation, value: value)
    }
}
