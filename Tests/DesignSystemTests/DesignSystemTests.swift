import XCTest
@testable import DesignSystem

final class DesignSystemTests: XCTestCase {

    func testSpacingScale() {
        // Verify spacing follows 4pt grid
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

    func testColorHexInit() {
        // Should not crash with valid hex
        let _ = Color(hex: "FF385C")
        let _ = Color(hex: "#FF385C")
        let _ = Color(hex: "AABBCCDD")
    }

    func testDefaultPaletteExists() {
        // Verify default palette is accessible
        let palette = DSColors.defaultPalette
        let _ = palette.primary
        let _ = palette.secondary
        let _ = palette.textPrimary
        let _ = palette.backgroundPrimary
    }

    func testThemeInitialization() {
        let theme = DSTheme()
        let _ = theme.light
        let _ = theme.dark
    }

    func testShadowValues() {
        XCTAssertEqual(DSShadow.none.radius, 0)
        XCTAssertTrue(DSShadow.sm.radius < DSShadow.md.radius)
        XCTAssertTrue(DSShadow.md.radius < DSShadow.lg.radius)
        XCTAssertTrue(DSShadow.lg.radius < DSShadow.xl.radius)
    }
}
