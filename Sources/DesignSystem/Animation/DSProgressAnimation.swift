import SwiftUI

// MARK: - Animated Progress Components
// Smooth, satisfying progress indicators for any app type.

// MARK: - Circular Progress

public struct DSCircularProgress: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let primaryColor: Color?
    let trackColor: Color?

    @State private var animatedProgress: Double = 0
    @DSThemed private var theme

    /// - Parameters:
    ///   - primaryColor: Progress ring color. Defaults to the theme accent.
    ///   - trackColor: Track color. Defaults to the palette border.
    public init(
        progress: Double,
        lineWidth: CGFloat = 6,
        size: CGFloat = 80,
        primaryColor: Color? = nil,
        trackColor: Color? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.size = size
        self.primaryColor = primaryColor
        self.trackColor = trackColor
    }

    public var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(trackColor ?? theme.palette.border, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    primaryColor ?? theme.accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(DSAnimation.progress) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(DSAnimation.progress) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Linear Progress Bar

public struct DSLinearProgress: View {
    let progress: Double
    let height: CGFloat
    let primaryColor: Color?
    let trackColor: Color?

    @State private var animatedProgress: Double = 0
    @DSThemed private var theme

    /// - Parameters:
    ///   - primaryColor: Fill color. Defaults to the theme accent.
    ///   - trackColor: Track color. Defaults to the palette border.
    public init(
        progress: Double,
        height: CGFloat = 6,
        primaryColor: Color? = nil,
        trackColor: Color? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.primaryColor = primaryColor
        self.trackColor = trackColor
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(trackColor ?? theme.palette.border)
                    .frame(height: height)

                // Fill
                Capsule()
                    .fill(primaryColor ?? theme.accent)
                    .frame(width: geometry.size.width * animatedProgress, height: height)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(DSAnimation.progress) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(DSAnimation.progress) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Gradient Progress Bar

public struct DSGradientProgress: View {
    let progress: Double
    let height: CGFloat
    let colors: [Color]?
    let trackColor: Color?

    @State private var animatedProgress: Double = 0
    @DSThemed private var theme

    /// - Parameters:
    ///   - colors: Gradient stops. Defaults to the theme gradient's stops.
    ///   - trackColor: Track color. Defaults to the palette border.
    public init(
        progress: Double,
        height: CGFloat = 8,
        colors: [Color]? = nil,
        trackColor: Color? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.colors = colors
        self.trackColor = trackColor
    }

    private var gradient: LinearGradient {
        LinearGradient(colors: colors ?? theme.gradient.stops, startPoint: .leading, endPoint: .trailing)
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor ?? theme.palette.border)
                    .frame(height: height)

                Capsule()
                    .fill(gradient)
                    .frame(width: geometry.size.width * animatedProgress, height: height)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(DSAnimation.progress) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(DSAnimation.progress) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Step Progress

public struct DSStepProgress: View {
    let currentStep: Int
    let totalSteps: Int
    let activeColor: Color?
    let inactiveColor: Color?

    @DSThemed private var theme

    /// - Parameters:
    ///   - activeColor: Fill for completed steps. Defaults to the theme accent.
    ///   - inactiveColor: Fill for remaining steps. Defaults to the palette border.
    public init(
        currentStep: Int,
        totalSteps: Int,
        activeColor: Color? = nil,
        inactiveColor: Color? = nil
    ) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xs) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index < currentStep ? (activeColor ?? theme.accent) : (inactiveColor ?? theme.palette.border))
                    .frame(height: 4)
                    .animation(DSAnimation.stagger(index: index), value: currentStep)
            }
        }
    }
}

// MARK: - Animated Number

public struct DSAnimatedNumber: View {
    let value: Double
    let format: String
    let style: DSTextStyle

    @State private var animatedValue: Double = 0

    public init(
        value: Double,
        format: String = "%.0f",
        style: DSTextStyle = .displayLarge
    ) {
        self.value = value
        self.format = format
        self.style = style
    }

    public var body: some View {
        Text(String(format: format, animatedValue))
            .dsTextStyle(style)
            .contentTransition(.numericText(value: animatedValue))
            .onAppear {
                withAnimation(DSAnimation.counting) {
                    animatedValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(DSAnimation.counting) {
                    animatedValue = newValue
                }
            }
    }
}

// MARK: - Shimmer Loading Effect

/// Sweeping highlight for skeleton loading. Width-independent: the gradient is
/// positioned in unit space, so it works on any size without a GeometryReader.
public struct DSShimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(colorScheme == .dark ? 0.18 : 0.45),
                        .clear
                    ],
                    startPoint: UnitPoint(x: phase - 1, y: 0.5),
                    endPoint: UnitPoint(x: phase, y: 0.5)
                )
                .mask(content)
                .allowsHitTesting(false)
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

public extension View {
    /// Add a shimmer loading effect
    func dsShimmer() -> some View {
        modifier(DSShimmer())
    }
}

// MARK: - Pulse Animation

public struct DSPulse: ViewModifier {
    @State private var isPulsing = false

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

public extension View {
    /// Add a gentle pulse animation (for loading states, attention)
    func dsPulse() -> some View {
        modifier(DSPulse())
    }
}
