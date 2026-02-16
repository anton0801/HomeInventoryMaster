import SwiftUI

struct Theme {
    struct Colors {
        static let primary = Color(hex: "1A2332")
        static let primaryDark = Color(hex: "0F1419")
        static let secondary = Color(hex: "2C3E50")
        static let accent = Color(hex: "00B4D8")
        static let accentLight = Color(hex: "90E0EF")
        static let gold = Color(hex: "D4AF37")
        static let goldLight = Color(hex: "F4E4C1")
        static let success = Color(hex: "2D6A4F")
        static let warning = Color(hex: "F4A261")
        static let error = Color(hex: "C1121F")
        static let background = Color(hex: "F8F9FA")
        static let cardBackground = Color.white
        static let textPrimary = Color(hex: "1A2332")
        static let textSecondary = Color(hex: "6C757D")
    }
    
    struct Fonts {
        static func title(size: CGFloat = 28) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        
        static func headline(size: CGFloat = 20) -> Font {
            .system(size: size, weight: .semibold, design: .default)
        }
        
        static func body(size: CGFloat = 16) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }
        
        static func caption(size: CGFloat = 13) -> Font {
            .system(size: size, weight: .medium, design: .default)
        }
    }
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
