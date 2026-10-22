import SwiftUI

// MARK: - Design System Spacing
// A harmonious spacing scale based on 4pt grid.
// Consistent spacing is what separates amateur from professional UI.

public enum DSSpacing {
    /// 2pt — Hairline gaps
    public static let xxxs: CGFloat = 2
    /// 4pt — Tight internal padding
    public static let xxs: CGFloat = 4
    /// 8pt — Compact spacing (between related items)
    public static let xs: CGFloat = 8
    /// 12pt — Default internal padding
    public static let sm: CGFloat = 12
    /// 16pt — Standard padding and gaps
    public static let md: CGFloat = 16
    /// 20pt — Comfortable padding
    public static let lg: CGFloat = 20
    /// 24pt — Section spacing
    public static let xl: CGFloat = 24
    /// 32pt — Group spacing
    public static let xxl: CGFloat = 32
    /// 40pt — Large section breaks
    public static let xxxl: CGFloat = 40
    /// 48pt — Screen-level spacing
    public static let huge: CGFloat = 48
    /// 64pt — Hero spacing
    public static let massive: CGFloat = 64

    // MARK: - Screen Margins

    /// Standard horizontal screen margin (20pt — Airbnb-style generous margins)
    public static let screenHorizontal: CGFloat = 20
    /// Compact horizontal margin for dense layouts
    public static let screenHorizontalCompact: CGFloat = 16
    /// Top screen padding
    public static let screenTop: CGFloat = 16
    /// Bottom screen padding (above tab bar)
    public static let screenBottom: CGFloat = 24
}

// MARK: - Spacing View Helpers

public extension View {
    /// Add standard screen horizontal padding
    func dsScreenPadding() -> some View {
        self.padding(.horizontal, DSSpacing.screenHorizontal)
    }

    /// Add uniform Design System spacing as padding
    func dsPadding(_ spacing: CGFloat) -> some View {
        self.padding(spacing)
    }

    /// Add Design System horizontal + vertical padding
    func dsPadding(horizontal: CGFloat = 0, vertical: CGFloat = 0) -> some View {
        self.padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
    }
}
