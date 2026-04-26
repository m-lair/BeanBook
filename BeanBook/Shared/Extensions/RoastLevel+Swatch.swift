import SwiftUI

extension RoastLevel {
    /// Color rail used by the C2 bag rows + bag-detail color block.
    var swatch: Color {
        switch self {
        case .light: Color(hex: "C9A675")
        case .mediumLight: Color(hex: "A77742")
        case .medium: Color(hex: "8A4F2A")
        case .mediumDark: Color(hex: "5C3320")
        case .dark: Color(hex: "2E1810")
        }
    }
}
