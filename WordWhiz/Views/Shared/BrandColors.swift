import SwiftUI

// MARK: - Design Tokens

enum BrandColors {
    static let accent = Color(hex: "5B7FFF")
    static let accentHover = Color(hex: "7B9AFF")
    static let accentDim = Color(hex: "5B7FFF").opacity(0.15)

    // Backgrounds
    static let bgPrimary = Color(hex: "1E1E1E")
    static let bgSecondary = Color(hex: "2A2A2A")
    static let bgTertiary = Color(hex: "333333")
    static let bgPanel = Color(hex: "252525")

    // Text
    static let textPrimary = Color(hex: "E8E8E8")
    static let textSecondary = Color(hex: "999999")
    static let textMuted = Color(hex: "666666")

    // Semantic
    static let border = Color(hex: "3A3A3A")
    static let green = Color(hex: "4CD964")
    static let orange = Color(hex: "FF9500")
    static let red = Color(hex: "FF3B30")
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
