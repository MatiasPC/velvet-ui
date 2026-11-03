import SwiftUI

// MARK: - Design System Toast Presenter
// `DSToast` draws the banner; this is how you *show* one. Bind a
// `DSToastValue?` to any view with `.dsToast($toast)` and the modifier floats
// the toast in from the chosen edge, fires the type's haptic, auto-dismisses
// after its duration, and lets the user flick it away. Setting the binding to a
// new value replaces the current toast; setting it to `nil` dismisses it.
//
// Idiomatic, like `.alert(item:)`: no `withAnimation` at the call site (the
// modifier owns its motion) and no presentation controller to wire up. The
// banner itself is unchanged — this reuses `DSToast`, so the glass restyle lands
// in one place when it comes.

// MARK: - Value

/// One toast to present: its message, kind, and how long it stays up.
public struct DSToastValue: Identifiable, Equatable {
    public let id = UUID()
    public var message: String
    public var type: DSToastType
    /// Seconds on screen before it auto-dismisses. `0` or less pins it until the
    /// binding is cleared (useful for a toast with its own dismiss affordance).
    public var duration: Double

    public init(_ message: String, type: DSToastType = .info, duration: Double = 2.5) {
        self.message = message
        self.type = type
        self.duration = duration
    }

    /// Identity is per-presentation: two values with the same text are still two
    /// distinct toasts, so re-assigning the binding always re-presents.
    public static func == (lhs: DSToastValue, rhs: DSToastValue) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Edge

/// Which edge the toast rides in from and flicks away toward.
public enum DSToastEdge: Sendable {
    /// Banner at the top, below the safe-area inset.
    case top
    /// Snackbar at the bottom, above the safe-area inset.
    case bottom

    var alignment: Alignment { self == .top ? .top : .bottom }
    var transitionEdge: Edge { self == .top ? .top : .bottom }
    var padEdge: Edge.Set { self == .top ? .top : .bottom }
}

// MARK: - Modifier

public struct DSToastModifier: ViewModifier {
    @Binding var toast: DSToastValue?
    let edge: DSToastEdge

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Travel past this, in the dismiss direction, to flick the toast away.
    private var dismissThreshold: CGFloat { DSSpacing.xl }
    /// How much the toast resists being dragged *into* the screen (it should only
    /// want to leave). Dimensionless, like the motion envelopes in `DSMotion`.
    private let inwardResistance: CGFloat = 0.2

    public func body(content: Content) -> some View {
        content.overlay(alignment: edge.alignment) {
            ZStack {
                if let current = toast {
                    DSToast(current.message, type: current.type)
                        .offset(y: dragOffset)
                        .gesture(dismissGesture)
                        .padding(edge.padEdge, DSSpacing.xs)
                        .id(current.id)
                        .transition(transition)
                }
            }
            // The modifier owns the present/dismiss animation so callers don't
            // have to wrap the binding mutation in `withAnimation`.
            .animation(reduceMotion ? nil : DSAnimation.springGentle, value: toast?.id)
        }
        .onChange(of: toast?.id) { _, _ in
            // A fresh toast starts flush and taps out its kind. (Firing here, in a
            // main-actor closure, keeps the haptic off the `.task` concurrency path.)
            dragOffset = 0
            if let current = toast {
                DSHapticEngine.shared.fire(current.type.haptic)
            }
        }
        .task(id: toast?.id) {
            // Auto-cancels and restarts whenever the toast changes, so a replacement
            // or an early dismiss stops the pending timer cleanly.
            guard let duration = toast?.duration, duration > 0 else { return }
            do {
                try await Task.sleep(for: .seconds(duration))
            } catch {
                return // cancelled — a newer toast (or a dismiss) owns the slot now
            }
            toast = nil
        }
    }

    private var transition: AnyTransition {
        reduceMotion
            ? .opacity
            : .move(edge: edge.transitionEdge).combined(with: .opacity)
    }

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let raw = value.translation.height
                switch edge {
                case .top:    dragOffset = raw < 0 ? raw : raw * inwardResistance
                case .bottom: dragOffset = raw > 0 ? raw : raw * inwardResistance
                }
            }
            .onEnded { value in
                let raw = value.translation.height
                let dismissed = edge == .top ? raw < -dismissThreshold : raw > dismissThreshold
                if dismissed {
                    toast = nil
                } else {
                    withAnimation(DSAnimation.springSnappy) { dragOffset = 0 }
                }
            }
    }
}

// MARK: - View Extension

public extension View {
    /// Present a toast bound to `toast`, floating in from `edge`.
    ///
    /// Set the binding to a `DSToastValue` to show it; it auto-dismisses after
    /// its `duration` (unless `duration <= 0`), or the user can flick it toward
    /// `edge`. Assigning a new value replaces the current toast; `nil` dismisses.
    ///
    ///     @State private var toast: DSToastValue?
    ///     // ...
    ///     DSScreen { content }
    ///         .dsToast($toast)
    ///     // ...
    ///     toast = DSToastValue("Saved", type: .success)
    ///
    /// Apply it at the screen root so the banner sits inside the safe area.
    func dsToast(_ toast: Binding<DSToastValue?>, edge: DSToastEdge = .top) -> some View {
        modifier(DSToastModifier(toast: toast, edge: edge))
    }
}

// MARK: - Preview

#if DEBUG
private struct DSToastPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var topToast: DSToastValue?
    @State private var bottomToast: DSToastValue?

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            DSPreviewThemeDots(theme: theme)

            Text("Toast presenter").ds(.title2)
            Text("Tap to present. Auto-dismisses, or flick it away.")
                .ds(.callout, color: DSColors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: DSSpacing.sm) {
                DSButton("Success (top)", variant: .primary, isFullWidth: true) {
                    topToast = DSToastValue("Changes saved", type: .success)
                }
                DSButton("Error (top)", variant: .secondary, isFullWidth: true) {
                    topToast = DSToastValue("Couldn’t reach the server", type: .error)
                }
                DSButton("Info (bottom)", variant: .outline, isFullWidth: true) {
                    bottomToast = DSToastValue("Copied to clipboard", type: .info)
                }
                DSButton("Sticky (bottom)", variant: .ghost, isFullWidth: true) {
                    bottomToast = DSToastValue("Uploading…", type: .warning, duration: 0)
                }
            }

            Spacer()
        }
        .dsScreenPadding()
        .padding(.vertical, DSSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .dsBackdrop()
        .dsToast($topToast, edge: .top)
        .dsToast($bottomToast, edge: .bottom)
        .dsTheme(theme)
    }
}

#Preview("Toast — Light") {
    DSToastPreviewHost().preferredColorScheme(.light)
}

#Preview("Toast — Dark") {
    DSToastPreviewHost().preferredColorScheme(.dark)
}
#endif
