import SwiftUI
import Accessibility

// MARK: - Design System Charts
// Two light, animated charts with no Swift Charts dependency:
//
//  - `DSSparkline`: a smooth trend line that draws itself on appear, morphs to
//    new data of the same length, fades a gradient under the line and ends in a
//    breathing dot.
//  - `DSBarChart`: rounded bars that grow from the baseline with staggered
//    springs, with optional labels and scrub-to-select.
//
// Both expose a VoiceOver Audio Graph (`AXChartDescriptorRepresentable`) and a
// spoken summary built by a pure, tested helper.

// MARK: - Geometry (pure)

/// Pure chart maths — kept free of SwiftUI state so it is unit-testable.
enum DSChartGeometry {

    /// Replaces NaN / infinite values with 0 so a bad sample can't poison the path.
    static func sanitized(_ values: [Double]) -> [Double] {
        values.map { $0.isFinite ? $0 : 0 }
    }

    /// Values scaled into `0...1` (min to 0, max to 1). Flat data maps to 0.5 so
    /// it draws as a centred line; empty input maps to `[]`.
    static func normalized(_ values: [Double]) -> [Double] {
        let clean = sanitized(values)
        guard let lo = clean.min(), let hi = clean.max() else { return [] }
        guard hi > lo else { return clean.map { _ in 0.5 } }
        return clean.map { ($0 - lo) / (hi - lo) }
    }

    /// Points for `values` inside `rect`: evenly spaced in x, min at the bottom,
    /// max at the top. One value sits at the centre; empty input gives no points.
    static func points(values: [Double], in rect: CGRect) -> [CGPoint] {
        let norm = normalized(values)
        switch norm.count {
        case 0:
            return []
        case 1:
            return [CGPoint(x: rect.midX, y: rect.maxY - CGFloat(norm[0]) * rect.height)]
        default:
            let step = rect.width / CGFloat(norm.count - 1)
            return norm.enumerated().map { index, n in
                CGPoint(x: rect.minX + CGFloat(index) * step, y: rect.maxY - CGFloat(n) * rect.height)
            }
        }
    }

    /// Cubic Bézier control points for each segment of a monotone curve
    /// (Fritsch–Carlson). Unlike Catmull-Rom the curve never overshoots the
    /// data: every control point's y stays between its segment's two endpoints.
    /// Expects strictly increasing x.
    static func controlPoints(for points: [CGPoint]) -> [(CGPoint, CGPoint)] {
        let n = points.count
        guard n >= 2 else { return [] }

        let dx = (0..<(n - 1)).map { Double(points[$0 + 1].x - points[$0].x) }
        let secants = (0..<(n - 1)).map { k -> Double in
            dx[k] == 0 ? 0 : Double(points[k + 1].y - points[k].y) / dx[k]
        }

        // Initial tangents.
        var tangents = [Double](repeating: 0, count: n)
        tangents[0] = secants[0]
        tangents[n - 1] = secants[n - 2]
        if n > 2 {
            for k in 1..<(n - 1) {
                tangents[k] = secants[k - 1] * secants[k] <= 0 ? 0 : (secants[k - 1] + secants[k]) / 2
            }
        }

        // Fritsch–Carlson limiter: keep each segment monotone.
        for k in 0..<(n - 1) {
            if secants[k] == 0 {
                tangents[k] = 0
                tangents[k + 1] = 0
            } else {
                let alpha = tangents[k] / secants[k]
                let beta = tangents[k + 1] / secants[k]
                let s = alpha * alpha + beta * beta
                if s > 9 {
                    let tau = 3 / s.squareRoot()
                    tangents[k] = tau * alpha * secants[k]
                    tangents[k + 1] = tau * beta * secants[k]
                }
            }
        }

        return (0..<(n - 1)).map { k in
            let third = dx[k] / 3
            let c1 = CGPoint(x: points[k].x + CGFloat(third), y: points[k].y + CGFloat(tangents[k] * third))
            let c2 = CGPoint(x: points[k + 1].x - CGFloat(third), y: points[k + 1].y - CGFloat(tangents[k + 1] * third))
            return (c1, c2)
        }
    }

