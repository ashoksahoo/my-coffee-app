import Foundation

enum RoastLevel: String, Codable, CaseIterable {
    case light = "light"
    case mediumLight = "medium_light"
    case medium = "medium"
    case mediumDark = "medium_dark"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .mediumLight: return "Medium-Light"
        case .medium: return "Medium"
        case .mediumDark: return "Medium-Dark"
        case .dark: return "Dark"
        }
    }
}
