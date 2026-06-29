import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// 设计色板
extension Color {
    static let rainBgDark = Color(hex: 0x0A1628)
    static let rainBgPill = Color(hex: 0x111B40)
    static let rainBgBorder = Color(hex: 0x1E3A5F)
    static let rainAccent = Color(hex: 0x4FC3F7)
    static let rainAccentDark = Color(hex: 0x29B6F6)
    static let rainTextPrimary = Color(hex: 0xE0E8F0)
    static let rainTextSecondary = Color(hex: 0x8899AA)
    static let rainDotGray = Color(hex: 0xB3B3B3)
    static let rainCoverNavy1 = Color(hex: 0x2B4D76)
    static let rainCoverNavy2 = Color(hex: 0x1E3A5F)
}