    /// The smooth line through `points`.
    static func linePath(through points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        if points.count == 1 {
            path.addLine(to: first) // zero-length, a round cap turns it into a dot
            return path
        }
        let controls = controlPoints(for: points)
        for (index, control) in controls.enumerated() {
            path.addCurve(to: points[index + 1], control1: control.0, control2: control.1)
        }
        return path
    }

    /// The region between the line and the bottom edge of `rect`.
    static func areaPath(through points: [CGPoint], in rect: CGRect) -> Path {
        guard points.count >= 2, let first = points.first, let last = points.last else { return Path() }
        var path = linePath(through: points)
        path.addLine(to: CGPoint(x: last.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: first.x, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    // MARK: Bars

    /// Bar heights as fractions of the tallest bar (`0...1`). Negative values
    /// clamp to 0; if nothing is positive every bar is 0.
    static func barFractions(_ values: [Double]) -> [Double] {
        let clamped = sanitized(values).map { max($0, 0) }
        guard let top = clamped.max(), top > 0 else { return clamped.map { _ in 0 } }
        return clamped.map { $0 / top }
    }

    /// The bar index under horizontal position `x` in a row `width` wide holding
    /// `count` equal columns. Positions outside the row clamp to the first or
    /// last bar so a scrub that overshoots keeps working. `nil` for no bars.
    static func barIndex(atX x: CGFloat, width: CGFloat, count: Int) -> Int? {
        guard count > 0, width > 0 else { return nil }
        let raw = Int((x / width * CGFloat(count)).rounded(.down))
        return min(max(raw, 0), count - 1)
    }
}

// MARK: - Formatting & spoken summaries (pure)

enum DSChartFormat {
    /// Locale-independent number text: `12` for whole numbers, one decimal otherwise.
    static func number(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        if value.rounded() == value, abs(value) < 1e15 { return String(Int(value)) }
        return String(format: "%.1f", value)
    }

    /// "12 values, from 3 to 18, latest 15".
    static func summary(values: [Double]) -> String {
        let clean = DSChartGeometry.sanitized(values)
        guard let lo = clean.min(), let hi = clean.max(), let last = clean.last else { return "No data" }
        if clean.count == 1 { return "1 value, \(number(last))" }
        return "\(clean.count) values, from \(number(lo)) to \(number(hi)), latest \(number(last))"
    }

    /// "Mon, 12" — or "Bar 3, 12" when there is no label for that bar.
    static func barElement(index: Int, value: Double, labels: [String]?) -> String {
        let name: String
        if let labels, labels.indices.contains(index), !labels[index].isEmpty {
            name = labels[index]
        } else {
            name = "Bar \(index + 1)"
        }
        return "\(name), \(number(max(value, 0)))"
    }
}

// MARK: - Audio Graph

/// Feeds VoiceOver's Audio Graphs: a list of values (optionally categorised by label).
struct DSChartDescriptor: AXChartDescriptorRepresentable {
    let title: String
    let values: [Double]
    let labels: [String]?
    let isContinuous: Bool

    func makeChartDescriptor() -> AXChartDescriptor {
        let clean = DSChartGeometry.sanitized(values)
        let lo = isContinuous ? (clean.min() ?? 0) : 0
        var hi = clean.max() ?? 1
        if hi <= lo { hi = lo + 1 }

        let yAxis = AXNumericDataAxisDescriptor(
            title: "Value",
            range: lo...hi,
            gridlinePositions: []
        ) { DSChartFormat.number($0) }

        let useCategories = (labels?.count == clean.count)
            && Set(labels ?? []).count == clean.count
            && !clean.isEmpty

        let xAxis: AXDataAxisDescriptor
        let points: [AXDataPoint]
        if useCategories, let labels {
            xAxis = AXCategoricalDataAxisDescriptor(title: "Category", categoryOrder: labels)
            points = zip(labels, clean).map { AXDataPoint(x: $0, y: $1) }
        } else {
            xAxis = AXNumericDataAxisDescriptor(
                title: "Position",
                range: 1...Double(max(clean.count, 2)),
                gridlinePositions: []
            ) { "\(Int($0))" }
            points = clean.enumerated().map { AXDataPoint(x: Double($0.offset + 1), y: $0.element) }
        }

        return AXChartDescriptor(
            title: title,
            summary: DSChartFormat.summary(values: clean),
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [AXDataSeriesDescriptor(name: title, isContinuous: isContinuous, dataPoints: points)]
        )
    }

    func updateChartDescriptor(_ descriptor: AXChartDescriptor) {
        descriptor.summary = DSChartFormat.summary(values: values)
    }
}

// MARK: - Animatable series

/// A `[Double]` that can be interpolated, so a shape built from data morphs
/// between two datasets of the same length.
struct DSChartSeries: VectorArithmetic {
    var values: [Double]

    static var zero: DSChartSeries { DSChartSeries(values: []) }

    static func + (lhs: DSChartSeries, rhs: DSChartSeries) -> DSChartSeries {
        combine(lhs, rhs, +)
    }

    static func - (lhs: DSChartSeries, rhs: DSChartSeries) -> DSChartSeries {
        combine(lhs, rhs, -)
    }

    private static func combine(
        _ lhs: DSChartSeries,
        _ rhs: DSChartSeries,
        _ op: (Double, Double) -> Double
    ) -> DSChartSeries {
        let count = max(lhs.values.count, rhs.values.count)
        return DSChartSeries(values: (0..<count).map { index in
            op(index < lhs.values.count ? lhs.values[index] : 0,
               index < rhs.values.count ? rhs.values[index] : 0)
        })
    }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }
}

// MARK: - Sparkline

private enum SparklineMetrics {
    /// Radius of the last-point dot.
    static let dotRadius: CGFloat = DSSpacing.xxs
    /// Radius of the soft halo around the dot.
    static let haloRadius: CGFloat = DSSpacing.xs + DSSpacing.xxxs
    /// Halo opacity at rest.
    static let haloOpacity: Double = 0.28
    /// Opacity of the fill gradient at the line.
    static let fillTopOpacity: Double = 0.32
    /// Delay before the fill fades in, so the line leads.
    static let fillDelay: Double = 0.3
    /// Delay before the dot appears: after the line has (nearly) arrived.
    static let dotDelay: Double = 0.7

    /// Space kept around the plot so strokes and the halo are never clipped.
    static func inset(lineWidth: CGFloat, showsLastPoint: Bool) -> CGFloat {
        showsLastPoint ? max(haloRadius, lineWidth / 2) : lineWidth / 2
    }
}

private struct DSSparklineShape: Shape {
    enum Kind { case line, area }

    var series: DSChartSeries
    var kind: Kind
    var inset: CGFloat

    var animatableData: DSChartSeries {
        get { series }
        set { series = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let plot = rect.insetBy(dx: inset, dy: inset)
        let points = DSChartGeometry.points(values: series.values, in: plot)
        switch kind {
        case .line: return DSChartGeometry.linePath(through: points)
        case .area: return DSChartGeometry.areaPath(through: points, in: plot)
        }
    }
}

/// The dot at the end of the line. An `Animatable` view, so it follows the
/// morph frame by frame instead of jumping to the new position.
private struct DSSparklineMarker: View, Animatable {
    nonisolated var series: DSChartSeries
    let inset: CGFloat
    let color: Color

    nonisolated var animatableData: DSChartSeries {
        get { series }
        set { series = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let plot = CGRect(origin: .zero, size: proxy.size).insetBy(dx: inset, dy: inset)
            if let last = DSChartGeometry.points(values: series.values, in: plot).last {
                ZStack {
                    Circle()
                        .fill(color.opacity(SparklineMetrics.haloOpacity))
                        .frame(width: SparklineMetrics.haloRadius * 2, height: SparklineMetrics.haloRadius * 2)
                        .dsBreathe(.strong)
                    Circle()
                        .fill(color)
                        .frame(width: SparklineMetrics.dotRadius * 2, height: SparklineMetrics.dotRadius * 2)
                }
                .position(last)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct DSSparklineContent: View {
    let values: [Double]
    let color: Color
    let lineWidth: CGFloat
    let showsFill: Bool
    let showsLastPoint: Bool

    @State private var drawn: CGFloat = 0
    @State private var fillShown = false
    @State private var dotShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var inset: CGFloat {
        SparklineMetrics.inset(lineWidth: lineWidth, showsLastPoint: showsLastPoint)
    }

    var body: some View {
        let series = DSChartSeries(values: DSChartGeometry.sanitized(values))
        ZStack {
            if showsFill {
                DSSparklineShape(series: series, kind: .area, inset: inset)
                    .fill(LinearGradient(
                        colors: [color.opacity(SparklineMetrics.fillTopOpacity), color.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .opacity(reduceMotion || fillShown ? 1 : 0)
            }

            DSSparklineShape(series: series, kind: .line, inset: inset)
                .trim(from: 0, to: reduceMotion ? 1 : drawn)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

            if showsLastPoint {
                DSSparklineMarker(series: series, inset: inset, color: color)
                    .opacity(reduceMotion || dotShown ? 1 : 0)
            }
        }
        .animation(reduceMotion ? nil : DSAnimation.slow, value: values)
        .onAppear(perform: drawOn)
    }

    private func drawOn() {
        guard !reduceMotion else { return }
        withAnimation(DSAnimation.counting) { drawn = 1 }
        withAnimation(DSAnimation.slow.delay(SparklineMetrics.fillDelay)) { fillShown = true }
        withAnimation(DSAnimation.normal.delay(SparklineMetrics.dotDelay)) { dotShown = true }
    }
}

/// A compact trend line that draws itself, morphs when the data changes and
/// ends in a softly breathing dot.
///
/// The line is normalised to its frame (lowest value at the bottom, highest at
/// the top; flat data is a centred line) and smoothed with a monotone curve
/// that never overshoots the data. Give it a frame, for example
/// `.frame(height: 64)`.
///
/// When `values` changes and keeps its count, the line morphs; with a different
/// count it redraws. With Reduce Motion on, data appears at rest and changes crossfade.
public struct DSSparkline: View {
    private let values: [Double]
    private let color: Color?
    private let lineWidth: CGFloat
    private let showsFill: Bool
    private let showsLastPoint: Bool
    private let label: String

    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - values: The samples, oldest first. Non-finite values count as 0.
    ///   - color: Line, fill and dot color. Defaults to `theme.accent`.
    ///   - lineWidth: Stroke width. Defaults to 2.
    ///   - showsFill: Fade a gradient of the line color under the line. Defaults to `true`.
    ///   - showsLastPoint: Show the breathing dot on the latest value. Defaults to `true`.
    ///   - accessibilityLabel: What the chart shows, spoken before the summary. Defaults to "Trend".
    public init(
        _ values: [Double],
        color: Color? = nil,
        lineWidth: CGFloat = 2,
        showsFill: Bool = true,
        showsLastPoint: Bool = true,
        accessibilityLabel: String = "Trend"
    ) {
        self.values = values
        self.color = color
        self.lineWidth = lineWidth
        self.showsFill = showsFill
        self.showsLastPoint = showsLastPoint
        self.label = accessibilityLabel
    }

    /// The spoken summary, for example "12 values, from 3 to 18, latest 15".
    static func accessibilitySummary(values: [Double]) -> String {
        DSChartFormat.summary(values: values)
    }

    /// Reduce Motion crossfades on every data change; otherwise only a change
    /// of count rebuilds the view (a redraw), and same-count changes morph.
    private var identity: Int {
        reduceMotion ? values.hashValue : values.count
    }

    public var body: some View {
        ZStack {
            DSSparklineContent(
                values: values,
                color: color ?? theme.accent,
                lineWidth: lineWidth,
                showsFill: showsFill,
                showsLastPoint: showsLastPoint
            )
            .id(identity)
            .transition(.opacity)
        }
        .animation(reduceMotion ? DSAnimation.fast : nil, value: identity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(Self.accessibilitySummary(values: values))
        .accessibilityChartDescriptor(
            DSChartDescriptor(title: label, values: values, labels: nil, isContinuous: true)
        )
    }
}

// MARK: - Bar chart

private enum BarMetrics {
    /// Gap between bars.
    static let spacing: CGFloat = DSSpacing.xxs
    /// Height reserved above the tallest bar for the selected-value label.
    static let valueLabelHeight: CGFloat = DSSpacing.md
    /// Gap between a bar and its value label.
    static let valueLabelGap: CGFloat = DSSpacing.xxs
    /// Opacity of unselected bars while some bar is selected.
    static let dimmedOpacity: Double = 0.35
    /// Smallest plot height when the caller gives no frame.
    static let minHeight: CGFloat = DSSpacing.massive * 2
    /// Bar top corner radius.
    static let cornerRadius: CGFloat = DSRadius.sm
}

/// Animated bars with optional labels and scrub-to-select.
///
/// Bars grow from the baseline with staggered springs and animate to new values
/// when `values` changes. Bars scale to the tallest value; **negative values
/// clamp to 0**. Give the chart a height, for example `.frame(height: 160)`.
///
/// Pass a `selection` binding to make it interactive: tap or drag across the
/// bars to scrub (a selection haptic ticks on each new bar and a small value
/// label rises above it), lift to keep the selection, and tap the selected bar
/// again to clear it. While a bar is selected the others dim. With Reduce Motion
/// on, bars appear at rest without growing.
public struct DSBarChart: View {
    private let values: [Double]
    private let labels: [String]?
    private let selection: Binding<Int?>?
    private let color: Color?
    private let label: String

    @State private var grown = false
    @State private var scrubActive = false
    @State private var scrubChanged = false
    @State private var scrubStart: Int?
    @DSThemed private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - values: One value per bar. Negative values clamp to 0.
    ///   - labels: Optional text under each bar, matched by index.
    ///   - selection: Binding to the selected bar index. Omit for a static chart.
    ///   - color: Bar color. Defaults to `theme.accent`.
    ///   - accessibilityLabel: What the chart shows. Defaults to "Chart".
    public init(
        _ values: [Double],
        labels: [String]? = nil,
        selection: Binding<Int?>? = nil,
        color: Color? = nil,
        accessibilityLabel: String = "Chart"
    ) {
        self.values = values
        self.labels = labels
        self.selection = selection
        self.color = color
        self.label = accessibilityLabel
    }

    /// The spoken summary, for example "7 values, from 0 to 18, latest 15".
    /// Negative values are read as 0, as they are drawn.
    static func accessibilitySummary(values: [Double]) -> String {
        DSChartFormat.summary(values: values.map { max($0, 0) })
    }

    /// What VoiceOver says for one bar, for example "Mon, 12".
    static func accessibilityBarLabel(index: Int, values: [Double], labels: [String]?) -> String {
        let value = values.indices.contains(index) ? values[index] : 0
        return DSChartFormat.barElement(index: index, value: value, labels: labels)
    }

    private var selectedIndex: Int? {
        guard let selection, let index = selection.wrappedValue, values.indices.contains(index) else { return nil }
        return index
    }

    public var body: some View {
        let fractions = DSChartGeometry.barFractions(values)
        let base = color ?? theme.accent

        VStack(spacing: DSSpacing.xs) {
            GeometryReader { proxy in
                let plotHeight = max(proxy.size.height - BarMetrics.valueLabelHeight - BarMetrics.valueLabelGap, 0)
                HStack(alignment: .bottom, spacing: BarMetrics.spacing) {
                    ForEach(fractions.indices, id: \.self) { index in
                        column(index, fraction: fractions[index], plotHeight: plotHeight, base: base)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                .contentShape(Rectangle())
                .gesture(scrubGesture(width: proxy.size.width), including: selection == nil ? .none : .all)
            }

            if let labels, !labels.isEmpty {
                HStack(spacing: BarMetrics.spacing) {
                    ForEach(fractions.indices, id: \.self) { index in
                        Text(labels.indices.contains(index) ? labels[index] : "")
                            .ds(.caption2, color: theme.palette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .frame(minHeight: BarMetrics.minHeight)
        // Each bar's own `.animation(stagger, value: grown)` springs it up;
        // under Reduce Motion that animation is nil, so the bars appear at rest.
        .onAppear { grown = true }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
        .accessibilityValue(Self.accessibilitySummary(values: values))
        .accessibilityChartDescriptor(
            DSChartDescriptor(
                title: label,
                values: values.map { max($0, 0) },
                labels: labels,
                isContinuous: false
            )
        )
    }

    // MARK: Column

    private func column(_ index: Int, fraction: Double, plotHeight: CGFloat, base: Color) -> some View {
        let isSelected = selectedIndex == index
        let opacity = (selectedIndex != nil && !isSelected) ? BarMetrics.dimmedOpacity : 1.0
        let target = plotHeight * CGFloat(fraction)

        return VStack(spacing: BarMetrics.valueLabelGap) {
            Spacer(minLength: 0)

            Text(DSChartFormat.number(max(values[index], 0)))
                .ds(.caption2, color: theme.palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(height: BarMetrics.valueLabelHeight)
                .opacity(isSelected ? 1 : 0)
                .animation(DSAnimation.fast, value: isSelected)

            UnevenRoundedRectangle(
                topLeadingRadius: BarMetrics.cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: BarMetrics.cornerRadius,
                style: .continuous
            )
            .fill(base.opacity(opacity))
            .animation(DSAnimation.fast, value: opacity)
            .frame(height: grown ? target : 0)
            .animation(reduceMotion ? nil : DSAnimation.springSmooth, value: target)
            .animation(reduceMotion ? nil : DSAnimation.stagger(index: index), value: grown)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityBarLabel(index: index, values: values, labels: labels))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .modifier(BarSelectAction(isEnabled: selection != nil) { toggle(index) })
    }

    // MARK: Selection

    /// Select `index`, or clear it when it is already selected.
    private func toggle(_ index: Int) {
        guard let selection else { return }
        withAnimation(DSAnimation.fast) {
            selection.wrappedValue = (selection.wrappedValue == index) ? nil : index
        }
        DSHapticEngine.shared.fire(.selection)
    }

    private func scrubGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                guard let selection,
                      let index = DSChartGeometry.barIndex(atX: drag.location.x, width: width, count: values.count)
                else { return }
                if !scrubActive {
                    scrubActive = true
                    scrubChanged = false
                    scrubStart = selection.wrappedValue
                }
                if selection.wrappedValue != index {
                    scrubChanged = true
                    withAnimation(DSAnimation.fast) { selection.wrappedValue = index }
                    DSHapticEngine.shared.fire(.selection)
                }
            }
            .onEnded { drag in
                defer { scrubActive = false; scrubChanged = false; scrubStart = nil }
                guard let selection,
                      let index = DSChartGeometry.barIndex(atX: drag.location.x, width: width, count: values.count)
                else { return }
                // A tap on the bar that was already selected clears it.
                if !scrubChanged, scrubStart == index, selection.wrappedValue == index {
                    withAnimation(DSAnimation.fast) { selection.wrappedValue = nil }
                    DSHapticEngine.shared.fire(.selection)
                }
            }
    }
}

/// Adds the VoiceOver "activate to select" action only when the chart is interactive.
private struct BarSelectAction: ViewModifier {
    let isEnabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .accessibilityAddTraits(.isButton)
                .accessibilityAction(.default, action)
        } else {
            content
        }
    }
}

// MARK: - Preview

#if DEBUG
private struct DSChartsPreviewHost: View {
    @State private var theme = DSTheme()
    @State private var series: [Double] = [12, 18, 14, 22, 19, 27, 24, 31, 28, 36]
    @State private var week: [Double] = [12, 18, 9, 22, 15, 6, 11]
    @State private var selected: Int? = 2

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                DSPreviewThemeDots(theme: theme)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Sparkline").ds(.overline, color: DSColors.textSecondary)
                    DSSparkline(series)
                        .frame(height: 72)
                    DSSparkline(series, showsFill: false, showsLastPoint: false)
                        .frame(height: 40)
                }

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Bar chart — drag to scrub").ds(.overline, color: DSColors.textSecondary)
                    DSBarChart(
                        week,
                        labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                        selection: $selected
                    )
                    .frame(height: 180)
                }

                DSButton("Shuffle data", size: .small) {
                    series = series.map { _ in Double.random(in: 10...40) }
                    week = week.map { _ in Double.random(in: 2...30) }
                }
            }
            .dsScreenPadding()
            .padding(.vertical, DSSpacing.xl)
        }
        .dsBackdrop()
        .dsTheme(theme)
    }
}

#Preview("Charts — Light") {
    DSChartsPreviewHost().preferredColorScheme(.light)
}

#Preview("Charts — Dark") {
    DSChartsPreviewHost().preferredColorScheme(.dark)
}
#endif
