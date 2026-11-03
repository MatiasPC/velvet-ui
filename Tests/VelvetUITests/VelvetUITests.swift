import XCTest
import SwiftUI
@testable import VelvetUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class VelvetUITests: XCTestCase {

    // MARK: - Spacing / Radius

    func testSpacingScale() {
        XCTAssertEqual(DSSpacing.xxs, 4)
        XCTAssertEqual(DSSpacing.xs, 8)
        XCTAssertEqual(DSSpacing.sm, 12)
        XCTAssertEqual(DSSpacing.md, 16)
        XCTAssertEqual(DSSpacing.lg, 20)
        XCTAssertEqual(DSSpacing.xl, 24)
        XCTAssertEqual(DSSpacing.xxl, 32)
    }

    func testRadiusScale() {
        XCTAssertTrue(DSRadius.xs < DSRadius.sm)
        XCTAssertTrue(DSRadius.sm < DSRadius.md)
        XCTAssertTrue(DSRadius.md < DSRadius.lg)
        XCTAssertTrue(DSRadius.lg < DSRadius.xl)
    }

    func testRadiusSemanticAliases() {
        XCTAssertEqual(DSRadius.card, 20, "Cards are 20pt — a product rule, not a convention")
        XCTAssertEqual(DSRadius.surface, 16)
        XCTAssertEqual(DSRadius.control, 12)
        XCTAssertEqual(DSRadius.chip, DSRadius.pill)
    }

    // MARK: - Colors

    func testColorHexInit() {
        let _ = Color(hex: "FF385C")
        let _ = Color(hex: "#FF385C")
        let _ = Color(hex: "AABBCCDD")
    }

    func testDefaultPaletteExists() {
        let palette = DSColors.defaultPalette
        let _ = palette.primary
        let _ = palette.secondary
        let _ = palette.textPrimary
        let _ = palette.backgroundPrimary
    }

    // MARK: - Theme

    func testThemeInitialization() {
        let theme = DSTheme()
        let _ = theme.light
        let _ = theme.dark
        XCTAssertEqual(theme.style, .sunset, "Sunset is the default style")
    }

    func testThemeResolvesPaletteForScheme() {
        let theme = DSTheme()
        let light = theme.resolved(for: .light)
        let dark = theme.resolved(for: .dark)

        XCTAssertFalse(light.isDark)
        XCTAssertTrue(dark.isDark)
        XCTAssertEqual(light.palette.backgroundPrimary, DSColors.defaultPalette.backgroundPrimary)
        XCTAssertEqual(dark.palette.backgroundPrimary, DSColors.defaultDarkPalette.backgroundPrimary)
        XCTAssertEqual(light.ink, theme.style.ink)
        XCTAssertEqual(dark.ink, theme.style.inkDark)
        XCTAssertEqual(light.backgroundColor, theme.style.background.light)
        XCTAssertEqual(dark.backgroundColor, theme.style.background.dark)
    }

    func testSubtleFillFollowsBackdropFlag() {
        let theme = DSTheme()
        let plain = theme.resolved(for: .light, onBackdrop: false)
        let onBackdrop = theme.resolved(for: .light, onBackdrop: true)

        XCTAssertEqual(plain.subtleFill, plain.palette.backgroundSecondary)
        XCTAssertEqual(onBackdrop.subtleFill, DSWash.surface(for: .light))
    }

    func testThemeStyleSwitchIsObserved() {
        let theme = DSTheme()
        theme.style = .lagoon
        XCTAssertEqual(theme.resolved(for: .light).accent, DSThemeStyle.lagoon.accent)
    }

    func testBuiltInStylesAreDistinct() {
        let ids = DSThemeStyle.all.map(\.id)
        XCTAssertEqual(ids.count, 3)
        XCTAssertEqual(Set(ids).count, 3)

        // Every style sits on a shipped solid background, and the light and
        // dark tones of each background are different surfaces.
        for style in DSThemeStyle.all {
            XCTAssertTrue(DSBackground.all.contains(style.background), "\(style.name) uses an unknown background")
            XCTAssertNotEqual(style.background.light, style.background.dark)
        }
        XCTAssertEqual(Set(DSThemeStyle.all.map(\.background.id)).count, 3, "Styles should not share a background tone")
    }

    // MARK: - Contrast (WCAG AA)
    // Every built-in style must keep text readable on the surfaces it is used on.
    // A new style that fails here is not shippable.

    func testThemeStylesMeetAAContrast() {
        for style in DSThemeStyle.all {
            assertContrast(style.onAccent, on: style.accent, atLeast: 4.5, "\(style.name) onAccent on accent")
            assertContrast(style.ink, on: style.background.light, atLeast: 4.5, "\(style.name) ink on light page")
            assertContrast(style.inkDark, on: style.background.dark, atLeast: 4.5, "\(style.name) inkDark on dark page")
        }
    }

    // MARK: - Motion

    func testPressConstants() {
        XCTAssertEqual(DSPress.scale, 0.96, "Press scale 0.96 is a product rule")
        XCTAssertEqual(DSPress.iconScale, 0.88)
    }

    // MARK: - Shadows

    func testShadowValues() {
        XCTAssertEqual(DSShadow.none.radius, 0)
        XCTAssertTrue(DSShadow.sm.radius < DSShadow.md.radius)
        XCTAssertTrue(DSShadow.md.radius < DSShadow.lg.radius)
        XCTAssertTrue(DSShadow.lg.radius < DSShadow.xl.radius)
        XCTAssertEqual(DSShadow.glow(.red).radius, 20)
    }

    // MARK: - Typography

    func testTypographyHasNumericStyles() {
        XCTAssertTrue(DSTextStyle.allCases.contains(.numeric))
        XCTAssertTrue(DSTextStyle.allCases.contains(.badge))
        XCTAssertLessThan(DSTextStyle.hero.kerning, 0, "Titles use negative tracking")
        XCTAssertGreaterThan(DSTextStyle.overline.kerning, 0)
    }

    // MARK: - Helpers

    private func assertContrast(
        _ foreground: Color,
        on background: Color,
        atLeast minimum: Double,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let fg = rgb(foreground), let bg = rgb(background) else {
            XCTFail("Could not resolve RGB for \(label)", file: file, line: line)
            return
        }
        let ratio = contrastRatio(fg, bg)
        XCTAssertGreaterThanOrEqual(
            ratio, minimum,
            String(format: "%@: %.2f:1 is below %.1f:1", label, ratio, minimum),
            file: file, line: line
        )
    }

    private func rgb(_ color: Color) -> (Double, Double, Double)? {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return (Double(r), Double(g), Double(b))
        #elseif canImport(AppKit)
        guard let c = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        return (Double(c.redComponent), Double(c.greenComponent), Double(c.blueComponent))
        #else
        return nil
        #endif
    }

    private func luminance(_ c: (Double, Double, Double)) -> Double {
        func lin(_ v: Double) -> Double {
            v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(c.0) + 0.7152 * lin(c.1) + 0.0722 * lin(c.2)
    }

    private func contrastRatio(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Double {
        let la = luminance(a), lb = luminance(b)
        let (hi, lo) = la > lb ? (la, lb) : (lb, la)
        return (hi + 0.05) / (lo + 0.05)
    }
}
