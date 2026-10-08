import SwiftUI

enum ThemeDefinition: String, CaseIterable, Identifiable, Sendable {
    case blue, pink, green, yellow, mono
    var id: String { rawValue }
    var name: String {
        switch self {
        case .blue: L("Blue")
        case .pink: L("Pink")
        case .green: L("Green")
        case .yellow: L("Yellow")
        case .mono: L("Monochrome")
        }
    }
    var background: Color { Color(hex: 0xFAFAFA) }
    var mapUnvisited: Color { Color(hex: 0xECEFF1) }
    var mapVisited: Color {
        switch self {
        case .blue: Color(hex: 0xDCEEFF)
        case .pink: Color(hex: 0xF7E1E8)
        case .green: Color(hex: 0xDFEFE3)
        case .yellow: Color(hex: 0xF4ECCB)
        case .mono: Color(hex: 0xBFC5CA)
        }
    }
    var mapSelected: Color { mapVisited.opacity(0.85) }
    var primaryText: Color { Color(hex: 0x262B30) }
    var secondaryText: Color { Color(hex: 0x737B82) }
    var border: Color { .white }
    var accent: Color {
        switch self {
        case .blue: Color(hex: 0x426887)
        case .pink: Color(hex: 0x865B6B)
        case .green: Color(hex: 0x4F735C)
        case .yellow: Color(hex: 0x7E6C32)
        case .mono: Color(hex: 0x424950)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255, opacity: 1)
    }
}
