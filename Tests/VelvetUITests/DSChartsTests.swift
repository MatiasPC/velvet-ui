import XCTest
import SwiftUI
@testable import VelvetUI

// Every code snippet on docs/components/Charts.md lives here verbatim.
enum DocSnippetsCharts {
    struct ChartsDemo: View {
        @State private var revenue: [Double] = [12, 18, 14, 22, 19, 27, 24, 31, 28, 36]
        @State private var week: [Double] = [12, 18, 9, 22, 15, 6, 11]
        @State private var selected: Int?

        var body: some View {
            DSScreen(backdrop: true) {
                VStack(spacing: DSSpacing.lg) {
                    DSCard {
                        VStack(alignment: .leading, spacing: DSSpacing.sm) {
                            Text("Revenue").ds(.callout)
                            DSSparkline(revenue, accessibilityLabel: "Revenue trend")
                                .frame(height: 72)
                        }
                    }

                    DSCard {
                        DSBarChart(
                            week,
                            labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                            selection: $selected,
                            accessibilityLabel: "Orders this week"
                        )
                        .frame(height: 180)
                    }

                    DSButton("Shuffle data", isFullWidth: true) {
                        revenue = revenue.map { _ in Double.random(in: 10...40) }
                        week = week.map { _ in Double.random(in: 2...30) }
                    }
                }
                .dsScreenPadding()
            }
        }
    }

    struct VariantsDemo: View {
        let revenue: [Double] = [12, 18, 14, 22]
        let week: [Double] = [12, 18, 9, 22]

        var body: some View {
            VStack {
                DSSparkline(revenue, color: DSColors.success, showsFill: false, showsLastPoint: false)
                    .frame(height: 40)

                DSBarChart(week, color: DSColors.info)
                    .frame(height: 96)
            }
        }
    }
}

@MainActor
final class DSChartsTests: XCTestCase {

    func testSnippetsInstantiate() {
        _ = DocSnippetsCharts.ChartsDemo().body
        _ = DocSnippetsCharts.VariantsDemo().body
    }

    // MARK: Normalisation

    func testNormalizedMapsMinToZeroAndMaxToOne() {
        XCTAssertEqual(DSChartGeometry.normalized([2, 4, 6]), [0, 0.5, 1])
    }

    func testFlatDataIsCentred() {
        XCTAssertEqual(DSChartGeometry.normalized([5, 5, 5]), [0.5, 0.5, 0.5])
    }

    func testEmptyAndSingleValue() {
        XCTAssertEqual(DSChartGeometry.normalized([]), [])
        XCTAssertEqual(DSChartGeometry.normalized([7]), [0.5])
        XCTAssertTrue(DSChartGeometry.points(values: [], in: CGRect(x: 0, y: 0, width: 100, height: 50)).isEmpty)
        let one = DSChartGeometry.points(values: [7], in: CGRect(x: 0, y: 0, width: 100, height: 50))
        XCTAssertEqual(one, [CGPoint(x: 50, y: 25)])
    }

    func testNonFiniteValuesCountAsZero() {
        XCTAssertEqual(DSChartGeometry.sanitized([1, .nan, .infinity]), [1, 0, 0])
    }

