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
// banner itself is unchanged — this reuses `DSToast`, so any restyle of the
// banner lands in one place.

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

    /// False for a sticky toast (`duration` of zero or less, or not finite).
    var autoDismisses: Bool { duration > 0 && duration.isFinite }
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

// MARK: - Logic (internal, unit-tested)

/// The drag maths and the auto-dismiss wait, kept out of the modifier so they
/// can be tested without a view hierarchy.
enum DSToastLogic {
    /// Travel toward the edge past this and the toast flicks away on release.
    static let dismissDistance: CGFloat = DSSpacing.xl
    /// A flick whose *projected* end passes this also dismisses, however short
    /// the finger travelled.
    static let projectedDismissDistance: CGFloat = DSSpacing.massive
    /// How much the toast resists being dragged *into* the screen (it should only
    /// want to leave). Dimensionless, like the motion envelopes in `DSMotion`.
    static let inwardResistance: CGFloat = 0.2

    /// Positive when the translation heads toward `edge` (the way the toast leaves).
    static func outward(_ translation: CGFloat, edge: DSToastEdge) -> CGFloat {
        edge == .top ? -translation : translation
    }

    /// Where the toast sits while the finger is down: it follows freely toward
    /// its edge and pulls back against the finger when dragged inward.
    static func dragOffset(translation: CGFloat, edge: DSToastEdge) -> CGFloat {
        outward(translation, edge: edge) >= 0 ? translation : translation * inwardResistance
    }

    /// Whether releasing at `translation` (with the gesture's projected end) flicks the toast away.
    static func shouldDismiss(translation: CGFloat, predictedEnd: CGFloat, edge: DSToastEdge) -> Bool {
        outward(translation, edge: edge) > dismissDistance
            || outward(predictedEnd, edge: edge) > projectedDismissDistance
    }

    /// Waits `seconds`. True when the full wait elapsed; false when the task was
    /// cancelled first (a replacement or a dismissal owns the slot now), in which
    /// case the caller must not clear anything.
    static func wait(_ seconds: Double) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(seconds))
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}

// MARK: - Modifier

private struct DSToastModifier: ViewModifier {
    @Binding var toast: DSToastValue?
    let edge: DSToastEdge

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: edge.alignment) {
                ZStack {
                    if let current = toast {
                        banner(current)
                            .offset(y: dragOffset)
                            .gesture(dismissGesture)
                            .padding(edge.padEdge, DSSpacing.xs)
                            .transition(presenceTransition)
                    }
                }
                // The modifier owns the present/dismiss animation so callers don't
                // wrap the binding mutation in `withAnimation`. It is keyed on
                // *presence*, not identity: swapping one toast for another is a cut.
                .animation(presenceAnimation, value: toast != nil)
            }
            .onChange(of: toast?.id) { _, newID in
                // A fresh toast starts flush and taps out its kind. (Fired from this
                // main-actor closure, not the `.task`, to keep haptics off the
                // concurrency path.)
                guard newID != nil, let current = toast else { return }
                dragOffset = 0
                DSHapticEngine.shared.fire(current.type.haptic)
            }
            .task(id: toast?.id) {
                // Restarts on every change of identity, so a replacement gets a full
                // fresh duration, and is cancelled by a dismissal (manual, flick or
                // `nil`) before it can fire.
                guard let current = toast, current.autoDismisses else { return }
                let id = current.id
                guard await DSToastLogic.wait(current.duration), toast?.id == id else { return }
                toast = nil
            }
    }

    /// The banner for one presentation. The `.id` re-mounts `DSToast` per
    /// presentation (so VoiceOver announces a replacement too) and the identity
    /// transition makes that swap a cut: the old banner never fades out beneath
    /// the new one.
    private func banner(_ current: DSToastValue) -> some View {
        DSToast(current.message, type: current.type)
            .id(current.id)
            .transition(.identity)
            .accessibilityAction(named: "Dismiss") { toast = nil }
    }

    // MARK: Motion

    /// Slides from the edge, or just fades under Reduce Motion.
    private var presenceTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .move(edge: edge.transitionEdge).combined(with: .opacity)
    }

    /// A spring for the slide; a short fade curve (never "no animation", which
    /// would make the fade a pop) under Reduce Motion.
    private var presenceAnimation: Animation {
        reduceMotion ? DSAnimation.fast : DSAnimation.springGentle
    }

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = DSToastLogic.dragOffset(translation: value.translation.height, edge: edge)
            }
            .onEnded { value in
                let flicked = DSToastLogic.shouldDismiss(
                    translation: value.translation.height,
                    predictedEnd: value.predictedEndTranslation.height,
                    edge: edge
                )
                if flicked {
                    toast = nil   // leaves from where it was dragged, via the presence transition
                } else {
                    withAnimation(reduceMotion ? DSAnimation.fast : DSAnimation.springSnappy) { dragOffset = 0 }
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
    /// `edge`. Assigning a new value replaces the current toast and restarts the
    /// timer; `nil` dismisses.
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
