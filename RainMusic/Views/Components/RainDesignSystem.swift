import SwiftUI

struct RainSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

struct RainTypography {
    static let bodySmall: Font = .system(size: 12)
    static let body: Font = .system(size: 13)
    static let bodyMedium: Font = .system(size: 14)
    static let headline: Font = .system(size: 15)
    static let headlineLarge: Font = .system(size: 16)
    static let title: Font = .system(size: 28)
}

struct RainCornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 20
    static let pill: CGFloat = 26
    static let full: CGFloat = 9999
}

struct RainShadow {
    static let small: Shadow = Shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    static let medium: Shadow = Shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    static let large: Shadow = Shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    static let xl: Shadow = Shadow(color: .black.opacity(0.2), radius: 16, y: 8)
    
    static let accent: Shadow = Shadow(color: .rainAccent.opacity(0.4), radius: 10, y: 4)
    static let accentLarge: Shadow = Shadow(color: .rainAccent.opacity(0.3), radius: 16, y: 8)
}

struct RainLayout {
    static let appWidth: CGFloat = 390
    static let appHeight: CGFloat = 844
    static let statusBarHeight: CGFloat = 62
    static let bottomTabHeight: CGFloat = 95
    static let albumArtSize: CGFloat = 280
    static let progressBarWidth: CGFloat = 350
    static let controlsPanelHeight: CGFloat = 80
}