    func testPointsPutMinAtBottomAndMaxAtTop() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 40)
        let points = DSChartGeometry.points(values: [1, 3, 2], in: rect)
        XCTAssertEqual(points.count, 3)
        XCTAssertEqual(points[0], CGPoint(x: 10, y: 60))
        XCTAssertEqual(points[1], CGPoint(x: 60, y: 20))
        XCTAssertEqual(points[2].x, 110)
        XCTAssertEqual(points[2].y, 40, accuracy: 0.0001)
    }

    // MARK: Monotone curve

    func testControlPointsNeverLeaveTheSegmentRange() {
        let values: [Double] = [1, 1, 10, 2, 2, 9, 0, 0, 5]
        let rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        let points = DSChartGeometry.points(values: values, in: rect)
        let controls = DSChartGeometry.controlPoints(for: points)
        XCTAssertEqual(controls.count, points.count - 1)
        for (k, control) in controls.enumerated() {
            let lo = min(points[k].y, points[k + 1].y) - 0.0001
            let hi = max(points[k].y, points[k + 1].y) + 0.0001
            XCTAssertTrue((lo...hi).contains(control.0.y), "c1 of segment \(k) overshoots")
            XCTAssertTrue((lo...hi).contains(control.1.y), "c2 of segment \(k) overshoots")
            XCTAssertTrue(control.0.x >= points[k].x && control.0.x <= points[k + 1].x)
            XCTAssertTrue(control.1.x >= points[k].x && control.1.x <= points[k + 1].x)
        }
    }

    func testCurveStaysInsideBoundsOfTheRect() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        let points = DSChartGeometry.points(values: [0, 100, 0, 100, 0], in: rect)
        let bounds = DSChartGeometry.linePath(through: points).boundingRect
        XCTAssertGreaterThanOrEqual(bounds.minY, rect.minY - 0.5)
        XCTAssertLessThanOrEqual(bounds.maxY, rect.maxY + 0.5)
    }

    func testControlPointsForFewerThanTwoPoints() {
        XCTAssertTrue(DSChartGeometry.controlPoints(for: []).isEmpty)
        XCTAssertTrue(DSChartGeometry.controlPoints(for: [.zero]).isEmpty)
    }

    // MARK: Series interpolation

    func testSeriesInterpolates() {
        var a = DSChartSeries(values: [0, 10])
        let b = DSChartSeries(values: [10, 20])
        var delta = b - a
        delta.scale(by: 0.5)
        a = a + delta
        XCTAssertEqual(a.values, [5, 15])
        XCTAssertEqual(DSChartSeries.zero.magnitudeSquared, 0)
    }

    // MARK: Bars

    func testBarFractionsClampNegativesAndScaleToTallest() {
        XCTAssertEqual(DSChartGeometry.barFractions([5, 10, -3]), [0.5, 1, 0])
        XCTAssertEqual(DSChartGeometry.barFractions([-1, 0]), [0, 0])
        XCTAssertEqual(DSChartGeometry.barFractions([]), [])
    }

    func testBarIndexMapsAndClamps() {
        XCTAssertEqual(DSChartGeometry.barIndex(atX: 0, width: 100, count: 4), 0)
        XCTAssertEqual(DSChartGeometry.barIndex(atX: 30, width: 100, count: 4), 1)
        XCTAssertEqual(DSChartGeometry.barIndex(atX: 99, width: 100, count: 4), 3)
        XCTAssertEqual(DSChartGeometry.barIndex(atX: -20, width: 100, count: 4), 0)
        XCTAssertEqual(DSChartGeometry.barIndex(atX: 500, width: 100, count: 4), 3)
        XCTAssertNil(DSChartGeometry.barIndex(atX: 10, width: 100, count: 0))
        XCTAssertNil(DSChartGeometry.barIndex(atX: 10, width: 0, count: 3))
    }

    // MARK: Accessibility strings

    func testSparklineSummary() {
        XCTAssertEqual(
            DSSparkline.accessibilitySummary(values: [3, 9, 18, 4, 7, 11, 5, 8, 10, 12, 6, 15]),
            "12 values, from 3 to 18, latest 15"
        )
        XCTAssertEqual(DSSparkline.accessibilitySummary(values: []), "No data")
        XCTAssertEqual(DSSparkline.accessibilitySummary(values: [4.75]), "1 value, 4.8")
    }

    func testBarSummaryReadsNegativesAsZero() {
        XCTAssertEqual(DSBarChart.accessibilitySummary(values: [-5, 10, 4]), "3 values, from 0 to 10, latest 4")
    }

    func testBarElementLabels() {
        XCTAssertEqual(DSBarChart.accessibilityBarLabel(index: 0, values: [12, 5], labels: ["Mon", "Tue"]), "Mon, 12")
        XCTAssertEqual(DSBarChart.accessibilityBarLabel(index: 1, values: [12, 5], labels: nil), "Bar 2, 5")
        XCTAssertEqual(DSBarChart.accessibilityBarLabel(index: 1, values: [12, -5], labels: ["Mon"]), "Bar 2, 0")
    }

    func testNumberFormatting() {
        XCTAssertEqual(DSChartFormat.number(12), "12")
        XCTAssertEqual(DSChartFormat.number(12.5), "12.5")
        XCTAssertEqual(DSChartFormat.number(.nan), "0")
    }

    func testChartDescriptorBuilds() {
        let bars = DSChartDescriptor(title: "Orders", values: [1, 2, 3], labels: ["a", "b", "c"], isContinuous: false)
        XCTAssertEqual(bars.makeChartDescriptor().series.first?.dataPoints.count, 3)
        let line = DSChartDescriptor(title: "Trend", values: [5, 5], labels: nil, isContinuous: true)
        XCTAssertEqual(line.makeChartDescriptor().series.first?.dataPoints.count, 2)
    }
}
