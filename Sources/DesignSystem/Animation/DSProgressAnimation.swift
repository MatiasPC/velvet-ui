import SwiftUI

// MARK: - Animated Progress Components
// Smooth, satisfying progress indicators for any app type.

// MARK: - Circular Progress

public struct DSCircularProgress: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let primaryColor: Color
    let trackColor: Color

    @State private var animatedProgress: Double = 0

    public init(
        progress: Double,
        lineWidth: CGFloat = 6,
        size: CGFloat = 80,
        primaryColor: Color = DSColors.defaultPalette.primary,
        trackColor: Color = DSColors.defaultPalette.border
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
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    primaryColor,
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
    let primaryColor: Color
    let trackColor: Color

    @State private var animatedProgress: Double = 0

    public init(
        progress: Double,
        height: CGFloat = 6,
        primaryColor: Color = DSColors.defaultPalette.primary,
        trackColor: Color = DSColors.defaultPalette.border
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
                    .fill(trackColor)
                    .frame(height: height)

                // Fill
                Capsule()
                    .fill(primaryColor)
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
    let gradient: LinearGradient
    let trackColor: Color

    @State private var animatedProgress: Double = 0

    public init(
        progress: Double,
        height: CGFloat = 8,
        colors: [Color] = [
            DSColors.defaultPalette.primary,
            DSColors.defaultPalette.secondary
        ],
        trackColor: Color = DSColors.defaultPalette.border
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.gradient = LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
        self.trackColor = trackColor
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)
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
    let activeColor: Color
    let inactiveColor: Color

    public init(
        currentStep: Int,
        totalSteps: Int,
        activeColor: Color = DSColors.defaultPalette.primary,
        inactiveColor: Color = DSColors.defaultPalette.border
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
                    .fill(index < currentStep ? activeColor : inactiveColor)
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

public struct DSShimmer: ViewModifier {
    @State private var phase: CGFloat = 0

    public func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 200
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
